"""
Web and Email Protection
Provides protection against malicious URLs, phishing, and email threats
"""
import asyncio
import aiohttp
import re
import dns.resolver
import email
import hashlib
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Set
from urllib.parse import urlparse
import json
import tempfile

from ..core_engine.config_manager import ConfigManager
from ..logging.security_logger import SecurityLogger


class WebFilter:
    """Web and email protection implementation"""
    
    def __init__(self, config_manager: ConfigManager, logger: SecurityLogger):
        self.config = config_manager
        self.logger = logger
        
        # Protection state
        self.is_filtering = False
        
        # URL databases
        self.malicious_urls = set()
        self.phishing_domains = set()
        self.safe_domains = set()
        self.url_cache = {}
        
        # Email protection
        self.spam_patterns = []
        self.blocked_senders = set()
        self.attachment_rules = []
        
        # Statistics
        self.stats = {
            "urls_scanned": 0,
            "urls_blocked": 0,
            "emails_scanned": 0,
            "threats_detected": 0,
            "start_time": None
        }
    
    async def initialize(self):
        """Initialize web and email protection"""
        self.logger.log_info("Initializing web and email protection")
        
        try:
            # Load protection databases
            await self._load_url_database()
            await self._load_email_rules()
            
            self.logger.log_info("Web and email protection initialized")
            
        except Exception as e:
            self.logger.log_error(f"Failed to initialize web protection: {e}")
            raise
    
    async def _load_url_database(self):
        """Load URL and domain databases"""
        database_file = Path.home() / ".antivirus_config" / "url_database.json"
        
        if database_file.exists():
            try:
                with open(database_file, 'r') as f:
                    data = json.load(f)
                    self.malicious_urls = set(data.get("malicious_urls", []))
                    self.phishing_domains = set(data.get("phishing_domains", []))
                    self.safe_domains = set(data.get("safe_domains", []))
            except Exception as e:
                self.logger.log_error(f"Error loading URL database: {e}")
        
        # Add default entries if empty
        if not self.malicious_urls:
            self.malicious_urls = {
                "malware.example.com/download",
                "exploit.example.net/payload",
                "trojan.example.org/install"
            }
        
        if not self.phishing_domains:
            self.phishing_domains = {
                "fake-bank.com",
                "login-secure-verify.net",
                "account-verify-service.com"
            }
    
    async def _load_email_rules(self):
        """Load email protection rules"""
        rules_file = Path.home() / ".antivirus_config" / "email_rules.json"
        
        if rules_file.exists():
            try:
                with open(rules_file, 'r') as f:
                    data = json.load(f)
                    self.spam_patterns = data.get("spam_patterns", [])
                    self.blocked_senders = set(data.get("blocked_senders", []))
                    self.attachment_rules = data.get("attachment_rules", [])
            except Exception as e:
                self.logger.log_error(f"Error loading email rules: {e}")
        
        # Add default rules if empty
        if not self.spam_patterns:
            self.spam_patterns = [
                r"(?i)viagra|cialis|pharmacy",
                r"(?i)lottery|winner|prize money",
                r"(?i)account.*verify|verify.*account",
                r"(?i)banking.*urgent|urgent.*banking"
            ]
        
        if not self.attachment_rules:
            self.attachment_rules = [
                {
                    "type": "extension",
                    "pattern": r"\.(exe|bat|cmd|sh|php|js)$",
                    "action": "block"
                },
                {
                    "type": "mime",
                    "pattern": "application/x-msdownload",
                    "action": "block"
                }
            ]
    
    async def start_filtering(self):
        """Start web and email filtering"""
        if self.is_filtering:
            return
        
        self.logger.log_info("Starting web and email protection")
        
        self.is_filtering = True
        self.stats["start_time"] = datetime.now().isoformat()
        
        self.logger.log_info("Web and email protection started")
    
    async def check_url(self, url: str) -> Dict:
        """Check if URL is safe"""
        self.stats["urls_scanned"] += 1
        
        try:
            # Check cache first
            if url in self.url_cache:
                cache_entry = self.url_cache[url]
                if datetime.now().timestamp() - cache_entry["timestamp"] < 3600:  # 1 hour cache
                    return cache_entry["result"]
            
            # Parse URL
            parsed_url = urlparse(url)
            domain = parsed_url.netloc.lower()
            full_path = f"{domain}{parsed_url.path}"
            
            # Check against databases
            if any(bad_url in full_path for bad_url in self.malicious_urls):
                result = self._create_threat_result(url, "malicious_url")
                self.stats["urls_blocked"] += 1
                return result
            
            if domain in self.phishing_domains:
                result = self._create_threat_result(url, "phishing")
                self.stats["urls_blocked"] += 1
                return result
            
            if domain in self.safe_domains:
                result = {
                    "safe": True,
                    "url": url,
                    "check_time": datetime.now().isoformat()
                }
                return result
            
            # Check URL reputation
            reputation = await self._check_url_reputation(url)
            if not reputation["safe"]:
                result = self._create_threat_result(url, reputation["threat_type"])
                self.stats["urls_blocked"] += 1
                return result
            
            # URL is safe
            result = {
                "safe": True,
                "url": url,
                "reputation_score": reputation.get("score", 0),
                "check_time": datetime.now().isoformat()
            }
            
            # Cache result
            self.url_cache[url] = {
                "timestamp": datetime.now().timestamp(),
                "result": result
            }
            
            return result
            
        except Exception as e:
            self.logger.log_error(f"Error checking URL {url}: {e}")
            return {
                "safe": False,
                "url": url,
                "error": str(e),
                "check_time": datetime.now().isoformat()
            }
    
    def _create_threat_result(self, url: str, threat_type: str) -> Dict:
        """Create threat result dictionary"""
        return {
            "safe": False,
            "url": url,
            "threat_type": threat_type,
            "severity": 8,
            "check_time": datetime.now().isoformat()
        }
    
    async def _check_url_reputation(self, url: str) -> Dict:
        """Check URL reputation using external services"""
        try:
            # In production, integrate with URL reputation services
            # For demonstration, implement basic checks
            
            parsed_url = urlparse(url)
            domain = parsed_url.netloc.lower()
            
            # Check domain age
            domain_age = await self._check_domain_age(domain)
            if domain_age and domain_age < 30:  # Domain less than 30 days old
                return {
                    "safe": False,
                    "threat_type": "suspicious_domain",
                    "score": 2
                }
            
            # Check SSL certificate
            ssl_valid = await self._check_ssl_certificate(domain)
            if not ssl_valid:
                return {
                    "safe": False,
                    "threat_type": "invalid_ssl",
                    "score": 3
                }
            
            return {"safe": True, "score": 8}
            
        except Exception as e:
            self.logger.log_error(f"Error checking URL reputation: {e}")
            return {"safe": True, "score": 5}  # Default to somewhat safe on error
    
    async def _check_domain_age(self, domain: str) -> Optional[int]:
        """Check domain registration age in days"""
        try:
            # In production, use WHOIS lookup
            # For demonstration, return random age
            return 100
        except Exception:
            return None
    
    async def _check_ssl_certificate(self, domain: str) -> bool:
        """Check if domain has valid SSL certificate"""
        try:
            # In production, verify SSL certificate
            # For demonstration, return True
            return True
        except Exception:
            return False
    
    async def scan_email(self, email_data: str) -> Dict:
        """Scan email for threats"""
        self.stats["emails_scanned"] += 1
        
        try:
            # Parse email
            msg = email.message_from_string(email_data)
            
            scan_result = {
                "safe": True,
                "threats": [],
                "scan_time": datetime.now().isoformat()
            }
            
            # Check sender
            sender = msg.get("from", "").lower()
            if any(blocked in sender for blocked in self.blocked_senders):
                scan_result["safe"] = False
                scan_result["threats"].append({
                    "type": "blocked_sender",
                    "details": sender
                })
            
            # Check subject and body for spam patterns
            subject = msg.get("subject", "")
            body = self._get_email_body(msg)
            
            for pattern in self.spam_patterns:
                if re.search(pattern, subject, re.IGNORECASE) or \
                   re.search(pattern, body, re.IGNORECASE):
                    scan_result["safe"] = False
                    scan_result["threats"].append({
                        "type": "spam_content",
                        "pattern": pattern
                    })
            
            # Check attachments
            attachments = await self._scan_attachments(msg)
            if attachments["threats"]:
                scan_result["safe"] = False
                scan_result["threats"].extend(attachments["threats"])
            
            # Check URLs in email
            urls = self._extract_urls(body)
            for url in urls:
                url_check = await self.check_url(url)
                if not url_check["safe"]:
                    scan_result["safe"] = False
                    scan_result["threats"].append({
                        "type": "malicious_url",
                        "url": url,
                        "details": url_check
                    })
            
            if not scan_result["safe"]:
                self.stats["threats_detected"] += 1
            
            return scan_result
            
        except Exception as e:
            self.logger.log_error(f"Error scanning email: {e}")
            return {
                "safe": False,
                "error": str(e),
                "scan_time": datetime.now().isoformat()
            }
    
    def _get_email_body(self, msg: email.message.Message) -> str:
        """Extract email body text"""
        body = ""
        if msg.is_multipart():
            for part in msg.walk():
                if part.get_content_type() == "text/plain":
                    body += part.get_payload(decode=True).decode()
        else:
            body = msg.get_payload(decode=True).decode()
        return body
    
    def _extract_urls(self, text: str) -> List[str]:
        """Extract URLs from text"""
        url_pattern = r'http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+'
        return re.findall(url_pattern, text)
    
    async def _scan_attachments(self, msg: email.message.Message) -> Dict:
        """Scan email attachments"""
        result = {
            "attachments": [],
            "threats": []
        }
        
        try:
            for part in msg.walk():
                if part.get_content_maintype() == 'multipart':
                    continue
                
                if part.get('Content-Disposition') is None:
                    continue
                
                filename = part.get_filename()
                if not filename:
                    continue
                
                # Check attachment rules
                for rule in self.attachment_rules:
                    if rule["type"] == "extension":
                        if re.search(rule["pattern"], filename, re.IGNORECASE):
                            result["threats"].append({
                                "type": "blocked_attachment",
                                "filename": filename,
                                "reason": "blocked_extension"
                            })
                            continue
                    
                    elif rule["type"] == "mime":
                        if rule["pattern"] in part.get_content_type():
                            result["threats"].append({
                                "type": "blocked_attachment",
                                "filename": filename,
                                "reason": "blocked_mime_type"
                            })
                            continue
                
                # If attachment not blocked, scan its content
                if not any(t["filename"] == filename for t in result["threats"]):
                    # Save attachment to temp file for scanning
                    temp_dir = Path(tempfile.mkdtemp())
                    temp_file = temp_dir / filename
                    
                    with open(temp_file, 'wb') as f:
                        f.write(part.get_payload(decode=True))
                    
                    # TODO: Scan attachment content with antivirus engine
                    
                    # Clean up
                    temp_file.unlink()
                    temp_dir.rmdir()
                
                result["attachments"].append(filename)
            
            return result
            
        except Exception as e:
            self.logger.log_error(f"Error scanning attachments: {e}")
            return {"attachments": [], "threats": []}
    
    async def add_malicious_url(self, url: str):
        """Add URL to malicious database"""
        self.malicious_urls.add(url)
        await self._save_url_database()
    
    async def add_phishing_domain(self, domain: str):
        """Add domain to phishing database"""
        self.phishing_domains.add(domain)
        await self._save_url_database()
    
    async def add_safe_domain(self, domain: str):
        """Add domain to safe list"""
        self.safe_domains.add(domain)
        await self._save_url_database()
    
    async def _save_url_database(self):
        """Save URL database to file"""
        database = {
            "malicious_urls": list(self.malicious_urls),
            "phishing_domains": list(self.phishing_domains),
            "safe_domains": list(self.safe_domains)
        }
        
        database_file = Path.home() / ".antivirus_config" / "url_database.json"
        try:
            with open(database_file, 'w') as f:
                json.dump(database, f, indent=2)
        except Exception as e:
            self.logger.log_error(f"Error saving URL database: {e}")
    
    async def add_spam_pattern(self, pattern: str):
        """Add spam detection pattern"""
        try:
            re.compile(pattern)  # Validate pattern
            self.spam_patterns.append(pattern)
            await self._save_email_rules()
            return True
        except Exception:
            return False
    
    async def add_blocked_sender(self, sender: str):
        """Add sender to blocked list"""
        self.blocked_senders.add(sender.lower())
        await self._save_email_rules()
    
    async def _save_email_rules(self):
        """Save email rules to file"""
        rules = {
            "spam_patterns": self.spam_patterns,
            "blocked_senders": list(self.blocked_senders),
            "attachment_rules": self.attachment_rules
        }
        
        rules_file = Path.home() / ".antivirus_config" / "email_rules.json"
        try:
            with open(rules_file, 'w') as f:
                json.dump(rules, f, indent=2)
        except Exception as e:
            self.logger.log_error(f"Error saving email rules: {e}")
    
    async def stop_filtering(self):
        """Stop web and email filtering"""
        if not self.is_filtering:
            return
        
        self.logger.log_info("Stopping web and email protection")
        self.is_filtering = False
        
        self.logger.log_info("Web and email protection stopped")
    
    def get_protection_stats(self) -> Dict:
        """Get protection statistics"""
        return {
            "is_filtering": self.is_filtering,
            "malicious_urls": len(self.malicious_urls),
            "phishing_domains": len(self.phishing_domains),
            "safe_domains": len(self.safe_domains),
            "spam_patterns": len(self.spam_patterns),
            "blocked_senders": len(self.blocked_senders),
            **self.stats
        }
