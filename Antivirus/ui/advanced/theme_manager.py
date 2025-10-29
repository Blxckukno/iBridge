"""
Theme Manager
Manages UI themes and visual styling for the antivirus interface
"""

import tkinter as tk
from tkinter import ttk, colorchooser, messagebox, filedialog
import json
import os
import logging
from datetime import datetime
from typing import Dict, List, Any, Optional, Tuple, Callable
from enum import Enum

class ThemeType(Enum):
    """Theme types"""
    LIGHT = "light"
    DARK = "dark"
    AUTO = "auto"
    CUSTOM = "custom"

class ThemeManager:
    """
    Theme Manager
    Handles UI theming and visual customization
    """
    
    def __init__(self, root_window: Optional[tk.Tk] = None):
        self.root_window = root_window
        self.current_theme = ThemeType.LIGHT
        
        # Initialize logging
        self.logger = logging.getLogger(__name__)
        
        # Theme data storage
        self.themes = {}
        self.custom_themes = {}
        
        # Current style
        self.style = ttk.Style()
        
        # Registered widgets for theme updates
        self.registered_widgets = []
        self.registered_callbacks = []
        
        # Theme settings
        self.settings = {
            'auto_theme': False,
            'follow_system': True,
            'transition_effects': True,
            'high_contrast': False,
            'font_scaling': 1.0,
            'accent_color': '#2196F3',
            'animation_speed': 'normal'
        }
        
        # Initialize built-in themes
        self._initialize_builtin_themes()
        
        # Load custom themes
        self._load_custom_themes()
        
        # Apply default theme
        self.apply_theme(ThemeType.LIGHT)
        
        self.logger.info("Theme Manager initialized")
    
    def _initialize_builtin_themes(self):
        """Initialize built-in themes"""
        # Light theme
        self.themes[ThemeType.LIGHT] = {
            'name': 'Light',
            'description': 'Clean light theme',
            'colors': {
                # Background colors
                'bg_primary': '#FFFFFF',
                'bg_secondary': '#F5F5F5',
                'bg_tertiary': '#EEEEEE',
                'bg_accent': '#E3F2FD',
                
                # Text colors
                'text_primary': '#212121',
                'text_secondary': '#757575',
                'text_disabled': '#BDBDBD',
                'text_accent': '#1976D2',
                
                # Widget colors
                'button_bg': '#2196F3',
                'button_fg': '#FFFFFF',
                'button_hover': '#1976D2',
                'button_active': '#0D47A1',
                
                'entry_bg': '#FFFFFF',
                'entry_fg': '#212121',
                'entry_border': '#CCCCCC',
                'entry_focus': '#2196F3',
                
                'frame_bg': '#FFFFFF',
                'frame_border': '#E0E0E0',
                
                'listbox_bg': '#FFFFFF',
                'listbox_fg': '#212121',
                'listbox_select': '#2196F3',
                
                'treeview_bg': '#FFFFFF',
                'treeview_fg': '#212121',
                'treeview_select': '#2196F3',
                
                'menu_bg': '#FFFFFF',
                'menu_fg': '#212121',
                'menu_select': '#E3F2FD',
                
                'scrollbar_bg': '#F5F5F5',
                'scrollbar_fg': '#CCCCCC',
                
                # Status colors
                'success': '#4CAF50',
                'warning': '#FF9800',
                'error': '#F44336',
                'info': '#2196F3',
                
                # Chart colors
                'chart_primary': '#2196F3',
                'chart_secondary': '#4CAF50',
                'chart_tertiary': '#FF9800',
                'chart_quaternary': '#9C27B0'
            },
            'fonts': {
                'default': ('Segoe UI', 9),
                'heading': ('Segoe UI', 12, 'bold'),
                'subheading': ('Segoe UI', 10, 'bold'),
                'small': ('Segoe UI', 8),
                'code': ('Consolas', 9)
            }
        }
        
        # Dark theme
        self.themes[ThemeType.DARK] = {
            'name': 'Dark',
            'description': 'Modern dark theme',
            'colors': {
                # Background colors
                'bg_primary': '#212121',
                'bg_secondary': '#303030',
                'bg_tertiary': '#424242',
                'bg_accent': '#1A237E',
                
                # Text colors
                'text_primary': '#FFFFFF',
                'text_secondary': '#CCCCCC',
                'text_disabled': '#757575',
                'text_accent': '#64B5F6',
                
                # Widget colors
                'button_bg': '#1976D2',
                'button_fg': '#FFFFFF',
                'button_hover': '#2196F3',
                'button_active': '#64B5F6',
                
                'entry_bg': '#303030',
                'entry_fg': '#FFFFFF',
                'entry_border': '#757575',
                'entry_focus': '#64B5F6',
                
                'frame_bg': '#212121',
                'frame_border': '#424242',
                
                'listbox_bg': '#303030',
                'listbox_fg': '#FFFFFF',
                'listbox_select': '#1976D2',
                
                'treeview_bg': '#303030',
                'treeview_fg': '#FFFFFF',
                'treeview_select': '#1976D2',
                
                'menu_bg': '#303030',
                'menu_fg': '#FFFFFF',
                'menu_select': '#1A237E',
                
                'scrollbar_bg': '#424242',
                'scrollbar_fg': '#757575',
                
                # Status colors
                'success': '#66BB6A',
                'warning': '#FFB74D',
                'error': '#EF5350',
                'info': '#64B5F6',
                
                # Chart colors
                'chart_primary': '#64B5F6',
                'chart_secondary': '#66BB6A',
                'chart_tertiary': '#FFB74D',
                'chart_quaternary': '#BA68C8'
            },
            'fonts': {
                'default': ('Segoe UI', 9),
                'heading': ('Segoe UI', 12, 'bold'),
                'subheading': ('Segoe UI', 10, 'bold'),
                'small': ('Segoe UI', 8),
                'code': ('Consolas', 9)
            }
        }
    
    def _load_custom_themes(self):
        """Load custom themes from file"""
        try:
            themes_file = os.path.join(os.path.dirname(__file__), '..', '..', 'config', 'themes.json')
            
            if os.path.exists(themes_file):
                with open(themes_file, 'r') as f:
                    self.custom_themes = json.load(f)
                    
                self.logger.info(f"Loaded {len(self.custom_themes)} custom themes")
            
        except Exception as e:
            self.logger.warning(f"Could not load custom themes: {e}")
    
    def _save_custom_themes(self):
        """Save custom themes to file"""
        try:
            config_dir = os.path.join(os.path.dirname(__file__), '..', '..', 'config')
            os.makedirs(config_dir, exist_ok=True)
            
            themes_file = os.path.join(config_dir, 'themes.json')
            
            with open(themes_file, 'w') as f:
                json.dump(self.custom_themes, f, indent=2)
                
            self.logger.info("Custom themes saved")
            
        except Exception as e:
            self.logger.error(f"Error saving custom themes: {e}")
    
    def apply_theme(self, theme_type: ThemeType, theme_name: Optional[str] = None):
        """Apply a theme to the interface"""
        try:
            # Get theme data
            if theme_type == ThemeType.CUSTOM and theme_name:
                if theme_name not in self.custom_themes:
                    raise ValueError(f"Custom theme '{theme_name}' not found")
                theme_data = self.custom_themes[theme_name]
            else:
                if theme_type not in self.themes:
                    raise ValueError(f"Built-in theme '{theme_type}' not found")
                theme_data = self.themes[theme_type]
            
            # Apply TTK styles
            self._apply_ttk_styles(theme_data)
            
            # Apply TK widget styles
            self._apply_tk_styles(theme_data)
            
            # Update registered widgets
            self._update_registered_widgets(theme_data)
            
            # Update current theme
            self.current_theme = theme_type
            
            # Call registered callbacks
            for callback in self.registered_callbacks:
                try:
                    callback(theme_type, theme_data)
                except Exception as e:
                    self.logger.error(f"Error in theme callback: {e}")
            
            self.logger.info(f"Applied theme: {theme_data.get('name', str(theme_type))}")
            
        except Exception as e:
            self.logger.error(f"Error applying theme: {e}")
            raise
    
    def _apply_ttk_styles(self, theme_data: Dict):
        """Apply styles to TTK widgets"""
        try:
            colors = theme_data['colors']
            fonts = theme_data['fonts']
            
            # Configure TTK style
            self.style.theme_use('clam')  # Use clam as base theme
            
            # Button styles
            self.style.configure(
                'TButton',
                background=colors['button_bg'],
                foreground=colors['button_fg'],
                font=fonts['default'],
                borderwidth=1,
                focuscolor=colors['entry_focus']
            )
            
            self.style.map(
                'TButton',
                background=[('active', colors['button_hover']),
                           ('pressed', colors['button_active'])]
            )
            
            # Entry styles
            self.style.configure(
                'TEntry',
                fieldbackground=colors['entry_bg'],
                foreground=colors['entry_fg'],
                bordercolor=colors['entry_border'],
                focuscolor=colors['entry_focus'],
                font=fonts['default']
            )
            
            # Label styles
            self.style.configure(
                'TLabel',
                background=colors['bg_primary'],
                foreground=colors['text_primary'],
                font=fonts['default']
            )
            
            self.style.configure(
                'Heading.TLabel',
                background=colors['bg_primary'],
                foreground=colors['text_primary'],
                font=fonts['heading']
            )
            
            # Frame styles
            self.style.configure(
                'TFrame',
                background=colors['frame_bg'],
                borderwidth=0
            )
            
            self.style.configure(
                'TLabelFrame',
                background=colors['frame_bg'],
                foreground=colors['text_primary'],
                borderwidth=1,
                relief='solid',
                bordercolor=colors['frame_border']
            )
            
            # Notebook styles
            self.style.configure(
                'TNotebook',
                background=colors['bg_secondary'],
                borderwidth=0
            )
            
            self.style.configure(
                'TNotebook.Tab',
                background=colors['bg_secondary'],
                foreground=colors['text_primary'],
                padding=[10, 5],
                font=fonts['default']
            )
            
            self.style.map(
                'TNotebook.Tab',
                background=[('selected', colors['bg_primary']),
                           ('active', colors['bg_accent'])]
            )
            
            # Treeview styles
            self.style.configure(
                'Treeview',
                background=colors['treeview_bg'],
                foreground=colors['treeview_fg'],
                fieldbackground=colors['treeview_bg'],
                font=fonts['default']
            )
            
            self.style.configure(
                'Treeview.Heading',
                background=colors['bg_secondary'],
                foreground=colors['text_primary'],
                font=fonts['subheading']
            )
            
            # Progressbar styles
            self.style.configure(
                'TProgressbar',
                background=colors['button_bg'],
                troughcolor=colors['bg_secondary'],
                borderwidth=0,
                lightcolor=colors['button_bg'],
                darkcolor=colors['button_bg']
            )
            
            # Scrollbar styles
            self.style.configure(
                'TScrollbar',
                background=colors['scrollbar_bg'],
                troughcolor=colors['bg_secondary'],
                borderwidth=0,
                arrowcolor=colors['scrollbar_fg']
            )
            
            # Checkbutton styles
            self.style.configure(
                'TCheckbutton',
                background=colors['bg_primary'],
                foreground=colors['text_primary'],
                font=fonts['default'],
                focuscolor=colors['entry_focus']
            )
            
            # Radiobutton styles
            self.style.configure(
                'TRadiobutton',
                background=colors['bg_primary'],
                foreground=colors['text_primary'],
                font=fonts['default'],
                focuscolor=colors['entry_focus']
            )
            
            # Combobox styles
            self.style.configure(
                'TCombobox',
                fieldbackground=colors['entry_bg'],
                foreground=colors['entry_fg'],
                background=colors['entry_bg'],
                bordercolor=colors['entry_border'],
                focuscolor=colors['entry_focus'],
                font=fonts['default']
            )
            
            # Spinbox styles
            self.style.configure(
                'TSpinbox',
                fieldbackground=colors['entry_bg'],
                foreground=colors['entry_fg'],
                background=colors['entry_bg'],
                bordercolor=colors['entry_border'],
                focuscolor=colors['entry_focus'],
                font=fonts['default']
            )
            
        except Exception as e:
            self.logger.error(f"Error applying TTK styles: {e}")
    
    def _apply_tk_styles(self, theme_data: Dict):
        """Apply styles to standard TK widgets"""
        try:
            colors = theme_data['colors']
            fonts = theme_data['fonts']
            
            if self.root_window:
                # Configure root window
                self.root_window.configure(bg=colors['bg_primary'])
                
                # Set default options for all widgets
                self.root_window.option_add('*Background', colors['bg_primary'])
                self.root_window.option_add('*Foreground', colors['text_primary'])
                self.root_window.option_add('*Font', fonts['default'])
                
                # Listbox specific options
                self.root_window.option_add('*Listbox*Background', colors['listbox_bg'])
                self.root_window.option_add('*Listbox*Foreground', colors['listbox_fg'])
                self.root_window.option_add('*Listbox*SelectBackground', colors['listbox_select'])
                
                # Text widget options
                self.root_window.option_add('*Text*Background', colors['entry_bg'])
                self.root_window.option_add('*Text*Foreground', colors['entry_fg'])
                
                # Menu options
                self.root_window.option_add('*Menu*Background', colors['menu_bg'])
                self.root_window.option_add('*Menu*Foreground', colors['menu_fg'])
                self.root_window.option_add('*Menu*SelectColor', colors['menu_select'])
            
        except Exception as e:
            self.logger.error(f"Error applying TK styles: {e}")
    
    def _update_registered_widgets(self, theme_data: Dict):
        """Update all registered widgets with new theme"""
        try:
            colors = theme_data['colors']
            fonts = theme_data['fonts']
            
            for widget_info in self.registered_widgets:
                widget = widget_info['widget']
                widget_type = widget_info['type']
                custom_config = widget_info.get('config', {})
                
                try:
                    if widget.winfo_exists():
                        if widget_type == 'Frame':
                            widget.configure(
                                bg=custom_config.get('bg', colors['frame_bg']),
                                **custom_config
                            )
                        elif widget_type == 'Label':
                            widget.configure(
                                bg=custom_config.get('bg', colors['bg_primary']),
                                fg=custom_config.get('fg', colors['text_primary']),
                                font=custom_config.get('font', fonts['default']),
                                **{k: v for k, v in custom_config.items() if k not in ['bg', 'fg', 'font']}
                            )
                        elif widget_type == 'Button':
                            widget.configure(
                                bg=custom_config.get('bg', colors['button_bg']),
                                fg=custom_config.get('fg', colors['button_fg']),
                                font=custom_config.get('font', fonts['default']),
                                **{k: v for k, v in custom_config.items() if k not in ['bg', 'fg', 'font']}
                            )
                        elif widget_type == 'Entry':
                            widget.configure(
                                bg=custom_config.get('bg', colors['entry_bg']),
                                fg=custom_config.get('fg', colors['entry_fg']),
                                font=custom_config.get('font', fonts['default']),
                                **{k: v for k, v in custom_config.items() if k not in ['bg', 'fg', 'font']}
                            )
                        elif widget_type == 'Text':
                            widget.configure(
                                bg=custom_config.get('bg', colors['entry_bg']),
                                fg=custom_config.get('fg', colors['entry_fg']),
                                font=custom_config.get('font', fonts['default']),
                                **{k: v for k, v in custom_config.items() if k not in ['bg', 'fg', 'font']}
                            )
                        elif widget_type == 'Listbox':
                            widget.configure(
                                bg=custom_config.get('bg', colors['listbox_bg']),
                                fg=custom_config.get('fg', colors['listbox_fg']),
                                selectbackground=custom_config.get('selectbackground', colors['listbox_select']),
                                font=custom_config.get('font', fonts['default']),
                                **{k: v for k, v in custom_config.items() if k not in ['bg', 'fg', 'selectbackground', 'font']}
                            )
                        # Add more widget types as needed
                        
                except Exception as e:
                    self.logger.warning(f"Could not update widget {widget}: {e}")
            
        except Exception as e:
            self.logger.error(f"Error updating registered widgets: {e}")
    
    def register_widget(self, widget, widget_type: str, custom_config: Optional[Dict] = None):
        """Register a widget for theme updates"""
        try:
            self.registered_widgets.append({
                'widget': widget,
                'type': widget_type,
                'config': custom_config or {}
            })
            
            # Apply current theme immediately
            if self.current_theme in self.themes:
                theme_data = self.themes[self.current_theme]
                self._update_registered_widgets(theme_data)
            
        except Exception as e:
            self.logger.error(f"Error registering widget: {e}")
    
    def register_callback(self, callback: Callable):
        """Register a callback for theme changes"""
        try:
            self.registered_callbacks.append(callback)
        except Exception as e:
            self.logger.error(f"Error registering callback: {e}")
    
    def create_custom_theme(self, name: str, base_theme: ThemeType = ThemeType.LIGHT):
        """Create a new custom theme based on existing theme"""
        try:
            if base_theme not in self.themes:
                raise ValueError(f"Base theme {base_theme} not found")
            
            # Copy base theme
            base_data = self.themes[base_theme].copy()
            
            # Create custom theme
            custom_theme = {
                'name': name,
                'description': f'Custom theme based on {base_data["name"]}',
                'colors': base_data['colors'].copy(),
                'fonts': base_data['fonts'].copy(),
                'created': datetime.now().isoformat()
            }
            
            self.custom_themes[name] = custom_theme
            self._save_custom_themes()
            
            self.logger.info(f"Created custom theme: {name}")
            return True
            
        except Exception as e:
            self.logger.error(f"Error creating custom theme: {e}")
            return False
    
    def edit_custom_theme(self, name: str) -> bool:
        """Edit a custom theme"""
        try:
            if name not in self.custom_themes:
                raise ValueError(f"Custom theme '{name}' not found")
            
            theme_data = self.custom_themes[name]
            
            # Create theme editor window
            self._show_theme_editor(name, theme_data)
            return True
            
        except Exception as e:
            self.logger.error(f"Error editing custom theme: {e}")
            return False
    
    def _show_theme_editor(self, theme_name: str, theme_data: Dict):
        """Show theme editor window"""
        editor_window = tk.Toplevel()
        editor_window.title(f"Edit Theme: {theme_name}")
        editor_window.geometry("600x500")
        editor_window.resizable(True, True)
        
        # Main notebook
        notebook = ttk.Notebook(editor_window)
        notebook.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Colors tab
        colors_frame = ttk.Frame(notebook)
        notebook.add(colors_frame, text="Colors")
        
        # Create color editor
        self._create_color_editor(colors_frame, theme_data['colors'])
        
        # Fonts tab
        fonts_frame = ttk.Frame(notebook)
        notebook.add(fonts_frame, text="Fonts")
        
        # Create font editor
        self._create_font_editor(fonts_frame, theme_data['fonts'])
        
        # Preview tab
        preview_frame = ttk.Frame(notebook)
        notebook.add(preview_frame, text="Preview")
        
        # Create preview
        self._create_theme_preview(preview_frame, theme_data)
        
        # Buttons
        button_frame = ttk.Frame(editor_window)
        button_frame.pack(fill=tk.X, padx=10, pady=5)
        
        def save_theme():
            self.custom_themes[theme_name] = theme_data
            self._save_custom_themes()
            messagebox.showinfo("Theme Saved", f"Theme '{theme_name}' saved successfully")
            editor_window.destroy()
        
        def apply_theme():
            self.apply_theme(ThemeType.CUSTOM, theme_name)
            messagebox.showinfo("Theme Applied", f"Theme '{theme_name}' applied successfully")
        
        ttk.Button(button_frame, text="Save", command=save_theme).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="Apply", command=apply_theme).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="Cancel", command=editor_window.destroy).pack(side=tk.RIGHT, padx=5)
        
        # Center window
        editor_window.transient()
        editor_window.grab_set()
    
    def _create_color_editor(self, parent: tk.Widget, colors: Dict):
        """Create color editor interface"""
        # Scrollable frame
        canvas = tk.Canvas(parent)
        scrollbar = ttk.Scrollbar(parent, orient=tk.VERTICAL, command=canvas.yview)
        scrollable_frame = ttk.Frame(canvas)
        
        scrollable_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )
        
        canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)
        
        # Color entries
        color_vars = {}
        row = 0
        
        for color_name, color_value in colors.items():
            # Label
            ttk.Label(scrollable_frame, text=color_name.replace('_', ' ').title()).grid(
                row=row, column=0, sticky=tk.W, padx=5, pady=2
            )
            
            # Color entry
            color_var = tk.StringVar(value=color_value)
            color_vars[color_name] = color_var
            
            entry_frame = ttk.Frame(scrollable_frame)
            entry_frame.grid(row=row, column=1, sticky=tk.EW, padx=5, pady=2)
            
            color_entry = ttk.Entry(entry_frame, textvariable=color_var, width=10)
            color_entry.pack(side=tk.LEFT, padx=(0, 5))
            
            # Color preview
            color_preview = tk.Frame(entry_frame, width=30, height=20, bg=color_value)
            color_preview.pack(side=tk.LEFT, padx=(0, 5))
            
            # Color picker button
            def pick_color(name=color_name, var=color_var, preview=color_preview):
                color = colorchooser.askcolor(initialcolor=var.get())[1]
                if color:
                    var.set(color)
                    preview.configure(bg=color)
                    colors[name] = color
            
            ttk.Button(entry_frame, text="Pick", command=pick_color).pack(side=tk.LEFT)
            
            # Bind entry changes
            def on_color_change(name=color_name, var=color_var, preview=color_preview):
                try:
                    color = var.get()
                    preview.configure(bg=color)
                    colors[name] = color
                except:
                    pass
            
            color_var.trace('w', lambda *args, callback=on_color_change: callback())
            
            row += 1
        
        scrollable_frame.columnconfigure(1, weight=1)
        
        canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
    
    def _create_font_editor(self, parent: tk.Widget, fonts: Dict):
        """Create font editor interface"""
        row = 0
        
        for font_name, font_value in fonts.items():
            # Label
            ttk.Label(parent, text=font_name.replace('_', ' ').title()).grid(
                row=row, column=0, sticky=tk.W, padx=5, pady=5
            )
            
            # Font frame
            font_frame = ttk.Frame(parent)
            font_frame.grid(row=row, column=1, sticky=tk.EW, padx=5, pady=5)
            
            # Family
            family_var = tk.StringVar(value=font_value[0] if font_value else 'Segoe UI')
            ttk.Label(font_frame, text="Family:").pack(side=tk.LEFT, padx=(0, 5))
            family_combo = ttk.Combobox(font_frame, textvariable=family_var, 
                                       values=['Segoe UI', 'Arial', 'Consolas', 'Times New Roman'],
                                       width=15)
            family_combo.pack(side=tk.LEFT, padx=(0, 10))
            
            # Size
            size_var = tk.IntVar(value=font_value[1] if len(font_value) > 1 else 9)
            ttk.Label(font_frame, text="Size:").pack(side=tk.LEFT, padx=(0, 5))
            size_spin = ttk.Spinbox(font_frame, textvariable=size_var, from_=6, to=20, width=5)
            size_spin.pack(side=tk.LEFT, padx=(0, 10))
            
            # Style
            style_var = tk.StringVar(value=font_value[2] if len(font_value) > 2 else 'normal')
            ttk.Label(font_frame, text="Style:").pack(side=tk.LEFT, padx=(0, 5))
            style_combo = ttk.Combobox(font_frame, textvariable=style_var,
                                      values=['normal', 'bold', 'italic', 'bold italic'],
                                      width=10)
            style_combo.pack(side=tk.LEFT)
            
            # Update font function
            def update_font(name=font_name):
                if style_var.get() == 'normal':
                    new_font = (family_var.get(), size_var.get())
                else:
                    new_font = (family_var.get(), size_var.get(), style_var.get())
                fonts[name] = new_font
            
            # Bind changes
            family_var.trace('w', lambda *args, callback=update_font: callback())
            size_var.trace('w', lambda *args, callback=update_font: callback())
            style_var.trace('w', lambda *args, callback=update_font: callback())
            
            row += 1
        
        parent.columnconfigure(1, weight=1)
    
    def _create_theme_preview(self, parent: tk.Widget, theme_data: Dict):
        """Create theme preview"""
        colors = theme_data['colors']
        fonts = theme_data['fonts']
        
        # Preview frame
        preview_frame = ttk.LabelFrame(parent, text="Theme Preview")
        preview_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Sample widgets
        ttk.Label(preview_frame, text="Sample Heading", font=fonts['heading']).pack(pady=5)
        ttk.Label(preview_frame, text="Sample text content", font=fonts['default']).pack(pady=2)
        
        button_frame = ttk.Frame(preview_frame)
        button_frame.pack(pady=10)
        
        ttk.Button(button_frame, text="Sample Button").pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="Disabled", state=tk.DISABLED).pack(side=tk.LEFT, padx=5)
        
        entry_frame = ttk.Frame(preview_frame)
        entry_frame.pack(pady=5, fill=tk.X, padx=20)
        
        ttk.Label(entry_frame, text="Sample Entry:").pack(side=tk.LEFT)
        sample_text = tk.StringVar(value="Sample text")
        ttk.Entry(entry_frame, textvariable=sample_text).pack(side=tk.LEFT, padx=5, fill=tk.X, expand=True)
        
        # Progress bar
        progress = ttk.Progressbar(preview_frame, value=75)
        progress.pack(pady=10, padx=20, fill=tk.X)
        
        # Sample listbox
        listbox_frame = ttk.LabelFrame(preview_frame, text="Sample List")
        listbox_frame.pack(pady=5, padx=20, fill=tk.BOTH, expand=True)
        
        listbox = tk.Listbox(listbox_frame, height=4)
        listbox.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        
        for i in range(5):
            listbox.insert(tk.END, f"Sample item {i + 1}")
    
    def get_available_themes(self) -> List[str]:
        """Get list of available themes"""
        builtin_themes = [theme.value for theme in ThemeType if theme != ThemeType.CUSTOM]
        custom_themes = list(self.custom_themes.keys())
        return builtin_themes + custom_themes
    
    def get_current_theme(self) -> Tuple[ThemeType, Optional[str]]:
        """Get current theme information"""
        return self.current_theme, None
    
    def get_theme_data(self, theme_type: ThemeType, theme_name: Optional[str] = None) -> Optional[Dict]:
        """Get theme data"""
        try:
            if theme_type == ThemeType.CUSTOM and theme_name:
                return self.custom_themes.get(theme_name)
            else:
                return self.themes.get(theme_type)
        except Exception as e:
            self.logger.error(f"Error getting theme data: {e}")
            return None
    
    def delete_custom_theme(self, theme_name: str) -> bool:
        """Delete a custom theme"""
        try:
            if theme_name in self.custom_themes:
                del self.custom_themes[theme_name]
                self._save_custom_themes()
                self.logger.info(f"Deleted custom theme: {theme_name}")
                return True
            return False
        except Exception as e:
            self.logger.error(f"Error deleting custom theme: {e}")
            return False
    
    def export_theme(self, theme_name: str, file_path: str) -> bool:
        """Export a custom theme to file"""
        try:
            if theme_name not in self.custom_themes:
                return False
            
            theme_data = self.custom_themes[theme_name]
            
            with open(file_path, 'w') as f:
                json.dump(theme_data, f, indent=2)
            
            self.logger.info(f"Exported theme {theme_name} to {file_path}")
            return True
            
        except Exception as e:
            self.logger.error(f"Error exporting theme: {e}")
            return False
    
    def import_theme(self, file_path: str) -> bool:
        """Import a theme from file"""
        try:
            with open(file_path, 'r') as f:
                theme_data = json.load(f)
            
            theme_name = theme_data.get('name', 'Imported Theme')
            
            # Ensure unique name
            original_name = theme_name
            counter = 1
            while theme_name in self.custom_themes:
                theme_name = f"{original_name} ({counter})"
                counter += 1
            
            theme_data['name'] = theme_name
            self.custom_themes[theme_name] = theme_data
            self._save_custom_themes()
            
            self.logger.info(f"Imported theme: {theme_name}")
            return True
            
        except Exception as e:
            self.logger.error(f"Error importing theme: {e}")
            return False

