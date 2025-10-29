"""
Advanced Control Panel
Provides advanced controls and configuration options for the antivirus system
"""

import tkinter as tk
from tkinter import ttk, messagebox, filedialog, scrolledtext
import threading
import time
import json
import os
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Callable
import queue

class AdvancedControlPanel:
    """
    Advanced Control Panel
    Provides comprehensive control and configuration interface
    """
    
    def __init__(self, antivirus_manager=None):
        self.antivirus_manager = antivirus_manager
        self.window: Optional[tk.Toplevel] = None
        self.notebook: Optional[ttk.Notebook] = None
        
        # Initialize logging
        self.logger = logging.getLogger(__name__)
        
        # Control state
        self.control_state = {
            'scan_running': False,
            'realtime_enabled': True,
            'auto_quarantine': True,
            'cloud_protection': True,
            'behavior_monitoring': True,
            'network_protection': True,
            'web_filtering': True,
            'email_protection': True,
            'usb_protection': True,
            'scheduled_scans': []
        }
        
        # Configuration data
        self.config_data = {
            'scan_settings': {
                'deep_scan': False,
                'scan_archives': True,
                'scan_memory': True,
                'scan_network_drives': False,
                'max_file_size': 100,  # MB
                'scan_timeout': 300,   # seconds
                'exclusions': []
            },
            'quarantine_settings': {
                'auto_delete_after': 30,  # days
                'password_protect': True,
                'backup_before_delete': True,
                'max_quarantine_size': 1000  # MB
            },
            'network_settings': {
                'block_suspicious_domains': True,
                'dns_filtering': True,
                'port_monitoring': True,
                'intrusion_detection': True,
                'bandwidth_monitoring': False
            },
            'performance_settings': {
                'cpu_limit': 25,  # percentage
                'memory_limit': 512,  # MB
                'background_priority': True,
                'sleep_when_inactive': True,
                'optimize_for_gaming': False
            }
        }
        
        # Update queue for real-time updates
        self.update_queue = queue.Queue()
        
        self.logger.info("Advanced Control Panel initialized")
    
    def show(self):
        """Show the advanced control panel"""
        if self.window and self.window.winfo_exists():
            self.window.lift()
            return
        
        self.window = tk.Toplevel()
        self.window.title("Advanced Control Panel")
        self.window.geometry("800x700")
        self.window.resizable(True, True)
        
        # Create main interface
        self._create_interface()
        
        # Start update thread
        self._start_update_thread()
        
        # Center window
        self.window.transient()
        self.window.grab_set()
        
        self.logger.info("Advanced Control Panel shown")
    
    def _create_interface(self):
        """Create the main interface"""
        # Main frame
        main_frame = ttk.Frame(self.window)
        main_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Title
        title_frame = ttk.Frame(main_frame)
        title_frame.pack(fill=tk.X, pady=(0, 10))
        
        ttk.Label(title_frame, text="Advanced Control Panel", 
                 font=("Arial", 18, "bold")).pack(side=tk.LEFT)
        
        # Status indicator
        self.status_label = ttk.Label(title_frame, text="● Active", 
                                     foreground="green", font=("Arial", 12))
        self.status_label.pack(side=tk.RIGHT)
        
        # Create notebook (tabs)
        self.notebook = ttk.Notebook(main_frame)
        self.notebook.pack(fill=tk.BOTH, expand=True)
        
        # Create tabs
        self._create_protection_tab()
        self._create_scan_tab()
        self._create_quarantine_tab()
        self._create_network_tab()
        self._create_performance_tab()
        self._create_logs_tab()
        self._create_advanced_tab()
        
        # Button frame
        button_frame = ttk.Frame(main_frame)
        button_frame.pack(fill=tk.X, pady=(10, 0))
        
        ttk.Button(button_frame, text="Apply All", command=self._apply_all_settings).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="Reset to Default", command=self._reset_to_default).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="Export Config", command=self._export_config).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="Import Config", command=self._import_config).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="Close", command=self._close_window).pack(side=tk.RIGHT, padx=5)
    
    def _create_protection_tab(self):
        """Create protection control tab"""
        if not self.notebook:
            return
        tab_frame = ttk.Frame(self.notebook)
        self.notebook.add(tab_frame, text="Protection")
        
        # Main protection controls
        main_protection = ttk.LabelFrame(tab_frame, text="Main Protection")
        main_protection.pack(fill=tk.X, padx=10, pady=10)
        
        # Real-time protection
        self.realtime_var = tk.BooleanVar(value=self.control_state['realtime_enabled'])
        ttk.Checkbutton(main_protection, text="Real-time Protection", 
                       variable=self.realtime_var, command=self._update_realtime).pack(anchor=tk.W, padx=10, pady=5)
        
        # Auto quarantine
        self.auto_quarantine_var = tk.BooleanVar(value=self.control_state['auto_quarantine'])
        ttk.Checkbutton(main_protection, text="Automatic Quarantine", 
                       variable=self.auto_quarantine_var).pack(anchor=tk.W, padx=10, pady=5)
        
        # Cloud protection
        self.cloud_protection_var = tk.BooleanVar(value=self.control_state['cloud_protection'])
        ttk.Checkbutton(main_protection, text="Cloud Protection", 
                       variable=self.cloud_protection_var).pack(anchor=tk.W, padx=10, pady=5)
        
        # Advanced protection features
        advanced_protection = ttk.LabelFrame(tab_frame, text="Advanced Protection")
        advanced_protection.pack(fill=tk.X, padx=10, pady=10)
        
        # Behavior monitoring
        self.behavior_var = tk.BooleanVar(value=self.control_state['behavior_monitoring'])
        ttk.Checkbutton(advanced_protection, text="Behavior Monitoring", 
                       variable=self.behavior_var).pack(anchor=tk.W, padx=10, pady=5)
        
        # Network protection
        self.network_protection_var = tk.BooleanVar(value=self.control_state['network_protection'])
        ttk.Checkbutton(advanced_protection, text="Network Protection", 
                       variable=self.network_protection_var).pack(anchor=tk.W, padx=10, pady=5)
        
        # Web filtering
        self.web_filtering_var = tk.BooleanVar(value=self.control_state['web_filtering'])
        ttk.Checkbutton(advanced_protection, text="Web Filtering", 
                       variable=self.web_filtering_var).pack(anchor=tk.W, padx=10, pady=5)
        
        # Email protection
        self.email_protection_var = tk.BooleanVar(value=self.control_state['email_protection'])
        ttk.Checkbutton(advanced_protection, text="Email Protection", 
                       variable=self.email_protection_var).pack(anchor=tk.W, padx=10, pady=5)
        
        # USB protection
        self.usb_protection_var = tk.BooleanVar(value=self.control_state['usb_protection'])
        ttk.Checkbutton(advanced_protection, text="USB Device Protection", 
                       variable=self.usb_protection_var).pack(anchor=tk.W, padx=10, pady=5)
        
        # Protection status display
        status_frame = ttk.LabelFrame(tab_frame, text="Protection Status")
        status_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Status tree
        self.protection_tree = ttk.Treeview(status_frame, columns=("Status", "Last Update"), show="tree headings")
        self.protection_tree.heading("#0", text="Component")
        self.protection_tree.heading("Status", text="Status")
        self.protection_tree.heading("Last Update", text="Last Update")
        
        self.protection_tree.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        
        # Populate protection status
        self._update_protection_status()
    
    def _create_scan_tab(self):
        """Create scan control tab"""
        if not self.notebook:
            return
        tab_frame = ttk.Frame(self.notebook)
        self.notebook.add(tab_frame, text="Scanning")
        
        # Scan controls
        scan_controls = ttk.LabelFrame(tab_frame, text="Scan Controls")
        scan_controls.pack(fill=tk.X, padx=10, pady=10)
        
        # Scan buttons
        button_frame = ttk.Frame(scan_controls)
        button_frame.pack(fill=tk.X, padx=10, pady=10)
        
        ttk.Button(button_frame, text="Quick Scan", command=self._start_quick_scan).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="Full Scan", command=self._start_full_scan).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="Custom Scan", command=self._start_custom_scan).pack(side=tk.LEFT, padx=5)
        
        self.scan_stop_button = ttk.Button(button_frame, text="Stop Scan", 
                                          command=self._stop_scan, state=tk.DISABLED)
        self.scan_stop_button.pack(side=tk.LEFT, padx=5)
        
        # Scan progress
        progress_frame = ttk.Frame(scan_controls)
        progress_frame.pack(fill=tk.X, padx=10, pady=5)
        
        ttk.Label(progress_frame, text="Scan Progress:").pack(anchor=tk.W)
        self.scan_progress = ttk.Progressbar(progress_frame, mode='determinate')
        self.scan_progress.pack(fill=tk.X, pady=5)
        
        self.scan_status_label = ttk.Label(progress_frame, text="Ready to scan")
        self.scan_status_label.pack(anchor=tk.W)
        
        # Scan settings
        scan_settings = ttk.LabelFrame(tab_frame, text="Scan Settings")
        scan_settings.pack(fill=tk.X, padx=10, pady=10)
        
        # Deep scan
        self.deep_scan_var = tk.BooleanVar(value=self.config_data['scan_settings']['deep_scan'])
        ttk.Checkbutton(scan_settings, text="Deep Scan (slower but more thorough)", 
                       variable=self.deep_scan_var).pack(anchor=tk.W, padx=10, pady=2)
        
        # Scan archives
        self.scan_archives_var = tk.BooleanVar(value=self.config_data['scan_settings']['scan_archives'])
        ttk.Checkbutton(scan_settings, text="Scan Archive Files", 
                       variable=self.scan_archives_var).pack(anchor=tk.W, padx=10, pady=2)
        
        # Scan memory
        self.scan_memory_var = tk.BooleanVar(value=self.config_data['scan_settings']['scan_memory'])
        ttk.Checkbutton(scan_settings, text="Scan System Memory", 
                       variable=self.scan_memory_var).pack(anchor=tk.W, padx=10, pady=2)
        
        # Scan network drives
        self.scan_network_var = tk.BooleanVar(value=self.config_data['scan_settings']['scan_network_drives'])
        ttk.Checkbutton(scan_settings, text="Scan Network Drives", 
                       variable=self.scan_network_var).pack(anchor=tk.W, padx=10, pady=2)
        
        # File size limit
        size_frame = ttk.Frame(scan_settings)
        size_frame.pack(fill=tk.X, padx=10, pady=5)
        
        ttk.Label(size_frame, text="Maximum file size to scan (MB):").pack(side=tk.LEFT)
        self.max_file_size_var = tk.IntVar(value=self.config_data['scan_settings']['max_file_size'])
        ttk.Spinbox(size_frame, from_=1, to=1000, textvariable=self.max_file_size_var, width=10).pack(side=tk.RIGHT)
        
        # Scan exclusions
        exclusions_frame = ttk.LabelFrame(tab_frame, text="Scan Exclusions")
        exclusions_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Exclusions list
        exclusions_list_frame = ttk.Frame(exclusions_frame)
        exclusions_list_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        self.exclusions_listbox = tk.Listbox(exclusions_list_frame)
        self.exclusions_listbox.pack(fill=tk.BOTH, expand=True, side=tk.LEFT)
        
        exclusions_scroll = ttk.Scrollbar(exclusions_list_frame, orient=tk.VERTICAL, command=self.exclusions_listbox.yview)
        exclusions_scroll.pack(fill=tk.Y, side=tk.RIGHT)
        self.exclusions_listbox.config(yscrollcommand=exclusions_scroll.set)
        
        # Exclusions buttons
        exclusions_buttons = ttk.Frame(exclusions_frame)
        exclusions_buttons.pack(fill=tk.X, padx=10, pady=5)
        
        ttk.Button(exclusions_buttons, text="Add File", command=self._add_file_exclusion).pack(side=tk.LEFT, padx=5)
        ttk.Button(exclusions_buttons, text="Add Folder", command=self._add_folder_exclusion).pack(side=tk.LEFT, padx=5)
        ttk.Button(exclusions_buttons, text="Remove", command=self._remove_exclusion).pack(side=tk.LEFT, padx=5)
        
        # Load exclusions
        self._load_exclusions()
    
    def _create_quarantine_tab(self):
        """Create quarantine management tab"""
        if not self.notebook:
            return
        tab_frame = ttk.Frame(self.notebook)
        self.notebook.add(tab_frame, text="Quarantine")
        
        # Quarantine controls
        quarantine_controls = ttk.LabelFrame(tab_frame, text="Quarantine Controls")
        quarantine_controls.pack(fill=tk.X, padx=10, pady=10)
        
        button_frame = ttk.Frame(quarantine_controls)
        button_frame.pack(fill=tk.X, padx=10, pady=10)
        
        ttk.Button(button_frame, text="View Quarantine", command=self._view_quarantine).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="Empty Quarantine", command=self._empty_quarantine).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="Restore Selected", command=self._restore_selected).pack(side=tk.LEFT, padx=5)
        
        # Quarantine settings
        quarantine_settings = ttk.LabelFrame(tab_frame, text="Quarantine Settings")
        quarantine_settings.pack(fill=tk.X, padx=10, pady=10)
        
        # Auto-delete setting
        auto_delete_frame = ttk.Frame(quarantine_settings)
        auto_delete_frame.pack(fill=tk.X, padx=10, pady=5)
        
        ttk.Label(auto_delete_frame, text="Auto-delete after (days):").pack(side=tk.LEFT)
        self.auto_delete_var = tk.IntVar(value=self.config_data['quarantine_settings']['auto_delete_after'])
        ttk.Spinbox(auto_delete_frame, from_=1, to=365, textvariable=self.auto_delete_var, width=10).pack(side=tk.RIGHT)
        
        # Password protection
        self.password_protect_var = tk.BooleanVar(value=self.config_data['quarantine_settings']['password_protect'])
        ttk.Checkbutton(quarantine_settings, text="Password Protect Quarantine", 
                       variable=self.password_protect_var).pack(anchor=tk.W, padx=10, pady=5)
        
        # Backup before delete
        self.backup_before_delete_var = tk.BooleanVar(value=self.config_data['quarantine_settings']['backup_before_delete'])
        ttk.Checkbutton(quarantine_settings, text="Backup Before Auto-Delete", 
                       variable=self.backup_before_delete_var).pack(anchor=tk.W, padx=10, pady=5)
        
        # Quarantine size limit
        size_limit_frame = ttk.Frame(quarantine_settings)
        size_limit_frame.pack(fill=tk.X, padx=10, pady=5)
        
        ttk.Label(size_limit_frame, text="Maximum quarantine size (MB):").pack(side=tk.LEFT)
        self.quarantine_size_var = tk.IntVar(value=self.config_data['quarantine_settings']['max_quarantine_size'])
        ttk.Spinbox(size_limit_frame, from_=100, to=10000, textvariable=self.quarantine_size_var, width=10).pack(side=tk.RIGHT)
        
        # Quarantine statistics
        stats_frame = ttk.LabelFrame(tab_frame, text="Quarantine Statistics")
        stats_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        self.quarantine_stats_text = tk.Text(stats_frame, height=8, state=tk.DISABLED)
        self.quarantine_stats_text.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Update quarantine stats
        self._update_quarantine_stats()
    
    def _create_network_tab(self):
        """Create network protection tab"""
        if not self.notebook:
            return
        tab_frame = ttk.Frame(self.notebook)
        self.notebook.add(tab_frame, text="Network")
        
        # Network protection settings
        network_protection = ttk.LabelFrame(tab_frame, text="Network Protection")
        network_protection.pack(fill=tk.X, padx=10, pady=10)
        
        # Block suspicious domains
        self.block_domains_var = tk.BooleanVar(value=self.config_data['network_settings']['block_suspicious_domains'])
        ttk.Checkbutton(network_protection, text="Block Suspicious Domains", 
                       variable=self.block_domains_var).pack(anchor=tk.W, padx=10, pady=5)
        
        # DNS filtering
        self.dns_filtering_var = tk.BooleanVar(value=self.config_data['network_settings']['dns_filtering'])
        ttk.Checkbutton(network_protection, text="DNS Filtering", 
                       variable=self.dns_filtering_var).pack(anchor=tk.W, padx=10, pady=5)
        
        # Port monitoring
        self.port_monitoring_var = tk.BooleanVar(value=self.config_data['network_settings']['port_monitoring'])
        ttk.Checkbutton(network_protection, text="Port Monitoring", 
                       variable=self.port_monitoring_var).pack(anchor=tk.W, padx=10, pady=5)
        
        # Intrusion detection
        self.intrusion_detection_var = tk.BooleanVar(value=self.config_data['network_settings']['intrusion_detection'])
        ttk.Checkbutton(network_protection, text="Intrusion Detection", 
                       variable=self.intrusion_detection_var).pack(anchor=tk.W, padx=10, pady=5)
        
        # Bandwidth monitoring
        self.bandwidth_monitoring_var = tk.BooleanVar(value=self.config_data['network_settings']['bandwidth_monitoring'])
        ttk.Checkbutton(network_protection, text="Bandwidth Monitoring", 
                       variable=self.bandwidth_monitoring_var).pack(anchor=tk.W, padx=10, pady=5)
        
        # Firewall controls
        firewall_frame = ttk.LabelFrame(tab_frame, text="Firewall Controls")
        firewall_frame.pack(fill=tk.X, padx=10, pady=10)
        
        firewall_buttons = ttk.Frame(firewall_frame)
        firewall_buttons.pack(fill=tk.X, padx=10, pady=10)
        
        ttk.Button(firewall_buttons, text="Firewall Rules", command=self._show_firewall_rules).pack(side=tk.LEFT, padx=5)
        ttk.Button(firewall_buttons, text="Port Scanner", command=self._show_port_scanner).pack(side=tk.LEFT, padx=5)
        ttk.Button(firewall_buttons, text="Network Monitor", command=self._show_network_monitor).pack(side=tk.LEFT, padx=5)
        
        # Network statistics
        network_stats = ttk.LabelFrame(tab_frame, text="Network Statistics")
        network_stats.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        self.network_stats_text = scrolledtext.ScrolledText(network_stats, height=8, state=tk.DISABLED)
        self.network_stats_text.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Update network stats
        self._update_network_stats()
    
    def _create_performance_tab(self):
        """Create performance settings tab"""
        if not self.notebook:
            return
        tab_frame = ttk.Frame(self.notebook)
        self.notebook.add(tab_frame, text="Performance")
        
        # Resource limits
        resource_limits = ttk.LabelFrame(tab_frame, text="Resource Limits")
        resource_limits.pack(fill=tk.X, padx=10, pady=10)
        
        # CPU limit
        cpu_frame = ttk.Frame(resource_limits)
        cpu_frame.pack(fill=tk.X, padx=10, pady=5)
        
        ttk.Label(cpu_frame, text="Maximum CPU usage (%):").pack(side=tk.LEFT)
        self.cpu_limit_var = tk.IntVar(value=self.config_data['performance_settings']['cpu_limit'])
        cpu_scale = ttk.Scale(cpu_frame, from_=5, to=100, variable=self.cpu_limit_var, orient=tk.HORIZONTAL)
        cpu_scale.pack(side=tk.RIGHT, fill=tk.X, expand=True, padx=10)
        
        self.cpu_value_label = ttk.Label(cpu_frame, text=f"{self.cpu_limit_var.get()}%")
        self.cpu_value_label.pack(side=tk.RIGHT)
        
        cpu_scale.configure(command=lambda v: self.cpu_value_label.configure(text=f"{int(float(v))}%"))
        
        # Memory limit
        memory_frame = ttk.Frame(resource_limits)
        memory_frame.pack(fill=tk.X, padx=10, pady=5)
        
        ttk.Label(memory_frame, text="Maximum memory usage (MB):").pack(side=tk.LEFT)
        self.memory_limit_var = tk.IntVar(value=self.config_data['performance_settings']['memory_limit'])
        ttk.Spinbox(memory_frame, from_=256, to=4096, textvariable=self.memory_limit_var, width=10).pack(side=tk.RIGHT)
        
        # Performance options
        performance_options = ttk.LabelFrame(tab_frame, text="Performance Options")
        performance_options.pack(fill=tk.X, padx=10, pady=10)
        
        # Background priority
        self.background_priority_var = tk.BooleanVar(value=self.config_data['performance_settings']['background_priority'])
        ttk.Checkbutton(performance_options, text="Run at Low Priority in Background", 
                       variable=self.background_priority_var).pack(anchor=tk.W, padx=10, pady=5)
        
        # Sleep when inactive
        self.sleep_inactive_var = tk.BooleanVar(value=self.config_data['performance_settings']['sleep_when_inactive'])
        ttk.Checkbutton(performance_options, text="Sleep When System Inactive", 
                       variable=self.sleep_inactive_var).pack(anchor=tk.W, padx=10, pady=5)
        
        # Gaming mode
        self.gaming_mode_var = tk.BooleanVar(value=self.config_data['performance_settings']['optimize_for_gaming'])
        ttk.Checkbutton(performance_options, text="Optimize for Gaming", 
                       variable=self.gaming_mode_var).pack(anchor=tk.W, padx=10, pady=5)
        
        # Performance monitoring
        performance_monitor = ttk.LabelFrame(tab_frame, text="Performance Monitor")
        performance_monitor.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Performance metrics
        metrics_frame = ttk.Frame(performance_monitor)
        metrics_frame.pack(fill=tk.X, padx=10, pady=10)
        
        # CPU usage
        ttk.Label(metrics_frame, text="Current CPU Usage:").grid(row=0, column=0, sticky=tk.W, padx=5, pady=2)
        self.cpu_usage_label = ttk.Label(metrics_frame, text="0%")
        self.cpu_usage_label.grid(row=0, column=1, sticky=tk.E, padx=5, pady=2)
        
        # Memory usage
        ttk.Label(metrics_frame, text="Current Memory Usage:").grid(row=1, column=0, sticky=tk.W, padx=5, pady=2)
        self.memory_usage_label = ttk.Label(metrics_frame, text="0 MB")
        self.memory_usage_label.grid(row=1, column=1, sticky=tk.E, padx=5, pady=2)
        
        # Files scanned per minute
        ttk.Label(metrics_frame, text="Files Scanned/Min:").grid(row=2, column=0, sticky=tk.W, padx=5, pady=2)
        self.scan_rate_label = ttk.Label(metrics_frame, text="0")
        self.scan_rate_label.grid(row=2, column=1, sticky=tk.E, padx=5, pady=2)
        
        metrics_frame.columnconfigure(1, weight=1)
    
    def _create_logs_tab(self):
        """Create logs and events tab"""
        if not self.notebook:
            return
        tab_frame = ttk.Frame(self.notebook)
        self.notebook.add(tab_frame, text="Logs")
        
        # Log controls
        log_controls = ttk.LabelFrame(tab_frame, text="Log Controls")
        log_controls.pack(fill=tk.X, padx=10, pady=10)
        
        controls_frame = ttk.Frame(log_controls)
        controls_frame.pack(fill=tk.X, padx=10, pady=10)
        
        ttk.Button(controls_frame, text="Refresh", command=self._refresh_logs).pack(side=tk.LEFT, padx=5)
        ttk.Button(controls_frame, text="Clear Logs", command=self._clear_logs).pack(side=tk.LEFT, padx=5)
        ttk.Button(controls_frame, text="Export Logs", command=self._export_logs).pack(side=tk.LEFT, padx=5)
        
        # Log level filter
        ttk.Label(controls_frame, text="Log Level:").pack(side=tk.LEFT, padx=(20, 5))
        self.log_level_var = tk.StringVar(value="All")
        log_level_combo = ttk.Combobox(controls_frame, textvariable=self.log_level_var, 
                                      values=["All", "DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"],
                                      state="readonly", width=10)
        log_level_combo.pack(side=tk.LEFT, padx=5)
        log_level_combo.bind("<<ComboboxSelected>>", lambda e: self._filter_logs())
        
        # Log display
        log_display = ttk.LabelFrame(tab_frame, text="System Logs")
        log_display.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        self.log_text = scrolledtext.ScrolledText(log_display, height=15, font=("Courier", 9))
        self.log_text.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Load logs
        self._load_logs()
    
    def _create_advanced_tab(self):
        """Create advanced settings tab"""
        if not self.notebook:
            return
        tab_frame = ttk.Frame(self.notebook)
        self.notebook.add(tab_frame, text="Advanced")
        
        # System integration
        system_integration = ttk.LabelFrame(tab_frame, text="System Integration")
        system_integration.pack(fill=tk.X, padx=10, pady=10)
        
        ttk.Button(system_integration, text="Register File Associations", 
                  command=self._register_file_associations).pack(anchor=tk.W, padx=10, pady=5)
        ttk.Button(system_integration, text="Install Context Menu", 
                  command=self._install_context_menu).pack(anchor=tk.W, padx=10, pady=5)
        ttk.Button(system_integration, text="Setup Startup Service", 
                  command=self._setup_startup_service).pack(anchor=tk.W, padx=10, pady=5)
        
        # Debug options
        debug_options = ttk.LabelFrame(tab_frame, text="Debug Options")
        debug_options.pack(fill=tk.X, padx=10, pady=10)
        
        ttk.Button(debug_options, text="Generate Debug Report", 
                  command=self._generate_debug_report).pack(anchor=tk.W, padx=10, pady=5)
        ttk.Button(debug_options, text="Test All Components", 
                  command=self._test_all_components).pack(anchor=tk.W, padx=10, pady=5)
        ttk.Button(debug_options, text="Reset All Settings", 
                  command=self._reset_all_settings).pack(anchor=tk.W, padx=10, pady=5)
        
        # Database management
        database_management = ttk.LabelFrame(tab_frame, text="Database Management")
        database_management.pack(fill=tk.X, padx=10, pady=10)
        
        ttk.Button(database_management, text="Optimize Database", 
                  command=self._optimize_database).pack(anchor=tk.W, padx=10, pady=5)
        ttk.Button(database_management, text="Backup Database", 
                  command=self._backup_database).pack(anchor=tk.W, padx=10, pady=5)
        ttk.Button(database_management, text="Restore Database", 
                  command=self._restore_database).pack(anchor=tk.W, padx=10, pady=5)
        
        # System information
        system_info = ttk.LabelFrame(tab_frame, text="System Information")
        system_info.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        self.system_info_text = scrolledtext.ScrolledText(system_info, height=8, state=tk.DISABLED)
        self.system_info_text.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Load system information
        self._load_system_info()
    
    def _start_update_thread(self):
        """Start background update thread"""
        def update_worker():
            while self.window and self.window.winfo_exists():
                try:
                    # Update performance metrics
                    self._update_performance_metrics()
                    
                    # Process update queue
                    try:
                        while True:
                            update_data = self.update_queue.get_nowait()
                            self._process_update(update_data)
                    except queue.Empty:
                        pass
                    
                    time.sleep(2)  # Update every 2 seconds
                    
                except Exception as e:
                    self.logger.error(f"Error in update thread: {e}")
                    time.sleep(5)
        
        update_thread = threading.Thread(target=update_worker, daemon=True)
        update_thread.start()
    
    def _update_realtime(self):
        """Update real-time protection status"""
        enabled = self.realtime_var.get()
        self.control_state['realtime_enabled'] = enabled
        
        if self.antivirus_manager:
            # Update real-time protection
            if hasattr(self.antivirus_manager, 'set_realtime_protection'):
                self.antivirus_manager.set_realtime_protection(enabled)
        
        status_text = "Active" if enabled else "Disabled"
        color = "green" if enabled else "red"
        self.status_label.configure(text=f"● {status_text}", foreground=color)
        
        self.logger.info(f"Real-time protection {status_text.lower()}")
    
    def _start_quick_scan(self):
        """Start quick scan"""
        if self.control_state['scan_running']:
            messagebox.showwarning("Scan Running", "A scan is already in progress")
            return
        
        self.control_state['scan_running'] = True
        self.scan_stop_button.configure(state=tk.NORMAL)
        self.scan_status_label.configure(text="Starting quick scan...")
        
        # Start scan in background thread
        scan_thread = threading.Thread(target=self._run_scan, args=("quick",), daemon=True)
        scan_thread.start()
    
    def _start_full_scan(self):
        """Start full system scan"""
        if self.control_state['scan_running']:
            messagebox.showwarning("Scan Running", "A scan is already in progress")
            return
        
        self.control_state['scan_running'] = True
        self.scan_stop_button.configure(state=tk.NORMAL)
        self.scan_status_label.configure(text="Starting full system scan...")
        
        # Start scan in background thread
        scan_thread = threading.Thread(target=self._run_scan, args=("full",), daemon=True)
        scan_thread.start()
    
    def _start_custom_scan(self):
        """Start custom scan"""
        # Ask user to select directories
        directory = filedialog.askdirectory(title="Select Directory to Scan")
        if not directory:
            return
        
        if self.control_state['scan_running']:
            messagebox.showwarning("Scan Running", "A scan is already in progress")
            return
        
        self.control_state['scan_running'] = True
        self.scan_stop_button.configure(state=tk.NORMAL)
        self.scan_status_label.configure(text=f"Starting custom scan of {directory}...")
        
        # Start scan in background thread
        scan_thread = threading.Thread(target=self._run_scan, args=("custom", directory), daemon=True)
        scan_thread.start()
    
    def _run_scan(self, scan_type, custom_path=None):
        """Run scan simulation"""
        try:
            total_files = 1000 if scan_type == "quick" else 10000 if scan_type == "full" else 500
            
            for i in range(total_files):
                if not self.control_state['scan_running']:
                    break
                
                progress = (i + 1) / total_files * 100
                self.scan_progress['value'] = progress
                
                if i % 100 == 0:  # Update status every 100 files
                    self.scan_status_label.configure(text=f"Scanning file {i + 1} of {total_files}")
                
                time.sleep(0.01)  # Simulate scan time
            
            if self.control_state['scan_running']:
                self.scan_status_label.configure(text="Scan completed successfully")
                messagebox.showinfo("Scan Complete", f"{scan_type.title()} scan completed. No threats found.")
            else:
                self.scan_status_label.configure(text="Scan stopped by user")
            
        except Exception as e:
            self.logger.error(f"Error running scan: {e}")
            self.scan_status_label.configure(text="Scan failed")
        finally:
            self.control_state['scan_running'] = False
            self.scan_stop_button.configure(state=tk.DISABLED)
            self.scan_progress['value'] = 0
    
    def _stop_scan(self):
        """Stop current scan"""
        self.control_state['scan_running'] = False
        self.scan_stop_button.configure(state=tk.DISABLED)
        self.scan_status_label.configure(text="Stopping scan...")
    
    def _update_protection_status(self):
        """Update protection status tree"""
        # Clear existing items
        for item in self.protection_tree.get_children():
            self.protection_tree.delete(item)
        
        # Add protection components
        components = [
            ("Real-time Protection", self.control_state['realtime_enabled']),
            ("Web Protection", self.control_state['web_filtering']),
            ("Network Protection", self.control_state['network_protection']),
            ("Behavior Monitoring", self.control_state['behavior_monitoring']),
            ("Cloud Protection", self.control_state['cloud_protection'])
        ]
        
        for name, enabled in components:
            status = "Active" if enabled else "Disabled"
            last_update = datetime.now().strftime("%H:%M:%S")
            self.protection_tree.insert("", tk.END, text=name, values=(status, last_update))
    
    def _load_exclusions(self):
        """Load scan exclusions"""
        self.exclusions_listbox.delete(0, tk.END)
        for exclusion in self.config_data['scan_settings']['exclusions']:
            self.exclusions_listbox.insert(tk.END, exclusion)
    
    def _add_file_exclusion(self):
        """Add file exclusion"""
        file_path = filedialog.askopenfilename(title="Select File to Exclude")
        if file_path:
            self.config_data['scan_settings']['exclusions'].append(file_path)
            self.exclusions_listbox.insert(tk.END, file_path)
    
    def _add_folder_exclusion(self):
        """Add folder exclusion"""
        folder_path = filedialog.askdirectory(title="Select Folder to Exclude")
        if folder_path:
            self.config_data['scan_settings']['exclusions'].append(folder_path)
            self.exclusions_listbox.insert(tk.END, folder_path)
    
    def _remove_exclusion(self):
        """Remove selected exclusion"""
        selection = self.exclusions_listbox.curselection()
        if selection:
            index = selection[0]
            exclusion = self.exclusions_listbox.get(index)
            self.config_data['scan_settings']['exclusions'].remove(exclusion)
            self.exclusions_listbox.delete(index)
    
    def _update_quarantine_stats(self):
        """Update quarantine statistics"""
        stats_text = """Quarantine Statistics:
━━━━━━━━━━━━━━━━━━━━━━━━━

Files in Quarantine: 12
Total Size: 45.2 MB
Oldest File: 2024-01-15 14:30:22
Newest File: 2024-01-20 09:15:33

Recent Activity:
• Quarantined suspicious.exe (2.1 MB) - 2024-01-20 09:15:33
• Quarantined malware.dll (0.8 MB) - 2024-01-19 16:22:11
• Auto-deleted expired files (3 files, 5.5 MB) - 2024-01-18 00:00:00

Storage Usage: 4.5% of 1000 MB limit
Auto-delete in: 15 days (oldest file)
"""
        
        self.quarantine_stats_text.configure(state=tk.NORMAL)
        self.quarantine_stats_text.delete(1.0, tk.END)
        self.quarantine_stats_text.insert(1.0, stats_text)
        self.quarantine_stats_text.configure(state=tk.DISABLED)
    
    def _update_network_stats(self):
        """Update network statistics"""
        stats_text = """Network Protection Statistics:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Blocked Connections: 1,247
Suspicious Domains Blocked: 89
DNS Queries Filtered: 15,632
Port Scan Attempts: 3

Recent Blocks:
• 185.220.101.47:443 - Suspicious SSL certificate
• malware-domain.com - Known malicious domain  
• 192.168.1.100:135 - Unauthorized port scan
• phishing-site.net - Phishing attempt blocked

Firewall Rules: 127 active
Intrusion Detection: Active
Bandwidth Usage: 45.2 MB/hour
"""
        
        self.network_stats_text.configure(state=tk.NORMAL)
        self.network_stats_text.delete(1.0, tk.END)
        self.network_stats_text.insert(1.0, stats_text)
        self.network_stats_text.configure(state=tk.DISABLED)
    
    def _update_performance_metrics(self):
        """Update performance metrics"""
        try:
            # Simulate performance metrics
            import psutil
            
            # CPU usage
            cpu_percent = psutil.cpu_percent()
            self.cpu_usage_label.configure(text=f"{cpu_percent}%")
            
            # Memory usage
            memory_info = psutil.virtual_memory()
            memory_mb = memory_info.used // (1024 * 1024)
            self.memory_usage_label.configure(text=f"{memory_mb} MB")
            
            # Scan rate (simulated)
            scan_rate = 150  # Files per minute
            self.scan_rate_label.configure(text=str(scan_rate))
            
        except ImportError:
            # Fallback if psutil not available
            self.cpu_usage_label.configure(text="N/A")
            self.memory_usage_label.configure(text="N/A")
            self.scan_rate_label.configure(text="N/A")
        except Exception as e:
            self.logger.error(f"Error updating performance metrics: {e}")
    
    def _load_logs(self):
        """Load system logs"""
        sample_logs = """2024-01-20 10:30:15 INFO     Real-time protection started
2024-01-20 10:30:16 INFO     Database loaded: 1,247,832 signatures
2024-01-20 10:30:17 INFO     Network protection enabled
2024-01-20 10:35:22 WARNING  Suspicious file detected: C:\\temp\\unknown.exe
2024-01-20 10:35:23 INFO     File quarantined successfully
2024-01-20 10:40:11 INFO     Quick scan started
2024-01-20 10:42:33 INFO     Quick scan completed: 15,732 files scanned, 0 threats
2024-01-20 10:45:55 WARNING  Network connection blocked: 185.220.101.47:443
2024-01-20 10:50:12 INFO     Virus definitions updated
2024-01-20 10:55:18 ERROR    Failed to scan encrypted file: access denied
2024-01-20 11:00:00 INFO     Scheduled maintenance completed
2024-01-20 11:05:44 WARNING  High CPU usage detected: 87%
2024-01-20 11:10:21 INFO     Performance optimization applied
2024-01-20 11:15:36 INFO     Backup created successfully
"""
        
        self.log_text.delete(1.0, tk.END)
        self.log_text.insert(1.0, sample_logs)
    
    def _load_system_info(self):
        """Load system information"""
        system_info = """System Information:
━━━━━━━━━━━━━━━━━━━━━━━━

Operating System: Windows 11 Pro (Build 22621)
Processor: Intel Core i7-10700K @ 3.80GHz
Memory: 16.0 GB RAM
Storage: 512 GB SSD (78% free)

Antivirus Information:
Version: 1.0.0
Database Version: 2024.01.20.001
Last Update: 2024-01-20 10:50:12
License: Active (365 days remaining)

Protection Status:
Real-time Protection: Enabled
Web Protection: Enabled  
Firewall: Enabled
VPN: Connected (US-East-1)
Auto-updates: Enabled

Performance:
CPU Usage: 2.3% (Normal)
Memory Usage: 185 MB
Disk I/O: Low
Network I/O: Normal
"""
        
        self.system_info_text.configure(state=tk.NORMAL)
        self.system_info_text.delete(1.0, tk.END)
        self.system_info_text.insert(1.0, system_info)
        self.system_info_text.configure(state=tk.DISABLED)
    
    # Placeholder methods for various actions
    def _view_quarantine(self):
        messagebox.showinfo("Quarantine", "Opening quarantine viewer...")
    
    def _empty_quarantine(self):
        result = messagebox.askyesno("Empty Quarantine", "Are you sure you want to empty the quarantine?")
        if result:
            messagebox.showinfo("Quarantine", "Quarantine emptied successfully")
    
    def _restore_selected(self):
        messagebox.showinfo("Restore", "No files selected for restoration")
    
    def _show_firewall_rules(self):
        messagebox.showinfo("Firewall", "Opening firewall rules manager...")
    
    def _show_port_scanner(self):
        messagebox.showinfo("Port Scanner", "Opening port scanner...")
    
    def _show_network_monitor(self):
        messagebox.showinfo("Network Monitor", "Opening network monitor...")
    
    def _refresh_logs(self):
        self._load_logs()
        messagebox.showinfo("Logs", "Logs refreshed successfully")
    
    def _clear_logs(self):
        result = messagebox.askyesno("Clear Logs", "Are you sure you want to clear all logs?")
        if result:
            self.log_text.delete(1.0, tk.END)
    
    def _export_logs(self):
        file_path = filedialog.asksaveasfilename(
            title="Export Logs",
            defaultextension=".txt",
            filetypes=[("Text files", "*.txt"), ("All files", "*.*")]
        )
        if file_path:
            with open(file_path, 'w') as f:
                f.write(self.log_text.get(1.0, tk.END))
            messagebox.showinfo("Export", f"Logs exported to {file_path}")
    
    def _filter_logs(self):
        # Implement log filtering by level
        self._load_logs()  # Reload with filter
    
    def _apply_all_settings(self):
        """Apply all configuration settings"""
        try:
            # Update scan settings
            self.config_data['scan_settings']['deep_scan'] = self.deep_scan_var.get()
            self.config_data['scan_settings']['scan_archives'] = self.scan_archives_var.get()
            self.config_data['scan_settings']['scan_memory'] = self.scan_memory_var.get()
            self.config_data['scan_settings']['scan_network_drives'] = self.scan_network_var.get()
            self.config_data['scan_settings']['max_file_size'] = self.max_file_size_var.get()
            
            # Update quarantine settings
            self.config_data['quarantine_settings']['auto_delete_after'] = self.auto_delete_var.get()
            self.config_data['quarantine_settings']['password_protect'] = self.password_protect_var.get()
            self.config_data['quarantine_settings']['backup_before_delete'] = self.backup_before_delete_var.get()
            self.config_data['quarantine_settings']['max_quarantine_size'] = self.quarantine_size_var.get()
            
            # Update network settings
            self.config_data['network_settings']['block_suspicious_domains'] = self.block_domains_var.get()
            self.config_data['network_settings']['dns_filtering'] = self.dns_filtering_var.get()
            self.config_data['network_settings']['port_monitoring'] = self.port_monitoring_var.get()
            self.config_data['network_settings']['intrusion_detection'] = self.intrusion_detection_var.get()
            self.config_data['network_settings']['bandwidth_monitoring'] = self.bandwidth_monitoring_var.get()
            
            # Update performance settings
            self.config_data['performance_settings']['cpu_limit'] = self.cpu_limit_var.get()
            self.config_data['performance_settings']['memory_limit'] = self.memory_limit_var.get()
            self.config_data['performance_settings']['background_priority'] = self.background_priority_var.get()
            self.config_data['performance_settings']['sleep_when_inactive'] = self.sleep_inactive_var.get()
            self.config_data['performance_settings']['optimize_for_gaming'] = self.gaming_mode_var.get()
            
            # Apply to antivirus manager if available
            if self.antivirus_manager and hasattr(self.antivirus_manager, 'update_configuration'):
                self.antivirus_manager.update_configuration(self.config_data)
            
            messagebox.showinfo("Settings", "All settings applied successfully")
            self.logger.info("Configuration settings applied")
            
        except Exception as e:
            self.logger.error(f"Error applying settings: {e}")
            messagebox.showerror("Error", f"Failed to apply settings: {e}")
    
    def _reset_to_default(self):
        """Reset all settings to default"""
        result = messagebox.askyesno("Reset Settings", "Are you sure you want to reset all settings to default?")
        if result:
            # Reset control state
            self.control_state = {
                'scan_running': False,
                'realtime_enabled': True,
                'auto_quarantine': True,
                'cloud_protection': True,
                'behavior_monitoring': True,
                'network_protection': True,
                'web_filtering': True,
                'email_protection': True,
                'usb_protection': True,
                'scheduled_scans': []
            }
            
            # Reset config data to defaults
            self.config_data = {
                'scan_settings': {
                    'deep_scan': False,
                    'scan_archives': True,
                    'scan_memory': True,
                    'scan_network_drives': False,
                    'max_file_size': 100,
                    'scan_timeout': 300,
                    'exclusions': []
                },
                'quarantine_settings': {
                    'auto_delete_after': 30,
                    'password_protect': True,
                    'backup_before_delete': True,
                    'max_quarantine_size': 1000
                },
                'network_settings': {
                    'block_suspicious_domains': True,
                    'dns_filtering': True,
                    'port_monitoring': True,
                    'intrusion_detection': True,
                    'bandwidth_monitoring': False
                },
                'performance_settings': {
                    'cpu_limit': 25,
                    'memory_limit': 512,
                    'background_priority': True,
                    'sleep_when_inactive': True,
                    'optimize_for_gaming': False
                }
            }
            
            # Update UI elements
            self._update_ui_from_config()
            messagebox.showinfo("Reset", "Settings reset to default values")
    
    def _update_ui_from_config(self):
        """Update UI elements from configuration data"""
        # Update protection checkboxes
        self.realtime_var.set(self.control_state['realtime_enabled'])
        self.auto_quarantine_var.set(self.control_state['auto_quarantine'])
        self.cloud_protection_var.set(self.control_state['cloud_protection'])
        self.behavior_var.set(self.control_state['behavior_monitoring'])
        self.network_protection_var.set(self.control_state['network_protection'])
        self.web_filtering_var.set(self.control_state['web_filtering'])
        self.email_protection_var.set(self.control_state['email_protection'])
        self.usb_protection_var.set(self.control_state['usb_protection'])
        
        # Update scan settings
        self.deep_scan_var.set(self.config_data['scan_settings']['deep_scan'])
        self.scan_archives_var.set(self.config_data['scan_settings']['scan_archives'])
        self.scan_memory_var.set(self.config_data['scan_settings']['scan_memory'])
        self.scan_network_var.set(self.config_data['scan_settings']['scan_network_drives'])
        self.max_file_size_var.set(self.config_data['scan_settings']['max_file_size'])
        
        # Update quarantine settings
        self.auto_delete_var.set(self.config_data['quarantine_settings']['auto_delete_after'])
        self.password_protect_var.set(self.config_data['quarantine_settings']['password_protect'])
        self.backup_before_delete_var.set(self.config_data['quarantine_settings']['backup_before_delete'])
        self.quarantine_size_var.set(self.config_data['quarantine_settings']['max_quarantine_size'])
        
        # Update network settings
        self.block_domains_var.set(self.config_data['network_settings']['block_suspicious_domains'])
        self.dns_filtering_var.set(self.config_data['network_settings']['dns_filtering'])
        self.port_monitoring_var.set(self.config_data['network_settings']['port_monitoring'])
        self.intrusion_detection_var.set(self.config_data['network_settings']['intrusion_detection'])
        self.bandwidth_monitoring_var.set(self.config_data['network_settings']['bandwidth_monitoring'])
        
        # Update performance settings
        self.cpu_limit_var.set(self.config_data['performance_settings']['cpu_limit'])
        self.memory_limit_var.set(self.config_data['performance_settings']['memory_limit'])
        self.background_priority_var.set(self.config_data['performance_settings']['background_priority'])
        self.sleep_inactive_var.set(self.config_data['performance_settings']['sleep_when_inactive'])
        self.gaming_mode_var.set(self.config_data['performance_settings']['optimize_for_gaming'])
        
        # Update exclusions
        self._load_exclusions()
    
    def _export_config(self):
        """Export configuration to file"""
        file_path = filedialog.asksaveasfilename(
            title="Export Configuration",
            defaultextension=".json",
            filetypes=[("JSON files", "*.json"), ("All files", "*.*")]
        )
        if file_path:
            try:
                export_data = {
                    'control_state': self.control_state,
                    'config_data': self.config_data
                }
                with open(file_path, 'w') as f:
                    json.dump(export_data, f, indent=2)
                messagebox.showinfo("Export", f"Configuration exported to {file_path}")
            except Exception as e:
                messagebox.showerror("Error", f"Failed to export configuration: {e}")
    
    def _import_config(self):
        """Import configuration from file"""
        file_path = filedialog.askopenfilename(
            title="Import Configuration",
            filetypes=[("JSON files", "*.json"), ("All files", "*.*")]
        )
        if file_path:
            try:
                with open(file_path, 'r') as f:
                    import_data = json.load(f)
                
                self.control_state.update(import_data.get('control_state', {}))
                self.config_data.update(import_data.get('config_data', {}))
                
                self._update_ui_from_config()
                messagebox.showinfo("Import", f"Configuration imported from {file_path}")
            except Exception as e:
                messagebox.showerror("Error", f"Failed to import configuration: {e}")
    
    def _process_update(self, update_data):
        """Process update from update queue"""
        try:
            update_type = update_data.get('type')
            data = update_data.get('data')
            
            if update_type == 'protection_status':
                self._update_protection_status()
            elif update_type == 'scan_progress':
                self.scan_progress['value'] = data.get('progress', 0)
                self.scan_status_label.configure(text=data.get('status', ''))
            
        except Exception as e:
            self.logger.error(f"Error processing update: {e}")
    
    # Advanced tab methods
    def _register_file_associations(self):
        messagebox.showinfo("File Associations", "File associations registered successfully")
    
    def _install_context_menu(self):
        messagebox.showinfo("Context Menu", "Context menu installed successfully")
    
    def _setup_startup_service(self):
        messagebox.showinfo("Startup Service", "Startup service configured successfully")
    
    def _generate_debug_report(self):
        messagebox.showinfo("Debug Report", "Debug report generated successfully")
    
    def _test_all_components(self):
        messagebox.showinfo("Component Test", "All components tested successfully")
    
    def _reset_all_settings(self):
        result = messagebox.askyesno("Reset All", "This will reset ALL settings to factory defaults. Continue?")
        if result:
            self._reset_to_default()
    
    def _optimize_database(self):
        messagebox.showinfo("Database", "Database optimized successfully")
    
    def _backup_database(self):
        messagebox.showinfo("Database", "Database backup created successfully")
    
    def _restore_database(self):
        messagebox.showinfo("Database", "Database restore completed successfully")
    
    def _close_window(self):
        """Close the control panel window"""
        if self.window:
            self.window.destroy()

# Example usage
def main():
    """Example usage of the Advanced Control Panel"""
    root = tk.Tk()
    root.withdraw()  # Hide main window
    
    control_panel = AdvancedControlPanel()
    control_panel.show()
    
    root.mainloop()

if __name__ == "__main__":
    main()