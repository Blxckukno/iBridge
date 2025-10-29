"""
Advanced Browser Protection System
Complete browser security with extension integration, web filtering, and threat detection
"""

import os
import json
import sqlite3
import threading
import time
import requests
import hashlib
import re
from pathlib import Path
from datetime import datetime, timedelta
from urllib.parse import urlparse, parse_qs
import logging
from typing import Dict, List, Optional, Set
import subprocess
import psutil
import base64
from cryptography.fernet import Fernet

class BrowserSecurityManager:
    """Advanced browser security management system"""
    
    def __init__(self, config_path="browser_security/"):
        self.config_path = Path(config_path)
        self.config_path.mkdir(parents=True, exist_ok=True)
        
        # Security configuration
        self.malware_protection = True
        self.phishing_protection = True
        self.tracking_protection = True
        self.ad_blocking = True
        self.safe_browsing = True
        self.script_blocking = True
        self.download_protection = True
        
        # Real-time monitoring
        self.monitoring_enabled = True
        self.real_time_scanning = True
        self.network_monitoring = True
        self.behavior_analysis = True
        
        # Browser support
        self.supported_browsers = {
            'chrome': {'name': 'Google Chrome', 'extension_id': 'chrome_extension'},
            'firefox': {'name': 'Mozilla Firefox', 'extension_id': 'firefox_addon'},
            'edge': {'name': 'Microsoft Edge', 'extension_id': 'edge_extension'},
            'safari': {'name': 'Apple Safari', 'extension_id': 'safari_extension'}
        }
        
        # Threat databases
        self.malware_domains = set()
        self.phishing_domains = set()
        self.tracking_domains = set()
        self.safe_domains = set()
        self.suspicious_patterns = []
        
        # Statistics
        self.stats = {
            'threats_blocked': 0,
            'malware_blocked': 0,
            'phishing_blocked': 0,
            'trackers_blocked': 0,
            'ads_blocked': 0,
            'downloads_scanned': 0,
            'safe_downloads': 0,
            'blocked_downloads': 0,
            'extensions_active': 0
        }
        
        # Active sessions
        self.browser_sessions = {}
        self.active_monitors = {}
        
        self.logger = self._setup_logging()
        self.db_path = self.config_path / "browser_security.db"
        
        self._init_database()
        self._load_threat_databases()
        self._load_configuration()
        self._check_browser_extensions()
    
    def _setup_logging(self):
        """Setup logging for browser security"""
        logging.basicConfig(level=logging.INFO)
        logger = logging.getLogger(__name__)
        
        log_file = self.config_path / "browser_security.log"
        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(logging.INFO)
        formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)
        
        return logger
    
    def _init_database(self):
        """Initialize browser security database"""
        try:
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS threat_domains (
                    id INTEGER PRIMARY KEY,
                    domain TEXT UNIQUE,
                    threat_type TEXT,
                    severity INTEGER,
                    first_seen TIMESTAMP,
                    last_updated TIMESTAMP,
                    source TEXT,
                    confidence_score REAL,
                    is_active BOOLEAN DEFAULT 1
                )
            ''')
            
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS browsing_history (
                    id INTEGER PRIMARY KEY,
                    timestamp TIMESTAMP,
                    browser TEXT,
                    url TEXT,
                    title TEXT,
                    user_agent TEXT,
                    risk_score REAL,
                    action_taken TEXT,
                    threat_detected TEXT
                )
            ''')
            
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS download_scans (
                    id INTEGER PRIMARY KEY,
                    timestamp TIMESTAMP,
                    file_path TEXT,
                    file_name TEXT,
                    file_size INTEGER,
                    file_hash TEXT,
                    download_url TEXT,
                    browser TEXT,
                    scan_result TEXT,
                    threat_type TEXT,
                    action_taken TEXT,
                    quarantined BOOLEAN DEFAULT 0
                )
            ''')
            
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS browser_extensions (
                    id INTEGER PRIMARY KEY,
                    browser TEXT,
                    extension_id TEXT,
                    extension_name TEXT,
                    version TEXT,
                    status TEXT,
                    last_updated TIMESTAMP,
                    auto_update BOOLEAN DEFAULT 1
                )
            ''')
            
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS security_events (
                    id INTEGER PRIMARY KEY,
                    timestamp TIMESTAMP,
                    event_type TEXT,
                    browser TEXT,
                    url TEXT,
                    details TEXT,
                    severity TEXT,
                    user_action TEXT,
                    system_action TEXT
                )
            ''')
            
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS blocked_content (
                    id INTEGER PRIMARY KEY,
                    timestamp TIMESTAMP,
                    browser TEXT,
                    url TEXT,
                    content_type TEXT,
                    block_reason TEXT,
                    user_override BOOLEAN DEFAULT 0
                )
            ''')
            
            # Create indexes for performance
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_domains_type ON threat_domains(threat_type)')
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_history_timestamp ON browsing_history(timestamp)')
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_downloads_timestamp ON download_scans(timestamp)')
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_events_timestamp ON security_events(timestamp)')
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"Database initialization error: {e}")
            raise
    
    def _load_threat_databases(self):
        """Load threat intelligence databases"""
        try:
            # Load malware domains
            self._load_domain_list('malware_domains.txt', self.malware_domains)
            
            # Load phishing domains
            self._load_domain_list('phishing_domains.txt', self.phishing_domains)
            
            # Load tracking domains
            self._load_domain_list('tracking_domains.txt', self.tracking_domains)
            
            # Load safe domains
            self._load_domain_list('safe_domains.txt', self.safe_domains)
            
            # Load suspicious patterns
            self._load_suspicious_patterns()
            
            # Update from online sources
            self._update_threat_databases()
            
        except Exception as e:
            self.logger.error(f"Threat database loading error: {e}")
    
    def _load_domain_list(self, filename: str, target_set: Set[str]):
        """Load domain list from file"""
        try:
            domain_file = self.config_path / filename
            if domain_file.exists():
                with open(domain_file, 'r') as f:
                    for line in f:
                        domain = line.strip().lower()
                        if domain and not domain.startswith('#'):
                            target_set.add(domain)
            else:
                # Create default lists
                self._create_default_domain_lists(filename, target_set)
                
        except Exception as e:
            self.logger.error(f"Domain list loading error for {filename}: {e}")
    
    def _create_default_domain_lists(self, filename: str, target_set: Set[str]):
        """Create default domain lists"""
        try:
            default_domains = {
                'malware_domains.txt': [
                    'malware-example.com',
                    'trojan-site.net',
                    'virus-download.org',
                    'suspicious-software.biz'
                ],
                'phishing_domains.txt': [
                    'fake-bank.com',
                    'phishing-site.net',
                    'scam-login.org',
                    'fake-paypal.biz'
                ],
                'tracking_domains.txt': [
                    'doubleclick.net',
                    'googletagmanager.com',
                    'facebook.com/tr',
                    'google-analytics.com'
                ],
                'safe_domains.txt': [
                    'google.com',
                    'microsoft.com',
                    'github.com',
                    'stackoverflow.com'
                ]
            }
            
            domains = default_domains.get(filename, [])
            target_set.update(domains)
            
            # Save to file
            domain_file = self.config_path / filename
            with open(domain_file, 'w') as f:
                f.write(f"# Default {filename}\n")
                for domain in domains:
                    f.write(f"{domain}\n")
                    
        except Exception as e:
            self.logger.error(f"Default domain list creation error: {e}")
    
    def _load_suspicious_patterns(self):
        """Load suspicious URL patterns"""
        try:
            patterns_file = self.config_path / "suspicious_patterns.json"
            if patterns_file.exists():
                with open(patterns_file, 'r') as f:
                    self.suspicious_patterns = json.load(f)
            else:
                # Create default patterns
                self.suspicious_patterns = [
                    r'.*\.exe\?.*',  # Executable downloads with parameters
                    r'.*bit\.ly.*',  # Shortened URLs
                    r'.*tinyurl.*',  # Shortened URLs
                    r'.*[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}.*',  # IP addresses
                    r'.*[a-z0-9]{20,}\.com.*',  # Suspicious long random domains
                    r'.*urgent.*login.*',  # Phishing keywords
                    r'.*verify.*account.*',  # Phishing keywords
                    r'.*suspended.*click.*'  # Phishing keywords
                ]
                
                with open(patterns_file, 'w') as f:
                    json.dump(self.suspicious_patterns, f, indent=2)
                    
        except Exception as e:
            self.logger.error(f"Suspicious patterns loading error: {e}")
    
    def _update_threat_databases(self):
        """Update threat databases from online sources"""
        try:
            # Update malware domains
            self._update_from_online_source(
                'https://urlhaus.abuse.ch/downloads/csv_recent/',
                self.malware_domains,
                'malware'
            )
            
            # Update phishing domains
            self._update_from_online_source(
                'https://openphish.com/feed.txt',
                self.phishing_domains,
                'phishing'
            )
            
            # Update tracking domains
            self._update_from_online_source(
                'https://someonewhocares.org/hosts/zero/hosts',
                self.tracking_domains,
                'tracking'
            )
            
        except Exception as e:
            self.logger.error(f"Online threat database update error: {e}")
    
    def _update_from_online_source(self, url: str, target_set: Set[str], threat_type: str):
        """Update domain set from online source"""
        try:
            # For demo purposes, we'll simulate the update
            # In reality, this would fetch from actual threat intelligence feeds
            
            self.logger.info(f"Simulating update from {url} for {threat_type}")
            
            # Simulate adding some new domains
            new_domains = [
                f"new-{threat_type}-1.example.com",
                f"new-{threat_type}-2.example.com",
                f"updated-{threat_type}.example.org"
            ]
            
            for domain in new_domains:
                target_set.add(domain)
                self._store_threat_domain(domain, threat_type, url)
            
            self.logger.info(f"Added {len(new_domains)} new {threat_type} domains")
            
        except Exception as e:
            self.logger.error(f"Online source update error for {url}: {e}")
    
    def _store_threat_domain(self, domain: str, threat_type: str, source: str):
        """Store threat domain in database"""
        try:
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT OR REPLACE INTO threat_domains 
                (domain, threat_type, severity, first_seen, last_updated, source, confidence_score)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (domain, threat_type, 5, datetime.now(), datetime.now(), source, 0.8))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"Threat domain storage error: {e}")
    
    def _load_configuration(self):
        """Load browser security configuration"""
        try:
            config_file = self.config_path / "security_config.json"
            if config_file.exists():
                with open(config_file, 'r') as f:
                    config = json.load(f)
                    
                    self.malware_protection = config.get('malware_protection', True)
                    self.phishing_protection = config.get('phishing_protection', True)
                    self.tracking_protection = config.get('tracking_protection', True)
                    self.ad_blocking = config.get('ad_blocking', True)
                    self.safe_browsing = config.get('safe_browsing', True)
                    self.script_blocking = config.get('script_blocking', True)
                    self.download_protection = config.get('download_protection', True)
                    self.monitoring_enabled = config.get('monitoring_enabled', True)
                    self.real_time_scanning = config.get('real_time_scanning', True)
                    self.network_monitoring = config.get('network_monitoring', True)
                    self.behavior_analysis = config.get('behavior_analysis', True)
            
        except Exception as e:
            self.logger.error(f"Configuration loading error: {e}")
    
    def save_configuration(self):
        """Save browser security configuration"""
        try:
            config = {
                'malware_protection': self.malware_protection,
                'phishing_protection': self.phishing_protection,
                'tracking_protection': self.tracking_protection,
                'ad_blocking': self.ad_blocking,
                'safe_browsing': self.safe_browsing,
                'script_blocking': self.script_blocking,
                'download_protection': self.download_protection,
                'monitoring_enabled': self.monitoring_enabled,
                'real_time_scanning': self.real_time_scanning,
                'network_monitoring': self.network_monitoring,
                'behavior_analysis': self.behavior_analysis,
                'saved_at': datetime.now().isoformat()
            }
            
            config_file = self.config_path / "security_config.json"
            with open(config_file, 'w') as f:
                json.dump(config, f, indent=2)
                
        except Exception as e:
            self.logger.error(f"Configuration saving error: {e}")
    
    def _check_browser_extensions(self):
        """Check status of browser extensions"""
        try:
            for browser_key, browser_info in self.supported_browsers.items():
                extension_status = self._get_extension_status(browser_key)
                
                if extension_status:
                    self.stats['extensions_active'] += 1
                    self._update_extension_info(browser_key, extension_status)
                else:
                    self.logger.warning(f"Extension not found for {browser_info['name']}")
                    
        except Exception as e:
            self.logger.error(f"Extension check error: {e}")
    
    def _get_extension_status(self, browser: str) -> Optional[Dict]:
        """Get browser extension status"""
        try:
            # This would check actual browser extension status
            # For demo purposes, we'll simulate extension presence
            
            if browser in ['chrome', 'edge']:
                return {
                    'installed': True,
                    'enabled': True,
                    'version': '1.0.0',
                    'last_update': datetime.now().isoformat()
                }
            
            return None
            
        except Exception as e:
            self.logger.error(f"Extension status check error for {browser}: {e}")
            return None
    
    def _update_extension_info(self, browser: str, status: Dict):
        """Update extension information in database"""
        try:
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT OR REPLACE INTO browser_extensions 
                (browser, extension_id, extension_name, version, status, last_updated)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (browser, self.supported_browsers[browser]['extension_id'],
                  self.supported_browsers[browser]['name'], status.get('version', '1.0.0'),
                  'active' if status.get('enabled') else 'inactive', datetime.now()))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"Extension info update error: {e}")
    
    def start_monitoring(self):
        """Start browser security monitoring"""
        try:
            if not self.monitoring_enabled:
                return False
            
            # Start browser process monitoring
            monitor_thread = threading.Thread(target=self._monitor_browsers, daemon=True)
            monitor_thread.start()
            
            # Start network monitoring
            if self.network_monitoring:
                network_thread = threading.Thread(target=self._monitor_network_traffic, daemon=True)
                network_thread.start()
            
            # Start download monitoring
            if self.download_protection:
                download_thread = threading.Thread(target=self._monitor_downloads, daemon=True)
                download_thread.start()
            
            self.logger.info("Browser security monitoring started")
            return True
            
        except Exception as e:
            self.logger.error(f"Monitoring start error: {e}")
            return False
    
    def _monitor_browsers(self):
        """Monitor browser processes and activities"""
        while self.monitoring_enabled:
            try:
                # Get running browser processes
                browser_processes = self._get_browser_processes()
                
                for process in browser_processes:
                    self._analyze_browser_process(process)
                
                time.sleep(10)  # Check every 10 seconds
                
            except Exception as e:
                self.logger.error(f"Browser monitoring error: {e}")
                time.sleep(30)
    
    def _get_browser_processes(self) -> List[Dict]:
        """Get running browser processes"""
        try:
            browser_processes = []
            browser_names = ['chrome.exe', 'firefox.exe', 'msedge.exe', 'safari.exe']
            
            for proc in psutil.process_iter(['pid', 'name', 'cmdline', 'create_time']):
                try:
                    proc_info = proc.info
                    if proc_info['name'].lower() in [name.lower() for name in browser_names]:
                        browser_processes.append({
                            'pid': proc_info['pid'],
                            'name': proc_info['name'],
                            'cmdline': proc_info['cmdline'],
                            'create_time': proc_info['create_time'],
                            'process': proc
                        })
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    continue
            
            return browser_processes
            
        except Exception as e:
            self.logger.error(f"Browser process detection error: {e}")
            return []
    
    def _analyze_browser_process(self, process_info: Dict):
        """Analyze browser process for security issues"""
        try:
            # Check command line arguments for suspicious activity
            cmdline = process_info.get('cmdline', [])
            
            for arg in cmdline:
                if isinstance(arg, str):
                    # Check for suspicious URLs in command line
                    if self._is_suspicious_url(arg):
                        self._log_security_event(
                            'SUSPICIOUS_URL_LAUNCH',
                            process_info['name'],
                            arg,
                            f"Suspicious URL launched: {arg}",
                            'WARNING'
                        )
            
            # Monitor process behavior
            self._monitor_process_behavior(process_info)
            
        except Exception as e:
            self.logger.error(f"Browser process analysis error: {e}")
    
    def _monitor_process_behavior(self, process_info: Dict):
        """Monitor browser process behavior"""
        try:
            proc = process_info['process']
            
            # Check memory usage
            memory_info = proc.memory_info()
            if memory_info.rss > 2 * 1024 * 1024 * 1024:  # > 2GB
                self.logger.warning(f"High memory usage in {process_info['name']}: {memory_info.rss // 1024 // 1024}MB")
            
            # Check CPU usage
            cpu_percent = proc.cpu_percent(interval=1)
            if cpu_percent > 80:
                self.logger.warning(f"High CPU usage in {process_info['name']}: {cpu_percent}%")
            
            # Check network connections
            connections = proc.connections()
            for conn in connections:
                if conn.raddr:
                    self._check_network_connection(conn, process_info['name'])
            
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            pass
        except Exception as e:
            self.logger.error(f"Process behavior monitoring error: {e}")
    
    def _check_network_connection(self, connection, browser_name: str):
        """Check network connection for threats"""
        try:
            if connection.raddr and connection.raddr.ip:
                remote_ip = connection.raddr.ip
                
                # Check if IP is in threat databases
                if self._is_malicious_ip(remote_ip):
                    self._log_security_event(
                        'MALICIOUS_CONNECTION',
                        browser_name,
                        remote_ip,
                        f"Connection to malicious IP: {remote_ip}",
                        'HIGH'
                    )
                    
                    # Block connection if possible
                    self._block_network_connection(connection)
            
        except Exception as e:
            self.logger.error(f"Network connection check error: {e}")
    
    def _is_malicious_ip(self, ip_address: str) -> bool:
        """Check if IP address is malicious"""
        try:
            # This would check against threat intelligence databases
            # For demo purposes, we'll use a simple check
            
            malicious_ips = [
                '192.168.1.100',  # Example malicious IP
                '10.0.0.50',      # Example malicious IP
            ]
            
            return ip_address in malicious_ips
            
        except Exception as e:
            self.logger.error(f"Malicious IP check error: {e}")
            return False
    
    def _block_network_connection(self, connection):
        """Block malicious network connection"""
        try:
            # This would implement actual connection blocking
            # For demo purposes, we'll just log the action
            
            self.logger.info(f"Blocking connection to {connection.raddr.ip}:{connection.raddr.port}")
            self.stats['threats_blocked'] += 1
            
        except Exception as e:
            self.logger.error(f"Connection blocking error: {e}")
    
    def _monitor_network_traffic(self):
        """Monitor network traffic for threats"""
        while self.monitoring_enabled and self.network_monitoring:
            try:
                # Monitor DNS requests
                self._monitor_dns_requests()
                
                # Monitor HTTP/HTTPS traffic
                self._monitor_http_traffic()
                
                time.sleep(5)  # Check every 5 seconds
                
            except Exception as e:
                self.logger.error(f"Network traffic monitoring error: {e}")
                time.sleep(30)
    
    def _monitor_dns_requests(self):
        """Monitor DNS requests for malicious domains"""
        try:
            # This would implement actual DNS monitoring
            # For demo purposes, we'll simulate DNS request checking
            
            # Simulate some DNS requests
            simulated_requests = [
                'google.com',
                'malware-example.com',
                'safe-site.org',
                'phishing-site.net'
            ]
            
            for domain in simulated_requests:
                if self._is_threat_domain(domain):
                    self._handle_threat_domain(domain)
            
        except Exception as e:
            self.logger.error(f"DNS monitoring error: {e}")
    
    def _monitor_http_traffic(self):
        """Monitor HTTP/HTTPS traffic"""
        try:
            # This would implement actual HTTP traffic monitoring
            # For demo purposes, we'll simulate traffic analysis
            
            # Simulate analyzing URLs
            simulated_urls = [
                'https://safe-website.com/page',
                'http://suspicious-site.com/download.exe',
                'https://tracking-site.com/pixel.gif'
            ]
            
            for url in simulated_urls:
                risk_score = self._analyze_url_risk(url)
                if risk_score > 0.7:
                    self._handle_high_risk_url(url, risk_score)
            
        except Exception as e:
            self.logger.error(f"HTTP traffic monitoring error: {e}")
    
    def _monitor_downloads(self):
        """Monitor file downloads"""
        while self.monitoring_enabled and self.download_protection:
            try:
                # Monitor common download directories
                download_dirs = [
                    os.path.expanduser("~/Downloads"),
                    os.path.expanduser("~/Desktop"),
                    "C:\\Users\\Public\\Downloads"
                ]
                
                for download_dir in download_dirs:
                    if os.path.exists(download_dir):
                        self._scan_download_directory(download_dir)
                
                time.sleep(15)  # Check every 15 seconds
                
            except Exception as e:
                self.logger.error(f"Download monitoring error: {e}")
                time.sleep(60)
    
    def _scan_download_directory(self, directory: str):
        """Scan download directory for new files"""
        try:
            current_time = time.time()
            
            for file_path in Path(directory).iterdir():
                if file_path.is_file():
                    # Check if file is recent (last 5 minutes)
                    file_time = file_path.stat().st_mtime
                    if current_time - file_time < 300:  # 5 minutes
                        self._scan_downloaded_file(str(file_path))
            
        except Exception as e:
            self.logger.error(f"Download directory scan error: {e}")
    
    def _scan_downloaded_file(self, file_path: str):
        """Scan downloaded file for threats"""
        try:
            file_name = os.path.basename(file_path)
            file_size = os.path.getsize(file_path)
            
            # Calculate file hash
            file_hash = self._calculate_file_hash(file_path)
            
            # Check against malware databases
            scan_result = self._check_file_reputation(file_hash, file_name)
            
            # Analyze file content
            content_analysis = self._analyze_file_content(file_path)
            
            # Determine overall threat level
            is_threat = scan_result['is_malware'] or content_analysis['is_suspicious']
            
            # Log download scan
            self._log_download_scan(file_path, file_name, file_size, file_hash, 
                                  scan_result, content_analysis, is_threat)
            
            if is_threat:
                self._handle_malicious_download(file_path, scan_result, content_analysis)
            
            self.stats['downloads_scanned'] += 1
            if not is_threat:
                self.stats['safe_downloads'] += 1
            else:
                self.stats['blocked_downloads'] += 1
            
        except Exception as e:
            self.logger.error(f"Downloaded file scan error: {e}")
    
    def _calculate_file_hash(self, file_path: str) -> str:
        """Calculate SHA256 hash of file"""
        try:
            hasher = hashlib.sha256()
            with open(file_path, 'rb') as f:
                for chunk in iter(lambda: f.read(4096), b""):
                    hasher.update(chunk)
            return hasher.hexdigest()
        except Exception as e:
            self.logger.error(f"File hash calculation error: {e}")
            return ""
    
    def _check_file_reputation(self, file_hash: str, file_name: str) -> Dict:
        """Check file reputation against threat databases"""
        try:
            # This would check against actual threat intelligence APIs
            # For demo purposes, we'll simulate reputation checking
            
            suspicious_extensions = ['.exe', '.bat', '.cmd', '.scr', '.vbs', '.js']
            suspicious_names = ['setup', 'install', 'update', 'crack', 'keygen']
            
            is_malware = False
            reputation_score = 0.0
            
            # Check file extension
            file_ext = os.path.splitext(file_name)[1].lower()
            if file_ext in suspicious_extensions:
                reputation_score += 0.3
            
            # Check file name
            name_lower = file_name.lower()
            for suspicious_name in suspicious_names:
                if suspicious_name in name_lower:
                    reputation_score += 0.2
            
            # Simulate hash-based detection
            if file_hash in ['abc123', 'def456']:  # Example malicious hashes
                is_malware = True
                reputation_score = 1.0
            
            return {
                'is_malware': is_malware,
                'reputation_score': reputation_score,
                'source': 'local_analysis',
                'details': f"File extension: {file_ext}, Name analysis: {reputation_score}"
            }
            
        except Exception as e:
            self.logger.error(f"File reputation check error: {e}")
            return {'is_malware': False, 'reputation_score': 0.0, 'source': 'error', 'details': str(e)}
    
    def _analyze_file_content(self, file_path: str) -> Dict:
        """Analyze file content for suspicious patterns"""
        try:
            file_size = os.path.getsize(file_path)
            is_suspicious = False
            analysis_details = []
            
            # Check file size
            if file_size > 100 * 1024 * 1024:  # > 100MB
                analysis_details.append("Large file size")
            
            # Check file header/magic bytes
            with open(file_path, 'rb') as f:
                header = f.read(1024)
                
                # Check for executable signatures
                if header.startswith(b'MZ'):  # Windows executable
                    analysis_details.append("Windows executable detected")
                    is_suspicious = True
                elif header.startswith(b'\x7fELF'):  # Linux executable
                    analysis_details.append("Linux executable detected")
                    is_suspicious = True
                elif b'<script' in header.lower():  # HTML with scripts
                    analysis_details.append("HTML with scripts detected")
                    is_suspicious = True
            
            return {
                'is_suspicious': is_suspicious,
                'analysis_details': analysis_details,
                'file_size': file_size
            }
            
        except Exception as e:
            self.logger.error(f"File content analysis error: {e}")
            return {'is_suspicious': False, 'analysis_details': ['Analysis failed'], 'file_size': 0}
    
    def _handle_malicious_download(self, file_path: str, scan_result: Dict, content_analysis: Dict):
        """Handle detection of malicious download"""
        try:
            self.logger.warning(f"Malicious download detected: {file_path}")
            
            # Quarantine file
            quarantine_path = self._quarantine_file(file_path)
            
            # Log security event
            self._log_security_event(
                'MALICIOUS_DOWNLOAD',
                'unknown',
                file_path,
                f"Malicious file quarantined: {os.path.basename(file_path)}",
                'HIGH'
            )
            
            # Update statistics
            self.stats['malware_blocked'] += 1
            self.stats['threats_blocked'] += 1
            
            # Notify user (would show notification in real implementation)
            self.logger.info(f"File quarantined: {quarantine_path}")
            
        except Exception as e:
            self.logger.error(f"Malicious download handling error: {e}")
    
    def _quarantine_file(self, file_path: str) -> str:
        """Quarantine malicious file"""
        try:
            quarantine_dir = self.config_path / "quarantine"
            quarantine_dir.mkdir(exist_ok=True)
            
            file_name = os.path.basename(file_path)
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            quarantine_name = f"{timestamp}_{file_name}.quarantined"
            quarantine_path = quarantine_dir / quarantine_name
            
            # Move file to quarantine
            os.rename(file_path, quarantine_path)
            
            # Encrypt quarantined file
            self._encrypt_quarantined_file(str(quarantine_path))
            
            return str(quarantine_path)
            
        except Exception as e:
            self.logger.error(f"File quarantine error: {e}")
            return file_path
    
    def _encrypt_quarantined_file(self, file_path: str):
        """Encrypt quarantined file"""
        try:
            # Generate encryption key
            key = Fernet.generate_key()
            cipher = Fernet(key)
            
            # Read and encrypt file
            with open(file_path, 'rb') as f:
                file_data = f.read()
            
            encrypted_data = cipher.encrypt(file_data)
            
            # Write encrypted file
            with open(file_path + '.enc', 'wb') as f:
                f.write(encrypted_data)
            
            # Store encryption key securely
            key_file = file_path + '.key'
            with open(key_file, 'wb') as f:
                f.write(key)
            
            # Remove original quarantined file
            os.remove(file_path)
            
        except Exception as e:
            self.logger.error(f"Quarantined file encryption error: {e}")
    
    def check_url(self, url: str) -> Dict:
        """Check URL for threats and return risk assessment"""
        try:
            parsed_url = urlparse(url)
            domain = parsed_url.netloc.lower()
            
            threat_info = {
                'url': url,
                'domain': domain,
                'is_safe': True,
                'threat_types': [],
                'risk_score': 0.0,
                'block_reason': None,
                'recommendations': []
            }
            
            # Check against threat databases
            if domain in self.malware_domains:
                threat_info['is_safe'] = False
                threat_info['threat_types'].append('malware')
                threat_info['risk_score'] = 1.0
                threat_info['block_reason'] = 'Domain in malware database'
                
            elif domain in self.phishing_domains:
                threat_info['is_safe'] = False
                threat_info['threat_types'].append('phishing')
                threat_info['risk_score'] = 0.9
                threat_info['block_reason'] = 'Domain in phishing database'
                
            elif domain in self.tracking_domains:
                if self.tracking_protection:
                    threat_info['is_safe'] = False
                    threat_info['threat_types'].append('tracking')
                    threat_info['risk_score'] = 0.3
                    threat_info['block_reason'] = 'Tracking domain blocked'
            
            # Check suspicious patterns
            for pattern in self.suspicious_patterns:
                if re.match(pattern, url, re.IGNORECASE):
                    threat_info['risk_score'] = max(threat_info['risk_score'], 0.6)
                    threat_info['threat_types'].append('suspicious_pattern')
                    if threat_info['risk_score'] > 0.7:
                        threat_info['is_safe'] = False
                        threat_info['block_reason'] = 'Matches suspicious pattern'
            
            # Additional URL analysis
            threat_info['risk_score'] = max(threat_info['risk_score'], self._analyze_url_risk(url))
            
            # Generate recommendations
            if not threat_info['is_safe']:
                threat_info['recommendations'].append('Do not visit this URL')
                threat_info['recommendations'].append('Report as malicious if encountered')
            elif threat_info['risk_score'] > 0.3:
                threat_info['recommendations'].append('Proceed with caution')
                threat_info['recommendations'].append('Verify URL authenticity')
            
            return threat_info
            
        except Exception as e:
            self.logger.error(f"URL check error: {e}")
            return {
                'url': url,
                'is_safe': True,
                'threat_types': ['analysis_error'],
                'risk_score': 0.0,
                'block_reason': None,
                'recommendations': ['Unable to analyze URL']
            }
    
    def _analyze_url_risk(self, url: str) -> float:
        """Analyze URL for risk factors"""
        try:
            risk_score = 0.0
            parsed_url = urlparse(url)
            
            # Check for suspicious characteristics
            domain = parsed_url.netloc.lower()
            path = parsed_url.path.lower()
            query = parsed_url.query.lower()
            
            # Domain analysis
            if re.match(r'.*[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}.*', domain):
                risk_score += 0.4  # IP address instead of domain
            
            if len(domain) > 50:
                risk_score += 0.2  # Very long domain
            
            if domain.count('.') > 4:
                risk_score += 0.2  # Many subdomains
            
            # Path analysis
            if any(ext in path for ext in ['.exe', '.bat', '.cmd', '.scr']):
                risk_score += 0.5  # Executable download
            
            # Query parameter analysis
            if any(param in query for param in ['download', 'install', 'update']):
                risk_score += 0.2  # Download-related parameters
            
            # Check for URL shorteners
            shortener_domains = ['bit.ly', 'tinyurl.com', 't.co', 'goo.gl', 'ow.ly']
            if any(shortener in domain for shortener in shortener_domains):
                risk_score += 0.3
            
            return min(risk_score, 1.0)
            
        except Exception as e:
            self.logger.error(f"URL risk analysis error: {e}")
            return 0.0
    
    def _is_threat_domain(self, domain: str) -> bool:
        """Check if domain is in threat databases"""
        domain_lower = domain.lower()
        return (domain_lower in self.malware_domains or 
                domain_lower in self.phishing_domains or 
                (self.tracking_protection and domain_lower in self.tracking_domains))
    
    def _is_suspicious_url(self, url: str) -> bool:
        """Check if URL matches suspicious patterns"""
        try:
            for pattern in self.suspicious_patterns:
                if re.match(pattern, url, re.IGNORECASE):
                    return True
            return False
        except Exception as e:
            self.logger.error(f"Suspicious URL check error: {e}")
            return False
    
    def _handle_threat_domain(self, domain: str):
        """Handle access to threat domain"""
        try:
            threat_type = 'unknown'
            
            if domain in self.malware_domains:
                threat_type = 'malware'
                self.stats['malware_blocked'] += 1
            elif domain in self.phishing_domains:
                threat_type = 'phishing'
                self.stats['phishing_blocked'] += 1
            elif domain in self.tracking_domains:
                threat_type = 'tracking'
                self.stats['trackers_blocked'] += 1
            
            self.stats['threats_blocked'] += 1
            
            # Log security event
            self._log_security_event(
                'THREAT_DOMAIN_BLOCKED',
                'unknown',
                domain,
                f"Blocked access to {threat_type} domain: {domain}",
                'HIGH' if threat_type in ['malware', 'phishing'] else 'MEDIUM'
            )
            
            # Log blocked content
            self._log_blocked_content(domain, threat_type, f"Blocked {threat_type} domain")
            
        except Exception as e:
            self.logger.error(f"Threat domain handling error: {e}")
    
    def _handle_high_risk_url(self, url: str, risk_score: float):
        """Handle high-risk URL access"""
        try:
            self.logger.warning(f"High-risk URL detected: {url} (risk: {risk_score:.2f})")
            
            # Log security event
            self._log_security_event(
                'HIGH_RISK_URL',
                'unknown',
                url,
                f"High-risk URL access: {url} (risk score: {risk_score:.2f})",
                'WARNING'
            )
            
            # Block if risk is very high
            if risk_score > 0.8:
                self.stats['threats_blocked'] += 1
                self._log_blocked_content(url, 'high_risk', f"Blocked high-risk URL (score: {risk_score:.2f})")
            
        except Exception as e:
            self.logger.error(f"High-risk URL handling error: {e}")
    
    def _log_security_event(self, event_type: str, browser: str, url: str, details: str, severity: str):
        """Log security event to database"""
        try:
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT INTO security_events 
                (timestamp, event_type, browser, url, details, severity, system_action)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (datetime.now(), event_type, browser, url, details, severity, 'logged'))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"Security event logging error: {e}")
    
    def _log_blocked_content(self, url: str, content_type: str, block_reason: str):
        """Log blocked content to database"""
        try:
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT INTO blocked_content 
                (timestamp, browser, url, content_type, block_reason)
                VALUES (?, ?, ?, ?, ?)
            ''', (datetime.now(), 'unknown', url, content_type, block_reason))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"Blocked content logging error: {e}")
    
    def _log_download_scan(self, file_path: str, file_name: str, file_size: int, 
                          file_hash: str, scan_result: Dict, content_analysis: Dict, is_threat: bool):
        """Log download scan results"""
        try:
            threat_type = None
            action_taken = 'allowed'
            
            if is_threat:
                if scan_result.get('is_malware'):
                    threat_type = 'malware'
                elif content_analysis.get('is_suspicious'):
                    threat_type = 'suspicious'
                action_taken = 'quarantined'
            
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT INTO download_scans 
                (timestamp, file_path, file_name, file_size, file_hash,
                 download_url, browser, scan_result, threat_type, action_taken, quarantined)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (datetime.now(), file_path, file_name, file_size, file_hash,
                  'unknown', 'unknown', 'threat' if is_threat else 'clean', 
                  threat_type, action_taken, is_threat))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"Download scan logging error: {e}")
    
    def get_security_status(self) -> Dict:
        """Get current browser security status"""
        try:
            return {
                'protection_status': {
                    'malware_protection': self.malware_protection,
                    'phishing_protection': self.phishing_protection,
                    'tracking_protection': self.tracking_protection,
                    'ad_blocking': self.ad_blocking,
                    'safe_browsing': self.safe_browsing,
                    'script_blocking': self.script_blocking,
                    'download_protection': self.download_protection
                },
                'monitoring_status': {
                    'monitoring_enabled': self.monitoring_enabled,
                    'real_time_scanning': self.real_time_scanning,
                    'network_monitoring': self.network_monitoring,
                    'behavior_analysis': self.behavior_analysis
                },
                'threat_databases': {
                    'malware_domains': len(self.malware_domains),
                    'phishing_domains': len(self.phishing_domains),
                    'tracking_domains': len(self.tracking_domains),
                    'safe_domains': len(self.safe_domains),
                    'suspicious_patterns': len(self.suspicious_patterns)
                },
                'statistics': self.stats,
                'browser_extensions': self.stats['extensions_active'],
                'last_database_update': datetime.now().isoformat()
            }
            
        except Exception as e:
            self.logger.error(f"Security status retrieval error: {e}")
            return {}
    
    def get_recent_threats(self, hours: int = 24) -> List[Dict]:
        """Get recent threat detections"""
        try:
            since_time = datetime.now() - timedelta(hours=hours)
            
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            
            cursor.execute('''
                SELECT timestamp, event_type, browser, url, details, severity
                FROM security_events
                WHERE timestamp > ? AND severity IN ('HIGH', 'CRITICAL')
                ORDER BY timestamp DESC
                LIMIT 50
            ''', (since_time,))
            
            threats = []
            for row in cursor.fetchall():
                threats.append({
                    'timestamp': row[0],
                    'event_type': row[1],
                    'browser': row[2],
                    'url': row[3],
                    'details': row[4],
                    'severity': row[5]
                })
            
            conn.close()
            return threats
            
        except Exception as e:
            self.logger.error(f"Recent threats retrieval error: {e}")
            return []
    
    def update_threat_databases(self) -> bool:
        """Update threat databases from external sources"""
        try:
            self.logger.info("Starting threat database update")
            
            # Update from online sources
            self._update_threat_databases()
            
            # Save updated databases
            self._save_threat_databases()
            
            self.logger.info("Threat database update completed")
            return True
            
        except Exception as e:
            self.logger.error(f"Threat database update error: {e}")
            return False
    
    def _save_threat_databases(self):
        """Save threat databases to files"""
        try:
            # Save malware domains
            with open(self.config_path / "malware_domains.txt", 'w') as f:
                f.write("# Malware domains database\n")
                for domain in sorted(self.malware_domains):
                    f.write(f"{domain}\n")
            
            # Save phishing domains
            with open(self.config_path / "phishing_domains.txt", 'w') as f:
                f.write("# Phishing domains database\n")
                for domain in sorted(self.phishing_domains):
                    f.write(f"{domain}\n")
            
            # Save tracking domains
            with open(self.config_path / "tracking_domains.txt", 'w') as f:
                f.write("# Tracking domains database\n")
                for domain in sorted(self.tracking_domains):
                    f.write(f"{domain}\n")
            
            # Save safe domains
            with open(self.config_path / "safe_domains.txt", 'w') as f:
                f.write("# Safe domains database\n")
                for domain in sorted(self.safe_domains):
                    f.write(f"{domain}\n")
            
        except Exception as e:
            self.logger.error(f"Threat database saving error: {e}")

if __name__ == "__main__":
    # Test browser security manager
    security_manager = BrowserSecurityManager()
    
    # Start monitoring
    if security_manager.start_monitoring():
        print("Browser security monitoring started")
    
    # Test URL checking
    test_urls = [
        'https://google.com',
        'https://malware-example.com',
        'https://phishing-site.net',
        'http://suspicious-site.com/download.exe'
    ]
    
    print("\nURL Security Analysis:")
    for url in test_urls:
        result = security_manager.check_url(url)
        print(f"URL: {url}")
        print(f"  Safe: {result['is_safe']}")
        print(f"  Risk Score: {result['risk_score']:.2f}")
        print(f"  Threat Types: {result['threat_types']}")
        if result['block_reason']:
            print(f"  Block Reason: {result['block_reason']}")
        print()
    
    # Get security status
    status = security_manager.get_security_status()
    print("Browser Security Status:")
    print(json.dumps(status, indent=2, default=str))
    
    print("\nBrowser Security Manager test completed")