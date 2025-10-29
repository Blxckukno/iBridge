"""
Advanced Antivirus & Cybersecurity System
Main entry point for the comprehensive security solution
"""
import asyncio
import logging
import signal
import sys
import threading
import time
from pathlib import Path

from core_engine.security_engine import SecurityEngine
from core_engine.config_manager import ConfigManager
from logging.security_logger import SecurityLogger
from ui.dashboard import Dashboard


class AntivirusSystem:
    """Main antivirus system orchestrator"""
    
    def __init__(self):
        self.config_manager = ConfigManager()
        self.logger = SecurityLogger()
        self.security_engine = SecurityEngine(self.config_manager, self.logger)
        self.dashboard = Dashboard(self.security_engine)
        self.running = False
        
    async def start(self):
        """Start the antivirus system"""
        try:
            self.logger.log_info("Starting Advanced Antivirus & Cybersecurity System")
            
            # Initialize all components
            await self.security_engine.initialize()
            
            # Start real-time protection
            await self.security_engine.start_real_time_protection()
            
            # Start network monitoring
            await self.security_engine.start_network_monitoring()
            
            # Start process monitoring
            await self.security_engine.start_process_monitoring()
            
            # Start dashboard
            await self.dashboard.start()
            
            self.running = True
            self.logger.log_info("Antivirus system started successfully")
            
            # Keep the system running
            while self.running:
                await asyncio.sleep(1)
                
        except Exception as e:
            self.logger.log_error(f"Failed to start antivirus system: {e}")
            sys.exit(1)
    
    async def stop(self):
        """Stop the antivirus system"""
        self.logger.log_info("Stopping antivirus system")
        self.running = False
        
        await self.security_engine.stop()
        await self.dashboard.stop()
        
        self.logger.log_info("Antivirus system stopped")
    
    def signal_handler(self, signum, frame):
        """Handle system signals for graceful shutdown"""
        print("\nReceived signal to stop. Shutting down gracefully...")
        asyncio.create_task(self.stop())


async def main():
    """Main entry point"""
    antivirus = AntivirusSystem()
    
    # Setup signal handlers
    signal.signal(signal.SIGINT, antivirus.signal_handler)
    signal.signal(signal.SIGTERM, antivirus.signal_handler)
    
    try:
        await antivirus.start()
    except KeyboardInterrupt:
        await antivirus.stop()


if __name__ == "__main__":
    print("Advanced Antivirus & Cybersecurity System")
    print("=" * 50)
    print("Starting system initialization...")
    
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nSystem shutdown complete.")
