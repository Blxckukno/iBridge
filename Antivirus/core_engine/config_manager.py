"""
Configuration Manager
Handles all system configuration and settings
"""
import json
import os
from pathlib import Path
from typing import Any, Dict, List


class ConfigManager:
    """Manages system configuration and settings"""
    
    def __init__(self, config_dir: str = None):
        if config_dir is None:
            config_dir = Path.home() / ".antivirus_config"
        
        self.config_dir = Path(config_dir)
        self.config_dir.mkdir(exist_ok=True)
        
        self.config_file = self.config_dir / "config.json"
        self.signature_db_path = self.config_dir / "signatures.db"
        self.quarantine_dir = self.config_dir / "quarantine"
        self.logs_dir = self.config_dir / "logs"
        
        # Create necessary directories
        self.quarantine_dir.mkdir(exist_ok=True)
        self.logs_dir.mkdir(exist_ok=True)
        
        self.config = self._load_default_config()
        self._load_config()
    
    def _load_default_config(self) -> Dict:
        """Load default configuration"""
        return {
            "general": {
                "auto_quarantine": True,
                "auto_update": True,
                "send_telemetry": False,
                "max_scan_threads": 4,
                "scan_memory_limit_mb": 1024
            },
            "real_time_protection": {
                "enabled": True,
                "scan_downloads": True,
                "scan_email_attachments": True,
                "scan_usb_devices": True,
                "monitor_system_files": True,
                "behavioral_analysis": True
            },
            "scanning": {
                "scan_archives": True,
                "scan_compressed": True,
                "max_file_size_mb": 100,
                "scan_timeout_seconds": 300,
                "deep_scan": False,
                "heuristic_analysis": True
            },
            "network": {
                "firewall_enabled": True,
                "block_malicious_ips": True,
                "dns_filtering": True,
                "intrusion_detection": True,
                "port_scan_detection": True,
                "suspicious_traffic_analysis": True
            },
            "web_protection": {
                "url_filtering": True,
                "phishing_protection": True,
                "malware_download_blocking": True,
                "social_engineering_protection": True,
                "safe_browsing": True
            },
            "ransomware_protection": {
                "enabled": True,
                "file_backup": True,
                "behavior_monitoring": True,
                "process_injection_detection": True,
                "encryption_detection": True,
                "honeypot_files": True
            },
            "ml_settings": {
                "enabled": True,
                "confidence_threshold": 0.7,
                "update_model_frequency": "weekly",
                "behavioral_learning": True,
                "anomaly_detection": True
            },
            "updates": {
                "auto_update_definitions": True,
                "auto_update_software": False,
                "update_frequency": "daily",
                "update_server": "https://updates.antivirus.local",
                "check_signatures_on_startup": True
            },
            "exclusions": {
                "paths": [
                    str(Path.home() / ".antivirus_config"),
                    "C:\\Windows\\System32",
                    "C:\\Program Files\\Antivirus"
                ],
                "file_extensions": [".log", ".tmp"],
                "processes": ["antivirus.exe", "system"]
            },
            "notifications": {
                "show_scan_results": True,
                "show_threat_alerts": True,
                "show_update_notifications": True,
                "sound_alerts": True,
                "desktop_notifications": True
            },
            "performance": {
                "low_priority_scanning": True,
                "idle_time_scanning": True,
                "cpu_usage_limit": 80,
                "memory_usage_limit": 70,
                "io_throttling": True
            }
        }
    
    def _load_config(self):
        """Load configuration from file"""
        if self.config_file.exists():
            try:
                with open(self.config_file, 'r') as f:
                    loaded_config = json.load(f)
                    # Merge with defaults
                    self._merge_config(self.config, loaded_config)
            except Exception as e:
                print(f"Error loading config: {e}")
        
        # Save merged config
        self.save_config()
    
    def _merge_config(self, default: Dict, loaded: Dict):
        """Recursively merge loaded config with defaults"""
        for key, value in loaded.items():
            if key in default:
                if isinstance(value, dict) and isinstance(default[key], dict):
                    self._merge_config(default[key], value)
                else:
                    default[key] = value
    
    def save_config(self):
        """Save current configuration to file"""
        try:
            with open(self.config_file, 'w') as f:
                json.dump(self.config, f, indent=4)
        except Exception as e:
            print(f"Error saving config: {e}")
    
    def get_setting(self, setting_path: str, default: Any = None) -> Any:
        """Get a configuration setting using dot notation"""
        parts = setting_path.split('.')
        current = self.config
        
        for part in parts:
            if isinstance(current, dict) and part in current:
                current = current[part]
            else:
                return default
        
        return current
    
    def set_setting(self, setting_path: str, value: Any):
        """Set a configuration setting using dot notation"""
        parts = setting_path.split('.')
        current = self.config
        
        for part in parts[:-1]:
            if part not in current:
                current[part] = {}
            current = current[part]
        
        current[parts[-1]] = value
        self.save_config()
    
    def get_scan_paths(self) -> List[str]:
        """Get paths to scan"""
        default_paths = [
            "C:\\",
            str(Path.home()),
            "C:\\Program Files",
            "C:\\Program Files (x86)"
        ]
        return self.get_setting("scanning.scan_paths", default_paths)
    
    def get_excluded_paths(self) -> List[str]:
        """Get paths to exclude from scanning"""
        return self.get_setting("exclusions.paths", [])
    
    def get_excluded_extensions(self) -> List[str]:
        """Get file extensions to exclude"""
        return self.get_setting("exclusions.file_extensions", [])
    
    def is_path_excluded(self, path: str) -> bool:
        """Check if a path should be excluded from scanning"""
        path = str(Path(path).resolve())
        
        for excluded_path in self.get_excluded_paths():
            if path.startswith(str(Path(excluded_path).resolve())):
                return True
        
        return False
    
    def is_extension_excluded(self, extension: str) -> bool:
        """Check if a file extension should be excluded"""
        return extension.lower() in [ext.lower() for ext in self.get_excluded_extensions()]
    
    def get_quarantine_dir(self) -> Path:
        """Get quarantine directory"""
        return self.quarantine_dir
    
    def get_logs_dir(self) -> Path:
        """Get logs directory"""
        return self.logs_dir
    
    def get_signature_db_path(self) -> Path:
        """Get signature database path"""
        return self.signature_db_path
    
    def reset_to_defaults(self):
        """Reset configuration to default values"""
        self.config = self._load_default_config()
        self.save_config()
    
    def export_config(self, file_path: str):
        """Export configuration to file"""
        with open(file_path, 'w') as f:
            json.dump(self.config, f, indent=4)
    
    def import_config(self, file_path: str):
        """Import configuration from file"""
        with open(file_path, 'r') as f:
            imported_config = json.load(f)
            self.config = self._load_default_config()
            self._merge_config(self.config, imported_config)
            self.save_config()
