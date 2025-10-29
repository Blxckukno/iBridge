"""
Core Security Engine
Main orchestrator for all security modules
"""
import asyncio
import threading
from typing import Dict, List, Optional
from datetime import datetime

from .config_manager import ConfigManager
from .threat_detector import ThreatDetector
from .ml_engine import MLEngine
from ..realtime_scanner.file_monitor import FileMonitor
from ..scheduled_scans.scan_scheduler import ScanScheduler
from ..quarantine.quarantine_manager import QuarantineManager
from ..firewall.network_monitor import NetworkMonitor
from ..process_monitor.process_watcher import ProcessWatcher
from ..updates.update_manager import UpdateManager
from ..web_email_protection.web_filter import WebFilter
from ..ransomware_protection.ransomware_detector import RansomwareDetector
from ..resource_optimization.resource_manager import ResourceManager
from ..logging.security_logger import SecurityLogger


class SecurityEngine:
    """Core security engine that coordinates all protection modules"""
    
    def __init__(self, config_manager: ConfigManager, logger: SecurityLogger):
        self.config = config_manager
        self.logger = logger
        
        # Core components
        self.threat_detector = ThreatDetector(config_manager, logger)
        self.ml_engine = MLEngine(config_manager, logger)
        self.quarantine_manager = QuarantineManager(config_manager, logger)
        
        # Protection modules
        self.file_monitor = FileMonitor(self.threat_detector, logger)
        self.scan_scheduler = ScanScheduler(self.threat_detector, logger)
        self.network_monitor = NetworkMonitor(config_manager, logger)
        self.process_watcher = ProcessWatcher(self.threat_detector, logger)
        self.update_manager = UpdateManager(config_manager, logger)
        self.web_filter = WebFilter(config_manager, logger)
        self.ransomware_detector = RansomwareDetector(config_manager, logger)
        self.resource_manager = ResourceManager(config_manager, logger)
        
        # State tracking
        self.is_initialized = False
        self.protection_enabled = False
        self.threats_detected = []
        self.scan_results = {}
        
    async def initialize(self):
        """Initialize all security components"""
        if self.is_initialized:
            return
            
        self.logger.log_info("Initializing security engine")
        
        try:
            # Initialize core components
            await self.threat_detector.initialize()
            await self.ml_engine.initialize()
            await self.quarantine_manager.initialize()
            
            # Initialize protection modules
            await self.file_monitor.initialize()
            await self.scan_scheduler.initialize()
            await self.network_monitor.initialize()
            await self.process_watcher.initialize()
            await self.update_manager.initialize()
            await self.web_filter.initialize()
            await self.ransomware_detector.initialize()
            await self.resource_manager.initialize()
            
            # Setup event handlers
            self._setup_event_handlers()
            
            self.is_initialized = True
            self.logger.log_info("Security engine initialized successfully")
            
        except Exception as e:
            self.logger.log_error(f"Failed to initialize security engine: {e}")
            raise
    
    async def start_real_time_protection(self):
        """Start real-time protection services"""
        if not self.is_initialized:
            await self.initialize()
            
        self.logger.log_info("Starting real-time protection")
        
        # Start file monitoring
        await self.file_monitor.start_monitoring()
        
        # Start ransomware detection
        await self.ransomware_detector.start_monitoring()
        
        # Start web filtering
        await self.web_filter.start_filtering()
        
        self.protection_enabled = True
        self.logger.log_info("Real-time protection started")
    
    async def start_network_monitoring(self):
        """Start network monitoring and firewall"""
        self.logger.log_info("Starting network monitoring")
        await self.network_monitor.start_monitoring()
    
    async def start_process_monitoring(self):
        """Start process monitoring"""
        self.logger.log_info("Starting process monitoring")
        await self.process_watcher.start_monitoring()
    
    async def scan_system(self, scan_type: str = "full") -> Dict:
        """Perform system scan"""
        self.logger.log_info(f"Starting {scan_type} system scan")
        
        scan_id = f"scan_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        if scan_type == "full":
            result = await self.scan_scheduler.full_system_scan()
        elif scan_type == "quick":
            result = await self.scan_scheduler.quick_scan()
        elif scan_type == "custom":
            result = await self.scan_scheduler.custom_scan()
        else:
            raise ValueError(f"Unknown scan type: {scan_type}")
        
        self.scan_results[scan_id] = result
        return result
    
    async def quarantine_threat(self, threat_info: Dict):
        """Quarantine a detected threat"""
        self.logger.log_warning(f"Quarantining threat: {threat_info['name']}")
        await self.quarantine_manager.quarantine_file(threat_info)
    
    async def get_system_status(self) -> Dict:
        """Get current system protection status"""
        return {
            "protection_enabled": self.protection_enabled,
            "real_time_scanning": self.file_monitor.is_monitoring,
            "network_monitoring": self.network_monitor.is_monitoring,
            "process_monitoring": self.process_watcher.is_monitoring,
            "threats_detected": len(self.threats_detected),
            "last_scan": self.scan_scheduler.get_last_scan_time(),
            "quarantined_items": await self.quarantine_manager.get_quarantine_count(),
            "definition_version": await self.update_manager.get_definition_version(),
            "system_performance": await self.resource_manager.get_performance_metrics()
        }
    
    async def update_definitions(self):
        """Update virus definitions and signatures"""
        self.logger.log_info("Starting definition update")
        await self.update_manager.update_definitions()
    
    def _setup_event_handlers(self):
        """Setup event handlers for threat detection"""
        self.file_monitor.on_threat_detected = self._handle_threat_detected
        self.process_watcher.on_suspicious_activity = self._handle_suspicious_activity
        self.network_monitor.on_malicious_connection = self._handle_malicious_connection
        self.ransomware_detector.on_ransomware_detected = self._handle_ransomware_detected
    
    async def _handle_threat_detected(self, threat_info: Dict):
        """Handle detected threats"""
        self.threats_detected.append(threat_info)
        self.logger.log_warning(f"Threat detected: {threat_info}")
        
        # Auto-quarantine if configured
        if self.config.get_setting("auto_quarantine", True):
            await self.quarantine_threat(threat_info)
    
    async def _handle_suspicious_activity(self, activity_info: Dict):
        """Handle suspicious process activity"""
        self.logger.log_warning(f"Suspicious activity detected: {activity_info}")
        
        # Analyze with ML engine
        ml_result = await self.ml_engine.analyze_behavior(activity_info)
        if ml_result["threat_level"] > 0.7:
            await self._handle_threat_detected({
                "type": "suspicious_process",
                "details": activity_info,
                "ml_confidence": ml_result["threat_level"]
            })
    
    async def _handle_malicious_connection(self, connection_info: Dict):
        """Handle malicious network connections"""
        self.logger.log_warning(f"Malicious connection blocked: {connection_info}")
    
    async def _handle_ransomware_detected(self, ransomware_info: Dict):
        """Handle ransomware detection"""
        self.logger.log_critical(f"RANSOMWARE DETECTED: {ransomware_info}")
        
        # Immediate action - isolate and alert
        await self.quarantine_threat(ransomware_info)
        
        # TODO: Trigger emergency protocols
    
    async def stop(self):
        """Stop all security services"""
        self.logger.log_info("Stopping security engine")
        
        # Stop all monitoring services
        await self.file_monitor.stop_monitoring()
        await self.network_monitor.stop_monitoring()
        await self.process_watcher.stop_monitoring()
        await self.ransomware_detector.stop_monitoring()
        await self.web_filter.stop_filtering()
        
        self.protection_enabled = False
        self.logger.log_info("Security engine stopped")
