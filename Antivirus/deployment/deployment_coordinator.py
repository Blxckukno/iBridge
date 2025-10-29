"""
Deployment Coordinator
Unified deployment orchestrator that manages installer creation, updates, and configuration
"""

import os
import sys
import json
import subprocess
import threading
import time
from pathlib import Path
from datetime import datetime
from typing import Dict, Any, List, Optional, Callable
import tempfile
import shutil
import zipfile
import hashlib

# Import our deployment modules
from .installer.windows_installer_builder import WindowsInstallerBuilder
from .updater.auto_updater import AutoUpdater
from .config.configuration_manager import ConfigurationManager, ConfigScope

class DeploymentStatus:
    """Deployment operation status tracking"""
    PENDING = "pending"
    RUNNING = "running"
    SUCCESS = "success"
    FAILED = "failed"
    CANCELLED = "cancelled"

class DeploymentOperation:
    """Represents a deployment operation"""
    
    def __init__(self, operation_id: str, operation_type: str, 
                 description: str, parameters: Optional[Dict[str, Any]] = None):
        self.operation_id = operation_id
        self.operation_type = operation_type
        self.description = description
        self.parameters = parameters or {}
        self.status = DeploymentStatus.PENDING
        self.start_time = None
        self.end_time = None
        self.result = None
        self.error_message = None
        self.progress = 0
        self.log_messages = []
    
    def add_log(self, message: str, level: str = "INFO"):
        """Add log message to operation"""
        timestamp = datetime.now().isoformat()
        log_entry = {
            'timestamp': timestamp,
            'level': level,
            'message': message
        }
        self.log_messages.append(log_entry)
        print(f"[{timestamp}] {level}: {message}")
    
    def start(self):
        """Mark operation as started"""
        self.status = DeploymentStatus.RUNNING
        self.start_time = datetime.now()
        self.add_log(f"Started {self.operation_type}: {self.description}")
    
    def complete(self, result: Any = None):
        """Mark operation as completed successfully"""
        self.status = DeploymentStatus.SUCCESS
        self.end_time = datetime.now()
        self.result = result
        self.progress = 100
        duration = (self.end_time - self.start_time).total_seconds() if self.start_time else 0
        self.add_log(f"Completed successfully in {duration:.2f} seconds")
    
    def fail(self, error_message: str):
        """Mark operation as failed"""
        self.status = DeploymentStatus.FAILED
        self.end_time = datetime.now()
        self.error_message = error_message
        duration = (self.end_time - self.start_time).total_seconds() if self.start_time else 0
        self.add_log(f"Failed after {duration:.2f} seconds: {error_message}", "ERROR")
    
    def update_progress(self, progress: int, message: str = ""):
        """Update operation progress"""
        self.progress = max(0, min(100, progress))
        if message:
            self.add_log(f"Progress {self.progress}%: {message}")

