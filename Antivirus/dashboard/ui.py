"""
Dashboard UI and Control Interface
Provides user interface for monitoring and controlling antivirus features
"""

import tkinter as tk
from tkinter import ttk
import threading
from datetime import datetime
import json
from pathlib import Path
import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
import numpy as np
from typing import Dict, List, Optional

from ..core_engine.config_manager import ConfigManager
from ..logging.security_logger import SecurityLogger


class Dashboard:
    """Main dashboard interface"""
    
    def __init__(self, config_manager: ConfigManager, logger: SecurityLogger):
        self.config = config_manager
        self.logger = logger
        
        # UI state
        self.root = None
        self.tabs = {}
        self.charts = {}
        self.status_labels = {}
        self.update_thread = None
        self.is_running = False
        
        # Component references
        self.realtime_scanner = None
        self.scheduled_scanner = None
        self.quarantine_manager = None
        self.web_filter = None
        self.ransomware_guard = None
        self.ml_engine = None
        self.resource_optimizer = None
        
        # Update intervals
        self.fast_update_interval = 1000  # 1 second
        self.slow_update_interval = 5000  # 5 seconds
        self.chart_update_interval = 10000  # 10 seconds
        
        # Chart history
        self.chart_data = {
            "cpu": [],
            "memory": [],
            "threats": [],
            "scans": []
        }
    
    def initialize(self, components: Dict):
        """Initialize dashboard with component references"""
        self.logger.log_info("Initializing dashboard")
        
        try:
            # Store component references
            self.realtime_scanner = components.get("realtime_scanner")
            self.scheduled_scanner = components.get("scheduled_scanner")
            self.quarantine_manager = components.get("quarantine_manager")
            self.web_filter = components.get("web_filter")
            self.ransomware_guard = components.get("ransomware_guard")
            self.ml_engine = components.get("ml_engine")
            self.resource_optimizer = components.get("resource_optimizer")
            
            # Create main window
            self.root = tk.Tk()
            self.root.title("Antivirus Dashboard")
            self.root.geometry("1200x800")
            
            # Setup UI
            self._setup_ui()
            
            self.logger.log_info("Dashboard initialized")
            
        except Exception as e:
            self.logger.log_error(f"Failed to initialize dashboard: {e}")
            raise
    
    def _setup_ui(self):
        """Setup dashboard UI components"""
        # Create main container
        main_container = ttk.PanedWindow(self.root, orient=tk.HORIZONTAL)
        main_container.pack(fill=tk.BOTH, expand=True)
        
        # Create left sidebar for status and controls
        sidebar = ttk.Frame(main_container)
        main_container.add(sidebar)
        
        # Create right content area with tabs
        content = ttk.Notebook(main_container)
        main_container.add(content)
        
        # Setup sidebar
        self._setup_sidebar(sidebar)
        
        # Setup content tabs
        self._setup_overview_tab(content)
        self._setup_protection_tab(content)
        self._setup_scans_tab(content)
        self._setup_quarantine_tab(content)
        self._setup_settings_tab(content)
        
        # Start update thread
        self.is_running = True
        self.update_thread = threading.Thread(target=self._update_loop)
        self.update_thread.daemon = True
        self.update_thread.start()
    
    def _setup_sidebar(self, sidebar: ttk.Frame):
        """Setup sidebar with status and quick controls"""
        # Protection status
        status_frame = ttk.LabelFrame(sidebar, text="Protection Status")
        status_frame.pack(fill=tk.X, padx=5, pady=5)
        
        self.status_labels["realtime"] = ttk.Label(status_frame, text="Realtime: Unknown")
        self.status_labels["realtime"].pack(anchor=tk.W, padx=5, pady=2)
        
        self.status_labels["web"] = ttk.Label(status_frame, text="Web Protection: Unknown")
        self.status_labels["web"].pack(anchor=tk.W, padx=5, pady=2)
        
        self.status_labels["ransomware"] = ttk.Label(status_frame, text="Ransomware: Unknown")
        self.status_labels["ransomware"].pack(anchor=tk.W, padx=5, pady=2)
        
        # Quick actions
        actions_frame = ttk.LabelFrame(sidebar, text="Quick Actions")
        actions_frame.pack(fill=tk.X, padx=5, pady=5)
        
        ttk.Button(actions_frame, text="Quick Scan", command=self._start_quick_scan).pack(fill=tk.X, padx=5, pady=2)
        ttk.Button(actions_frame, text="Update Now", command=self._update_definitions).pack(fill=tk.X, padx=5, pady=2)
        ttk.Button(actions_frame, text="View Quarantine", command=self._show_quarantine).pack(fill=tk.X, padx=5, pady=2)
    
    def _setup_overview_tab(self, notebook: ttk.Notebook):
        """Setup overview tab with charts and statistics"""
        overview = ttk.Frame(notebook)
        notebook.add(overview, text="Overview")
        
        # Create chart frames
        charts_top = ttk.Frame(overview)
        charts_top.pack(fill=tk.X, padx=5, pady=5)
        
        charts_bottom = ttk.Frame(overview)
        charts_bottom.pack(fill=tk.X, padx=5, pady=5)
        
        # CPU usage chart
        cpu_frame = ttk.LabelFrame(charts_top, text="CPU Usage")
        cpu_frame.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=5)
        
        figure1, ax1 = plt.subplots(figsize=(6, 4))
        self.charts["cpu"] = {
            "figure": figure1,
            "ax": ax1,
            "canvas": FigureCanvasTkAgg(figure1, cpu_frame)
        }
        self.charts["cpu"]["canvas"].get_tk_widget().pack(fill=tk.BOTH, expand=True)
        
        # Memory usage chart
        memory_frame = ttk.LabelFrame(charts_top, text="Memory Usage")
        memory_frame.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=5)
        
        figure2, ax2 = plt.subplots(figsize=(6, 4))
        self.charts["memory"] = {
            "figure": figure2,
            "ax": ax2,
            "canvas": FigureCanvasTkAgg(figure2, memory_frame)
        }
        self.charts["memory"]["canvas"].get_tk_widget().pack(fill=tk.BOTH, expand=True)
        
        # Threats chart
        threats_frame = ttk.LabelFrame(charts_bottom, text="Threats Detected")
        threats_frame.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=5)
        
        figure3, ax3 = plt.subplots(figsize=(6, 4))
        self.charts["threats"] = {
            "figure": figure3,
            "ax": ax3,
            "canvas": FigureCanvasTkAgg(figure3, threats_frame)
        }
        self.charts["threats"]["canvas"].get_tk_widget().pack(fill=tk.BOTH, expand=True)
        
        # Scan history chart
        scans_frame = ttk.LabelFrame(charts_bottom, text="Scan History")
        scans_frame.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=5)
        
        figure4, ax4 = plt.subplots(figsize=(6, 4))
        self.charts["scans"] = {
            "figure": figure4,
            "ax": ax4,
            "canvas": FigureCanvasTkAgg(figure4, scans_frame)
        }
        self.charts["scans"]["canvas"].get_tk_widget().pack(fill=tk.BOTH, expand=True)
    
    def _setup_protection_tab(self, notebook: ttk.Notebook):
        """Setup protection status and settings tab"""
        protection = ttk.Frame(notebook)
        notebook.add(protection, text="Protection")
        
        # Realtime protection
        realtime_frame = ttk.LabelFrame(protection, text="Realtime Protection")
        realtime_frame.pack(fill=tk.X, padx=5, pady=5)
        
        ttk.Label(realtime_frame, text="Status:").grid(row=0, column=0, padx=5, pady=2)
        self.status_labels["realtime_status"] = ttk.Label(realtime_frame, text="Unknown")
        self.status_labels["realtime_status"].grid(row=0, column=1, padx=5, pady=2)
        
        ttk.Button(realtime_frame, text="Enable", command=lambda: self._toggle_protection("realtime", True)).grid(row=0, column=2, padx=5, pady=2)
        ttk.Button(realtime_frame, text="Disable", command=lambda: self._toggle_protection("realtime", False)).grid(row=0, column=3, padx=5, pady=2)
        
        # Web protection
        web_frame = ttk.LabelFrame(protection, text="Web Protection")
        web_frame.pack(fill=tk.X, padx=5, pady=5)
        
        ttk.Label(web_frame, text="Status:").grid(row=0, column=0, padx=5, pady=2)
        self.status_labels["web_status"] = ttk.Label(web_frame, text="Unknown")
        self.status_labels["web_status"].grid(row=0, column=1, padx=5, pady=2)
        
        ttk.Button(web_frame, text="Enable", command=lambda: self._toggle_protection("web", True)).grid(row=0, column=2, padx=5, pady=2)
        ttk.Button(web_frame, text="Disable", command=lambda: self._toggle_protection("web", False)).grid(row=0, column=3, padx=5, pady=2)
        
        # Ransomware protection
        ransomware_frame = ttk.LabelFrame(protection, text="Ransomware Protection")
        ransomware_frame.pack(fill=tk.X, padx=5, pady=5)
        
        ttk.Label(ransomware_frame, text="Status:").grid(row=0, column=0, padx=5, pady=2)
        self.status_labels["ransomware_status"] = ttk.Label(ransomware_frame, text="Unknown")
        self.status_labels["ransomware_status"].grid(row=0, column=1, padx=5, pady=2)
        
        ttk.Button(ransomware_frame, text="Enable", command=lambda: self._toggle_protection("ransomware", True)).grid(row=0, column=2, padx=5, pady=2)
        ttk.Button(ransomware_frame, text="Disable", command=lambda: self._toggle_protection("ransomware", False)).grid(row=0, column=3, padx=5, pady=2)
    
    def _setup_scans_tab(self, notebook: ttk.Notebook):
        """Setup scan management tab"""
        scans = ttk.Frame(notebook)
        notebook.add(scans, text="Scans")
        
        # Scan types
        scan_frame = ttk.LabelFrame(scans, text="Start New Scan")
        scan_frame.pack(fill=tk.X, padx=5, pady=5)
        
        ttk.Button(scan_frame, text="Quick Scan", command=self._start_quick_scan).grid(row=0, column=0, padx=5, pady=5)
        ttk.Button(scan_frame, text="Full Scan", command=self._start_full_scan).grid(row=0, column=1, padx=5, pady=5)
        ttk.Button(scan_frame, text="Custom Scan", command=self._start_custom_scan).grid(row=0, column=2, padx=5, pady=5)
        
        # Scan history
        history_frame = ttk.LabelFrame(scans, text="Scan History")
        history_frame.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        
        self.scan_history = ttk.Treeview(history_frame, columns=("date", "type", "result", "threats"), show="headings")
        self.scan_history.heading("date", text="Date")
        self.scan_history.heading("type", text="Type")
        self.scan_history.heading("result", text="Result")
        self.scan_history.heading("threats", text="Threats")
        self.scan_history.pack(fill=tk.BOTH, expand=True)
    
    def _setup_quarantine_tab(self, notebook: ttk.Notebook):
        """Setup quarantine management tab"""
        quarantine = ttk.Frame(notebook)
        notebook.add(quarantine, text="Quarantine")
        
        # Quarantined items list
        items_frame = ttk.Frame(quarantine)
        items_frame.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        
        self.quarantine_list = ttk.Treeview(items_frame, columns=("date", "file", "threat", "status"), show="headings")
        self.quarantine_list.heading("date", text="Date")
        self.quarantine_list.heading("file", text="File")
        self.quarantine_list.heading("threat", text="Threat")
        self.quarantine_list.heading("status", text="Status")
        self.quarantine_list.pack(fill=tk.BOTH, expand=True)
        
        # Actions
        actions_frame = ttk.Frame(quarantine)
        actions_frame.pack(fill=tk.X, padx=5, pady=5)
        
        ttk.Button(actions_frame, text="Restore", command=self._restore_quarantine).pack(side=tk.LEFT, padx=5)
        ttk.Button(actions_frame, text="Delete", command=self._delete_quarantine).pack(side=tk.LEFT, padx=5)
        ttk.Button(actions_frame, text="Delete All", command=self._delete_all_quarantine).pack(side=tk.LEFT, padx=5)
    
    def _setup_settings_tab(self, notebook: ttk.Notebook):
        """Setup settings and configuration tab"""
        settings = ttk.Frame(notebook)
        notebook.add(settings, text="Settings")
        
        # General settings
        general_frame = ttk.LabelFrame(settings, text="General Settings")
        general_frame.pack(fill=tk.X, padx=5, pady=5)
        
        ttk.Label(general_frame, text="Start with Windows:").grid(row=0, column=0, padx=5, pady=2)
        ttk.Checkbutton(general_frame).grid(row=0, column=1, padx=5, pady=2)
        
        ttk.Label(general_frame, text="Update automatically:").grid(row=1, column=0, padx=5, pady=2)
        ttk.Checkbutton(general_frame).grid(row=1, column=1, padx=5, pady=2)
        
        # Scan settings
        scan_frame = ttk.LabelFrame(settings, text="Scan Settings")
        scan_frame.pack(fill=tk.X, padx=5, pady=5)
        
        ttk.Label(scan_frame, text="CPU usage limit:").grid(row=0, column=0, padx=5, pady=2)
        ttk.Scale(scan_frame, from_=10, to=100, orient=tk.HORIZONTAL).grid(row=0, column=1, padx=5, pady=2)
        
        ttk.Label(scan_frame, text="Scheduled scans:").grid(row=1, column=0, padx=5, pady=2)
        ttk.Combobox(scan_frame, values=["Daily", "Weekly", "Monthly"]).grid(row=1, column=1, padx=5, pady=2)
    
    def _update_loop(self):
        """Main update loop for UI elements"""
        while self.is_running:
            try:
                # Fast updates (status labels)
                self._update_status_labels()
                self.root.after(self.fast_update_interval)
                
                # Slow updates (lists and details)
                self._update_lists()
                self.root.after(self.slow_update_interval)
                
                # Chart updates
                self._update_charts()
                self.root.after(self.chart_update_interval)
                
            except Exception as e:
                self.logger.log_error(f"Error in update loop: {e}")
                self.root.after(self.slow_update_interval)  # Wait longer on error
    
    def _update_status_labels(self):
        """Update status labels"""
        try:
            # Update realtime protection status
            if self.realtime_scanner:
                status = "Active" if self.realtime_scanner.is_scanning else "Inactive"
                self.status_labels["realtime"].config(text=f"Realtime: {status}")
                self.status_labels["realtime_status"].config(text=status)
            
            # Update web protection status
            if self.web_filter:
                status = "Active" if self.web_filter.is_filtering else "Inactive"
                self.status_labels["web"].config(text=f"Web Protection: {status}")
                self.status_labels["web_status"].config(text=status)
            
            # Update ransomware protection status
            if self.ransomware_guard:
                status = "Active" if self.ransomware_guard.is_monitoring else "Inactive"
                self.status_labels["ransomware"].config(text=f"Ransomware: {status}")
                self.status_labels["ransomware_status"].config(text=status)
            
        except Exception as e:
            self.logger.log_error(f"Error updating status labels: {e}")
    
    def _update_lists(self):
        """Update list views"""
        try:
            # Update scan history
            if self.scheduled_scanner:
                self.scan_history.delete(*self.scan_history.get_children())
                history = self.scheduled_scanner.get_scan_history()
                for scan in history:
                    self.scan_history.insert("", "end", values=(
                        scan["date"],
                        scan["type"],
                        scan["result"],
                        scan["threats_found"]
                    ))
            
            # Update quarantine list
            if self.quarantine_manager:
                self.quarantine_list.delete(*self.quarantine_list.get_children())
                items = self.quarantine_manager.get_quarantined_items()
                for item in items:
                    self.quarantine_list.insert("", "end", values=(
                        item["date"],
                        item["file_name"],
                        item["threat_type"],
                        item["status"]
                    ))
            
        except Exception as e:
            self.logger.log_error(f"Error updating lists: {e}")
    
    def _update_charts(self):
        """Update performance charts"""
        try:
            # Get performance data
            if self.resource_optimizer:
                stats = self.resource_optimizer.get_resource_stats()
                
                # Update CPU chart
                cpu_data = self.resource_optimizer.get_performance_history("cpu", 3600)
                if cpu_data:
                    times = [datetime.fromisoformat(d["timestamp"]) for d in cpu_data]
                    values = [d["percent"] for d in cpu_data]
                    
                    ax = self.charts["cpu"]["ax"]
                    ax.clear()
                    ax.plot(times, values)
                    ax.set_ylabel("CPU %")
                    ax.tick_params(axis='x', rotation=45)
                    self.charts["cpu"]["canvas"].draw()
                
                # Update memory chart
                memory_data = self.resource_optimizer.get_performance_history("memory", 3600)
                if memory_data:
                    times = [datetime.fromisoformat(d["timestamp"]) for d in memory_data]
                    values = [d["percent"] for d in memory_data]
                    
                    ax = self.charts["memory"]["ax"]
                    ax.clear()
                    ax.plot(times, values)
                    ax.set_ylabel("Memory %")
                    ax.tick_params(axis='x', rotation=45)
                    self.charts["memory"]["canvas"].draw()
            
            # Update threats chart
            if self.ml_engine:
                stats = self.ml_engine.get_model_info()
                threat_data = [
                    stats.get("threats_detected", 0),
                    stats.get("files_analyzed", 0),
                    stats.get("behaviors_analyzed", 0)
                ]
                
                ax = self.charts["threats"]["ax"]
                ax.clear()
                ax.bar(["Threats", "Files", "Behaviors"], threat_data)
                ax.set_ylabel("Count")
                self.charts["threats"]["canvas"].draw()
            
            # Update scans chart
            if self.scheduled_scanner:
                scan_history = self.scheduled_scanner.get_scan_history()
                scan_types = ["Quick", "Full", "Custom"]
                scan_counts = [
                    sum(1 for scan in scan_history if scan["type"] == t)
                    for t in scan_types
                ]
                
                ax = self.charts["scans"]["ax"]
                ax.clear()
                ax.pie(scan_counts, labels=scan_types, autopct='%1.1f%%')
                self.charts["scans"]["canvas"].draw()
            
        except Exception as e:
            self.logger.log_error(f"Error updating charts: {e}")
    
    def _toggle_protection(self, protection_type: str, enable: bool):
        """Toggle protection features"""
        try:
            if protection_type == "realtime" and self.realtime_scanner:
                if enable:
                    self.realtime_scanner.start_scanning()
                else:
                    self.realtime_scanner.stop_scanning()
            
            elif protection_type == "web" and self.web_filter:
                if enable:
                    self.web_filter.start_filtering()
                else:
                    self.web_filter.stop_filtering()
            
            elif protection_type == "ransomware" and self.ransomware_guard:
                if enable:
                    self.ransomware_guard.start_protection()
                else:
                    self.ransomware_guard.stop_protection()
            
        except Exception as e:
            self.logger.log_error(f"Error toggling {protection_type} protection: {e}")
    
    def _start_quick_scan(self):
        """Start quick scan"""
        try:
            if self.scheduled_scanner:
                self.scheduled_scanner.start_scan("quick")
        except Exception as e:
            self.logger.log_error(f"Error starting quick scan: {e}")
    
    def _start_full_scan(self):
        """Start full system scan"""
        try:
            if self.scheduled_scanner:
                self.scheduled_scanner.start_scan("full")
        except Exception as e:
            self.logger.log_error(f"Error starting full scan: {e}")
    
    def _start_custom_scan(self):
        """Start custom scan"""
        try:
            # Open file dialog for path selection
            from tkinter import filedialog
            path = filedialog.askdirectory()
            if path and self.scheduled_scanner:
                self.scheduled_scanner.start_scan("custom", path=path)
        except Exception as e:
            self.logger.log_error(f"Error starting custom scan: {e}")
    
    def _update_definitions(self):
        """Update virus definitions"""
        try:
            # Implement update logic here
            pass
        except Exception as e:
            self.logger.log_error(f"Error updating definitions: {e}")
    
    def _show_quarantine(self):
        """Show quarantine tab"""
        notebook = self.root.children["!panedwindow"].children["!notebook"]
        notebook.select(3)  # Select quarantine tab
    
    def _restore_quarantine(self):
        """Restore selected quarantined item"""
        try:
            selected = self.quarantine_list.selection()
            if selected and self.quarantine_manager:
                item = self.quarantine_list.item(selected[0])
                file_name = item["values"][1]
                self.quarantine_manager.restore_file(file_name)
        except Exception as e:
            self.logger.log_error(f"Error restoring quarantined item: {e}")
    
    def _delete_quarantine(self):
        """Delete selected quarantined item"""
        try:
            selected = self.quarantine_list.selection()
            if selected and self.quarantine_manager:
                item = self.quarantine_list.item(selected[0])
                file_name = item["values"][1]
                self.quarantine_manager.delete_file(file_name)
        except Exception as e:
            self.logger.log_error(f"Error deleting quarantined item: {e}")
    
    def _delete_all_quarantine(self):
        """Delete all quarantined items"""
        try:
            if self.quarantine_manager:
                self.quarantine_manager.delete_all()
        except Exception as e:
            self.logger.log_error(f"Error deleting all quarantined items: {e}")
    
    def start(self):
        """Start the dashboard"""
        if self.root:
            self.root.mainloop()
    
    def stop(self):
        """Stop the dashboard"""
        self.is_running = False
        if self.root:
            self.root.quit()
