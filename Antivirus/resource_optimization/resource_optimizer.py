"""
Resource Optimization System
Monitors and optimizes system resource usage
"""

import psutil
import threading
import time
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional
import json
import logging

from ..core_engine.config_manager import ConfigManager
from ..logging.security_logger import SecurityLogger


class ResourceOptimizer:
    """Resource optimization and monitoring"""
    
    def __init__(self, config_manager: ConfigManager, logger: SecurityLogger):
        self.config = config_manager
        self.logger = logger
        
        # Monitoring state
        self.is_monitoring = False
        self.monitoring_thread = None
        
        # Resource thresholds
        self.cpu_threshold = 80  # %
        self.memory_threshold = 85  # %
        self.disk_threshold = 90  # %
        self.network_threshold = 80  # % of max observed
        
        # Performance data
        self.performance_data = {
            "cpu": [],
            "memory": [],
            "disk": [],
            "network": [],
            "processes": {}
        }
        
        # Resource allocation
        self.resource_limits = {
            "scan_cpu_limit": 30,  # %
            "realtime_cpu_limit": 10,  # %
            "max_concurrent_scans": 2
        }
        
        # Optimization rules
        self.optimization_rules = []
        
        # Statistics
        self.stats = {
            "optimizations_performed": 0,
            "resource_alerts": 0,
            "start_time": None
        }
    
    async def initialize(self):
        """Initialize resource optimization"""
        self.logger.log_info("Initializing resource optimization")
        
        try:
            # Load configuration
            await self._load_config()
            
            # Initialize optimization rules
            self._setup_optimization_rules()
            
            self.logger.log_info("Resource optimization initialized")
            
        except Exception as e:
            self.logger.log_error(f"Failed to initialize resource optimization: {e}")
            raise
    
    async def _load_config(self):
        """Load optimization configuration"""
        config_file = Path.home() / ".antivirus_config" / "resource_config.json"
        
        if config_file.exists():
            try:
                with open(config_file, 'r') as f:
                    config = json.load(f)
                    self.cpu_threshold = config.get("cpu_threshold", 80)
                    self.memory_threshold = config.get("memory_threshold", 85)
                    self.disk_threshold = config.get("disk_threshold", 90)
                    self.network_threshold = config.get("network_threshold", 80)
                    self.resource_limits = config.get("resource_limits", self.resource_limits)
            except Exception as e:
                self.logger.log_error(f"Error loading resource config: {e}")
    
    def _setup_optimization_rules(self):
        """Setup resource optimization rules"""
        self.optimization_rules = [
            {
                "name": "high_cpu_usage",
                "condition": lambda metrics: metrics["cpu_percent"] > self.cpu_threshold,
                "action": self._handle_high_cpu
            },
            {
                "name": "high_memory_usage",
                "condition": lambda metrics: metrics["memory_percent"] > self.memory_threshold,
                "action": self._handle_high_memory
            },
            {
                "name": "high_disk_usage",
                "condition": lambda metrics: metrics["disk_percent"] > self.disk_threshold,
                "action": self._handle_high_disk
            },
            {
                "name": "scan_resource_limit",
                "condition": lambda metrics: self._check_scan_resources(metrics),
                "action": self._adjust_scan_resources
            }
        ]
    
    async def start_monitoring(self):
        """Start resource monitoring"""
        if self.is_monitoring:
            return
        
        self.logger.log_info("Starting resource monitoring")
        
        self.is_monitoring = True
        self.stats["start_time"] = datetime.now().isoformat()
        
        # Start monitoring thread
        self.monitoring_thread = threading.Thread(target=self._monitor_resources)
        self.monitoring_thread.daemon = True
        self.monitoring_thread.start()
        
        self.logger.log_info("Resource monitoring started")
    
    def _monitor_resources(self):
        """Monitor system resources"""
        while self.is_monitoring:
            try:
                # Collect metrics
                metrics = self._collect_system_metrics()
                
                # Store performance data
                self._update_performance_data(metrics)
                
                # Check optimization rules
                self._check_optimization_rules(metrics)
                
                # Clean up old data
                self._cleanup_old_data()
                
                time.sleep(5)  # Check every 5 seconds
                
            except Exception as e:
                self.logger.log_error(f"Error monitoring resources: {e}")
                time.sleep(30)  # Wait longer on error
    
    def _collect_system_metrics(self) -> Dict:
        """Collect system resource metrics"""
        try:
            # CPU usage
            cpu_percent = psutil.cpu_percent(interval=1)
            cpu_times = psutil.cpu_times_percent()
            cpu_freq = psutil.cpu_freq()
            
            # Memory usage
            memory = psutil.virtual_memory()
            swap = psutil.swap_memory()
            
            # Disk usage
            disk = psutil.disk_usage('/')
            disk_io = psutil.disk_io_counters()
            
            # Network usage
            network = psutil.net_io_counters()
            
            # Process information
            processes = {}
            for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']):
                try:
                    pinfo = proc.info
                    processes[pinfo['pid']] = {
                        'name': pinfo['name'],
                        'cpu_percent': pinfo['cpu_percent'],
                        'memory_percent': pinfo['memory_percent']
                    }
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    pass
            
            return {
                "timestamp": datetime.now().isoformat(),
                "cpu_percent": cpu_percent,
                "cpu_times": {
                    "user": cpu_times.user,
                    "system": cpu_times.system,
                    "idle": cpu_times.idle
                },
                "cpu_freq": {
                    "current": cpu_freq.current,
                    "min": cpu_freq.min,
                    "max": cpu_freq.max
                },
                "memory_percent": memory.percent,
                "memory": {
                    "total": memory.total,
                    "available": memory.available,
                    "used": memory.used,
                    "free": memory.free
                },
                "swap": {
                    "total": swap.total,
                    "used": swap.used,
                    "free": swap.free,
                    "percent": swap.percent
                },
                "disk_percent": disk.percent,
                "disk": {
                    "total": disk.total,
                    "used": disk.used,
                    "free": disk.free
                },
                "disk_io": {
                    "read_bytes": disk_io.read_bytes,
                    "write_bytes": disk_io.write_bytes
                },
                "network": {
                    "bytes_sent": network.bytes_sent,
                    "bytes_recv": network.bytes_recv,
                    "packets_sent": network.packets_sent,
                    "packets_recv": network.packets_recv
                },
                "processes": processes
            }
            
        except Exception as e:
            self.logger.log_error(f"Error collecting system metrics: {e}")
            return {}
    
    def _update_performance_data(self, metrics: Dict):
        """Update performance history"""
        if not metrics:
            return
        
        # Keep last hour of data
        max_history = 720  # 1 hour at 5 second intervals
        
        # Update CPU data
        self.performance_data["cpu"].append({
            "timestamp": metrics["timestamp"],
            "percent": metrics["cpu_percent"]
        })
        if len(self.performance_data["cpu"]) > max_history:
            self.performance_data["cpu"].pop(0)
        
        # Update memory data
        self.performance_data["memory"].append({
            "timestamp": metrics["timestamp"],
            "percent": metrics["memory_percent"]
        })
        if len(self.performance_data["memory"]) > max_history:
            self.performance_data["memory"].pop(0)
        
        # Update disk data
        self.performance_data["disk"].append({
            "timestamp": metrics["timestamp"],
            "percent": metrics["disk_percent"]
        })
        if len(self.performance_data["disk"]) > max_history:
            self.performance_data["disk"].pop(0)
        
        # Update network data
        self.performance_data["network"].append({
            "timestamp": metrics["timestamp"],
            "bytes_sent": metrics["network"]["bytes_sent"],
            "bytes_recv": metrics["network"]["bytes_recv"]
        })
        if len(self.performance_data["network"]) > max_history:
            self.performance_data["network"].pop(0)
        
        # Update process data
        self.performance_data["processes"] = metrics["processes"]
    
    def _check_optimization_rules(self, metrics: Dict):
        """Check and apply optimization rules"""
        if not metrics:
            return
        
        for rule in self.optimization_rules:
            try:
                if rule["condition"](metrics):
                    rule["action"](metrics)
                    self.stats["optimizations_performed"] += 1
            except Exception as e:
                self.logger.log_error(f"Error checking rule {rule['name']}: {e}")
    
    def _handle_high_cpu(self, metrics: Dict):
        """Handle high CPU usage"""
        self.logger.log_warning(f"High CPU usage detected: {metrics['cpu_percent']}%")
        self.stats["resource_alerts"] += 1
        
        try:
            # Find resource-intensive processes
            high_cpu_processes = []
            for pid, pinfo in metrics["processes"].items():
                if pinfo["cpu_percent"] > 20:  # Processes using more than 20% CPU
                    high_cpu_processes.append((pid, pinfo))
            
            # Sort by CPU usage
            high_cpu_processes.sort(key=lambda x: x[1]["cpu_percent"], reverse=True)
            
            # Adjust antivirus operations
            if high_cpu_processes:
                self.resource_limits["scan_cpu_limit"] = max(
                    10,  # Minimum limit
                    self.resource_limits["scan_cpu_limit"] - 5  # Reduce by 5%
                )
                
                self.logger.log_info(
                    f"Adjusted scan CPU limit to {self.resource_limits['scan_cpu_limit']}%"
                )
        
        except Exception as e:
            self.logger.log_error(f"Error handling high CPU: {e}")
    
    def _handle_high_memory(self, metrics: Dict):
        """Handle high memory usage"""
        self.logger.log_warning(f"High memory usage detected: {metrics['memory_percent']}%")
        self.stats["resource_alerts"] += 1
        
        try:
            # Find memory-intensive processes
            high_mem_processes = []
            for pid, pinfo in metrics["processes"].items():
                if pinfo["memory_percent"] > 5:  # Processes using more than 5% memory
                    high_mem_processes.append((pid, pinfo))
            
            # Sort by memory usage
            high_mem_processes.sort(key=lambda x: x[1]["memory_percent"], reverse=True)
            
            if high_mem_processes:
                # Suggest memory optimization
                self.logger.log_info("Memory optimization suggested")
                
                # Reduce concurrent scan limit if needed
                if self.resource_limits["max_concurrent_scans"] > 1:
                    self.resource_limits["max_concurrent_scans"] -= 1
                    self.logger.log_info(
                        f"Reduced max concurrent scans to {self.resource_limits['max_concurrent_scans']}"
                    )
        
        except Exception as e:
            self.logger.log_error(f"Error handling high memory: {e}")
    
    def _handle_high_disk(self, metrics: Dict):
        """Handle high disk usage"""
        self.logger.log_warning(f"High disk usage detected: {metrics['disk_percent']}%")
        self.stats["resource_alerts"] += 1
        
        try:
            # Check disk space
            if metrics["disk"]["free"] < 1_000_000_000:  # Less than 1GB free
                self.logger.log_warning("Critical low disk space")
                
                # Suggest cleanup
                self._suggest_disk_cleanup()
        
        except Exception as e:
            self.logger.log_error(f"Error handling high disk: {e}")
    
    def _check_scan_resources(self, metrics: Dict) -> bool:
        """Check if scan resource limits are exceeded"""
        try:
            antivirus_processes = []
            for pid, pinfo in metrics["processes"].items():
                if "antivirus" in pinfo["name"].lower():
                    antivirus_processes.append(pinfo)
            
            total_cpu = sum(p["cpu_percent"] for p in antivirus_processes)
            return total_cpu > self.resource_limits["scan_cpu_limit"]
        
        except Exception:
            return False
    
    def _adjust_scan_resources(self, metrics: Dict):
        """Adjust scan resource usage"""
        try:
            # Calculate current usage
            antivirus_cpu = 0
            antivirus_memory = 0
            
            for pid, pinfo in metrics["processes"].items():
                if "antivirus" in pinfo["name"].lower():
                    antivirus_cpu += pinfo["cpu_percent"]
                    antivirus_memory += pinfo["memory_percent"]
            
            # Adjust limits if needed
            if antivirus_cpu > self.resource_limits["scan_cpu_limit"]:
                self.resource_limits["scan_cpu_limit"] = max(
                    10,
                    self.resource_limits["scan_cpu_limit"] - 5
                )
                self.logger.log_info(f"Adjusted scan CPU limit to {self.resource_limits['scan_cpu_limit']}%")
            
            elif antivirus_cpu < self.resource_limits["scan_cpu_limit"] / 2:
                self.resource_limits["scan_cpu_limit"] = min(
                    50,
                    self.resource_limits["scan_cpu_limit"] + 5
                )
                self.logger.log_info(f"Increased scan CPU limit to {self.resource_limits['scan_cpu_limit']}%")
        
        except Exception as e:
            self.logger.log_error(f"Error adjusting scan resources: {e}")
    
    def _suggest_disk_cleanup(self):
        """Suggest disk cleanup actions"""
        cleanup_suggestions = []
        
        try:
            # Check quarantine folder
            quarantine_path = Path.home() / ".antivirus_quarantine"
            if quarantine_path.exists():
                quarantine_size = sum(f.stat().st_size for f in quarantine_path.rglob('*'))
                if quarantine_size > 100_000_000:  # 100MB
                    cleanup_suggestions.append({
                        "type": "quarantine",
                        "size": quarantine_size,
                        "action": "Review and clean quarantine folder"
                    })
            
            # Check log files
            log_path = Path.home() / ".antivirus_logs"
            if log_path.exists():
                log_size = sum(f.stat().st_size for f in log_path.rglob('*.log'))
                if log_size > 50_000_000:  # 50MB
                    cleanup_suggestions.append({
                        "type": "logs",
                        "size": log_size,
                        "action": "Archive old log files"
                    })
            
            # Check scan reports
            reports_path = Path.home() / ".antivirus_reports"
            if reports_path.exists():
                reports_size = sum(f.stat().st_size for f in reports_path.rglob('*'))
                if reports_size > 200_000_000:  # 200MB
                    cleanup_suggestions.append({
                        "type": "reports",
                        "size": reports_size,
                        "action": "Clean old scan reports"
                    })
            
            if cleanup_suggestions:
                self.logger.log_info("Disk cleanup suggestions available")
                return cleanup_suggestions
            
        except Exception as e:
            self.logger.log_error(f"Error suggesting disk cleanup: {e}")
            return []
    
    def _cleanup_old_data(self):
        """Clean up old performance data"""
        try:
            current_time = datetime.now()
            one_hour_ago = current_time - timedelta(hours=1)
            
            # Convert ISO timestamp to datetime for comparison
            for metric in ["cpu", "memory", "disk", "network"]:
                self.performance_data[metric] = [
                    data for data in self.performance_data[metric]
                    if datetime.fromisoformat(data["timestamp"]) > one_hour_ago
                ]
        
        except Exception as e:
            self.logger.log_error(f"Error cleaning up old data: {e}")
    
    async def stop_monitoring(self):
        """Stop resource monitoring"""
        if not self.is_monitoring:
            return
        
        self.logger.log_info("Stopping resource monitoring")
        
        self.is_monitoring = False
        if self.monitoring_thread:
            self.monitoring_thread.join(timeout=5)
        
        self.logger.log_info("Resource monitoring stopped")
    
    def get_resource_stats(self) -> Dict:
        """Get resource statistics"""
        return {
            "is_monitoring": self.is_monitoring,
            "thresholds": {
                "cpu": self.cpu_threshold,
                "memory": self.memory_threshold,
                "disk": self.disk_threshold,
                "network": self.network_threshold
            },
            "resource_limits": self.resource_limits,
            "current_usage": {
                "cpu": self.performance_data["cpu"][-1] if self.performance_data["cpu"] else None,
                "memory": self.performance_data["memory"][-1] if self.performance_data["memory"] else None,
                "disk": self.performance_data["disk"][-1] if self.performance_data["disk"] else None
            },
            **self.stats
        }
    
    def get_performance_history(self, metric: str, duration: int = 3600) -> List[Dict]:
        """Get performance history for specified metric"""
        try:
            if metric not in self.performance_data:
                return []
            
            current_time = datetime.now()
            start_time = current_time - timedelta(seconds=duration)
            
            return [
                data for data in self.performance_data[metric]
                if datetime.fromisoformat(data["timestamp"]) > start_time
            ]
        
        except Exception as e:
            self.logger.log_error(f"Error getting performance history: {e}")
            return []
    
    async def update_resource_limits(self, limits: Dict):
        """Update resource limits"""
        try:
            self.resource_limits.update(limits)
            await self._save_config()
            self.logger.log_info("Resource limits updated")
        
        except Exception as e:
            self.logger.log_error(f"Error updating resource limits: {e}")
    
    async def _save_config(self):
        """Save resource configuration"""
        config = {
            "cpu_threshold": self.cpu_threshold,
            "memory_threshold": self.memory_threshold,
            "disk_threshold": self.disk_threshold,
            "network_threshold": self.network_threshold,
            "resource_limits": self.resource_limits
        }
        
        config_file = Path.home() / ".antivirus_config" / "resource_config.json"
        try:
            with open(config_file, 'w') as f:
                json.dump(config, f, indent=2)
        except Exception as e:
            self.logger.log_error(f"Error saving resource config: {e}")
