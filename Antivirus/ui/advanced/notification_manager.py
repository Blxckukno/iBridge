"""
Notification Manager
Handles all notification types and delivery methods for the antivirus system
"""

import tkinter as tk
from tkinter import ttk
import threading
import time
import logging
import queue
import json
import os
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Callable
from enum import Enum

try:
    import plyer
    from plyer import notification
    PLYER_AVAILABLE = True
except ImportError:
    notification = None
    PLYER_AVAILABLE = False

try:
    import win10toast
    WIN10TOAST_AVAILABLE = True
except ImportError:
    win10toast = None
    WIN10TOAST_AVAILABLE = False

class NotificationType(Enum):
    """Notification types"""
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    SUCCESS = "success"
    THREAT = "threat"
    UPDATE = "update"
    SCAN = "scan"
    SYSTEM = "system"

class NotificationPriority(Enum):
    """Notification priorities"""
    LOW = 1
    NORMAL = 2
    HIGH = 3
    CRITICAL = 4

class NotificationMethod(Enum):
    """Notification delivery methods"""
    TOAST = "toast"
    POPUP = "popup"
    BALLOON = "balloon"
    LOG_ONLY = "log_only"
    ALL = "all"

class NotificationManager:
    """
    Notification Manager
    Centralized notification system with multiple delivery methods
    """
    
    def __init__(self, antivirus_manager=None):
        self.antivirus_manager = antivirus_manager
        self.running = False
        
        # Initialize logging
        self.logger = logging.getLogger(__name__)
        
        # Notification queue
        self.notification_queue = queue.PriorityQueue()
        self.notification_history = []
        
        # Settings
        self.settings = {
            'enabled': True,
            'show_toast': True,
            'show_popup': True,
            'show_balloon': True,
            'play_sound': True,
            'log_notifications': True,
            'max_history': 1000,
            'toast_duration': 5,
            'popup_duration': 10,
            'critical_always_show': True,
            'do_not_disturb': False,
            'quiet_hours_enabled': False,
            'quiet_hours_start': "22:00",
            'quiet_hours_end': "08:00",
            'filter_duplicates': True,
            'duplicate_timeout': 60,  # seconds
            'priority_threshold': NotificationPriority.NORMAL
        }
        
        # Recent notifications for duplicate filtering
        self.recent_notifications = {}
        
        # Notification statistics
        self.stats = {
            'total_sent': 0,
            'total_displayed': 0,
            'total_suppressed': 0,
            'by_type': {ntype.value: 0 for ntype in NotificationType},
            'by_priority': {priority.name: 0 for priority in NotificationPriority}
        }
        
        # Active popup windows
        self.active_popups = []
        
        # Toast notification handler
        self.toast_handler = None
        if WIN10TOAST_AVAILABLE and win10toast:
            try:
                self.toast_handler = win10toast.ToastNotifier()
            except Exception as e:
                self.logger.warning(f"Failed to initialize Windows toast handler: {e}")
        
        self.logger.info("Notification Manager initialized")
    
    def start(self):
        """Start the notification manager"""
        if self.running:
            return True
        
        self.running = True
        
        # Start notification processing thread
        process_thread = threading.Thread(target=self._process_notifications, daemon=True)
        process_thread.start()
        
        # Start cleanup thread
        cleanup_thread = threading.Thread(target=self._cleanup_expired, daemon=True)
        cleanup_thread.start()
        
        self.logger.info("Notification Manager started")
        return True
    
    def stop(self):
        """Stop the notification manager"""
        self.running = False
        
        # Close any active popups
        for popup in self.active_popups:
            try:
                popup.destroy()
            except:
                pass
        self.active_popups.clear()
        
        self.logger.info("Notification Manager stopped")
    
    def send_notification(self, 
                         title: str, 
                         message: str, 
                         notification_type: NotificationType = NotificationType.INFO,
                         priority: NotificationPriority = NotificationPriority.NORMAL,
                         method: NotificationMethod = NotificationMethod.ALL,
                         duration: Optional[int] = None,
                         actions: Optional[List[Dict]] = None,
                         data: Optional[Dict] = None):
        """Send a notification"""
        try:
            # Check if notifications are enabled
            if not self.settings['enabled'] and priority != NotificationPriority.CRITICAL:
                return False
            
            # Check priority threshold
            if priority.value < self.settings['priority_threshold'].value:
                self.stats['total_suppressed'] += 1
                return False
            
            # Check do not disturb mode
            if self.settings['do_not_disturb'] and priority != NotificationPriority.CRITICAL:
                self.stats['total_suppressed'] += 1
                return False
            
            # Check quiet hours
            if self._is_quiet_hours() and priority != NotificationPriority.CRITICAL:
                self.stats['total_suppressed'] += 1
                return False
            
            # Check for duplicates
            if self.settings['filter_duplicates']:
                notification_key = f"{title}:{message}"
                current_time = time.time()
                
                if notification_key in self.recent_notifications:
                    last_time = self.recent_notifications[notification_key]
                    if current_time - last_time < self.settings['duplicate_timeout']:
                        self.stats['total_suppressed'] += 1
                        return False
                
                self.recent_notifications[notification_key] = current_time
            
            # Create notification object
            notification_obj = {
                'id': f"notif_{int(time.time() * 1000)}",
                'title': title,
                'message': message,
                'type': notification_type,
                'priority': priority,
                'method': method,
                'duration': duration or self._get_default_duration(notification_type),
                'actions': actions or [],
                'data': data or {},
                'timestamp': datetime.now(),
                'delivered': False,
                'dismissed': False
            }
            
            # Add to queue with priority
            self.notification_queue.put((priority.value * -1, notification_obj))  # Negative for descending order
            
            # Update statistics
            self.stats['total_sent'] += 1
            self.stats['by_type'][notification_type.value] += 1
            self.stats['by_priority'][priority.name] += 1
            
            self.logger.info(f"Notification queued: {title} ({notification_type.value}, {priority.name})")
            return True
            
        except Exception as e:
            self.logger.error(f"Error sending notification: {e}")
            return False
    
    def _process_notifications(self):
        """Process notification queue"""
        while self.running:
            try:
                # Get notification from queue with timeout
                try:
                    priority, notification_obj = self.notification_queue.get(timeout=1)
                except queue.Empty:
                    continue
                
                # Deliver notification
                self._deliver_notification(notification_obj)
                
                # Add to history
                self.notification_history.append(notification_obj)
                
                # Limit history size
                if len(self.notification_history) > self.settings['max_history']:
                    self.notification_history = self.notification_history[-self.settings['max_history']:]
                
                # Mark as processed
                self.notification_queue.task_done()
                
            except Exception as e:
                self.logger.error(f"Error processing notification: {e}")
                time.sleep(1)
    
    def _deliver_notification(self, notification_obj: Dict):
        """Deliver notification using specified method"""
        try:
            method = notification_obj['method']
            
            # Always log if enabled
            if self.settings['log_notifications']:
                self._log_notification(notification_obj)
            
            # Deliver using specified methods
            if method == NotificationMethod.ALL:
                success = False
                if self.settings['show_toast']:
                    success |= self._show_toast_notification(notification_obj)
                if self.settings['show_popup']:
                    success |= self._show_popup_notification(notification_obj)
                if self.settings['show_balloon']:
                    success |= self._show_balloon_notification(notification_obj)
            elif method == NotificationMethod.TOAST and self.settings['show_toast']:
                success = self._show_toast_notification(notification_obj)
            elif method == NotificationMethod.POPUP and self.settings['show_popup']:
                success = self._show_popup_notification(notification_obj)
            elif method == NotificationMethod.BALLOON and self.settings['show_balloon']:
                success = self._show_balloon_notification(notification_obj)
            elif method == NotificationMethod.LOG_ONLY:
                success = True  # Already logged above
            else:
                success = False
            
            if success:
                notification_obj['delivered'] = True
                self.stats['total_displayed'] += 1
                
                # Play sound if enabled
                if self.settings['play_sound']:
                    self._play_notification_sound(notification_obj['type'])
            
        except Exception as e:
            self.logger.error(f"Error delivering notification: {e}")
    
    def _show_toast_notification(self, notification_obj: Dict) -> bool:
        """Show toast notification"""
        try:
            title = notification_obj['title']
            message = notification_obj['message']
            duration = notification_obj['duration']
            
            # Try Windows 10 toast first
            if self.toast_handler:
                try:
                    self.toast_handler.show_toast(
                        title=title,
                        msg=message,
                        duration=duration,
                        threaded=True
                    )
                    return True
                except Exception as e:
                    self.logger.warning(f"Windows toast failed: {e}")
            
            # Fallback to plyer
            if PLYER_AVAILABLE and notification is not None and hasattr(notification, 'notify') and callable(notification.notify):
                try:
                    notification.notify(
                        title=title,
                        message=message,
                        timeout=duration,
                        app_name="Antivirus"
                    )
                    return True
                except Exception as e:
                    self.logger.warning(f"Plyer notification failed: {e}")
            
            return False
            
        except Exception as e:
            self.logger.error(f"Error showing toast notification: {e}")
            return False
    
    def _show_popup_notification(self, notification_obj: Dict) -> bool:
        """Show popup notification window"""
        try:
            popup_thread = threading.Thread(
                target=self._create_popup_window, 
                args=(notification_obj,), 
                daemon=True
            )
            popup_thread.start()
            return True
            
        except Exception as e:
            self.logger.error(f"Error showing popup notification: {e}")
            return False
    
    def _create_popup_window(self, notification_obj: Dict):
        """Create popup notification window"""
        try:
            popup = tk.Toplevel()
            popup.withdraw()  # Hide initially
            
            # Configure popup
            popup.title("Antivirus Notification")
            popup.geometry("400x200")
            popup.resizable(False, False)
            popup.attributes('-topmost', True)
            
            # Remove window decorations for clean look
            popup.overrideredirect(True)
            
            # Get notification data
            title = notification_obj['title']
            message = notification_obj['message']
            notification_type = notification_obj['type']
            duration = notification_obj['duration']
            actions = notification_obj['actions']
            
            # Main frame with border
            main_frame = tk.Frame(popup, relief=tk.RAISED, borderwidth=2)
            main_frame.pack(fill=tk.BOTH, expand=True)
            
            # Header frame
            header_frame = tk.Frame(main_frame, bg=self._get_type_color(notification_type))
            header_frame.pack(fill=tk.X)
            
            # Icon and title
            icon_label = tk.Label(header_frame, text=self._get_type_icon(notification_type), 
                                 font=("Arial", 16), bg=header_frame['bg'], fg="white")
            icon_label.pack(side=tk.LEFT, padx=10, pady=5)
            
            title_label = tk.Label(header_frame, text=title, font=("Arial", 12, "bold"), 
                                  bg=header_frame['bg'], fg="white")
            title_label.pack(side=tk.LEFT, padx=(0, 10), pady=5)
            
            # Close button
            close_button = tk.Button(header_frame, text="✕", font=("Arial", 10), 
                                   bg=header_frame['bg'], fg="white", border=0,
                                   command=lambda: self._close_popup(popup))
            close_button.pack(side=tk.RIGHT, padx=10, pady=5)
            
            # Content frame
            content_frame = tk.Frame(main_frame, bg="white")
            content_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
            
            # Message
            message_label = tk.Label(content_frame, text=message, font=("Arial", 10), 
                                   bg="white", wraplength=350, justify=tk.LEFT)
            message_label.pack(anchor=tk.W, pady=(0, 10))
            
            # Timestamp
            timestamp_text = notification_obj['timestamp'].strftime("%H:%M:%S")
            timestamp_label = tk.Label(content_frame, text=timestamp_text, 
                                     font=("Arial", 8), bg="white", fg="gray")
            timestamp_label.pack(anchor=tk.W)
            
            # Action buttons
            if actions:
                button_frame = tk.Frame(content_frame, bg="white")
                button_frame.pack(fill=tk.X, pady=(10, 0))
                
                for action in actions:
                    btn = tk.Button(button_frame, text=action.get('text', 'Action'),
                                   command=lambda a=action: self._handle_action(a, popup))
                    btn.pack(side=tk.LEFT, padx=5)
            
            # Position popup (bottom-right corner)
            popup.update_idletasks()
            screen_width = popup.winfo_screenwidth()
            screen_height = popup.winfo_screenheight()
            popup_width = popup.winfo_width()
            popup_height = popup.winfo_height()
            
            x = screen_width - popup_width - 20
            y = screen_height - popup_height - 50 - (len(self.active_popups) * (popup_height + 10))
            
            popup.geometry(f"{popup_width}x{popup_height}+{x}+{y}")
            popup.deiconify()  # Show popup
            
            # Add to active popups
            self.active_popups.append(popup)
            
            # Auto-close after duration
            popup.after(duration * 1000, lambda: self._close_popup(popup))
            
        except Exception as e:
            self.logger.error(f"Error creating popup window: {e}")
    
    def _show_balloon_notification(self, notification_obj: Dict) -> bool:
        """Show balloon notification (system tray)"""
        try:
            # This would integrate with system tray if available
            if self.antivirus_manager and hasattr(self.antivirus_manager, 'system_tray'):
                # Use system tray for balloon notifications
                tray = self.antivirus_manager.system_tray
                if tray:
                    tray.add_notification(
                        notification_obj['title'],
                        notification_obj['message'],
                        notification_obj['type'].value
                    )
                    return True
            
            return False
            
        except Exception as e:
            self.logger.error(f"Error showing balloon notification: {e}")
            return False
    
    def _log_notification(self, notification_obj: Dict):
        """Log notification to system log"""
        try:
            log_level = self._get_log_level(notification_obj['type'])
            log_message = f"NOTIFICATION [{notification_obj['type'].value.upper()}] {notification_obj['title']}: {notification_obj['message']}"
            
            if log_level == logging.DEBUG:
                self.logger.debug(log_message)
            elif log_level == logging.INFO:
                self.logger.info(log_message)
            elif log_level == logging.WARNING:
                self.logger.warning(log_message)
            elif log_level == logging.ERROR:
                self.logger.error(log_message)
            elif log_level == logging.CRITICAL:
                self.logger.critical(log_message)
            
        except Exception as e:
            self.logger.error(f"Error logging notification: {e}")
    
    def _cleanup_expired(self):
        """Clean up expired notifications and data"""
        while self.running:
            try:
                current_time = time.time()
                
                # Clean recent notifications cache
                expired_keys = []
                for key, timestamp in self.recent_notifications.items():
                    if current_time - timestamp > self.settings['duplicate_timeout']:
                        expired_keys.append(key)
                
                for key in expired_keys:
                    del self.recent_notifications[key]
                
                # Clean up dismissed popups
                active_popups = []
                for popup in self.active_popups:
                    try:
                        if popup.winfo_exists():
                            active_popups.append(popup)
                    except:
                        pass  # Popup already destroyed
                
                self.active_popups = active_popups
                
                time.sleep(60)  # Clean every minute
                
            except Exception as e:
                self.logger.error(f"Error in cleanup: {e}")
                time.sleep(60)
    
    def _close_popup(self, popup):
        """Close popup notification"""
        try:
            if popup in self.active_popups:
                self.active_popups.remove(popup)
            popup.destroy()
        except Exception as e:
            self.logger.error(f"Error closing popup: {e}")
    
    def _handle_action(self, action: Dict, popup):
        """Handle notification action"""
        try:
            action_type = action.get('type', 'close')
            callback = action.get('callback')
            
            if callback and callable(callback):
                callback()
            
            if action_type != 'keep_open':
                self._close_popup(popup)
                
        except Exception as e:
            self.logger.error(f"Error handling action: {e}")
    
    def _play_notification_sound(self, notification_type: NotificationType):
        """Play notification sound"""
        try:
            # Use different sounds for different types
            if notification_type == NotificationType.ERROR:
                sound_file = "error.wav"
            elif notification_type == NotificationType.WARNING:
                sound_file = "warning.wav"
            elif notification_type == NotificationType.THREAT:
                sound_file = "threat.wav"
            else:
                sound_file = "notification.wav"
            
            # Try to play sound (would need sound files)
            # For now, just use system beep
            import winsound
            if notification_type in [NotificationType.ERROR, NotificationType.THREAT]:
                winsound.MessageBeep(winsound.MB_ICONHAND)
            elif notification_type == NotificationType.WARNING:
                winsound.MessageBeep(winsound.MB_ICONEXCLAMATION)
            else:
                winsound.MessageBeep(winsound.MB_ICONASTERISK)
                
        except Exception as e:
            self.logger.warning(f"Could not play notification sound: {e}")
    
    def _get_default_duration(self, notification_type: NotificationType) -> int:
        """Get default duration for notification type"""
        if notification_type in [NotificationType.ERROR, NotificationType.THREAT]:
            return self.settings['popup_duration']
        else:
            return self.settings['toast_duration']
    
    def _get_type_color(self, notification_type: NotificationType) -> str:
        """Get color for notification type"""
        colors = {
            NotificationType.INFO: "#2196F3",
            NotificationType.SUCCESS: "#4CAF50",
            NotificationType.WARNING: "#FF9800",
            NotificationType.ERROR: "#F44336",
            NotificationType.THREAT: "#D32F2F",
            NotificationType.UPDATE: "#9C27B0",
            NotificationType.SCAN: "#00BCD4",
            NotificationType.SYSTEM: "#607D8B"
        }
        return colors.get(notification_type, "#2196F3")
    
    def _get_type_icon(self, notification_type: NotificationType) -> str:
        """Get icon for notification type"""
        icons = {
            NotificationType.INFO: "ℹ",
            NotificationType.SUCCESS: "✓",
            NotificationType.WARNING: "⚠",
            NotificationType.ERROR: "✗",
            NotificationType.THREAT: "🛡",
            NotificationType.UPDATE: "↓",
            NotificationType.SCAN: "🔍",
            NotificationType.SYSTEM: "⚙"
        }
        return icons.get(notification_type, "ℹ")
    
    def _get_log_level(self, notification_type: NotificationType) -> int:
        """Get log level for notification type"""
        levels = {
            NotificationType.INFO: logging.INFO,
            NotificationType.SUCCESS: logging.INFO,
            NotificationType.WARNING: logging.WARNING,
            NotificationType.ERROR: logging.ERROR,
            NotificationType.THREAT: logging.CRITICAL,
            NotificationType.UPDATE: logging.INFO,
            NotificationType.SCAN: logging.INFO,
            NotificationType.SYSTEM: logging.INFO
        }
        return levels.get(notification_type, logging.INFO)
    
    def _is_quiet_hours(self) -> bool:
        """Check if currently in quiet hours"""
        if not self.settings['quiet_hours_enabled']:
            return False
        
        try:
            current_time = datetime.now().time()
            start_time = datetime.strptime(self.settings['quiet_hours_start'], "%H:%M").time()
            end_time = datetime.strptime(self.settings['quiet_hours_end'], "%H:%M").time()
            
            if start_time <= end_time:
                # Same day
                return start_time <= current_time <= end_time
            else:
                # Overnight
                return current_time >= start_time or current_time <= end_time
                
        except Exception as e:
            self.logger.error(f"Error checking quiet hours: {e}")
            return False
    
    # Convenience methods for common notification types
    def info(self, title: str, message: str, **kwargs):
        """Send info notification"""
        return self.send_notification(title, message, NotificationType.INFO, **kwargs)
    
    def success(self, title: str, message: str, **kwargs):
        """Send success notification"""
        return self.send_notification(title, message, NotificationType.SUCCESS, **kwargs)
    
    def warning(self, title: str, message: str, **kwargs):
        """Send warning notification"""
        return self.send_notification(title, message, NotificationType.WARNING, 
                                    NotificationPriority.HIGH, **kwargs)
    
    def error(self, title: str, message: str, **kwargs):
        """Send error notification"""
        return self.send_notification(title, message, NotificationType.ERROR, 
                                    NotificationPriority.HIGH, **kwargs)
    
    def threat(self, title: str, message: str, **kwargs):
        """Send threat notification"""
        return self.send_notification(title, message, NotificationType.THREAT, 
                                    NotificationPriority.CRITICAL, **kwargs)
    
    def update(self, title: str, message: str, **kwargs):
        """Send update notification"""
        return self.send_notification(title, message, NotificationType.UPDATE, **kwargs)
    
    def scan(self, title: str, message: str, **kwargs):
        """Send scan notification"""
        return self.send_notification(title, message, NotificationType.SCAN, **kwargs)
    
    def system(self, title: str, message: str, **kwargs):
        """Send system notification"""
        return self.send_notification(title, message, NotificationType.SYSTEM, **kwargs)
    
    # Settings management
    def update_settings(self, new_settings: Dict):
        """Update notification settings"""
        try:
            self.settings.update(new_settings)
            self.logger.info("Notification settings updated")
        except Exception as e:
            self.logger.error(f"Error updating settings: {e}")
    
    def get_settings(self) -> Dict:
        """Get current notification settings"""
        return self.settings.copy()
    
    def get_statistics(self) -> Dict:
        """Get notification statistics"""
        return {
            'stats': self.stats.copy(),
            'queue_size': self.notification_queue.qsize(),
            'history_size': len(self.notification_history),
            'active_popups': len(self.active_popups),
            'recent_notifications': len(self.recent_notifications)
        }
    
    def get_notification_history(self, limit: Optional[int] = None) -> List[Dict]:
        """Get notification history"""
        history = self.notification_history.copy()
        if limit:
            history = history[-limit:]
        return history
    
    def clear_history(self):
        """Clear notification history"""
        self.notification_history.clear()
        self.logger.info("Notification history cleared")
    
    def dismiss_all_popups(self):
        """Dismiss all active popup notifications"""
        for popup in self.active_popups[:]:
            self._close_popup(popup)

