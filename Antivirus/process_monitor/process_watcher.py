"""
Process Monitor
Monitors system processes for suspicious behavior
"""
import asyncio
import psutil
import threading
import time
from datetime import datetime
from typing import Dict, List, Optional, Set
import winreg
import json
from pathlib import Path
import hashlib

from ..core_engine.config_manager import ConfigManager
from ..logging.security_logger import SecurityLogger


class ProcessWatcher:
    """Monitors system processes for suspicious activity"""
    
    def __init__(self, threat_detector, logger: SecurityLogger):
        self.threat_detector = threat_detector
        self.logger = logger
        
        # Monitoring state
        self.is_monitoring = False
        self.monitor_thread = None
        
        # Process tracking
        self.process_list = {}
        self.suspicious_processes = set()
        self.known_processes = set()
        
        # Behavior patterns
        self.suspicious_patterns = {
            "file_operations": [
                r".*\\windows\\system32\\.*\.exe$",
                r".*\\temp\\.*\.exe$",
                r".*\\appdata\\.*\.exe$"
            ],
            "registry_keys": [
                r"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run",
                r"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\RunOnce",
                r"SYSTEM\\CurrentControlSet\\Services"
            ],
            "network_connections": [
                ("0.0.0.0", 0),  # Any connection
                ("127.0.0.1", 4444),  # Common exploit port
            ]
        }
        
        # Statistics
        self.stats = {
            "processes_monitored": 0,
            "suspicious_detected": 0,
            "blocked_processes": 0,
            "start_time": None
        }
        
        # Event handlers
        self.on_suspicious_activity = None
    
    async def initialize(self):
        """Initialize process monitoring"""
        self.logger.log_info("Initializing process monitor")
        
        try:
            # Load known good processes
            await self._load_known_processes()
            
            # Initial process scan
            await self._scan_running_processes()
            
            self.logger.log_info("Process monitor initialized")
            
        except Exception as e:
            self.logger.log_error(f"Failed to initialize process monitor: {e}")
            raise
    
    async def _load_known_processes(self):
        """Load known good processes from database"""
        known_processes_file = Path.home() / ".antivirus_config" / "known_processes.json"
        
        if known_processes_file.exists():
            try:
                with open(known_processes_file, 'r') as f:
                    processes = json.load(f)
                    self.known_processes = set(processes)
            except Exception as e:
                self.logger.log_error(f"Error loading known processes: {e}")
        
        # Add default known processes
        default_known = {
            "explorer.exe",
            "svchost.exe",
            "lsass.exe",
            "services.exe",
            "winlogon.exe",
            "csrss.exe",
            "smss.exe"
        }
        self.known_processes.update(default_known)
    
    async def _scan_running_processes(self):
        """Initial scan of running processes"""
        for proc in psutil.process_iter(['pid', 'name', 'exe', 'cmdline']):
            try:
                self.process_list[proc.info['pid']] = {
                    'name': proc.info['name'],
                    'exe': proc.info['exe'],
                    'cmdline': proc.info['cmdline'],
                    'start_time': proc.create_time(),
                    'suspicious': False
                }
            except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
                continue
    
    async def start_monitoring(self):
        """Start process monitoring"""
        if self.is_monitoring:
            return
        
        self.logger.log_info("Starting process monitoring")
        
        self.is_monitoring = True
        self.stats["start_time"] = datetime.now().isoformat()
        
        # Start monitoring thread
        self.monitor_thread = threading.Thread(
            target=self._monitor_processes,
            daemon=True
        )
        self.monitor_thread.start()
        
        self.logger.log_info("Process monitoring started")
    
    def _monitor_processes(self):
        """Monitor processes in separate thread"""
        while self.is_monitoring:
            try:
                # Get current process list
                current_processes = {}
                for proc in psutil.process_iter(['pid', 'name', 'exe', 'cmdline']):
                    try:
                        current_processes[proc.info['pid']] = {
                            'name': proc.info['name'],
                            'exe': proc.info['exe'],
                            'cmdline': proc.info['cmdline'],
                            'start_time': proc.create_time()
                        }
                    except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
                        continue
                
                # Check for new processes
                for pid, info in current_processes.items():
                    if pid not in self.process_list:
                        asyncio.run(self._handle_new_process(pid, info))
                
                # Check for terminated processes
                terminated_pids = set(self.process_list.keys()) - set(current_processes.keys())
                for pid in terminated_pids:
                    del self.process_list[pid]
                
                # Update process list
                self.process_list = current_processes
                
                # Monitor behavior of running processes
                for pid in current_processes:
                    asyncio.run(self._monitor_process_behavior(pid))
                
                # Update statistics
                self.stats["processes_monitored"] = len(self.process_list)
                
                time.sleep(1)  # Check every second
                
            except Exception as e:
                self.logger.log_error(f"Error in process monitoring: {e}")
                time.sleep(5)  # Wait before retrying
    
    async def _handle_new_process(self, pid: int, info: Dict):
        """Handle newly detected process"""
        try:
            self.logger.log_debug(f"New process detected: {info['name']} (PID: {pid})")
            
            # Check if process is suspicious
            is_suspicious = await self._check_process_suspicious(pid, info)
            
            if is_suspicious:
                self.suspicious_processes.add(pid)
                self.stats["suspicious_detected"] += 1
                
                threat_info = {
                    "type": "suspicious_process",
                    "pid": pid,
                    "name": info["name"],
                    "exe": info["exe"],
                    "cmdline": info["cmdline"],
                    "detection_time": datetime.now().isoformat()
                }
                
                if self.on_suspicious_activity:
                    await self.on_suspicious_activity(threat_info)
            
        except Exception as e:
            self.logger.log_error(f"Error handling new process {pid}: {e}")
    
    async def _check_process_suspicious(self, pid: int, info: Dict) -> bool:
        """Check if a process is suspicious"""
        try:
            # Skip known good processes
            if info["name"].lower() in self.known_processes:
                return False
            
            # Check executable path
            if info["exe"]:
                exe_path = Path(info["exe"])
                
                # Check suspicious locations
                for pattern in self.suspicious_patterns["file_operations"]:
                    if re.match(pattern, str(exe_path), re.IGNORECASE):
                        return True
                
                # Verify digital signature
                if not self._verify_file_signature(exe_path):
                    return True
            
            # Check command line arguments
            if info["cmdline"]:
                cmdline = " ".join(info["cmdline"])
                suspicious_args = [
                    "-encode", "base64", "powershell -enc",
                    "cmd /c", "rundll32", "regsvr32"
                ]
                
                for arg in suspicious_args:
                    if arg.lower() in cmdline.lower():
                        return True
            
            # Check process behavior
            try:
                process = psutil.Process(pid)
                
                # Check network connections
                connections = process.connections()
                for conn in connections:
                    if conn.status == "LISTEN":
                        for suspicious_addr in self.suspicious_patterns["network_connections"]:
                            if (conn.laddr.ip == suspicious_addr[0] and 
                                (suspicious_addr[1] == 0 or conn.laddr.port == suspicious_addr[1])):
                                return True
                
                # Check open files
                open_files = process.open_files()
                for file in open_files:
                    if any(re.match(pattern, file.path, re.IGNORECASE) 
                          for pattern in self.suspicious_patterns["file_operations"]):
                        return True
                
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                pass
            
            return False
            
        except Exception as e:
            self.logger.log_error(f"Error checking process {pid}: {e}")
            return False
    
    def _verify_file_signature(self, file_path: Path) -> bool:
        """Verify digital signature of executable"""
        try:
            # This is a placeholder - in production, use proper signature verification
            return True
        except Exception:
            return False
    
    async def _monitor_process_behavior(self, pid: int):
        """Monitor behavior of a running process"""
        try:
            if pid in self.suspicious_processes:
                return  # Already marked as suspicious
            
            process = psutil.Process(pid)
            
            # Monitor CPU usage
            cpu_percent = process.cpu_percent()
            if cpu_percent > 90:  # High CPU usage
                await self._report_suspicious_behavior(pid, "high_cpu_usage", cpu_percent)
            
            # Monitor memory usage
            memory_info = process.memory_info()
            if memory_info.rss > 1000 * 1024 * 1024:  # Over 1GB RAM
                await self._report_suspicious_behavior(pid, "high_memory_usage", memory_info.rss)
            
            # Monitor file operations
            try:
                open_files = process.open_files()
                for file in open_files:
                    if any(re.match(pattern, file.path, re.IGNORECASE) 
                          for pattern in self.suspicious_patterns["file_operations"]):
                        await self._report_suspicious_behavior(pid, "suspicious_file_access", file.path)
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                pass
            
            # Monitor network connections
            try:
                connections = process.connections()
                for conn in connections:
                    for suspicious_addr in self.suspicious_patterns["network_connections"]:
                        if (conn.laddr.ip == suspicious_addr[0] and 
                            (suspicious_addr[1] == 0 or conn.laddr.port == suspicious_addr[1])):
                            await self._report_suspicious_behavior(
                                pid, "suspicious_network", f"{conn.laddr.ip}:{conn.laddr.port}"
                            )
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                pass
            
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            if pid in self.process_list:
                del self.process_list[pid]
        except Exception as e:
            self.logger.log_error(f"Error monitoring process {pid}: {e}")
    
    async def _report_suspicious_behavior(self, pid: int, behavior_type: str, details: any):
        """Report suspicious process behavior"""
        try:
            if pid not in self.process_list:
                return
            
            process_info = self.process_list[pid]
            
            threat_info = {
                "type": "suspicious_behavior",
                "pid": pid,
                "name": process_info["name"],
                "exe": process_info["exe"],
                "behavior": behavior_type,
                "details": str(details),
                "detection_time": datetime.now().isoformat()
            }
            
            self.suspicious_processes.add(pid)
            self.stats["suspicious_detected"] += 1
            
            if self.on_suspicious_activity:
                await self.on_suspicious_activity(threat_info)
                
        except Exception as e:
            self.logger.log_error(f"Error reporting suspicious behavior for {pid}: {e}")
    
    async def terminate_process(self, pid: int) -> bool:
        """Terminate a suspicious process"""
        try:
            process = psutil.Process(pid)
            process.terminate()
            
            # Wait for process to terminate
            process.wait(timeout=5)
            
            self.stats["blocked_processes"] += 1
            self.logger.log_warning(f"Terminated suspicious process: {pid}")
            return True
            
        except psutil.NoSuchProcess:
            return True  # Process already terminated
        except Exception as e:
            self.logger.log_error(f"Failed to terminate process {pid}: {e}")
            return False
    
    async def add_known_process(self, process_name: str):
        """Add process to known good list"""
        self.known_processes.add(process_name.lower())
        await self._save_known_processes()
    
    async def _save_known_processes(self):
        """Save known processes to file"""
        known_processes_file = Path.home() / ".antivirus_config" / "known_processes.json"
        try:
            with open(known_processes_file, 'w') as f:
                json.dump(list(self.known_processes), f, indent=2)
        except Exception as e:
            self.logger.log_error(f"Error saving known processes: {e}")
    
    async def stop_monitoring(self):
        """Stop process monitoring"""
        if not self.is_monitoring:
            return
        
        self.logger.log_info("Stopping process monitoring")
        
        self.is_monitoring = False
        if self.monitor_thread:
            self.monitor_thread.join(timeout=5)
        
        self.logger.log_info("Process monitoring stopped")
    
    def get_monitoring_stats(self) -> Dict:
        """Get process monitoring statistics"""
        return {
            "is_monitoring": self.is_monitoring,
            "known_processes": len(self.known_processes),
            "suspicious_processes": len(self.suspicious_processes),
            **self.stats
        }
    
    async def export_process_info(self, export_path: Path):
        """Export process monitoring information"""
        try:
            export_data = {
                "known_processes": list(self.known_processes),
                "suspicious_processes": [
                    {
                        "pid": pid,
                        **self.process_list[pid]
                    }
                    for pid in self.suspicious_processes
                    if pid in self.process_list
                ],
                "stats": self.stats
            }
            
            with open(export_path, 'w') as f:
                json.dump(export_data, f, indent=2)
            
            self.logger.log_info(f"Process information exported to: {export_path}")
            return True
            
        except Exception as e:
            self.logger.log_error(f"Failed to export process information: {e}")
            return False
