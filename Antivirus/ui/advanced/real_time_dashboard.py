"""
Real-Time Dashboard
Advanced dashboard with live monitoring and dynamic updates
"""

import tkinter as tk
from tkinter import ttk
import threading
import time
import json
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Callable
import logging

try:
    import matplotlib.pyplot as plt
    from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
    from matplotlib.animation import FuncAnimation
    MATPLOTLIB_AVAILABLE = True
except ImportError:
    MATPLOTLIB_AVAILABLE = False

try:
    import numpy as np
    NUMPY_AVAILABLE = True
except ImportError:
    NUMPY_AVAILABLE = False

try:
    import psutil
    PSUTIL_AVAILABLE = True
except ImportError:
    PSUTIL_AVAILABLE = False

try:
    import plotly.graph_objects as go
    from plotly.subplots import make_subplots
    import plotly.express as px
    PLOTLY_AVAILABLE = True
except ImportError:
    PLOTLY_AVAILABLE = False

class RealTimeMetrics:
    """Real-time metrics collector"""
    
    def __init__(self, max_history: int = 100):
        self.max_history = max_history
        self.data = {
            'timestamps': [],
            'cpu_usage': [],
            'memory_usage': [],
            'disk_usage': [],
            'network_io': [],
            'threats_detected': [],
            'files_scanned': [],
            'quarantine_count': [],
            'active_connections': [],
            'blocked_attempts': []
        }
        self.lock = threading.Lock()
    
    def add_datapoint(self, metrics: Dict[str, Any]):
        """Add new metrics datapoint"""
        with self.lock:
            timestamp = datetime.now()
            self.data['timestamps'].append(timestamp)
            
            # System metrics
            self.data['cpu_usage'].append(metrics.get('cpu_usage', 0))
            self.data['memory_usage'].append(metrics.get('memory_usage', 0))
            self.data['disk_usage'].append(metrics.get('disk_usage', 0))
            self.data['network_io'].append(metrics.get('network_io', 0))
            
            # Security metrics
            self.data['threats_detected'].append(metrics.get('threats_detected', 0))
            self.data['files_scanned'].append(metrics.get('files_scanned', 0))
            self.data['quarantine_count'].append(metrics.get('quarantine_count', 0))
            self.data['active_connections'].append(metrics.get('active_connections', 0))
            self.data['blocked_attempts'].append(metrics.get('blocked_attempts', 0))
            
            # Maintain history limit
            if len(self.data['timestamps']) > self.max_history:
                for key in self.data:
                    self.data[key] = self.data[key][-self.max_history:]
    
    def get_latest(self, metric: str, count: int = 1) -> List[Any]:
        """Get latest values for a metric"""
        with self.lock:
            if metric in self.data:
                return self.data[metric][-count:]
            return []
    
    def get_range(self, metric: str, start_time: datetime, end_time: datetime) -> List[Any]:
        """Get metric values for a time range"""
        with self.lock:
            if metric not in self.data:
                return []
            
            result = []
            for i, timestamp in enumerate(self.data['timestamps']):
                if start_time <= timestamp <= end_time:
                    result.append(self.data[metric][i])
            
            return result

