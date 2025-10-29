"""
Test Configuration Manager
Handles loading, validation, and management of test configurations
"""

import json
import os
import sys
import logging
from pathlib import Path
from typing import Dict, Any, Optional, Union
import copy

class ConfigurationManager:
    """
    Manages test configurations for the testing framework
    """
    
    def __init__(self):
        self.logger = logging.getLogger('ConfigManager')
        
        # Base directory for configuration files
        self.config_dir = Path(__file__).parent / "config"
        self.config_dir.mkdir(exist_ok=True)
        
        # Default configuration file path
        self.default_config_path = self.config_dir / "default_config.json"
        
        # Currently loaded configuration
        self.current_config = None
        
        # Built-in configurations
        self.builtin_configs = {
            'default': None,  # Will be loaded from file
            'unit_tests': {
                'run_unit_tests': True,
                'run_integration_tests': False,
                'run_security_tests': False,
                'run_performance_tests': False,
                'verbose_output': True
            },
            'integration_tests': {
                'run_unit_tests': False,
                'run_integration_tests': True,
                'run_security_tests': False,
                'run_performance_tests': False
            },
            'security_tests': {
                'run_unit_tests': False,
                'run_integration_tests': False,
                'run_security_tests': True,
                'run_performance_tests': False
            },
            'performance_tests': {
                'run_unit_tests': False,
                'run_integration_tests': False,
                'run_security_tests': False,
                'run_performance_tests': True,
                'parallel_tests': True
            },
            'ci': {
                'verbose_output': False,
                'create_test_report': True,
                'report_format': 'xml',
                'fail_fast': True,
                'retry_failed_tests': 1
            }
        }
        
        # Load default configuration
        self.load_default_config()
    
    def load_default_config(self) -> bool:
        """Load default configuration from file"""
        try:
            if self.default_config_path.exists():
                with open(self.default_config_path, 'r') as f:
                    self.builtin_configs['default'] = json.load(f)
                self.current_config = copy.deepcopy(self.builtin_configs['default'])
                self.logger.info(f"Default configuration loaded from {self.default_config_path}")
                return True
            else:
                self.logger.warning(f"Default configuration file not found: {self.default_config_path}")
                # Create a minimal default configuration
                self.builtin_configs['default'] = {
                    'run_unit_tests': True,
                    'run_integration_tests': True,
                    'run_security_tests': True,
                    'run_performance_tests': True,
                    'verbose_output': True,
                    'create_test_report': True,
                    'test_timeout': 300,
                    'parallel_tests': False,
                    'cleanup_after_tests': True
                }
                self.current_config = copy.deepcopy(self.builtin_configs['default'])
                return True
                
        except Exception as e:
            self.logger.error(f"Error loading default configuration: {str(e)}")
            return False
    
    def load_config(self, config_name_or_path: str) -> bool:
        """
        Load configuration by name or from file path
        
        Args:
            config_name_or_path: Name of built-in config or path to config file
        
        Returns:
            bool: True if configuration was loaded successfully
        """
        try:
            # Check if it's a built-in configuration
            if config_name_or_path in self.builtin_configs:
                if self.builtin_configs[config_name_or_path] is None:
                    self.load_default_config()
                else:
                    # Start with default and update with built-in
                    self.current_config = copy.deepcopy(self.builtin_configs['default'])
                    self.current_config.update(self.builtin_configs[config_name_or_path])
                    self.logger.info(f"Built-in configuration '{config_name_or_path}' loaded")
                return True
            
            # Check if it's a file in the config directory without extension
            config_file = self.config_dir / f"{config_name_or_path}.json"
            if config_file.exists():
                with open(config_file, 'r') as f:
                    config_data = json.load(f)
                
                # Start with default and update with loaded config
                self.current_config = copy.deepcopy(self.builtin_configs['default'])
                self.current_config.update(config_data)
                self.logger.info(f"Configuration loaded from {config_file}")
                return True
            
            # Check if it's a full file path
            config_path = Path(config_name_or_path)
            if config_path.exists() and config_path.is_file():
                with open(config_path, 'r') as f:
                    config_data = json.load(f)
                
                # Start with default and update with loaded config
                self.current_config = copy.deepcopy(self.builtin_configs['default'])
                self.current_config.update(config_data)
                self.logger.info(f"Configuration loaded from {config_path}")
                return True
            
            self.logger.warning(f"Configuration not found: {config_name_or_path}")
            return False
            
        except Exception as e:
            self.logger.error(f"Error loading configuration: {str(e)}")
            return False
    
    def update_config(self, updates: Dict[str, Any]) -> bool:
        """
        Update current configuration with new values
        
        Args:
            updates: Dictionary of configuration updates
        
        Returns:
            bool: True if configuration was updated successfully
        """
        try:
            if self.current_config is None:
                self.load_default_config()
            
            if self.current_config is not None:
                self.current_config.update(updates)
                self.logger.debug("Configuration updated")
                return True
            else:
                self.logger.error("Failed to load default configuration")
                return False
            
        except Exception as e:
            self.logger.error(f"Error updating configuration: {str(e)}")
            return False
    
    def get_config(self) -> Dict[str, Any]:
        """
        Get current configuration
        
        Returns:
            dict: Current configuration dictionary
        """
        if self.current_config is None:
            self.load_default_config()
        
        # Ensure we return a valid dictionary
        if self.current_config is None:
            # Fallback to minimal configuration
            return {
                'run_unit_tests': True,
                'run_integration_tests': True,
                'run_security_tests': True,
                'run_performance_tests': True,
                'verbose_output': True,
                'create_test_report': True,
                'cleanup_after_tests': True
            }
        
        return self.current_config
    
    def save_config(self, file_path: str) -> bool:
        """
        Save current configuration to file
        
        Args:
            file_path: Path where to save the configuration
        
        Returns:
            bool: True if configuration was saved successfully
        """
        try:
            if self.current_config is None:
                self.load_default_config()
            
            output_path = Path(file_path)
            with open(output_path, 'w') as f:
                json.dump(self.current_config, f, indent=2)
            
            self.logger.info(f"Configuration saved to {output_path}")
            return True
            
        except Exception as e:
            self.logger.error(f"Error saving configuration: {str(e)}")
            return False
    
    def validate_config(self) -> bool:
        """
        Validate current configuration
        
        Returns:
            bool: True if configuration is valid
        """
        if self.current_config is None:
            self.load_default_config()
        
        # Ensure we have a valid configuration
        if self.current_config is None:
            self.logger.error("No configuration available for validation")
            return False
        
        # Required fields
        required_fields = [
            'run_unit_tests',
            'run_integration_tests', 
            'run_security_tests',
            'run_performance_tests',
            'verbose_output',
            'create_test_report',
            'cleanup_after_tests'
        ]
        
        # Check required fields
        for field in required_fields:
            if field not in self.current_config:
                self.logger.error(f"Required configuration field missing: {field}")
                return False
        
        # Check if at least one test type is enabled
        if not any([
            self.current_config.get('run_unit_tests', False),
            self.current_config.get('run_integration_tests', False),
            self.current_config.get('run_security_tests', False),
            self.current_config.get('run_performance_tests', False)
        ]):
            self.logger.warning("No test types are enabled in configuration")
        
        return True
    
    def get_available_configs(self) -> Dict[str, str]:
        """
        Get list of available configurations
        
        Returns:
            dict: Dictionary mapping config names to their descriptions
        """
        configs = {}
        
        # Add built-in configs
        configs.update({
            'default': 'Default configuration',
            'unit_tests': 'Run only unit tests',
            'integration_tests': 'Run only integration tests',
            'security_tests': 'Run only security tests',
            'performance_tests': 'Run only performance tests',
            'ci': 'Configuration for continuous integration'
        })
        
        # Add configs from config directory
        for config_file in self.config_dir.glob('*.json'):
            name = config_file.stem
            if name != 'default_config':  # Exclude default config
                # Try to get description from file
                try:
                    with open(config_file, 'r') as f:
                        data = json.load(f)
                        description = data.get('description', f'Configuration from {config_file.name}')
                except Exception:
                    description = f'Configuration from {config_file.name}'
                
                configs[name] = description
        
        return configs