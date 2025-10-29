"""
Advanced Logging System
Provides comprehensive logging, analytics and reporting capabilities
"""

import logging
import logging.handlers
from pathlib import Path
import json
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Union
import threading
import queue
import sqlite3
import pandas as pd
import matplotlib.pyplot as plt
from dataclasses import dataclass, asdict
import hashlib

from ..core_engine.config_manager import ConfigManager


@dataclass
class LogEvent:
    """Log event data structure"""
    timestamp: str
    level: str
    module: str
    event_type: str
    message: str
    details: Dict
    session_id: str


class SecurityLogger:
    """Advanced logging and analytics system"""
    
    def __init__(self, config_manager: ConfigManager):
        self.config = config_manager
        
        # Logging setup
        self.log_dir = Path.home() / ".antivirus_logs"
        self.db_path = self.log_dir / "security_logs.db"
        self.log_queue = queue.Queue()
        self.is_running = False
        
        # Session tracking
        self.session_id = self._generate_session_id()
        
        # File loggers
        self.file_loggers = {}
        self.log_files = {
            "security": self.log_dir / "security.log",
            "scan": self.log_dir / "scan.log",
            "threat": self.log_dir / "threat.log",
            "system": self.log_dir / "system.log"
        }
        
        # Database connection
        self.db_conn = None
        self.write_thread = None
        
        # Analytics cache
        self.analytics_cache = {
            "threat_summary": None,
            "performance_metrics": None,
            "last_update": None
        }
        self.cache_duration = 300  # 5 minutes
    
    async def initialize(self):
        """Initialize logging system"""
        print("Initializing logging system")  # Temporary debug print
        
        try:
            # Create log directory
            self.log_dir.mkdir(parents=True, exist_ok=True)
            
            # Initialize file loggers
            self._setup_file_loggers()
            
            # Initialize database
            await self._init_database()
            
            # Start processing thread
            self.is_running = True
            self.write_thread = threading.Thread(target=self._process_log_queue)
            self.write_thread.daemon = True
            self.write_thread.start()
            
            print("Logging system initialized")  # Temporary debug print
            
        except Exception as e:
            print(f"Failed to initialize logging system: {e}")  # Temporary debug print
            raise
    
    def _setup_file_loggers(self):
        """Setup file loggers"""
        for name, path in self.log_files.items():
            # Create logger
            logger = logging.getLogger(f"antivirus.{name}")
            logger.setLevel(logging.DEBUG)
            
            # Create rotating file handler
            handler = logging.handlers.RotatingFileHandler(
                path,
                maxBytes=10_000_000,  # 10MB
                backupCount=5
            )
            
            # Create formatter
            formatter = logging.Formatter(
                '%(asctime)s - %(levelname)s - %(message)s'
            )
            handler.setFormatter(formatter)
            
            # Add handler to logger
            logger.addHandler(handler)
            
            # Store logger reference
            self.file_loggers[name] = logger
    
    async def _init_database(self):
        """Initialize SQLite database"""
        try:
            self.db_conn = sqlite3.connect(str(self.db_path))
            cursor = self.db_conn.cursor()
            
            # Create tables
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS security_logs (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp TEXT NOT NULL,
                    level TEXT NOT NULL,
                    module TEXT NOT NULL,
                    event_type TEXT NOT NULL,
                    message TEXT NOT NULL,
                    details TEXT,
                    session_id TEXT NOT NULL
                )
            """)
            
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS threat_logs (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp TEXT NOT NULL,
                    threat_type TEXT NOT NULL,
                    severity INTEGER NOT NULL,
                    file_path TEXT,
                    action_taken TEXT,
                    details TEXT,
                    session_id TEXT NOT NULL
                )
            """)
            
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS performance_logs (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp TEXT NOT NULL,
                    cpu_percent REAL,
                    memory_percent REAL,
                    disk_percent REAL,
                    network_bytes_sent INTEGER,
                    network_bytes_recv INTEGER,
                    session_id TEXT NOT NULL
                )
            """)
            
            self.db_conn.commit()
            
        except Exception as e:
            print(f"Database initialization error: {e}")  # Temporary debug print
            raise
    
    def _generate_session_id(self) -> str:
        """Generate unique session ID"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        random = hashlib.md5(str(datetime.now().timestamp()).encode()).hexdigest()[:6]
        return f"session_{timestamp}_{random}"
    
    def log_event(self, level: str, module: str, event_type: str, 
                  message: str, details: Dict = None):
        """Log security event"""
        event = LogEvent(
            timestamp=datetime.now().isoformat(),
            level=level,
            module=module,
            event_type=event_type,
            message=message,
            details=details or {},
            session_id=self.session_id
        )
        
        # Add to queue for database storage
        self.log_queue.put(event)
        
        # Log to file
        logger = self.file_loggers.get(module.lower(), self.file_loggers["system"])
        log_message = f"[{event_type}] {message}"
        
        if level == "DEBUG":
            logger.debug(log_message)
        elif level == "INFO":
            logger.info(log_message)
        elif level == "WARNING":
            logger.warning(log_message)
        elif level == "ERROR":
            logger.error(log_message)
        elif level == "CRITICAL":
            logger.critical(log_message)
    
    def log_threat(self, threat_type: str, severity: int, file_path: Optional[str],
                   action: str, details: Dict = None):
        """Log threat detection"""
        threat = {
            "timestamp": datetime.now().isoformat(),
            "threat_type": threat_type,
            "severity": severity,
            "file_path": file_path,
            "action_taken": action,
            "details": json.dumps(details) if details else None,
            "session_id": self.session_id
        }
        
        # Log to threat file
        message = f"Threat detected: {threat_type} (Severity: {severity})"
        if file_path:
            message += f" in {file_path}"
        message += f". Action: {action}"
        
        self.file_loggers["threat"].warning(message)
        
        # Store in database
        try:
            cursor = self.db_conn.cursor()
            cursor.execute("""
                INSERT INTO threat_logs 
                (timestamp, threat_type, severity, file_path, action_taken, details, session_id)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (
                threat["timestamp"], threat["threat_type"], threat["severity"],
                threat["file_path"], threat["action_taken"], threat["details"],
                threat["session_id"]
            ))
            self.db_conn.commit()
            
        except Exception as e:
            self.log_error(f"Error logging threat: {e}")
    
    def log_performance(self, metrics: Dict):
        """Log performance metrics"""
        try:
            cursor = self.db_conn.cursor()
            cursor.execute("""
                INSERT INTO performance_logs
                (timestamp, cpu_percent, memory_percent, disk_percent,
                 network_bytes_sent, network_bytes_recv, session_id)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (
                datetime.now().isoformat(),
                metrics.get("cpu_percent"),
                metrics.get("memory_percent"),
                metrics.get("disk_percent"),
                metrics.get("network", {}).get("bytes_sent"),
                metrics.get("network", {}).get("bytes_recv"),
                self.session_id
            ))
            self.db_conn.commit()
            
        except Exception as e:
            self.log_error(f"Error logging performance: {e}")
    
    def _process_log_queue(self):
        """Process queued log events"""
        while self.is_running:
            try:
                # Get event from queue
                event = self.log_queue.get(timeout=1)
                
                # Store in database
                cursor = self.db_conn.cursor()
                cursor.execute("""
                    INSERT INTO security_logs
                    (timestamp, level, module, event_type, message, details, session_id)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                """, (
                    event.timestamp,
                    event.level,
                    event.module,
                    event.event_type,
                    event.message,
                    json.dumps(event.details),
                    event.session_id
                ))
                self.db_conn.commit()
                
            except queue.Empty:
                continue
            except Exception as e:
                print(f"Error processing log event: {e}")  # Temporary debug print
    
    def get_recent_events(self, hours: int = 24, 
                         levels: Optional[List[str]] = None) -> pd.DataFrame:
        """Get recent security events"""
        try:
            query = """
                SELECT timestamp, level, module, event_type, message, details
                FROM security_logs
                WHERE timestamp >= ?
            """
            
            if levels:
                query += f" AND level IN ({','.join(['?']*len(levels))})"
            
            query += " ORDER BY timestamp DESC"
            
            # Calculate time threshold
            threshold = (datetime.now() - timedelta(hours=hours)).isoformat()
            
            cursor = self.db_conn.cursor()
            if levels:
                cursor.execute(query, [threshold] + levels)
            else:
                cursor.execute(query, [threshold])
            
            columns = ["timestamp", "level", "module", "event_type", "message", "details"]
            df = pd.DataFrame(cursor.fetchall(), columns=columns)
            
            # Parse timestamps and details
            df["timestamp"] = pd.to_datetime(df["timestamp"])
            df["details"] = df["details"].apply(lambda x: json.loads(x) if x else {})
            
            return df
            
        except Exception as e:
            self.log_error(f"Error getting recent events: {e}")
            return pd.DataFrame()
    
    def get_threat_summary(self, force_refresh: bool = False) -> Dict:
        """Get threat detection summary"""
        # Check cache
        if not force_refresh and self.analytics_cache["threat_summary"]:
            cache_age = (datetime.now() - self.analytics_cache["last_update"]).total_seconds()
            if cache_age < self.cache_duration:
                return self.analytics_cache["threat_summary"]
        
        try:
            cursor = self.db_conn.cursor()
            
            # Get threat counts by type
            cursor.execute("""
                SELECT threat_type, COUNT(*) as count, AVG(severity) as avg_severity
                FROM threat_logs
                GROUP BY threat_type
                ORDER BY count DESC
            """)
            threat_types = cursor.fetchall()
            
            # Get daily threat counts
            cursor.execute("""
                SELECT date(timestamp) as date, COUNT(*) as count
                FROM threat_logs
                GROUP BY date(timestamp)
                ORDER BY date DESC
                LIMIT 30
            """)
            daily_counts = cursor.fetchall()
            
            # Get high severity threats
            cursor.execute("""
                SELECT *
                FROM threat_logs
                WHERE severity >= 8
                ORDER BY timestamp DESC
                LIMIT 10
            """)
            high_severity = cursor.fetchall()
            
            summary = {
                "threat_types": {
                    t[0]: {"count": t[1], "avg_severity": t[2]}
                    for t in threat_types
                },
                "daily_counts": {
                    str(d[0]): d[1] for d in daily_counts
                },
                "high_severity_threats": [
                    {
                        "timestamp": t[1],
                        "threat_type": t[2],
                        "severity": t[3],
                        "file_path": t[4],
                        "action": t[5]
                    }
                    for t in high_severity
                ],
                "total_threats": sum(t[1] for t in threat_types)
            }
            
            # Update cache
            self.analytics_cache["threat_summary"] = summary
            self.analytics_cache["last_update"] = datetime.now()
            
            return summary
            
        except Exception as e:
            self.log_error(f"Error getting threat summary: {e}")
            return {}
    
    def get_performance_metrics(self, hours: int = 24) -> Dict:
        """Get system performance metrics"""
        try:
            # Calculate time threshold
            threshold = (datetime.now() - timedelta(hours=hours)).isoformat()
            
            cursor = self.db_conn.cursor()
            cursor.execute("""
                SELECT timestamp,
                       AVG(cpu_percent) as cpu_avg,
                       MAX(cpu_percent) as cpu_max,
                       AVG(memory_percent) as mem_avg,
                       MAX(memory_percent) as mem_max,
                       AVG(disk_percent) as disk_avg,
                       SUM(network_bytes_sent) as net_sent,
                       SUM(network_bytes_recv) as net_recv
                FROM performance_logs
                WHERE timestamp >= ?
                GROUP BY strftime('%H', timestamp)
                ORDER BY timestamp
            """, [threshold])
            
            results = cursor.fetchall()
            
            metrics = {
                "hourly_metrics": [
                    {
                        "timestamp": r[0],
                        "cpu_avg": r[1],
                        "cpu_max": r[2],
                        "memory_avg": r[3],
                        "memory_max": r[4],
                        "disk_avg": r[5],
                        "network_sent": r[6],
                        "network_recv": r[7]
                    }
                    for r in results
                ],
                "summary": {
                    "cpu_overall_avg": sum(r[1] for r in results) / len(results) if results else 0,
                    "memory_overall_avg": sum(r[3] for r in results) / len(results) if results else 0,
                    "disk_overall_avg": sum(r[5] for r in results) / len(results) if results else 0,
                    "total_network_sent": sum(r[6] for r in results),
                    "total_network_recv": sum(r[7] for r in results)
                }
            }
            
            return metrics
            
        except Exception as e:
            self.log_error(f"Error getting performance metrics: {e}")
            return {}
    
    def generate_report(self, report_type: str = "full") -> Dict:
        """Generate comprehensive security report"""
        try:
            report = {
                "generated_at": datetime.now().isoformat(),
                "session_id": self.session_id,
                "report_type": report_type
            }
            
            if report_type in ["full", "threats"]:
                report["threat_analysis"] = self.get_threat_summary(force_refresh=True)
            
            if report_type in ["full", "performance"]:
                report["performance_analysis"] = self.get_performance_metrics(hours=24)
            
            if report_type in ["full", "events"]:
                events_df = self.get_recent_events(hours=24)
                report["recent_events"] = events_df.to_dict(orient="records")
            
            # Generate visualizations
            if report_type == "full":
                report["visualizations"] = self._generate_report_visualizations()
            
            return report
            
        except Exception as e:
            self.log_error(f"Error generating report: {e}")
            return {}
    
    def _generate_report_visualizations(self) -> Dict:
        """Generate report visualizations"""
        visualizations = {}
        
        try:
            # Threat type distribution
            threat_summary = self.get_threat_summary()
            threat_types = threat_summary.get("threat_types", {})
            
            if threat_types:
                fig, ax = plt.subplots(figsize=(10, 6))
                types = list(threat_types.keys())
                counts = [t["count"] for t in threat_types.values()]
                
                ax.bar(types, counts)
                ax.set_title("Threat Distribution")
                ax.set_xlabel("Threat Type")
                ax.set_ylabel("Count")
                plt.xticks(rotation=45)
                
                visualizations["threat_distribution"] = self._save_plot(fig, "threat_dist.png")
            
            # Performance trends
            metrics = self.get_performance_metrics()
            hourly = metrics.get("hourly_metrics", [])
            
            if hourly:
                fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8))
                
                times = [datetime.fromisoformat(h["timestamp"]) for h in hourly]
                cpu = [h["cpu_avg"] for h in hourly]
                memory = [h["memory_avg"] for h in hourly]
                
                ax1.plot(times, cpu, label="CPU")
                ax1.plot(times, memory, label="Memory")
                ax1.set_title("Resource Usage Trends")
                ax1.set_xlabel("Time")
                ax1.set_ylabel("Percentage")
                ax1.legend()
                
                network_in = [h["network_recv"] / 1_000_000 for h in hourly]  # MB
                network_out = [h["network_sent"] / 1_000_000 for h in hourly]  # MB
                
                ax2.plot(times, network_in, label="Network In")
                ax2.plot(times, network_out, label="Network Out")
                ax2.set_title("Network Traffic")
                ax2.set_xlabel("Time")
                ax2.set_ylabel("MB")
                ax2.legend()
                
                plt.tight_layout()
                visualizations["performance_trends"] = self._save_plot(fig, "performance.png")
            
            return visualizations
            
        except Exception as e:
            self.log_error(f"Error generating visualizations: {e}")
            return {}
    
    def _save_plot(self, fig: plt.Figure, filename: str) -> str:
        """Save plot to file and return path"""
        try:
            plots_dir = self.log_dir / "plots"
            plots_dir.mkdir(exist_ok=True)
            
            path = plots_dir / filename
            fig.savefig(path)
            plt.close(fig)
            
            return str(path)
            
        except Exception as e:
            self.log_error(f"Error saving plot: {e}")
            return ""
    
    def export_logs(self, start_date: str, end_date: str, 
                    format: str = "csv") -> Optional[str]:
        """Export logs to file"""
        try:
            # Create export directory
            export_dir = self.log_dir / "exports"
            export_dir.mkdir(exist_ok=True)
            
            # Generate filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"security_logs_{timestamp}.{format}"
            export_path = export_dir / filename
            
            # Query logs
            cursor = self.db_conn.cursor()
            cursor.execute("""
                SELECT *
                FROM security_logs
                WHERE timestamp BETWEEN ? AND ?
                ORDER BY timestamp
            """, [start_date, end_date])
            
            columns = [description[0] for description in cursor.description]
            data = cursor.fetchall()
            
            if format == "csv":
                df = pd.DataFrame(data, columns=columns)
                df.to_csv(export_path, index=False)
            
            elif format == "json":
                logs = [dict(zip(columns, row)) for row in data]
                with open(export_path, 'w') as f:
                    json.dump(logs, f, indent=2)
            
            return str(export_path)
            
        except Exception as e:
            self.log_error(f"Error exporting logs: {e}")
            return None
    
    def cleanup_old_logs(self, days: int = 90):
        """Clean up old logs"""
        try:
            threshold = (datetime.now() - timedelta(days=days)).isoformat()
            
            cursor = self.db_conn.cursor()
            
            # Clean up database logs
            cursor.execute("DELETE FROM security_logs WHERE timestamp < ?", [threshold])
            cursor.execute("DELETE FROM threat_logs WHERE timestamp < ?", [threshold])
            cursor.execute("DELETE FROM performance_logs WHERE timestamp < ?", [threshold])
            
            self.db_conn.commit()
            
            # Clean up log files
            for log_file in self.log_files.values():
                if log_file.exists():
                    # Read file content
                    with open(log_file, 'r') as f:
                        lines = f.readlines()
                    
                    # Keep only recent logs
                    new_lines = []
                    for line in lines:
                        try:
                            log_date = datetime.strptime(line[:19], "%Y-%m-%d %H:%M:%S")
                            if log_date > datetime.now() - timedelta(days=days):
                                new_lines.append(line)
                        except ValueError:
                            continue
                    
                    # Write back filtered content
                    with open(log_file, 'w') as f:
                        f.writelines(new_lines)
            
            # Clean up plots and exports
            for directory in ["plots", "exports"]:
                dir_path = self.log_dir / directory
                if dir_path.exists():
                    for file in dir_path.iterdir():
                        if file.stat().st_mtime < (datetime.now() - timedelta(days=days)).timestamp():
                            file.unlink()
            
        except Exception as e:
            self.log_error(f"Error cleaning up logs: {e}")
    
    def log_debug(self, message: str, module: str = "system", event_type: str = "debug",
                  details: Dict = None):
        """Log debug message"""
        self.log_event("DEBUG", module, event_type, message, details)
    
    def log_info(self, message: str, module: str = "system", event_type: str = "info",
                 details: Dict = None):
        """Log info message"""
        self.log_event("INFO", module, event_type, message, details)
    
    def log_warning(self, message: str, module: str = "system", event_type: str = "warning",
                    details: Dict = None):
        """Log warning message"""
        self.log_event("WARNING", module, event_type, message, details)
    
    def log_error(self, message: str, module: str = "system", event_type: str = "error",
                  details: Dict = None):
        """Log error message"""
        self.log_event("ERROR", module, event_type, message, details)
    
    def log_critical(self, message: str, module: str = "system", event_type: str = "critical",
                     details: Dict = None):
        """Log critical message"""
        self.log_event("CRITICAL", module, event_type, message, details)
    
    def stop(self):
        """Stop logging system"""
        self.is_running = False
        if self.write_thread:
            self.write_thread.join()
        
        if self.db_conn:
            self.db_conn.close()
            self.db_conn = None