class RealTimeDashboard:
    """
    Advanced Real-Time Dashboard
    Provides live monitoring with dynamic charts and metrics
    """
    
    def __init__(self, security_manager=None, theme='dark'):
        self.security_manager = security_manager
        self.theme = theme
        self.root = None
        self.charts = {}
        self.widgets = {}
        self.animations = {}
        
        # Metrics collector
        self.metrics = RealTimeMetrics()
        
        # Update intervals
        self.fast_update_ms = 1000  # 1 second
        self.medium_update_ms = 5000  # 5 seconds
        self.slow_update_ms = 30000  # 30 seconds
        
        # State
        self.running = False
        self.update_threads = []
        
        # Initialize logging
        self.logger = logging.getLogger(__name__)
        
        # Color schemes
        self.color_schemes = {
            'dark': {
                'bg': '#1e1e1e',
                'fg': '#ffffff',
                'accent': '#0078d4',
                'success': '#107c10',
                'warning': '#ff8c00',
                'danger': '#d13438',
                'grid': '#333333'
            },
            'light': {
                'bg': '#ffffff',
                'fg': '#000000',
                'accent': '#0078d4',
                'success': '#107c10',
                'warning': '#ff8c00',
                'danger': '#d13438',
                'grid': '#cccccc'
            }
        }
        
        self.colors = self.color_schemes[theme]
        
        self.logger.info("Real-time dashboard initialized")
    
    def initialize(self, parent=None):
        """Initialize the dashboard UI"""
        if parent is None:
            self.root = tk.Tk()
            self.root.title("Antivirus Real-Time Dashboard")
            self.root.geometry("1600x1000")
            self.root.configure(bg=self.colors['bg'])
            container = self.root
        else:
            container = parent
        
        # Apply theme
        self._apply_theme()
        
        # Create main layout
        self._create_layout(container)
        
        # Start real-time updates
        self.start_monitoring()
        
        self.logger.info("Dashboard UI initialized")
    
    def _apply_theme(self):
        """Apply theme to UI components"""
        style = ttk.Style()
        
        if self.theme == 'dark':
            style.theme_use('clam')
            style.configure('TLabel', background=self.colors['bg'], foreground=self.colors['fg'])
            style.configure('TFrame', background=self.colors['bg'])
            style.configure('TLabelFrame', background=self.colors['bg'], foreground=self.colors['fg'])
            style.configure('TNotebook', background=self.colors['bg'])
            style.configure('TNotebook.Tab', background=self.colors['grid'], foreground=self.colors['fg'])
    
    def _create_layout(self, container):
        """Create the main dashboard layout"""
        # Create main notebook for tabs
        notebook = ttk.Notebook(container)
        notebook.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        
        # Create tabs
        self._create_overview_tab(notebook)
        self._create_security_tab(notebook)
        self._create_performance_tab(notebook)
        self._create_network_tab(notebook)
        self._create_incidents_tab(notebook)
        self._create_analytics_tab(notebook)
    
    def _create_overview_tab(self, notebook):
        """Create overview tab with key metrics"""
        overview_frame = ttk.Frame(notebook)
        notebook.add(overview_frame, text="Overview")
        
        # Top row - Status cards
        status_frame = ttk.Frame(overview_frame)
        status_frame.pack(fill=tk.X, padx=5, pady=5)
        
        self._create_status_cards(status_frame)
        
        # Middle row - Real-time charts
        charts_frame = ttk.Frame(overview_frame)
        charts_frame.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        
        self._create_overview_charts(charts_frame)
        
        # Bottom row - Recent activities
        activities_frame = ttk.LabelFrame(overview_frame, text="Recent Activities")
        activities_frame.pack(fill=tk.X, padx=5, pady=5, ipady=5)
        
        self._create_activity_feed(activities_frame)
    
    def _create_status_cards(self, parent):
        """Create status indicator cards"""
        cards_data = [
            {"title": "Protection Status", "key": "protection_status", "color": "success"},
            {"title": "Threats Blocked", "key": "threats_blocked", "color": "danger"},
            {"title": "Files Scanned", "key": "files_scanned", "color": "accent"},
            {"title": "System Health", "key": "system_health", "color": "warning"}
        ]
        
        for i, card_data in enumerate(cards_data):
            card_frame = ttk.LabelFrame(parent, text=card_data["title"])
            card_frame.grid(row=0, column=i, padx=5, pady=5, sticky="ew")
            parent.columnconfigure(i, weight=1)
            
            # Value label
            value_label = ttk.Label(card_frame, text="0", font=("Arial", 24, "bold"))
            value_label.pack(pady=10)
            
            # Trend indicator
            trend_label = ttk.Label(card_frame, text="▲ 0%", font=("Arial", 12))
            trend_label.pack()
            
            self.widgets[f"card_{card_data['key']}_value"] = value_label
            self.widgets[f"card_{card_data['key']}_trend"] = trend_label
    
    def _create_matplotlib_chart(self, parent, chart_id, figsize, title, ylabel="", xlabel="", subplot_config=None):
        """Helper method to create matplotlib charts with availability checking"""
        if not MATPLOTLIB_AVAILABLE:
            # Create placeholder frame when matplotlib is not available
            placeholder_frame = ttk.Frame(parent)
            placeholder_frame.pack(fill=tk.BOTH, expand=True)
            
            label = ttk.Label(placeholder_frame, 
                            text=f"{title} requires matplotlib\nPlease install: pip install matplotlib",
                            justify=tk.CENTER)
            label.place(relx=0.5, rely=0.5, anchor=tk.CENTER)
            
            self.charts[chart_id] = {
                'figure': None,
                'axes': [],
                'canvas': None,
                'lines': []
            }
            return None, [], None
        
        # Import matplotlib components here when needed
        import matplotlib.pyplot as plt  # type: ignore
        from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg  # type: ignore
        
        # Create figure and axes based on subplot configuration
        if subplot_config is None:
            fig, ax = plt.subplots(figsize=figsize, facecolor=self.colors['bg'])
            axes = [ax] if not isinstance(ax, (list, tuple)) else list(ax)
        else:
            fig, ax = plt.subplots(*subplot_config, figsize=figsize, facecolor=self.colors['bg'])
            axes = [ax] if not isinstance(ax, (list, tuple)) else list(ax)
        
        # Set figure background color (skip patch attribute issue)
        try:
            fig.patch.set_facecolor(self.colors['bg'])
        except AttributeError:
            pass
        
        # Configure axes
        if len(axes) == 1:
            ax = axes[0]
            ax.set_title(title, color=self.colors['fg'])
            ax.set_ylabel(ylabel, color=self.colors['fg'])
            ax.set_xlabel(xlabel, color=self.colors['fg'])
            ax.set_facecolor(self.colors['bg'])
            ax.tick_params(colors=self.colors['fg'])
            ax.grid(True, color=self.colors['grid'], alpha=0.3)
        else:
            # For multiple subplots, configure each individually
            for i, ax in enumerate(axes):
                ax.set_facecolor(self.colors['bg'])
                ax.tick_params(colors=self.colors['fg'])
                ax.grid(True, color=self.colors['grid'], alpha=0.3)
        
        canvas = FigureCanvasTkAgg(fig, parent)
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)
        
        chart_data = {
            'figure': fig,
            'axes': axes,
            'canvas': canvas,
            'lines': []
        }
        
        if chart_id:
            self.charts[chart_id] = chart_data
        
        return fig, axes, canvas

    def _create_overview_charts(self, parent):
        """Create overview charts"""
        # Create chart container
        chart_container = ttk.Frame(parent)
        chart_container.pack(fill=tk.BOTH, expand=True)
        
        # System performance chart
        perf_frame = ttk.LabelFrame(chart_container, text="System Performance")
        perf_frame.grid(row=0, column=0, padx=5, pady=5, sticky="nsew")
        
        self._create_performance_chart(perf_frame, "system_performance")
        
        # Security events chart
        security_frame = ttk.LabelFrame(chart_container, text="Security Events")
        security_frame.grid(row=0, column=1, padx=5, pady=5, sticky="nsew")
        
        self._create_security_events_chart(security_frame, "security_events")
        
        # Network activity chart
        network_frame = ttk.LabelFrame(chart_container, text="Network Activity")
        network_frame.grid(row=1, column=0, columnspan=2, padx=5, pady=5, sticky="nsew")
        
        self._create_network_chart(network_frame, "network_activity")
        
        # Configure grid weights
        chart_container.rowconfigure(0, weight=1)
        chart_container.rowconfigure(1, weight=1)
        chart_container.columnconfigure(0, weight=1)
        chart_container.columnconfigure(1, weight=1)
    
    def _create_performance_chart(self, parent, chart_id):
        """Create system performance chart"""
        if not MATPLOTLIB_AVAILABLE:
            # Create placeholder frame when matplotlib is not available
            placeholder_frame = ttk.Frame(parent)
            placeholder_frame.pack(fill=tk.BOTH, expand=True)
            
            label = ttk.Label(placeholder_frame, 
                            text="Performance charts require matplotlib\nPlease install: pip install matplotlib",
                            justify=tk.CENTER)
            label.place(relx=0.5, rely=0.5, anchor=tk.CENTER)
            
            self.charts[chart_id] = {
                'figure': None,
                'axes': [],
                'canvas': None,
                'lines': []
            }
            return
        
        if not MATPLOTLIB_AVAILABLE:
            # Create placeholder frame when matplotlib is not available
            placeholder_frame = ttk.Frame(parent)
            placeholder_frame.pack(fill=tk.BOTH, expand=True)
            
            label = ttk.Label(placeholder_frame, 
                            text="Performance charts require matplotlib\nPlease install: pip install matplotlib",
                            justify=tk.CENTER)
            label.place(relx=0.5, rely=0.5, anchor=tk.CENTER)
            
            self.charts[chart_id] = {
                'figure': None,
                'axes': [],
                'canvas': None,
                'lines': []
            }
            return

        # Import matplotlib components when needed
        import matplotlib.pyplot as plt  # type: ignore
        from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg  # type: ignore
        
        fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(8, 6), facecolor=self.colors['bg'])
        try:
            fig.patch.set_facecolor(self.colors['bg'])
        except AttributeError:
            pass
        
        # CPU usage
        ax1.set_title("CPU Usage (%)", color=self.colors['fg'])
        ax1.set_ylabel("Usage %", color=self.colors['fg'])
        ax1.set_facecolor(self.colors['bg'])
        ax1.tick_params(colors=self.colors['fg'])
        ax1.grid(True, color=self.colors['grid'], alpha=0.3)
        
        # Memory usage
        ax2.set_title("Memory Usage (%)", color=self.colors['fg'])
        ax2.set_ylabel("Usage %", color=self.colors['fg'])
        ax2.set_xlabel("Time", color=self.colors['fg'])
        ax2.set_facecolor(self.colors['bg'])
        ax2.tick_params(colors=self.colors['fg'])
        ax2.grid(True, color=self.colors['grid'], alpha=0.3)
        
        canvas = FigureCanvasTkAgg(fig, parent)
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)
        
        self.charts[chart_id] = {
            'figure': fig,
            'axes': [ax1, ax2],
            'canvas': canvas,
            'lines': []
        }
    
    def _create_security_events_chart(self, parent, chart_id):
        """Create security events chart"""
        if not MATPLOTLIB_AVAILABLE:
            # Create placeholder frame when matplotlib is not available
            placeholder_frame = ttk.Frame(parent)
            placeholder_frame.pack(fill=tk.BOTH, expand=True)
            
            label = ttk.Label(placeholder_frame, 
                            text="Security events charts require matplotlib\nPlease install: pip install matplotlib",
                            justify=tk.CENTER)
            label.place(relx=0.5, rely=0.5, anchor=tk.CENTER)
            
            self.charts[chart_id] = {
                'figure': None,
                'axes': [],
                'canvas': None,
                'lines': []
            }
            return
        
        if not MATPLOTLIB_AVAILABLE:
            # Create placeholder frame when matplotlib is not available
            placeholder_frame = ttk.Frame(parent)
            placeholder_frame.pack(fill=tk.BOTH, expand=True)
            
            label = ttk.Label(placeholder_frame, 
                            text="Security events charts require matplotlib\nPlease install: pip install matplotlib",
                            justify=tk.CENTER)
            label.place(relx=0.5, rely=0.5, anchor=tk.CENTER)
            
            self.charts[chart_id] = {
                'figure': None,
                'axes': [],
                'canvas': None,
                'lines': []
            }
            return

        # Import matplotlib components when needed  
        import matplotlib.pyplot as plt  # type: ignore
        from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg  # type: ignore
        
        fig, ax = plt.subplots(figsize=(8, 6), facecolor=self.colors['bg'])
        try:
            fig.patch.set_facecolor(self.colors['bg'])
        except AttributeError:
            pass
        
        ax.set_title("Security Events", color=self.colors['fg'])
        ax.set_ylabel("Events Count", color=self.colors['fg'])
        ax.set_xlabel("Time", color=self.colors['fg'])
        ax.set_facecolor(self.colors['bg'])
        ax.tick_params(colors=self.colors['fg'])
        ax.grid(True, color=self.colors['grid'], alpha=0.3)
        
        canvas = FigureCanvasTkAgg(fig, parent)
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)
        
        self.charts[chart_id] = {
            'figure': fig,
            'axes': [ax],
            'canvas': canvas,
            'lines': []
        }
    
    def _create_network_chart(self, parent, chart_id):
        """Create network activity chart"""
        if not MATPLOTLIB_AVAILABLE:
            # Create placeholder frame when matplotlib is not available
            placeholder_frame = ttk.Frame(parent)
            placeholder_frame.pack(fill=tk.BOTH, expand=True)
            
            label = ttk.Label(placeholder_frame, 
                            text="Network charts require matplotlib\nPlease install: pip install matplotlib",
                            justify=tk.CENTER)
            label.place(relx=0.5, rely=0.5, anchor=tk.CENTER)
            
            self.charts[chart_id] = {
                'figure': None,
                'axes': [],
                'canvas': None,
                'lines': []
            }
            return
        
        if not MATPLOTLIB_AVAILABLE:
            # Create placeholder frame when matplotlib is not available
            placeholder_frame = ttk.Frame(parent)
            placeholder_frame.pack(fill=tk.BOTH, expand=True)
            
            label = ttk.Label(placeholder_frame, 
                            text="Network charts require matplotlib\nPlease install: pip install matplotlib",
                            justify=tk.CENTER)
            label.place(relx=0.5, rely=0.5, anchor=tk.CENTER)
            
            self.charts[chart_id] = {
                'figure': None,
                'axes': [],
                'canvas': None,
                'lines': []
            }
            return

        # Import matplotlib components when needed
        import matplotlib.pyplot as plt  # type: ignore
        from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg  # type: ignore
        
        fig, ax = plt.subplots(figsize=(16, 4), facecolor=self.colors['bg'])
        try:
            fig.patch.set_facecolor(self.colors['bg'])
        except AttributeError:
            pass
        
        ax.set_title("Network Activity", color=self.colors['fg'])
        ax.set_ylabel("Connections", color=self.colors['fg'])
        ax.set_xlabel("Time", color=self.colors['fg'])
        ax.set_facecolor(self.colors['bg'])
        ax.tick_params(colors=self.colors['fg'])
        ax.grid(True, color=self.colors['grid'], alpha=0.3)
        
        canvas = FigureCanvasTkAgg(fig, parent)
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)
        
        self.charts[chart_id] = {
            'figure': fig,
            'axes': [ax],
            'canvas': canvas,
            'lines': []
        }
    
    def _create_activity_feed(self, parent):
        """Create activity feed"""
        # Create scrollable text widget
        text_frame = ttk.Frame(parent)
        text_frame.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        
        # Activity text widget with scrollbar
        text_widget = tk.Text(text_frame, height=8, bg=self.colors['bg'], 
                             fg=self.colors['fg'], wrap=tk.WORD)
        scrollbar = ttk.Scrollbar(text_frame, orient=tk.VERTICAL, command=text_widget.yview)
        text_widget.configure(yscrollcommand=scrollbar.set)
        
        text_widget.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        
        self.widgets['activity_feed'] = text_widget
    
    def _create_security_tab(self, notebook):
        """Create security monitoring tab"""
        security_frame = ttk.Frame(notebook)
        notebook.add(security_frame, text="Security")
        
        # Security metrics grid
        metrics_frame = ttk.LabelFrame(security_frame, text="Security Metrics")
        metrics_frame.pack(fill=tk.X, padx=5, pady=5)
        
        # Create security metrics widgets
        security_metrics = [
            "Real-time Protection", "Web Protection", "Email Protection",
            "Firewall Status", "VPN Status", "Intrusion Detection"
        ]
        
        for i, metric in enumerate(security_metrics):
            row = i // 3
            col = i % 3
            
            metric_frame = ttk.Frame(metrics_frame)
            metric_frame.grid(row=row, column=col, padx=10, pady=5, sticky="ew")
            metrics_frame.columnconfigure(col, weight=1)
            
            label = ttk.Label(metric_frame, text=metric)
            label.pack(anchor=tk.W)
            
            status = ttk.Label(metric_frame, text="Active", foreground=self.colors['success'])
            status.pack(anchor=tk.W)
            
            self.widgets[f"security_{metric.lower().replace(' ', '_')}"] = status
        
        # Threat detection chart
        threat_frame = ttk.LabelFrame(security_frame, text="Threat Detection Timeline")
        threat_frame.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        
        self._create_threat_timeline_chart(threat_frame)
    
    def _create_threat_timeline_chart(self, parent):
        """Create threat detection timeline chart"""
        if not MATPLOTLIB_AVAILABLE:
            # Create placeholder frame when matplotlib is not available
            placeholder_frame = ttk.Frame(parent)
            placeholder_frame.pack(fill=tk.BOTH, expand=True)
            
            label = ttk.Label(placeholder_frame, 
                            text="Threat timeline charts require matplotlib\nPlease install: pip install matplotlib",
                            justify=tk.CENTER)
            label.place(relx=0.5, rely=0.5, anchor=tk.CENTER)
            
            self.charts['threat_timeline'] = {
                'figure': None,
                'axes': [],
                'canvas': None,
                'lines': []
            }
            return
        
        # Import matplotlib components when needed
        import matplotlib.pyplot as plt  # type: ignore
        from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg  # type: ignore
        
        fig, ax = plt.subplots(figsize=(12, 6), facecolor=self.colors['bg'])
        try:
            fig.patch.set_facecolor(self.colors['bg'])
        except AttributeError:
            pass
        
        ax.set_title("Threat Detection Timeline", color=self.colors['fg'])
        ax.set_ylabel("Threat Count", color=self.colors['fg'])
        ax.set_xlabel("Time", color=self.colors['fg'])
        ax.set_facecolor(self.colors['bg'])
        ax.tick_params(colors=self.colors['fg'])
        ax.grid(True, color=self.colors['grid'], alpha=0.3)
        
        canvas = FigureCanvasTkAgg(fig, parent)
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)
        
        self.charts['threat_timeline'] = {
            'figure': fig,
            'axes': [ax],
            'canvas': canvas,
            'lines': []
        }
    
    def _create_performance_tab(self, notebook):
        """Create performance monitoring tab"""
        perf_frame = ttk.Frame(notebook)
        notebook.add(perf_frame, text="Performance")
        
        # Performance metrics
        self._create_performance_metrics(perf_frame)
    
    def _create_performance_metrics(self, parent):
        """Create performance metrics display"""
        # Resource usage frame
        resource_frame = ttk.LabelFrame(parent, text="Resource Usage")
        resource_frame.pack(fill=tk.X, padx=5, pady=5)
        
        # CPU gauge
        cpu_frame = ttk.Frame(resource_frame)
        cpu_frame.grid(row=0, column=0, padx=10, pady=10)
        
        ttk.Label(cpu_frame, text="CPU Usage").pack()
        cpu_progress = ttk.Progressbar(cpu_frame, length=200, mode='determinate')
        cpu_progress.pack(pady=5)
        cpu_label = ttk.Label(cpu_frame, text="0%")
        cpu_label.pack()
        
        self.widgets['cpu_progress'] = cpu_progress
        self.widgets['cpu_label'] = cpu_label
        
        # Memory gauge
        memory_frame = ttk.Frame(resource_frame)
        memory_frame.grid(row=0, column=1, padx=10, pady=10)
        
        ttk.Label(memory_frame, text="Memory Usage").pack()
        memory_progress = ttk.Progressbar(memory_frame, length=200, mode='determinate')
        memory_progress.pack(pady=5)
        memory_label = ttk.Label(memory_frame, text="0%")
        memory_label.pack()
        
        self.widgets['memory_progress'] = memory_progress
        self.widgets['memory_label'] = memory_label
        
        # Disk gauge
        disk_frame = ttk.Frame(resource_frame)
        disk_frame.grid(row=0, column=2, padx=10, pady=10)
        
        ttk.Label(disk_frame, text="Disk Usage").pack()
        disk_progress = ttk.Progressbar(disk_frame, length=200, mode='determinate')
        disk_progress.pack(pady=5)
        disk_label = ttk.Label(disk_frame, text="0%")
        disk_label.pack()
        
        self.widgets['disk_progress'] = disk_progress
        self.widgets['disk_label'] = disk_label
        
        # Performance chart
        chart_frame = ttk.LabelFrame(parent, text="Performance History")
        chart_frame.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        
        self._create_performance_history_chart(chart_frame)
    
    def _create_performance_history_chart(self, parent):
        """Create performance history chart"""
        if not MATPLOTLIB_AVAILABLE:
            # Create placeholder frame when matplotlib is not available
            placeholder_frame = ttk.Frame(parent)
            placeholder_frame.pack(fill=tk.BOTH, expand=True)
            
            label = ttk.Label(placeholder_frame, 
                            text="Performance history charts require matplotlib\nPlease install: pip install matplotlib",
                            justify=tk.CENTER)
            label.place(relx=0.5, rely=0.5, anchor=tk.CENTER)
            
            self.charts['performance_history'] = {
                'figure': None,
                'axes': [],
                'canvas': None,
                'lines': []
            }
            return
        
        # Import matplotlib components when needed
        import matplotlib.pyplot as plt
        from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
        
        fig, (ax1, ax2, ax3) = plt.subplots(3, 1, figsize=(12, 8), facecolor=self.colors['bg'])
        try:
            fig.patch.set_facecolor(self.colors['bg'])
        except AttributeError:
            pass
        
        axes_config = [
            (ax1, "CPU Usage (%)", self.colors['accent']),
            (ax2, "Memory Usage (%)", self.colors['success']),
            (ax3, "Disk I/O (MB/s)", self.colors['warning'])
        ]
        
        for ax, title, color in axes_config:
            ax.set_title(title, color=self.colors['fg'])
            ax.set_ylabel("Value", color=self.colors['fg'])
            ax.set_facecolor(self.colors['bg'])
            ax.tick_params(colors=self.colors['fg'])
            ax.grid(True, color=self.colors['grid'], alpha=0.3)
        
        ax3.set_xlabel("Time", color=self.colors['fg'])
        
        canvas = FigureCanvasTkAgg(fig, parent)
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)
        
        self.charts['performance_history'] = {
            'figure': fig,
            'axes': [ax1, ax2, ax3],
            'canvas': canvas,
            'lines': []
        }
    
    def _create_network_tab(self, notebook):
        """Create network monitoring tab"""
        network_frame = ttk.Frame(notebook)
        notebook.add(network_frame, text="Network")
        
        # Network statistics
        stats_frame = ttk.LabelFrame(network_frame, text="Network Statistics")
        stats_frame.pack(fill=tk.X, padx=5, pady=5)
        
        # Create network stats widgets
        stats_data = [
            ("Active Connections", "active_connections"),
            ("Blocked Attempts", "blocked_attempts"),
            ("Data Transferred", "data_transferred"),
            ("Bandwidth Usage", "bandwidth_usage")
        ]
        
        for i, (label, key) in enumerate(stats_data):
            stat_frame = ttk.Frame(stats_frame)
            stat_frame.grid(row=i//2, column=i%2, padx=20, pady=10, sticky="ew")
            stats_frame.columnconfigure(i%2, weight=1)
            
            ttk.Label(stat_frame, text=label).pack(anchor=tk.W)
            value_label = ttk.Label(stat_frame, text="0", font=("Arial", 14, "bold"))
            value_label.pack(anchor=tk.W)
            
            self.widgets[f"network_{key}"] = value_label
        
        # Network traffic chart
        traffic_frame = ttk.LabelFrame(network_frame, text="Network Traffic")
        traffic_frame.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        
        self._create_network_traffic_chart(traffic_frame)
    
    def _create_network_traffic_chart(self, parent):
        """Create network traffic chart"""
        if not MATPLOTLIB_AVAILABLE:
            # Create placeholder frame when matplotlib is not available
            placeholder_frame = ttk.Frame(parent)
            placeholder_frame.pack(fill=tk.BOTH, expand=True)
            
            label = ttk.Label(placeholder_frame, 
                            text="Network traffic charts require matplotlib\nPlease install: pip install matplotlib",
                            justify=tk.CENTER)
            label.place(relx=0.5, rely=0.5, anchor=tk.CENTER)
            
            self.charts['network_traffic'] = {
                'figure': None,
                'axes': [],
                'canvas': None,
                'lines': []
            }
            return
        
        # Import matplotlib components when needed
        import matplotlib.pyplot as plt
        from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
        
        fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 6), facecolor=self.colors['bg'])
        try:
            fig.patch.set_facecolor(self.colors['bg'])
        except AttributeError:
            pass
        
        # Incoming traffic
        ax1.set_title("Incoming Traffic", color=self.colors['fg'])
        ax1.set_ylabel("MB/s", color=self.colors['fg'])
        ax1.set_facecolor(self.colors['bg'])
        ax1.tick_params(colors=self.colors['fg'])
        ax1.grid(True, color=self.colors['grid'], alpha=0.3)
        
        # Outgoing traffic
        ax2.set_title("Outgoing Traffic", color=self.colors['fg'])
        ax2.set_ylabel("MB/s", color=self.colors['fg'])
        ax2.set_xlabel("Time", color=self.colors['fg'])
        ax2.set_facecolor(self.colors['bg'])
        ax2.tick_params(colors=self.colors['fg'])
        ax2.grid(True, color=self.colors['grid'], alpha=0.3)
        
        canvas = FigureCanvasTkAgg(fig, parent)
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)
        
        self.charts['network_traffic'] = {
            'figure': fig,
            'axes': [ax1, ax2],
            'canvas': canvas,
            'lines': []
        }
    
    def _create_incidents_tab(self, notebook):
        """Create incidents monitoring tab"""
        incidents_frame = ttk.Frame(notebook)
        notebook.add(incidents_frame, text="Incidents")
        
        # Incidents list
        list_frame = ttk.LabelFrame(incidents_frame, text="Recent Incidents")
        list_frame.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        
        # Create treeview for incidents
        columns = ("Time", "Type", "Severity", "Description", "Status")
        incidents_tree = ttk.Treeview(list_frame, columns=columns, show="headings", height=15)
        
        for col in columns:
            incidents_tree.heading(col, text=col)
            incidents_tree.column(col, width=150)
        
        scrollbar_incidents = ttk.Scrollbar(list_frame, orient=tk.VERTICAL, command=incidents_tree.yview)
        incidents_tree.configure(yscrollcommand=scrollbar_incidents.set)
        
        incidents_tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar_incidents.pack(side=tk.RIGHT, fill=tk.Y)
        
        self.widgets['incidents_tree'] = incidents_tree
    
    def _create_analytics_tab(self, notebook):
        """Create analytics and reporting tab"""
        analytics_frame = ttk.Frame(notebook)
        notebook.add(analytics_frame, text="Analytics")
        
        # Analytics summary
        summary_frame = ttk.LabelFrame(analytics_frame, text="Security Analytics")
        summary_frame.pack(fill=tk.X, padx=5, pady=5)
        
        # Create analytics widgets
        analytics_data = [
            ("Total Scans", "total_scans"),
            ("Threats Found", "total_threats"),
            ("Files Quarantined", "total_quarantined"),
            ("Uptime", "system_uptime")
        ]
        
        for i, (label, key) in enumerate(analytics_data):
            analytics_widget_frame = ttk.Frame(summary_frame)
            analytics_widget_frame.grid(row=i//2, column=i%2, padx=20, pady=10, sticky="ew")
            summary_frame.columnconfigure(i%2, weight=1)
            
            ttk.Label(analytics_widget_frame, text=label).pack(anchor=tk.W)
            value_label = ttk.Label(analytics_widget_frame, text="0", font=("Arial", 14, "bold"))
            value_label.pack(anchor=tk.W)
            
            self.widgets[f"analytics_{key}"] = value_label
        
        # Trend analysis chart
        trend_frame = ttk.LabelFrame(analytics_frame, text="Security Trends")
        trend_frame.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        
        self._create_trend_analysis_chart(trend_frame)
    
    def _create_trend_analysis_chart(self, parent):
        """Create trend analysis chart"""
        if not MATPLOTLIB_AVAILABLE:
            # Create placeholder frame when matplotlib is not available
            placeholder_frame = ttk.Frame(parent)
            placeholder_frame.pack(fill=tk.BOTH, expand=True)
            
            label = ttk.Label(placeholder_frame, 
                            text="Trend analysis charts require matplotlib\nPlease install: pip install matplotlib",
                            justify=tk.CENTER)
            label.place(relx=0.5, rely=0.5, anchor=tk.CENTER)
            
            self.charts['trend_analysis'] = {
                'figure': None,
                'axes': [],
                'canvas': None,
                'lines': []
            }
            return
        
        # Import matplotlib components when needed
        import matplotlib.pyplot as plt
        from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
        
        fig, ax = plt.subplots(figsize=(12, 6), facecolor=self.colors['bg'])
        try:
            fig.patch.set_facecolor(self.colors['bg'])
        except AttributeError:
            pass
        
        ax.set_title("Security Trends Analysis", color=self.colors['fg'])
        ax.set_ylabel("Count", color=self.colors['fg'])
        ax.set_xlabel("Time", color=self.colors['fg'])
        ax.set_facecolor(self.colors['bg'])
        ax.tick_params(colors=self.colors['fg'])
        ax.grid(True, color=self.colors['grid'], alpha=0.3)
        
        canvas = FigureCanvasTkAgg(fig, parent)
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)
        
        self.charts['trend_analysis'] = {
            'figure': fig,
            'axes': [ax],
            'canvas': canvas,
            'lines': []
        }
    
    def start_monitoring(self):
        """Start real-time monitoring"""
        if self.running:
            return
        
        self.running = True
        
        # Start update threads
        self.update_threads = [
            threading.Thread(target=self._fast_update_loop, daemon=True),
            threading.Thread(target=self._medium_update_loop, daemon=True),
            threading.Thread(target=self._slow_update_loop, daemon=True)
        ]
        
        for thread in self.update_threads:
            thread.start()
        
        self.logger.info("Real-time monitoring started")
    
    def stop_monitoring(self):
        """Stop real-time monitoring"""
        self.running = False
        self.logger.info("Real-time monitoring stopped")
    
    def _fast_update_loop(self):
        """Fast update loop for real-time metrics"""
        while self.running:
            try:
                # Collect system metrics
                metrics = self._collect_system_metrics()
                self.metrics.add_datapoint(metrics)
                
                # Update widgets on main thread
                if self.root:
                    self.root.after(0, self._update_fast_widgets, metrics)
                
                time.sleep(self.fast_update_ms / 1000)
                
            except Exception as e:
                self.logger.error(f"Error in fast update loop: {e}")
                time.sleep(1)
    
    def _medium_update_loop(self):
        """Medium update loop for charts"""
        while self.running:
            try:
                # Update charts
                if self.root:
                    self.root.after(0, self._update_charts)
                
                time.sleep(self.medium_update_ms / 1000)
                
            except Exception as e:
                self.logger.error(f"Error in medium update loop: {e}")
                time.sleep(5)
    
    def _slow_update_loop(self):
        """Slow update loop for analytics"""
        while self.running:
            try:
                # Update analytics and summary data
                if self.root:
                    self.root.after(0, self._update_analytics)
                
                time.sleep(self.slow_update_ms / 1000)
                
            except Exception as e:
                self.logger.error(f"Error in slow update loop: {e}")
                time.sleep(30)
    
    def _collect_system_metrics(self) -> Dict[str, Any]:
        """Collect current system metrics"""
        try:
            metrics: Dict[str, Any] = {
                'cpu_usage': 0.0,
                'memory_usage': 0.0,
                'disk_usage': 0.0,
                'network_io': 0.0,
                'threats_detected': 0,
                'files_scanned': 0,
                'quarantine_count': 0,
                'active_connections': 0,
                'blocked_attempts': 0
            }
            
            # Use psutil if available
            if PSUTIL_AVAILABLE:
                import psutil
                metrics['cpu_usage'] = psutil.cpu_percent(interval=None)
                metrics['memory_usage'] = psutil.virtual_memory().percent
                metrics['disk_usage'] = psutil.disk_usage('/').percent if hasattr(psutil.disk_usage('/'), 'percent') else 0.0
                metrics['network_io'] = sum([psutil.net_io_counters().bytes_sent, psutil.net_io_counters().bytes_recv]) / (1024*1024)  # MB
                metrics['active_connections'] = len(psutil.net_connections())
            
            # Integrate with security manager if available
            if self.security_manager:
                try:
                    security_status = self.security_manager.get_security_status()
                    metrics['threats_detected'] = security_status.get('active_threats', 0)
                    metrics['files_scanned'] = security_status.get('metrics', {}).get('threats_detected', 0)
                except Exception as e:
                    self.logger.error(f"Error getting security status: {e}")
            
            return metrics
            
        except Exception as e:
            self.logger.error(f"Error collecting system metrics: {e}")
            return {
                'cpu_usage': 0.0,
                'memory_usage': 0.0,
                'disk_usage': 0.0,
                'network_io': 0.0,
                'threats_detected': 0,
                'files_scanned': 0,
                'quarantine_count': 0,
                'active_connections': 0,
                'blocked_attempts': 0
            }
    
    def _update_fast_widgets(self, metrics: Dict[str, Any]):
        """Update fast-updating widgets"""
        try:
            # Update progress bars
            if 'cpu_progress' in self.widgets:
                self.widgets['cpu_progress']['value'] = metrics.get('cpu_usage', 0)
                self.widgets['cpu_label'].config(text=f"{metrics.get('cpu_usage', 0):.1f}%")
            
            if 'memory_progress' in self.widgets:
                self.widgets['memory_progress']['value'] = metrics.get('memory_usage', 0)
                self.widgets['memory_label'].config(text=f"{metrics.get('memory_usage', 0):.1f}%")
            
            if 'disk_progress' in self.widgets:
                self.widgets['disk_progress']['value'] = metrics.get('disk_usage', 0)
                self.widgets['disk_label'].config(text=f"{metrics.get('disk_usage', 0):.1f}%")
            
            # Update status cards
            if 'card_threats_blocked_value' in self.widgets:
                self.widgets['card_threats_blocked_value'].config(text=str(metrics.get('threats_detected', 0)))
            
            if 'card_files_scanned_value' in self.widgets:
                self.widgets['card_files_scanned_value'].config(text=str(metrics.get('files_scanned', 0)))
            
            # Update network stats
            if 'network_active_connections' in self.widgets:
                self.widgets['network_active_connections'].config(text=str(metrics.get('active_connections', 0)))
            
            if 'network_blocked_attempts' in self.widgets:
                self.widgets['network_blocked_attempts'].config(text=str(metrics.get('blocked_attempts', 0)))
            
        except Exception as e:
            self.logger.error(f"Error updating fast widgets: {e}")
    
    def _update_charts(self):
        """Update all charts with latest data"""
        try:
            # Get recent data
            timestamps = self.metrics.get_latest('timestamps', 50)
            
            if not timestamps:
                return
            
            # Update performance charts
            self._update_performance_chart(timestamps)
            self._update_security_chart(timestamps)
            self._update_network_chart(timestamps)
            
        except Exception as e:
            self.logger.error(f"Error updating charts: {e}")
    
    def _update_performance_chart(self, timestamps):
        """Update performance chart"""
        try:
            if 'system_performance' not in self.charts:
                return
            
            chart = self.charts['system_performance']
            axes = chart['axes']
            
            cpu_data = self.metrics.get_latest('cpu_usage', len(timestamps))
            memory_data = self.metrics.get_latest('memory_usage', len(timestamps))
            
            # Clear and redraw
            axes[0].clear()
            axes[1].clear()
            
            if cpu_data and len(cpu_data) == len(timestamps):
                axes[0].plot(timestamps, cpu_data, color=self.colors['accent'], linewidth=2)
                axes[0].set_title("CPU Usage (%)", color=self.colors['fg'])
                axes[0].set_ylabel("Usage %", color=self.colors['fg'])
                axes[0].set_facecolor(self.colors['bg'])
                axes[0].tick_params(colors=self.colors['fg'])
                axes[0].grid(True, color=self.colors['grid'], alpha=0.3)
            
            if memory_data and len(memory_data) == len(timestamps):
                axes[1].plot(timestamps, memory_data, color=self.colors['success'], linewidth=2)
                axes[1].set_title("Memory Usage (%)", color=self.colors['fg'])
                axes[1].set_ylabel("Usage %", color=self.colors['fg'])
                axes[1].set_xlabel("Time", color=self.colors['fg'])
                axes[1].set_facecolor(self.colors['bg'])
                axes[1].tick_params(colors=self.colors['fg'])
                axes[1].grid(True, color=self.colors['grid'], alpha=0.3)
            
            chart['canvas'].draw()
            
        except Exception as e:
            self.logger.error(f"Error updating performance chart: {e}")
    
    def _update_security_chart(self, timestamps):
        """Update security events chart"""
        try:
            if 'security_events' not in self.charts:
                return
            
            chart = self.charts['security_events']
            ax = chart['axes'][0]
            
            threats_data = self.metrics.get_latest('threats_detected', len(timestamps))
            
            ax.clear()
            
            if threats_data and len(threats_data) == len(timestamps):
                ax.plot(timestamps, threats_data, color=self.colors['danger'], linewidth=2, marker='o')
                ax.set_title("Security Events", color=self.colors['fg'])
                ax.set_ylabel("Events Count", color=self.colors['fg'])
                ax.set_xlabel("Time", color=self.colors['fg'])
                ax.set_facecolor(self.colors['bg'])
                ax.tick_params(colors=self.colors['fg'])
                ax.grid(True, color=self.colors['grid'], alpha=0.3)
            
            chart['canvas'].draw()
            
        except Exception as e:
            self.logger.error(f"Error updating security chart: {e}")
    
    def _update_network_chart(self, timestamps):
        """Update network activity chart"""
        try:
            if 'network_activity' not in self.charts:
                return
            
            chart = self.charts['network_activity']
            ax = chart['axes'][0]
            
            connections_data = self.metrics.get_latest('active_connections', len(timestamps))
            
            ax.clear()
            
            if connections_data and len(connections_data) == len(timestamps):
                ax.plot(timestamps, connections_data, color=self.colors['warning'], linewidth=2)
                ax.set_title("Network Activity", color=self.colors['fg'])
                ax.set_ylabel("Connections", color=self.colors['fg'])
                ax.set_xlabel("Time", color=self.colors['fg'])
                ax.set_facecolor(self.colors['bg'])
                ax.tick_params(colors=self.colors['fg'])
                ax.grid(True, color=self.colors['grid'], alpha=0.3)
            
            chart['canvas'].draw()
            
        except Exception as e:
            self.logger.error(f"Error updating network chart: {e}")
    
    def _update_analytics(self):
        """Update analytics and summary data"""
        try:
            # Update analytics widgets
            if 'analytics_total_scans' in self.widgets:
                # Would integrate with actual scan data
                self.widgets['analytics_total_scans'].config(text="1,234")
            
            if 'analytics_total_threats' in self.widgets:
                total_threats = sum(self.metrics.get_latest('threats_detected', 100))
                self.widgets['analytics_total_threats'].config(text=str(total_threats))
            
            # Update activity feed
            if 'activity_feed' in self.widgets:
                self._update_activity_feed()
            
        except Exception as e:
            self.logger.error(f"Error updating analytics: {e}")
    
    def _update_activity_feed(self):
        """Update the activity feed"""
        try:
            activity_widget = self.widgets['activity_feed']
            
            # Add new activity (simulation)
            timestamp = datetime.now().strftime("%H:%M:%S")
            activity = f"[{timestamp}] System scan completed - No threats detected\n"
            
            activity_widget.insert(tk.END, activity)
            activity_widget.see(tk.END)
            
            # Limit lines
            lines = activity_widget.get("1.0", tk.END).split('\n')
            if len(lines) > 100:
                activity_widget.delete("1.0", "2.0")
            
        except Exception as e:
            self.logger.error(f"Error updating activity feed: {e}")
    
    def add_security_event(self, event_type: str, description: str, severity: str = "medium"):
        """Add a security event to the dashboard"""
        try:
            # Add to incidents tree
            if 'incidents_tree' in self.widgets:
                tree = self.widgets['incidents_tree']
                timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                tree.insert("", 0, values=(timestamp, event_type, severity, description, "Active"))
                
                # Limit entries
                children = tree.get_children()
                if len(children) > 50:
                    tree.delete(children[-1])
            
            # Add to activity feed
            if 'activity_feed' in self.widgets:
                timestamp = datetime.now().strftime("%H:%M:%S")
                activity = f"[{timestamp}] {event_type}: {description}\n"
                self.widgets['activity_feed'].insert(tk.END, activity)
                self.widgets['activity_feed'].see(tk.END)
            
        except Exception as e:
            self.logger.error(f"Error adding security event: {e}")
    
    def run(self):
        """Run the dashboard"""
        if self.root:
            self.root.mainloop()
    
    def shutdown(self):
        """Shutdown the dashboard"""
        self.logger.info("Shutting down real-time dashboard")
        self.stop_monitoring()
        
        if self.root:
            self.root.quit()
            self.root.destroy()

# Example usage
def main():
    """Example usage of the Real-Time Dashboard"""
    dashboard = RealTimeDashboard(theme='dark')
    dashboard.initialize()
    
    # Simulate some security events
    dashboard.add_security_event("Malware Detection", "Threat detected in file: suspicious.exe", "high")
    dashboard.add_security_event("Web Protection", "Blocked malicious URL", "medium")
    dashboard.add_security_event("Firewall", "Blocked suspicious connection", "low")
    
    try:
        dashboard.run()
    except KeyboardInterrupt:
        print("Shutting down dashboard...")
    finally:
        dashboard.shutdown()

if __name__ == "__main__":
    main()