# Example usage and testing
def main():
    """Example usage of the Notification Manager"""
    import time
    
    # Create notification manager
    notification_manager = NotificationManager()
    
    # Start manager
    notification_manager.start()
    
    # Send various types of notifications
    notification_manager.info("System Started", "Antivirus protection is now active")
    time.sleep(1)
    
    notification_manager.warning("Update Available", "New virus definitions are available for download")
    time.sleep(1)
    
    notification_manager.threat("Threat Detected", "Malicious file has been quarantined: trojan.exe")
    time.sleep(1)
    
    notification_manager.success("Scan Complete", "Full system scan completed. No threats found.")
    time.sleep(1)
    
    # Test notification with actions
    actions = [
        {'text': 'View Details', 'type': 'callback', 'callback': lambda: print("View details clicked")},
        {'text': 'Dismiss', 'type': 'close'}
    ]
    
    notification_manager.send_notification(
        "Security Alert",
        "Suspicious network activity detected from 192.168.1.100",
        NotificationType.WARNING,
        NotificationPriority.HIGH,
        actions=actions
    )
    
    # Print statistics
    print("\nNotification Statistics:")
    stats = notification_manager.get_statistics()
    for key, value in stats['stats'].items():
        print(f"  {key}: {value}")
    
    # Keep running for demonstration
    try:
        print("\nNotification manager running... Press Ctrl+C to stop")
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\nStopping notification manager...")
        notification_manager.stop()

if __name__ == "__main__":
    main()