class DeploymentCoordinator:
    """
    Main deployment coordinator that orchestrates all deployment operations
    """
    
    def __init__(self, app_root: Optional[str] = None, config_file: Optional[str] = None):
        self.app_root = Path(app_root or os.getcwd())
        self.deployment_dir = self.app_root / "deployment"
        self.work_dir = self.deployment_dir / "work"
        self.output_dir = self.deployment_dir / "output"
        self.logs_dir = self.deployment_dir / "logs"
        
        # Initialize components
        self.installer_builder = None
        self.auto_updater = None
        self.config_manager = None
        
        # Operation tracking
        self.operations = {}
        self.operation_callbacks = []
        self.operation_counter = 0
        
        # Configuration
        self.deployment_config = self._load_deployment_config(config_file)
        
        self._setup_directories()
        self._initialize_components()
    
    def _setup_directories(self):
        """Setup deployment directories"""
        for directory in [self.deployment_dir, self.work_dir, self.output_dir, self.logs_dir]:
            directory.mkdir(parents=True, exist_ok=True)
    
    def _load_deployment_config(self, config_file: Optional[str] = None) -> Dict[str, Any]:
        """Load deployment configuration"""
        default_config = {
            'product': {
                'name': 'iBridge Antivirus',
                'version': '1.0.0',
                'description': 'Advanced Antivirus and Security Suite',
                'manufacturer': 'iBridge Security',
                'website': 'https://www.ibridge-security.com'
            },
            'installer': {
                'create_msi': True,
                'create_exe': True,
                'sign_installers': False,
                'include_dependencies': True,
                'compression_level': 'high'
            },
            'updater': {
                'update_server': 'https://updates.ibridge-security.com',
                'check_interval': 86400,
                'auto_download': True,
                'auto_install': False,
                'signature_verification': True
            },
            'distribution': {
                'create_zip_package': True,
                'create_portable_version': True,
                'include_documentation': True,
                'target_platforms': ['windows-x64', 'windows-x86']
            }
        }
        
        if config_file and Path(config_file).exists():
            try:
                with open(config_file, 'r') as f:
                    user_config = json.load(f)
                # Merge with defaults
                self._deep_merge(default_config, user_config)
            except Exception as e:
                print(f"Failed to load config file {config_file}: {e}")
        
        return default_config
    
    def _deep_merge(self, base_dict: Dict, update_dict: Dict):
        """Deep merge two dictionaries"""
        for key, value in update_dict.items():
            if key in base_dict and isinstance(base_dict[key], dict) and isinstance(value, dict):
                self._deep_merge(base_dict[key], value)
            else:
                base_dict[key] = value
    
    def _initialize_components(self):
        """Initialize deployment components"""
        try:
            # Initialize configuration manager
            self.config_manager = ConfigurationManager(str(self.app_root))
            
            # Initialize installer builder
            self.installer_builder = WindowsInstallerBuilder(str(self.app_root))
            # Update installer config from deployment config
            installer_config = self.deployment_config.get('installer', {})
            product_config = self.deployment_config.get('product', {})
            self.installer_builder.config.update({
                'product_name': product_config.get('name', 'iBridge Antivirus'),
                'product_version': product_config.get('version', '1.0.0'),
                'manufacturer': product_config.get('manufacturer', 'iBridge Security'),
                'description': product_config.get('description', 'Advanced Antivirus and Security Suite')
            })
            
            # Initialize auto-updater
            updater_config = self.deployment_config.get('updater', {})
            updater_config['app_root'] = str(self.app_root)
            updater_config.update(product_config)
            self.auto_updater = AutoUpdater(updater_config)
            
            print("Deployment components initialized successfully")
            
        except Exception as e:
            print(f"Failed to initialize deployment components: {e}")
            raise
    
    def add_operation_callback(self, callback: Callable):
        """Add callback for operation events"""
        self.operation_callbacks.append(callback)
    
    def _notify_operation_callbacks(self, operation: DeploymentOperation, event: str):
        """Notify operation callbacks"""
        for callback in self.operation_callbacks:
            try:
                callback(operation, event)
            except Exception as e:
                print(f"Callback error: {e}")
    
    def _create_operation(self, operation_type: str, description: str, 
                         parameters: Optional[Dict[str, Any]] = None) -> DeploymentOperation:
        """Create new deployment operation"""
        self.operation_counter += 1
        operation_id = f"op_{self.operation_counter:04d}_{int(time.time())}"
        
        operation = DeploymentOperation(operation_id, operation_type, description, parameters)
        self.operations[operation_id] = operation
        
        self._notify_operation_callbacks(operation, "created")
        return operation
    
    def create_installer(self, version: Optional[str] = None, sign: Optional[bool] = None,
                        output_dir: Optional[str] = None) -> str:
        """
        Create Windows installer package
        """
        operation = self._create_operation(
            "create_installer",
            f"Creating Windows installer for version {version or 'current'}",
            {
                'version': version,
                'sign': sign,
                'output_dir': output_dir
            }
        )
        
        try:
            operation.start()
            
            # Check if installer builder is available
            if not self.installer_builder:
                raise Exception("Installer builder not initialized")
            
            # Update version if provided
            if version:
                self.installer_builder.config['product_version'] = version
                operation.update_progress(10, "Version updated")
            
            # Set signing preference
            sign_installer = sign if sign is not None else self.deployment_config['installer']['sign_installers']
            operation.update_progress(20, "Configuration prepared")
            
            # Create installer
            operation.update_progress(30, "Building installer package...")
            installer_file = self.installer_builder.create_installer(sign_installer=sign_installer)
            
            if installer_file:
                operation.update_progress(80, "Installer created successfully")
                
                # Copy to output directory if specified
                if output_dir:
                    output_path = Path(output_dir)
                    output_path.mkdir(parents=True, exist_ok=True)
                    final_installer = output_path / installer_file.name
                    shutil.copy2(installer_file, final_installer)
                    installer_file = final_installer
                    operation.update_progress(90, f"Installer copied to {output_dir}")
                
                operation.complete(str(installer_file))
                return str(installer_file)
            else:
                raise Exception("Installer creation failed")
                
        except Exception as e:
            operation.fail(str(e))
            raise
    
    def create_update_package(self, version: str, source_dir: Optional[str] = None, 
                            description: str = "") -> str:
        """
        Create update package for auto-updater
        """
        operation = self._create_operation(
            "create_update",
            f"Creating update package for version {version}",
            {
                'version': version,
                'source_dir': source_dir,
                'description': description
            }
        )
        
        try:
            operation.start()
            
            # Determine source directory
            if source_dir:
                source_path = Path(source_dir)
            else:
                source_path = self.app_root
            
            if not source_path.exists():
                raise ValueError(f"Source directory does not exist: {source_path}")
            
            operation.update_progress(10, "Source directory validated")
            
            # Create update package directory
            update_dir = self.work_dir / f"update_{version}"
            update_dir.mkdir(exist_ok=True)
            
            # Copy application files
            operation.update_progress(20, "Copying application files...")
            self._copy_update_files(source_path, update_dir)
            operation.update_progress(50, "Application files copied")
            
            # Create update manifest
            manifest = self._create_update_manifest(version, description, update_dir)
            manifest_file = update_dir / "update_manifest.json"
            with open(manifest_file, 'w') as f:
                json.dump(manifest, f, indent=2)
            operation.update_progress(60, "Update manifest created")
            
            # Create ZIP package
            update_package = self.output_dir / f"update_{version}.zip"
            operation.update_progress(70, "Creating update package...")
            with zipfile.ZipFile(update_package, 'w', zipfile.ZIP_DEFLATED) as zf:
                for file_path in update_dir.rglob('*'):
                    if file_path.is_file():
                        arcname = file_path.relative_to(update_dir)
                        zf.write(file_path, arcname)
            
            operation.update_progress(90, "Update package created")
            
            # Clean up temporary directory
            shutil.rmtree(update_dir, ignore_errors=True)
            
            operation.complete(str(update_package))
            return str(update_package)
            
        except Exception as e:
            operation.fail(str(e))
            raise
    
    def _copy_update_files(self, source_dir: Path, target_dir: Path):
        """Copy files for update package"""
        # Files/directories to include in update
        include_items = [
            'main.py',
            'antivirus_core',
            'firewall', 
            'vpn',
            'browser_protection',
            'data_vault',
            'security_manager',
            'ui',
            'utils',
            'config.json',
            'LICENSE',
            'README.md'
        ]
        
        # Files/patterns to exclude
        exclude_patterns = [
            '__pycache__',
            '*.pyc',
            '*.pyo',
            '.git',
            '.pytest_cache',
            'tests',
            '*.log',
            'deployment',
            '.env'
        ]
        
        for item in include_items:
            source_path = source_dir / item
            if source_path.exists():
                target_path = target_dir / item
                
                if source_path.is_file():
                    target_path.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(source_path, target_path)
                elif source_path.is_dir():
                    shutil.copytree(source_path, target_path, 
                                  ignore=shutil.ignore_patterns(*exclude_patterns))
    
    def _create_update_manifest(self, version: str, description: str, 
                               update_dir: Path) -> Dict[str, Any]:
        """Create update manifest"""
        manifest = {
            'version': version,
            'description': description,
            'created_at': datetime.now().isoformat(),
            'files': []
        }
        
        # Calculate file hashes
        for file_path in update_dir.rglob('*'):
            if file_path.is_file() and file_path.name != 'update_manifest.json':
                relative_path = file_path.relative_to(update_dir)
                file_hash = self._calculate_file_hash(file_path)
                
                manifest['files'].append({
                    'path': str(relative_path),
                    'hash': file_hash,
                    'size': file_path.stat().st_size
                })
        
        return manifest
    
    def _calculate_file_hash(self, file_path: Path) -> str:
        """Calculate SHA256 hash of file"""
        hash_sha256 = hashlib.sha256()
        with open(file_path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_sha256.update(chunk)
        return hash_sha256.hexdigest()
    
    def deploy_configuration(self, config_data: Dict[str, Any], 
                           scope: str = "system") -> bool:
        """
        Deploy configuration settings
        """
        operation = self._create_operation(
            "deploy_config",
            f"Deploying configuration to {scope} scope",
            {
                'config_data': config_data,
                'scope': scope
            }
        )
        
        try:
            operation.start()
            
            # Check if configuration manager is available
            if not self.config_manager:
                raise Exception("Configuration manager not initialized")
            
            # Convert scope string to ConfigScope enum
            from .config.configuration_manager import ConfigScope
            config_scope = ConfigScope(scope)
            operation.update_progress(10, "Scope validated")
            
            # Deploy each configuration item
            total_items = len(config_data)
            deployed_count = 0
            
            for key, value in config_data.items():
                try:
                    success = self.config_manager.set_value(
                        key, value, config_scope, changed_by="deployment"
                    )
                    if success:
                        deployed_count += 1
                    
                    progress = int((deployed_count / total_items) * 80) + 10
                    operation.update_progress(progress, f"Deployed {key}")
                    
                except Exception as e:
                    operation.add_log(f"Failed to deploy {key}: {e}", "WARNING")
            
            operation.update_progress(90, f"Deployed {deployed_count}/{total_items} settings")
            
            if deployed_count == total_items:
                operation.complete(f"Successfully deployed all {deployed_count} settings")
                return True
            else:
                operation.complete(f"Deployed {deployed_count}/{total_items} settings with warnings")
                return True
                
        except Exception as e:
            operation.fail(str(e))
            return False
    
    def create_distribution_package(self, version: Optional[str] = None, 
                                  include_portable: bool = True) -> Dict[str, str]:
        """
        Create complete distribution package
        """
        operation = self._create_operation(
            "create_distribution",
            f"Creating distribution package for version {version or 'current'}",
            {
                'version': version,
                'include_portable': include_portable
            }
        )
        
        try:
            operation.start()
            
            current_version = version or self.deployment_config['product']['version']
            dist_dir = self.output_dir / f"distribution_{current_version}"
            dist_dir.mkdir(exist_ok=True)
            
            results = {}
            
            # Create installer
            operation.update_progress(10, "Creating installer...")
            installer_file = self.create_installer(
                version=current_version,
                output_dir=str(dist_dir / "installer")
            )
            results['installer'] = installer_file
            operation.update_progress(30, "Installer created")
            
            # Create update package
            operation.update_progress(40, "Creating update package...")
            update_package = self.create_update_package(
                version=current_version,
                description=f"Update package for {current_version}"
            )
            update_dest = dist_dir / "updates" / Path(update_package).name
            update_dest.parent.mkdir(exist_ok=True)
            shutil.copy2(update_package, update_dest)
            results['update_package'] = str(update_dest)
            operation.update_progress(60, "Update package created")
            
            # Create portable version
            if include_portable:
                operation.update_progress(70, "Creating portable version...")
                portable_dir = dist_dir / "portable"
                self._create_portable_version(portable_dir)
                results['portable'] = str(portable_dir)
                operation.update_progress(80, "Portable version created")
            
            # Create documentation package
            operation.update_progress(85, "Creating documentation...")
            docs_dir = dist_dir / "documentation"
            self._create_documentation_package(docs_dir)
            results['documentation'] = str(docs_dir)
            
            # Create distribution manifest
            operation.update_progress(90, "Creating distribution manifest...")
            manifest = self._create_distribution_manifest(current_version, results)
            manifest_file = dist_dir / "distribution_manifest.json"
            with open(manifest_file, 'w') as f:
                json.dump(manifest, f, indent=2)
            results['manifest'] = str(manifest_file)
            
            operation.complete(results)
            return results
            
        except Exception as e:
            operation.fail(str(e))
            raise
    
    def _create_portable_version(self, portable_dir: Path):
        """Create portable version of the application"""
        portable_dir.mkdir(parents=True, exist_ok=True)
        
        # Copy application files
        self._copy_update_files(self.app_root, portable_dir)
        
        # Create portable launcher
        launcher_content = '''
@echo off
setlocal

REM iBridge Antivirus Portable Launcher
set "PORTABLE_DIR=%~dp0"
set "PORTABLE_MODE=1"

echo Starting iBridge Antivirus (Portable Mode)...
cd /d "%PORTABLE_DIR%"
python main.py --portable

endlocal
'''
        
        launcher_file = portable_dir / "iBridge_Antivirus_Portable.bat"
        with open(launcher_file, 'w') as f:
            f.write(launcher_content)
        
        # Create portable configuration
        portable_config = {
            'portable_mode': True,
            'data_directory': './data',
            'config_directory': './config',
            'logs_directory': './logs'
        }
        
        config_file = portable_dir / "portable_config.json"
        with open(config_file, 'w') as f:
            json.dump(portable_config, f, indent=2)
    
    def _create_documentation_package(self, docs_dir: Path):
        """Create documentation package"""
        docs_dir.mkdir(parents=True, exist_ok=True)
        
        # Create basic documentation files
        readme_content = f'''
# {self.deployment_config['product']['name']}

Version: {self.deployment_config['product']['version']}
Manufacturer: {self.deployment_config['product']['manufacturer']}

## Installation Guide

1. Run the installer as Administrator
2. Follow the installation wizard
3. Configure initial settings
4. Start the application

## Features

- Real-time antivirus protection
- Advanced firewall
- VPN capabilities
- Browser protection
- Secure data vault
- Automatic updates

## Support

For support and documentation, visit: {self.deployment_config['product'].get('website', 'N/A')}

## License

See LICENSE file for license information.
'''
        
        readme_file = docs_dir / "README.md"
        with open(readme_file, 'w') as f:
            f.write(readme_content)
        
        # Copy existing documentation if available
        docs_source = self.app_root / "docs"
        if docs_source.exists():
            shutil.copytree(docs_source, docs_dir / "docs", dirs_exist_ok=True)
        
        # Copy license
        license_source = self.app_root / "LICENSE"
        if license_source.exists():
            shutil.copy2(license_source, docs_dir / "LICENSE")
    
    def _create_distribution_manifest(self, version: str, 
                                    results: Dict[str, str]) -> Dict[str, Any]:
        """Create distribution manifest"""
        manifest = {
            'product': self.deployment_config['product'],
            'version': version,
            'created_at': datetime.now().isoformat(),
            'distribution_contents': {},
            'checksums': {}
        }
        
        # Add file information and checksums
        for component, file_path in results.items():
            if file_path and Path(file_path).exists():
                file_path_obj = Path(file_path)
                manifest['distribution_contents'][component] = {
                    'path': str(file_path_obj.name),
                    'size': file_path_obj.stat().st_size if file_path_obj.is_file() else 0,
                    'type': 'file' if file_path_obj.is_file() else 'directory'
                }
                
                if file_path_obj.is_file():
                    manifest['checksums'][component] = self._calculate_file_hash(file_path_obj)
        
        return manifest
    
    def get_operation_status(self, operation_id: str) -> Optional[DeploymentOperation]:
        """Get status of deployment operation"""
        return self.operations.get(operation_id)
    
    def list_operations(self, status_filter: Optional[str] = None) -> List[DeploymentOperation]:
        """List deployment operations"""
        operations = list(self.operations.values())
        
        if status_filter:
            operations = [op for op in operations if op.status == status_filter]
        
        # Sort by start time (newest first)
        operations.sort(key=lambda x: x.start_time or datetime.min, reverse=True)
        return operations
    
    def cleanup_work_directory(self):
        """Clean up temporary work directory"""
        if self.work_dir.exists():
            shutil.rmtree(self.work_dir, ignore_errors=True)
            self.work_dir.mkdir(exist_ok=True)
            print("Work directory cleaned up")

def main():
    """Main function for deployment coordinator"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Deployment Coordinator')
    parser.add_argument('--create-installer', action='store_true', help='Create Windows installer')
    parser.add_argument('--create-update', help='Create update package for version')
    parser.add_argument('--create-distribution', action='store_true', help='Create distribution package')
    parser.add_argument('--version', help='Version for operations')
    parser.add_argument('--config', help='Configuration file path')
    parser.add_argument('--output-dir', help='Output directory')
    parser.add_argument('--list-operations', action='store_true', help='List recent operations')
    parser.add_argument('--cleanup', action='store_true', help='Clean up work directory')
    
    args = parser.parse_args()
    
    # Create deployment coordinator
    coordinator = DeploymentCoordinator(config_file=args.config)
    
    # Add console callback
    def console_callback(operation, event):
        print(f"Operation {operation.operation_id} ({operation.operation_type}): {event}")
        if event == "completed":
            print(f"  Result: {operation.result}")
        elif event == "failed":
            print(f"  Error: {operation.error_message}")
    
    coordinator.add_operation_callback(console_callback)
    
    try:
        if args.create_installer:
            result = coordinator.create_installer(
                version=args.version,
                output_dir=args.output_dir
            )
            print(f"Installer created: {result}")
        
        elif args.create_update:
            result = coordinator.create_update_package(
                version=args.create_update,
                description=f"Update package for version {args.create_update}"
            )
            print(f"Update package created: {result}")
        
        elif args.create_distribution:
            results = coordinator.create_distribution_package(version=args.version)
            print("Distribution package created:")
            for component, path in results.items():
                print(f"  {component}: {path}")
        
        elif args.list_operations:
            operations = coordinator.list_operations()
            print(f"Recent operations ({len(operations)}):")
            for op in operations[:10]:  # Show last 10
                status_symbol = "✓" if op.status == "success" else "✗" if op.status == "failed" else "●"
                print(f"  {status_symbol} {op.operation_id}: {op.description} ({op.status})")
        
        elif args.cleanup:
            coordinator.cleanup_work_directory()
        
        else:
            parser.print_help()
    
    except Exception as e:
        print(f"Operation failed: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())