# Example usage
def main():
    """Example usage of the Theme Manager"""
    root = tk.Tk()
    root.title("Theme Manager Demo")
    root.geometry("600x400")
    
    # Create theme manager
    theme_manager = ThemeManager(root)
    
    # Create sample interface
    main_frame = ttk.Frame(root)
    main_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
    
    # Theme selection
    theme_frame = ttk.LabelFrame(main_frame, text="Theme Selection")
    theme_frame.pack(fill=tk.X, pady=(0, 10))
    
    theme_var = tk.StringVar(value="light")
    
    def apply_selected_theme():
        theme_name = theme_var.get()
        if theme_name == "light":
            theme_manager.apply_theme(ThemeType.LIGHT)
        elif theme_name == "dark":
            theme_manager.apply_theme(ThemeType.DARK)
    
    ttk.Radiobutton(theme_frame, text="Light Theme", variable=theme_var, 
                   value="light", command=apply_selected_theme).pack(side=tk.LEFT, padx=10, pady=5)
    ttk.Radiobutton(theme_frame, text="Dark Theme", variable=theme_var, 
                   value="dark", command=apply_selected_theme).pack(side=tk.LEFT, padx=10, pady=5)
    
    # Sample content
    content_frame = ttk.LabelFrame(main_frame, text="Sample Content")
    content_frame.pack(fill=tk.BOTH, expand=True)
    
    ttk.Label(content_frame, text="Sample Heading", font=("Arial", 14, "bold")).pack(pady=10)
    ttk.Label(content_frame, text="This is sample content to demonstrate theming.").pack(pady=5)
    
    button_frame = ttk.Frame(content_frame)
    button_frame.pack(pady=10)
    
    ttk.Button(button_frame, text="Sample Button").pack(side=tk.LEFT, padx=5)
    ttk.Button(button_frame, text="Another Button").pack(side=tk.LEFT, padx=5)
    
    entry_frame = ttk.Frame(content_frame)
    entry_frame.pack(pady=10, fill=tk.X, padx=20)
    
    ttk.Label(entry_frame, text="Sample Entry:").pack(side=tk.LEFT)
    ttk.Entry(entry_frame).pack(side=tk.LEFT, padx=5, fill=tk.X, expand=True)
    
    # Register some widgets for theme updates
    theme_manager.register_widget(content_frame, 'Frame')
    
    root.mainloop()

if __name__ == "__main__":
    main()