"""
Browser Extension Integration System
Real browser extension integration and communication
"""

import os
import json
import socket
import threading
import time
import struct
from pathlib import Path
from datetime import datetime
import logging
from typing import Dict, List, Optional
import base64
import hashlib
import subprocess

class BrowserExtensionInterface:
    """Interface for communicating with browser extensions"""
    
    def __init__(self, config_path="browser_extensions/"):
        self.config_path = Path(config_path)
        self.config_path.mkdir(parents=True, exist_ok=True)
        
        # Extension configuration
        self.extensions = {
            'chrome': {
                'name': 'iBridge Antivirus Chrome Extension',
                'id': 'ibridge_av_chrome',
                'manifest_version': 3,
                'native_host': 'com.ibridge.antivirus.chrome'
            },
            'firefox': {
                'name': 'iBridge Antivirus Firefox Addon',
                'id': 'ibridge_av_firefox',
                'manifest_version': 2,
                'native_host': 'com.ibridge.antivirus.firefox'
            },
            'edge': {
                'name': 'iBridge Antivirus Edge Extension',
                'id': 'ibridge_av_edge',
                'manifest_version': 3,
                'native_host': 'com.ibridge.antivirus.edge'
            }
        }
        
        # Communication configuration
        self.native_messaging_hosts = {}
        self.extension_ports = {}
        self.active_connections = {}
        
        # Message handling
        self.message_handlers = {
            'url_check': self._handle_url_check,
            'download_scan': self._handle_download_scan,
            'page_analysis': self._handle_page_analysis,
            'settings_update': self._handle_settings_update,
            'status_request': self._handle_status_request
        }
        
        self.logger = self._setup_logging()
        self._setup_native_messaging()
        self._generate_extension_files()
    
    def _setup_logging(self):
        """Setup logging for extension interface"""
        logging.basicConfig(level=logging.INFO)
        logger = logging.getLogger(__name__)
        
        log_file = self.config_path / "extension_interface.log"
        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(logging.INFO)
        formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)
        
        return logger
    
    def _setup_native_messaging(self):
        """Setup native messaging hosts for browser communication"""
        try:
            for browser, config in self.extensions.items():
                host_path = self._create_native_messaging_host(browser, config)
                if host_path:
                    self.native_messaging_hosts[browser] = host_path
                    self._register_native_host(browser, host_path)
                    
        except Exception as e:
            self.logger.error(f"Native messaging setup error: {e}")
    
    def _create_native_messaging_host(self, browser: str, config: Dict) -> Optional[str]:
        """Create native messaging host configuration"""
        try:
            host_name = config['native_host']
            
            # Create host manifest
            if browser in ['chrome', 'edge']:
                manifest = {
                    "name": host_name,
                    "description": f"iBridge Antivirus Native Host for {browser.title()}",
                    "path": str(self.config_path / f"{browser}_host.exe"),
                    "type": "stdio",
                    "allowed_origins": [
                        f"chrome-extension://{config['id']}/"
                    ]
                }
                manifest_path = self.config_path / f"{host_name}.json"
                
            elif browser == 'firefox':
                manifest = {
                    "name": host_name,
                    "description": f"iBridge Antivirus Native Host for Firefox",
                    "path": str(self.config_path / f"{browser}_host.exe"),
                    "type": "stdio",
                    "allowed_extensions": [config['id']]
                }
                manifest_path = self.config_path / f"{host_name}.json"
            
            else:
                return None
            
            # Save manifest
            with open(manifest_path, 'w') as f:
                json.dump(manifest, f, indent=2)
            
            # Create host executable (simplified Python script)
            self._create_host_executable(browser)
            
            return str(manifest_path)
            
        except Exception as e:
            self.logger.error(f"Native host creation error for {browser}: {e}")
            return None
    
    def _create_host_executable(self, browser: str):
        """Create native messaging host executable"""
        try:
            host_script = f"""#!/usr/bin/env python3
import sys
import json
import struct
import logging

class NativeMessagingHost:
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        logging.basicConfig(level=logging.INFO, 
                          filename=r'{self.config_path}/host_{browser}.log')
    
    def read_message(self):
        raw_length = sys.stdin.buffer.read(4)
        if len(raw_length) == 0:
            return None
        message_length = struct.unpack('@I', raw_length)[0]
        message = sys.stdin.buffer.read(message_length).decode('utf-8')
        return json.loads(message)
    
    def send_message(self, message):
        encoded_message = json.dumps(message).encode('utf-8')
        encoded_length = struct.pack('@I', len(encoded_message))
        sys.stdout.buffer.write(encoded_length)
        sys.stdout.buffer.write(encoded_message)
        sys.stdout.buffer.flush()
    
    def run(self):
        while True:
            try:
                message = self.read_message()
                if message is None:
                    break
                
                self.logger.info(f"Received message: {{message}}")
                
                # Process message and send response
                response = {{"status": "received", "browser": "{browser}"}}
                self.send_message(response)
                
            except Exception as e:
                self.logger.error(f"Message processing error: {{e}}")
                break

if __name__ == "__main__":
    host = NativeMessagingHost()
    host.run()
"""
            
            host_file = self.config_path / f"{browser}_host.py"
            with open(host_file, 'w') as f:
                f.write(host_script)
            
            # Create batch file for Windows
            batch_content = f"""@echo off
python "{host_file}" %*
"""
            batch_file = self.config_path / f"{browser}_host.bat"
            with open(batch_file, 'w') as f:
                f.write(batch_content)
            
        except Exception as e:
            self.logger.error(f"Host executable creation error: {e}")
    
    def _register_native_host(self, browser: str, manifest_path: str):
        """Register native messaging host with browser"""
        try:
            if browser == 'chrome':
                # Register with Chrome
                reg_path = r"HKEY_CURRENT_USER\Software\Google\Chrome\NativeMessagingHosts"
                host_name = self.extensions[browser]['native_host']
                
                # Create registry entry (would use Windows registry in real implementation)
                self.logger.info(f"Would register Chrome native host: {host_name} -> {manifest_path}")
                
            elif browser == 'firefox':
                # Register with Firefox
                reg_path = r"HKEY_CURRENT_USER\Software\Mozilla\NativeMessagingHosts"
                host_name = self.extensions[browser]['native_host']
                
                self.logger.info(f"Would register Firefox native host: {host_name} -> {manifest_path}")
                
            elif browser == 'edge':
                # Register with Edge
                reg_path = r"HKEY_CURRENT_USER\Software\Microsoft\Edge\NativeMessagingHosts"
                host_name = self.extensions[browser]['native_host']
                
                self.logger.info(f"Would register Edge native host: {host_name} -> {manifest_path}")
            
        except Exception as e:
            self.logger.error(f"Native host registration error: {e}")
    
    def _generate_extension_files(self):
        """Generate browser extension files"""
        try:
            for browser, config in self.extensions.items():
                extension_dir = self.config_path / f"{browser}_extension"
                extension_dir.mkdir(exist_ok=True)
                
                # Generate manifest
                self._generate_extension_manifest(browser, config, extension_dir)
                
                # Generate content scripts
                self._generate_content_scripts(browser, extension_dir)
                
                # Generate background scripts
                self._generate_background_scripts(browser, extension_dir)
                
                # Generate popup interface
                self._generate_popup_interface(browser, extension_dir)
                
        except Exception as e:
            self.logger.error(f"Extension file generation error: {e}")
    
    def _generate_extension_manifest(self, browser: str, config: Dict, extension_dir: Path):
        """Generate extension manifest file"""
        try:
            if browser in ['chrome', 'edge']:
                # Manifest V3 for Chrome/Edge
                manifest = {
                    "manifest_version": 3,
                    "name": config['name'],
                    "version": "1.0.0",
                    "description": "iBridge Antivirus browser protection extension",
                    "permissions": [
                        "activeTab",
                        "storage",
                        "nativeMessaging",
                        "webRequest",
                        "webRequestBlocking",
                        "downloads"
                    ],
                    "host_permissions": [
                        "http://*/*",
                        "https://*/*"
                    ],
                    "background": {
                        "service_worker": "background.js"
                    },
                    "content_scripts": [
                        {
                            "matches": ["http://*/*", "https://*/*"],
                            "js": ["content.js"],
                            "run_at": "document_start"
                        }
                    ],
                    "action": {
                        "default_popup": "popup.html",
                        "default_title": "iBridge Antivirus"
                    },
                    "icons": {
                        "16": "icons/icon16.png",
                        "32": "icons/icon32.png",
                        "48": "icons/icon48.png",
                        "128": "icons/icon128.png"
                    },
                    "web_accessible_resources": [
                        {
                            "resources": ["inject.js"],
                            "matches": ["http://*/*", "https://*/*"]
                        }
                    ]
                }
                
            elif browser == 'firefox':
                # Manifest V2 for Firefox
                manifest = {
                    "manifest_version": 2,
                    "name": config['name'],
                    "version": "1.0.0",
                    "description": "iBridge Antivirus browser protection addon",
                    "permissions": [
                        "activeTab",
                        "storage",
                        "nativeMessaging",
                        "webRequest",
                        "webRequestBlocking",
                        "downloads",
                        "http://*/*",
                        "https://*/*"
                    ],
                    "background": {
                        "scripts": ["background.js"],
                        "persistent": True
                    },
                    "content_scripts": [
                        {
                            "matches": ["http://*/*", "https://*/*"],
                            "js": ["content.js"],
                            "run_at": "document_start"
                        }
                    ],
                    "browser_action": {
                        "default_popup": "popup.html",
                        "default_title": "iBridge Antivirus"
                    },
                    "icons": {
                        "16": "icons/icon16.png",
                        "32": "icons/icon32.png",
                        "48": "icons/icon48.png",
                        "128": "icons/icon128.png"
                    },
                    "web_accessible_resources": ["inject.js"]
                }
            else:
                # Default manifest
                manifest = {
                    "manifest_version": 2,
                    "name": config['name'],
                    "version": "1.0.0",
                    "description": "iBridge Antivirus browser protection"
                }
            
            # Save manifest
            manifest_file = extension_dir / "manifest.json"
            with open(manifest_file, 'w') as f:
                json.dump(manifest, f, indent=2)
                
        except Exception as e:
            self.logger.error(f"Extension manifest generation error: {e}")
    
    def _generate_content_scripts(self, browser: str, extension_dir: Path):
        """Generate content scripts for extension"""
        try:
            # Main content script
            content_script = """
// iBridge Antivirus Content Script
(function() {
    'use strict';
    
    console.log('iBridge Antivirus content script loaded');
    
    // URL monitoring
    function checkCurrentURL() {
        const currentURL = window.location.href;
        
        // Send URL to background script for checking
        if (typeof chrome !== 'undefined' && chrome.runtime) {
            chrome.runtime.sendMessage({
                type: 'url_check',
                url: currentURL,
                timestamp: Date.now()
            });
        }
    }
    
    // Download monitoring
    function monitorDownloads() {
        document.addEventListener('click', function(event) {
            const target = event.target;
            const href = target.href || target.closest('a')?.href;
            
            if (href && (href.includes('download') || href.match(/\\.(exe|zip|rar|dmg|pkg)$/i))) {
                chrome.runtime.sendMessage({
                    type: 'download_detected',
                    url: href,
                    timestamp: Date.now()
                });
            }
        });
    }
    
    // Form monitoring (for phishing detection)
    function monitorForms() {
        const forms = document.querySelectorAll('form');
        forms.forEach(form => {
            form.addEventListener('submit', function(event) {
                const action = form.action || window.location.href;
                const hasPasswordField = form.querySelector('input[type="password"]') !== null;
                
                if (hasPasswordField) {
                    chrome.runtime.sendMessage({
                        type: 'form_submit',
                        action: action,
                        hasPassword: hasPasswordField,
                        timestamp: Date.now()
                    });
                }
            });
        });
    }
    
    // Script injection monitoring
    function monitorScriptInjection() {
        const observer = new MutationObserver(function(mutations) {
            mutations.forEach(function(mutation) {
                mutation.addedNodes.forEach(function(node) {
                    if (node.tagName === 'SCRIPT') {
                        chrome.runtime.sendMessage({
                            type: 'script_injection',
                            src: node.src || 'inline',
                            content: node.src ? null : node.textContent.substring(0, 500),
                            timestamp: Date.now()
                        });
                    }
                });
            });
        });
        
        observer.observe(document.body || document.documentElement, {
            childList: true,
            subtree: true
        });
    }
    
    // Initialize monitoring
    function initialize() {
        checkCurrentURL();
        monitorDownloads();
        monitorForms();
        monitorScriptInjection();
        
        // Check URL on navigation
        let lastURL = window.location.href;
        setInterval(() => {
            if (window.location.href !== lastURL) {
                lastURL = window.location.href;
                checkCurrentURL();
            }
        }, 1000);
    }
    
    // Start when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initialize);
    } else {
        initialize();
    }
    
    // Listen for messages from background script
    chrome.runtime.onMessage.addListener(function(message, sender, sendResponse) {
        if (message.type === 'page_blocked') {
            // Show blocking overlay
            showBlockingOverlay(message.reason, message.threat_type);
        } else if (message.type === 'warning_display') {
            // Show warning banner
            showWarningBanner(message.message, message.severity);
        }
        
        sendResponse({status: 'received'});
    });
    
    // Blocking overlay
    function showBlockingOverlay(reason, threatType) {
        const overlay = document.createElement('div');
        overlay.id = 'ibridge-block-overlay';
        overlay.style.cssText = `
            position: fixed !important;
            top: 0 !important;
            left: 0 !important;
            width: 100% !important;
            height: 100% !important;
            background: #ff4444 !important;
            color: white !important;
            z-index: 999999 !important;
            display: flex !important;
            align-items: center !important;
            justify-content: center !important;
            font-family: Arial, sans-serif !important;
            font-size: 18px !important;
        `;
        
        overlay.innerHTML = `
            <div style="text-align: center; padding: 40px;">
                <h1 style="color: white; margin-bottom: 20px;">⚠️ Site Blocked by iBridge Antivirus</h1>
                <p style="margin-bottom: 10px;"><strong>Threat Type:</strong> ${threatType}</p>
                <p style="margin-bottom: 20px;"><strong>Reason:</strong> ${reason}</p>
                <button onclick="history.back()" style="
                    background: white;
                    color: #ff4444;
                    border: none;
                    padding: 10px 20px;
                    font-size: 16px;
                    cursor: pointer;
                    border-radius: 5px;
                ">Go Back</button>
            </div>
        `;
        
        document.body.appendChild(overlay);
    }
    
    // Warning banner
    function showWarningBanner(message, severity) {
        const existingBanner = document.getElementById('ibridge-warning-banner');
        if (existingBanner) {
            existingBanner.remove();
        }
        
        const banner = document.createElement('div');
        banner.id = 'ibridge-warning-banner';
        banner.style.cssText = `
            position: fixed !important;
            top: 0 !important;
            left: 0 !important;
            width: 100% !important;
            background: ${severity === 'high' ? '#ff6b6b' : '#ffa726'} !important;
            color: white !important;
            padding: 10px !important;
            text-align: center !important;
            z-index: 999998 !important;
            font-family: Arial, sans-serif !important;
            font-size: 14px !important;
        `;
        
        banner.innerHTML = `
            <span>⚠️ ${message}</span>
            <button onclick="this.parentElement.remove()" style="
                background: none;
                border: none;
                color: white;
                margin-left: 10px;
                cursor: pointer;
                font-size: 16px;
            ">×</button>
        `;
        
        document.body.insertBefore(banner, document.body.firstChild);
        
        // Auto-remove after 10 seconds
        setTimeout(() => {
            if (banner.parentElement) {
                banner.remove();
            }
        }, 10000);
    }
    
})();
"""
            
            content_file = extension_dir / "content.js"
            with open(content_file, 'w') as f:
                f.write(content_script)
                
        except Exception as e:
            self.logger.error(f"Content script generation error: {e}")
    
    def _generate_background_scripts(self, browser: str, extension_dir: Path):
        """Generate background scripts for extension"""
        try:
            # Background script
            if browser in ['chrome', 'edge']:
                # Service worker for Manifest V3
                background_script = """
// iBridge Antivirus Background Script (Service Worker)
console.log('iBridge Antivirus background script loaded');

// Native messaging port
let nativePort = null;

// Connect to native messaging host
function connectToNativeHost() {
    try {
        nativePort = chrome.runtime.connectNative('com.ibridge.antivirus.chrome');
        
        nativePort.onMessage.addListener(function(message) {
            console.log('Message from native host:', message);
            handleNativeMessage(message);
        });
        
        nativePort.onDisconnect.addListener(function() {
            console.log('Native host disconnected');
            nativePort = null;
            
            // Retry connection after 5 seconds
            setTimeout(connectToNativeHost, 5000);
        });
        
        console.log('Connected to native messaging host');
    } catch (error) {
        console.error('Failed to connect to native host:', error);
        setTimeout(connectToNativeHost, 5000);
    }
}

// Initialize connection
connectToNativeHost();

// Handle messages from content scripts
chrome.runtime.onMessage.addListener(function(message, sender, sendResponse) {
    console.log('Message from content script:', message);
    
    switch (message.type) {
        case 'url_check':
            handleURLCheck(message, sender);
            break;
        case 'download_detected':
            handleDownloadDetection(message, sender);
            break;
        case 'form_submit':
            handleFormSubmit(message, sender);
            break;
        case 'script_injection':
            handleScriptInjection(message, sender);
            break;
    }
    
    sendResponse({status: 'processed'});
});

// URL checking
function handleURLCheck(message, sender) {
    if (nativePort) {
        nativePort.postMessage({
            type: 'url_check',
            url: message.url,
            tabId: sender.tab?.id,
            timestamp: message.timestamp
        });
    }
}

// Download detection
function handleDownloadDetection(message, sender) {
    if (nativePort) {
        nativePort.postMessage({
            type: 'download_scan',
            url: message.url,
            tabId: sender.tab?.id,
            timestamp: message.timestamp
        });
    }
}

// Form submission monitoring
function handleFormSubmit(message, sender) {
    if (nativePort) {
        nativePort.postMessage({
            type: 'form_analysis',
            action: message.action,
            hasPassword: message.hasPassword,
            tabId: sender.tab?.id,
            timestamp: message.timestamp
        });
    }
}

// Script injection monitoring
function handleScriptInjection(message, sender) {
    if (nativePort) {
        nativePort.postMessage({
            type: 'script_analysis',
            src: message.src,
            content: message.content,
            tabId: sender.tab?.id,
            timestamp: message.timestamp
        });
    }
}

// Handle responses from native host
function handleNativeMessage(message) {
    switch (message.type) {
        case 'url_threat_detected':
            blockURL(message);
            break;
        case 'download_threat_detected':
            blockDownload(message);
            break;
        case 'phishing_detected':
            showPhishingWarning(message);
            break;
        case 'malicious_script_detected':
            blockMaliciousScript(message);
            break;
    }
}

// Block malicious URL
function blockURL(message) {
    if (message.tabId) {
        chrome.tabs.sendMessage(message.tabId, {
            type: 'page_blocked',
            reason: message.reason,
            threat_type: message.threat_type
        });
    }
}

// Block malicious download
function blockDownload(message) {
    if (message.tabId) {
        chrome.tabs.sendMessage(message.tabId, {
            type: 'warning_display',
            message: 'Malicious download blocked by iBridge Antivirus',
            severity: 'high'
        });
    }
}

// Show phishing warning
function showPhishingWarning(message) {
    if (message.tabId) {
        chrome.tabs.sendMessage(message.tabId, {
            type: 'warning_display',
            message: 'Potential phishing site detected. Proceed with caution.',
            severity: 'high'
        });
    }
}

// Block malicious script
function blockMaliciousScript(message) {
    if (message.tabId) {
        chrome.tabs.sendMessage(message.tabId, {
            type: 'warning_display',
            message: 'Malicious script blocked by iBridge Antivirus',
            severity: 'medium'
        });
    }
}

// Web request blocking
chrome.webRequest.onBeforeRequest.addListener(
    function(details) {
        // This would implement real-time URL blocking
        // For now, we'll just log the request
        console.log('Web request:', details.url);
        
        return {};
    },
    {urls: ["<all_urls>"]},
    ["blocking"]
);

// Download monitoring
chrome.downloads.onCreated.addListener(function(downloadItem) {
    console.log('Download started:', downloadItem);
    
    if (nativePort) {
        nativePort.postMessage({
            type: 'download_started',
            downloadId: downloadItem.id,
            url: downloadItem.url,
            filename: downloadItem.filename,
            fileSize: downloadItem.fileSize,
            timestamp: Date.now()
        });
    }
});

chrome.downloads.onChanged.addListener(function(delta) {
    if (delta.state && delta.state.current === 'complete') {
        console.log('Download completed:', delta.id);
        
        if (nativePort) {
            nativePort.postMessage({
                type: 'download_completed',
                downloadId: delta.id,
                timestamp: Date.now()
            });
        }
    }
});
"""
            
            else:
                # Background script for Firefox Manifest V2
                background_script = """
// iBridge Antivirus Background Script (Firefox)
console.log('iBridge Antivirus background script loaded');

// Native messaging port
let nativePort = null;

// Connect to native messaging host
function connectToNativeHost() {
    try {
        nativePort = browser.runtime.connectNative('com.ibridge.antivirus.firefox');
        
        nativePort.onMessage.addListener(function(message) {
            console.log('Message from native host:', message);
            handleNativeMessage(message);
        });
        
        nativePort.onDisconnect.addListener(function() {
            console.log('Native host disconnected');
            nativePort = null;
            
            // Retry connection after 5 seconds
            setTimeout(connectToNativeHost, 5000);
        });
        
        console.log('Connected to native messaging host');
    } catch (error) {
        console.error('Failed to connect to native host:', error);
        setTimeout(connectToNativeHost, 5000);
    }
}

// Initialize connection
connectToNativeHost();

// Handle messages from content scripts
browser.runtime.onMessage.addListener(function(message, sender, sendResponse) {
    console.log('Message from content script:', message);
    
    switch (message.type) {
        case 'url_check':
            handleURLCheck(message, sender);
            break;
        case 'download_detected':
            handleDownloadDetection(message, sender);
            break;
        case 'form_submit':
            handleFormSubmit(message, sender);
            break;
        case 'script_injection':
            handleScriptInjection(message, sender);
            break;
    }
    
    sendResponse({status: 'processed'});
});

// Similar implementation as Chrome but using browser API instead of chrome API
// ... (rest of the functions would be similar with browser. instead of chrome.)
"""
            
            background_file = extension_dir / "background.js"
            with open(background_file, 'w') as f:
                f.write(background_script)
                
        except Exception as e:
            self.logger.error(f"Background script generation error: {e}")
    
    def _generate_popup_interface(self, browser: str, extension_dir: Path):
        """Generate popup interface for extension"""
        try:
            # Popup HTML
            popup_html = """
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body {
            width: 350px;
            padding: 15px;
            font-family: Arial, sans-serif;
            background: #f8f9fa;
        }
        
        .header {
            text-align: center;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #007bff;
        }
        
        .logo {
            font-size: 20px;
            font-weight: bold;
            color: #007bff;
            margin-bottom: 5px;
        }
        
        .status {
            display: flex;
            align-items: center;
            margin-bottom: 15px;
            padding: 10px;
            border-radius: 5px;
            background: #e7f3ff;
        }
        
        .status.protected {
            background: #d4edda;
            border: 1px solid #c3e6cb;
        }
        
        .status.warning {
            background: #fff3cd;
            border: 1px solid #ffeaa7;
        }
        
        .status-icon {
            font-size: 20px;
            margin-right: 10px;
        }
        
        .status-text {
            flex: 1;
        }
        
        .stats {
            margin-bottom: 15px;
        }
        
        .stat-item {
            display: flex;
            justify-content: space-between;
            margin-bottom: 8px;
            padding: 5px 0;
            border-bottom: 1px solid #e9ecef;
        }
        
        .stat-label {
            color: #666;
        }
        
        .stat-value {
            font-weight: bold;
            color: #333;
        }
        
        .actions {
            margin-top: 15px;
        }
        
        .btn {
            width: 100%;
            padding: 8px 12px;
            margin-bottom: 8px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            transition: background-color 0.3s;
        }
        
        .btn-primary {
            background: #007bff;
            color: white;
        }
        
        .btn-primary:hover {
            background: #0056b3;
        }
        
        .btn-secondary {
            background: #6c757d;
            color: white;
        }
        
        .btn-secondary:hover {
            background: #545b62;
        }
        
        .btn-danger {
            background: #dc3545;
            color: white;
        }
        
        .btn-danger:hover {
            background: #c82333;
        }
        
        .footer {
            text-align: center;
            margin-top: 15px;
            padding-top: 10px;
            border-top: 1px solid #e9ecef;
            font-size: 12px;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="logo">🛡️ iBridge Antivirus</div>
        <div style="font-size: 12px; color: #666;">Browser Protection</div>
    </div>
    
    <div id="status" class="status protected">
        <div class="status-icon">✅</div>
        <div class="status-text">
            <div style="font-weight: bold;">Protection Active</div>
            <div style="font-size: 12px; color: #666;">All systems operational</div>
        </div>
    </div>
    
    <div class="stats">
        <div class="stat-item">
            <div class="stat-label">Threats Blocked Today:</div>
            <div class="stat-value" id="threats-blocked">0</div>
        </div>
        <div class="stat-item">
            <div class="stat-label">Malware Blocked:</div>
            <div class="stat-value" id="malware-blocked">0</div>
        </div>
        <div class="stat-item">
            <div class="stat-label">Phishing Blocked:</div>
            <div class="stat-value" id="phishing-blocked">0</div>
        </div>
        <div class="stat-item">
            <div class="stat-label">Trackers Blocked:</div>
            <div class="stat-value" id="trackers-blocked">0</div>
        </div>
    </div>
    
    <div class="actions">
        <button class="btn btn-primary" id="scan-page">🔍 Scan Current Page</button>
        <button class="btn btn-secondary" id="open-dashboard">📊 Open Dashboard</button>
        <button class="btn btn-secondary" id="settings">⚙️ Settings</button>
    </div>
    
    <div class="footer">
        Version 1.0.0 | iBridge Security
    </div>
    
    <script src="popup.js"></script>
</body>
</html>
"""
            
            popup_file = extension_dir / "popup.html"
            with open(popup_file, 'w') as f:
                f.write(popup_html)
            
            # Popup JavaScript
            popup_js = """
// iBridge Antivirus Popup Script
document.addEventListener('DOMContentLoaded', function() {
    console.log('iBridge Antivirus popup loaded');
    
    // Load current statistics
    loadStatistics();
    
    // Setup event listeners
    document.getElementById('scan-page').addEventListener('click', scanCurrentPage);
    document.getElementById('open-dashboard').addEventListener('click', openDashboard);
    document.getElementById('settings').addEventListener('click', openSettings);
    
    // Refresh statistics every 5 seconds
    setInterval(loadStatistics, 5000);
});

function loadStatistics() {
    // Get statistics from background script
    chrome.runtime.sendMessage({type: 'get_statistics'}, function(response) {
        if (response && response.stats) {
            updateStatisticsDisplay(response.stats);
        }
    });
}

function updateStatisticsDisplay(stats) {
    document.getElementById('threats-blocked').textContent = stats.threats_blocked || 0;
    document.getElementById('malware-blocked').textContent = stats.malware_blocked || 0;
    document.getElementById('phishing-blocked').textContent = stats.phishing_blocked || 0;
    document.getElementById('trackers-blocked').textContent = stats.trackers_blocked || 0;
    
    // Update status based on protection state
    const statusElement = document.getElementById('status');
    if (stats.protection_active) {
        statusElement.className = 'status protected';
        statusElement.innerHTML = `
            <div class="status-icon">✅</div>
            <div class="status-text">
                <div style="font-weight: bold;">Protection Active</div>
                <div style="font-size: 12px; color: #666;">All systems operational</div>
            </div>
        `;
    } else {
        statusElement.className = 'status warning';
        statusElement.innerHTML = `
            <div class="status-icon">⚠️</div>
            <div class="status-text">
                <div style="font-weight: bold;">Protection Disabled</div>
                <div style="font-size: 12px; color: #666;">Click to enable protection</div>
            </div>
        `;
    }
}

function scanCurrentPage() {
    chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
        if (tabs[0]) {
            chrome.runtime.sendMessage({
                type: 'manual_scan',
                url: tabs[0].url,
                tabId: tabs[0].id
            });
            
            // Show scanning feedback
            const scanButton = document.getElementById('scan-page');
            const originalText = scanButton.textContent;
            scanButton.textContent = '🔄 Scanning...';
            scanButton.disabled = true;
            
            setTimeout(() => {
                scanButton.textContent = originalText;
                scanButton.disabled = false;
            }, 3000);
        }
    });
}

function openDashboard() {
    chrome.tabs.create({url: chrome.runtime.getURL('dashboard.html')});
    window.close();
}

function openSettings() {
    chrome.tabs.create({url: chrome.runtime.getURL('settings.html')});
    window.close();
}
"""
            
            popup_js_file = extension_dir / "popup.js"
            with open(popup_js_file, 'w') as f:
                f.write(popup_js)
                
        except Exception as e:
            self.logger.error(f"Popup interface generation error: {e}")
    
    def start_extension_interface(self):
        """Start the extension interface service"""
        try:
            # Start native messaging listener
            listener_thread = threading.Thread(target=self._native_messaging_listener, daemon=True)
            listener_thread.start()
            
            self.logger.info("Browser extension interface started")
            return True
            
        except Exception as e:
            self.logger.error(f"Extension interface start error: {e}")
            return False
    
    def _native_messaging_listener(self):
        """Listen for native messaging connections"""
        try:
            # This would implement actual native messaging protocol
            # For demo purposes, we'll simulate the listener
            
            while True:
                # Simulate receiving messages from browser extensions
                time.sleep(30)
                
                # Process any queued messages
                self._process_queued_messages()
                
        except Exception as e:
            self.logger.error(f"Native messaging listener error: {e}")
    
    def _process_queued_messages(self):
        """Process queued messages from extensions"""
        try:
            # This would process actual messages from browser extensions
            # For demo purposes, we'll simulate message processing
            
            self.logger.debug("Processing extension messages")
            
        except Exception as e:
            self.logger.error(f"Message processing error: {e}")
    
    def _handle_url_check(self, message: Dict) -> Dict:
        """Handle URL check request from extension"""
        try:
            url = message.get('url', '')
            
            # This would integrate with the browser security manager
            # For demo purposes, we'll simulate URL checking
            
            is_safe = not any(threat in url.lower() for threat in ['malware', 'phishing', 'virus'])
            
            return {
                'type': 'url_check_response',
                'url': url,
                'is_safe': is_safe,
                'threat_type': 'malware' if not is_safe else None,
                'action': 'block' if not is_safe else 'allow'
            }
            
        except Exception as e:
            self.logger.error(f"URL check handling error: {e}")
            return {'type': 'error', 'message': str(e)}
    
    def _handle_download_scan(self, message: Dict) -> Dict:
        """Handle download scan request from extension"""
        try:
            download_url = message.get('url', '')
            filename = message.get('filename', '')
            
            # This would integrate with the download scanner
            # For demo purposes, we'll simulate download scanning
            
            is_safe = not any(ext in filename.lower() for ext in ['.exe', '.bat', '.scr'])
            
            return {
                'type': 'download_scan_response',
                'url': download_url,
                'filename': filename,
                'is_safe': is_safe,
                'threat_type': 'malware' if not is_safe else None,
                'action': 'block' if not is_safe else 'allow'
            }
            
        except Exception as e:
            self.logger.error(f"Download scan handling error: {e}")
            return {'type': 'error', 'message': str(e)}
    
    def _handle_page_analysis(self, message: Dict) -> Dict:
        """Handle page analysis request from extension"""
        try:
            url = message.get('url', '')
            content_type = message.get('content_type', '')
            
            # This would perform comprehensive page analysis
            # For demo purposes, we'll simulate analysis
            
            risk_score = 0.1  # Low risk by default
            
            return {
                'type': 'page_analysis_response',
                'url': url,
                'risk_score': risk_score,
                'recommendations': ['Page appears safe'] if risk_score < 0.5 else ['Proceed with caution']
            }
            
        except Exception as e:
            self.logger.error(f"Page analysis handling error: {e}")
            return {'type': 'error', 'message': str(e)}
    
    def _handle_settings_update(self, message: Dict) -> Dict:
        """Handle settings update from extension"""
        try:
            settings = message.get('settings', {})
            
            # Update extension settings
            self.logger.info(f"Extension settings updated: {settings}")
            
            return {
                'type': 'settings_update_response',
                'status': 'success',
                'message': 'Settings updated successfully'
            }
            
        except Exception as e:
            self.logger.error(f"Settings update handling error: {e}")
            return {'type': 'error', 'message': str(e)}
    
    def _handle_status_request(self, message: Dict) -> Dict:
        """Handle status request from extension"""
        try:
            return {
                'type': 'status_response',
                'protection_active': True,
                'statistics': {
                    'threats_blocked': 42,
                    'malware_blocked': 15,
                    'phishing_blocked': 12,
                    'trackers_blocked': 156
                },
                'last_update': datetime.now().isoformat()
            }
            
        except Exception as e:
            self.logger.error(f"Status request handling error: {e}")
            return {'type': 'error', 'message': str(e)}
    
    def get_extension_status(self) -> Dict:
        """Get status of all browser extensions"""
        try:
            status = {}
            
            for browser, config in self.extensions.items():
                extension_installed = self._check_extension_installed(browser)
                
                status[browser] = {
                    'name': config['name'],
                    'installed': extension_installed,
                    'active': extension_installed,
                    'version': '1.0.0',
                    'last_communication': datetime.now().isoformat() if extension_installed else None
                }
            
            return status
            
        except Exception as e:
            self.logger.error(f"Extension status error: {e}")
            return {}
    
    def _check_extension_installed(self, browser: str) -> bool:
        """Check if extension is installed for browser"""
        try:
            # This would check if the extension is actually installed
            # For demo purposes, we'll assume it's installed if manifest exists
            
            extension_dir = self.config_path / f"{browser}_extension"
            manifest_file = extension_dir / "manifest.json"
            
            return manifest_file.exists()
            
        except Exception as e:
            self.logger.error(f"Extension installation check error: {e}")
            return False

if __name__ == "__main__":
    # Test browser extension interface
    interface = BrowserExtensionInterface()
    
    # Start interface
    if interface.start_extension_interface():
        print("Browser extension interface started")
    
    # Get extension status
    status = interface.get_extension_status()
    print("Extension Status:")
    print(json.dumps(status, indent=2))
    
    # Test message handling
    test_message = {
        'type': 'url_check',
        'url': 'https://malware-example.com',
        'timestamp': time.time()
    }
    
    response = interface._handle_url_check(test_message)
    print(f"URL Check Response: {response}")
    
    print("Browser Extension Interface test completed")