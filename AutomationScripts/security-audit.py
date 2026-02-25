#!/usr/bin/env python3
"""
iBridge security audit helper.
Scans database and security log files for suspicious patterns and outputs JSON.
"""

from __future__ import annotations

import json
import re
import sqlite3
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List


SUSPICIOUS_TEXT_PATTERN = re.compile(
    r"(?i)(<script|javascript:|onerror=|onload=|union\s+select|drop\s+table|insert\s+into|\.\./|%2e%2e|cmd\.exe|powershell)"
)
SUSPICIOUS_LOG_PATTERN = re.compile(
    r"(?i)(SUSPICIOUS_REQUEST_BLOCKED|LOGIN_ATTEMPT_INVALID_USER|CSP_VIOLATION|REQUEST_TOO_LARGE|blocked)"
)


def has_table(cursor: sqlite3.Cursor, table_name: str) -> bool:
    row = cursor.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        (table_name,),
    ).fetchone()
    return row is not None


def scan_db(db_path: Path) -> Dict[str, object]:
    report: Dict[str, object] = {
        "db_path": str(db_path),
        "users_total": 0,
        "users_failed_login_gt0": 0,
        "users_locked_now": 0,
        "tickets_total": 0,
        "tickets_suspicious_count": 0,
        "tickets_suspicious_samples": [],
        "activity_total": 0,
        "activity_suspicious_count": 0,
        "activity_suspicious_samples": [],
    }

    if not db_path.exists():
        report["error"] = "Database file not found"
        return report

    conn = sqlite3.connect(str(db_path))
    try:
        cursor = conn.cursor()

        if has_table(cursor, "user"):
            report["users_total"] = cursor.execute("SELECT COUNT(*) FROM user").fetchone()[0]
            report["users_failed_login_gt0"] = cursor.execute(
                "SELECT COUNT(*) FROM user WHERE COALESCE(failed_login_attempts, 0) > 0"
            ).fetchone()[0]
            report["users_locked_now"] = cursor.execute(
                "SELECT COUNT(*) FROM user WHERE locked_until IS NOT NULL"
            ).fetchone()[0]

        if has_table(cursor, "ticket"):
            rows = cursor.execute("SELECT id, title, description FROM ticket").fetchall()
            suspicious: List[Dict[str, object]] = []
            for ticket_id, title, description in rows:
                text = f"{title or ''} {description or ''}"
                if SUSPICIOUS_TEXT_PATTERN.search(text):
                    suspicious.append({"id": ticket_id, "title": title or ""})
            report["tickets_total"] = len(rows)
            report["tickets_suspicious_count"] = len(suspicious)
            report["tickets_suspicious_samples"] = suspicious[:20]

        if has_table(cursor, "activity_log"):
            rows = cursor.execute(
                "SELECT id, activity_type, activity_data, ip_address, user_agent FROM activity_log"
            ).fetchall()
            suspicious = []
            for row in rows:
                event_id, activity_type, activity_data, ip_address, user_agent = row
                text = f"{activity_type or ''} {activity_data or ''} {ip_address or ''} {user_agent or ''}"
                if SUSPICIOUS_TEXT_PATTERN.search(text):
                    suspicious.append({"id": event_id, "activity_type": activity_type or ""})
            report["activity_total"] = len(rows)
            report["activity_suspicious_count"] = len(suspicious)
            report["activity_suspicious_samples"] = suspicious[:20]
    finally:
        conn.close()

    return report


def scan_security_log(log_path: Path) -> Dict[str, object]:
    report = {
        "log_path": str(log_path),
        "exists": log_path.exists(),
        "total_entries": 0,
        "suspicious_entries": 0,
        "recent_suspicious_samples": [],
    }
    if not log_path.exists():
        return report

    lines = log_path.read_text(encoding="utf-8", errors="ignore").splitlines()
    suspicious_lines = [line for line in lines if SUSPICIOUS_LOG_PATTERN.search(line)]
    report["total_entries"] = len(lines)
    report["suspicious_entries"] = len(suspicious_lines)
    report["recent_suspicious_samples"] = suspicious_lines[-10:]
    return report


def main() -> None:
    repo_root = Path(__file__).resolve().parents[1]
    db_path = repo_root / "BackendServices" / "backend" / "instance" / "ibridge.db"
    log_path = repo_root / "logs" / "security-events.log"

    output = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "database_audit": scan_db(db_path),
        "security_log_audit": scan_security_log(log_path),
    }

    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
