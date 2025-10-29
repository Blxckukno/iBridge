"""
Windows Installer Builder
Creates MSI installer package for the antivirus system
"""

import os
import sys
import shutil
import subprocess
import json
import hashlib
import zipfile
import tempfile
from pathlib import Path
from datetime import datetime
import xml.etree.ElementTree as ET

class WindowsInstallerBuilder:
    """
    Professional Windows installer builder with MSI generation
    """
    
    def __init__(self, project_root=None):
        self.project_root = Path(project_root) if project_root else Path(__file__).parent.parent
        self.installer_dir = self.project_root / "deployment" / "installer"
        self.build_dir = self.installer_dir / "build"
        self.output_dir = self.installer_dir / "output"
        self.resources_dir = self.installer_dir / "resources"
        
        # Create directories
        for directory in [self.build_dir, self.output_dir, self.resources_dir]:
            directory.mkdir(parents=True, exist_ok=True)
        
        # Product information
        self.product_info = {
            'name': 'iBridge Antivirus Pro',
            'version': '1.0.0',
            'manufacturer': 'iBridge Security Solutions',
            'description': 'Professional antivirus and security suite',
            'copyright': f'Copyright © {datetime.now().year} iBridge Security Solutions',
            'product_code': '{12345678-1234-1234-1234-123456789012}',
            'upgrade_code': '{87654321-4321-4321-4321-210987654321}',
            'install_dir': 'iBridge\\Antivirus',
            'start_menu_folder': 'iBridge Antivirus Pro'
        }
        
        # Dependencies and requirements
        self.system_requirements = {
            'os_version': 'Windows 10 (64-bit)',
            'memory_mb': 2048,
            'disk_space_mb': 500,
            'dotnet_version': '4.7.2',
            'python_version': '3.8'
        }
        
        # Installation components
        self.components = {
            'core': {
                'name': 'Core Engine',
                'description': 'Antivirus core engine and threat detection',
                'required': True,
                'size_mb': 50
            },
            'firewall': {
                'name': 'Firewall Protection',
                'description': 'Advanced firewall and network protection',
                'required': True,
                'size_mb': 15
            },
            'vpn': {
                'name': 'VPN Client',
                'description': 'Secure VPN connectivity',
                'required': False,
                'size_mb': 25
            },
            'browser_protection': {
                'name': 'Browser Protection',
                'description': 'Real-time browser security',
                'required': True,
                'size_mb': 10
            },
            'data_vault': {
                'name': 'Secure Data Vault',
                'description': 'Encrypted file storage',
                'required': False,
                'size_mb': 20
            },
            'ui': {
                'name': 'User Interface',
                'description': 'Management console and dashboard',
                'required': True,
                'size_mb': 30
            }
        }
    
    def create_installer_package(self):
        """Create complete installer package"""
        try:
            print("Starting installer package creation...")
            
            # Step 1: Prepare build environment
            self._prepare_build_environment()
            
            # Step 2: Copy application files
            self._copy_application_files()
            
            # Step 3: Generate installer configuration
            self._generate_installer_config()
            
            # Step 4: Create WiX source files
            self._create_wix_source()
            
            # Step 5: Build MSI package
            msi_path = self._build_msi_package()
            
            # Step 6: Sign installer
            signed_msi = self._sign_installer(msi_path)
            
            # Step 7: Create installer bundle
            bundle_path = self._create_installer_bundle(signed_msi)
            
            # Step 8: Generate checksums
            self._generate_checksums(bundle_path)
            
            print(f"Installer package created successfully: {bundle_path}")
            return bundle_path
            
        except Exception as e:
            print(f"Error creating installer package: {e}")
            return None
    
    def _prepare_build_environment(self):
        """Prepare build environment"""
        print("Preparing build environment...")
        
        # Clean build directory
        if self.build_dir.exists():
            shutil.rmtree(self.build_dir)
        self.build_dir.mkdir(parents=True)
        
        # Create standard directories
        directories = [
            'app',
            'resources',
            'dependencies',
            'temp',
            'wix'
        ]
        
        for directory in directories:
            (self.build_dir / directory).mkdir(exist_ok=True)
    
    def _copy_application_files(self):
        """Copy application files to build directory"""
        print("Copying application files...")
        
        app_dir = self.build_dir / "app"
        
        # Copy core modules
        core_modules = [
            'antivirus_core',
            'firewall',
            'vpn',
            'browser_protection',
            'data_vault',
            'security_manager',
            'ui',
            'utils'
        ]
        
        for module in core_modules:
            module_path = self.project_root / module
            if module_path.exists():
                dest_path = app_dir / module
                if module_path.is_dir():
                    shutil.copytree(module_path, dest_path, ignore=shutil.ignore_patterns('__pycache__', '*.pyc'))
                else:
                    shutil.copy2(module_path, dest_path)
        
        # Copy main application files
        main_files = [
            'main.py',
            'requirements.txt',
            'README.md',
            'LICENSE'
        ]
        
        for file_name in main_files:
            file_path = self.project_root / file_name
            if file_path.exists():
                shutil.copy2(file_path, app_dir / file_name)
        
        # Copy configuration files
        config_files = [
            'config/default_config.json',
            'config/security_policies.json'
        ]
        
        for config_file in config_files:
            config_path = self.project_root / config_file
            if config_path.exists():
                dest_path = app_dir / config_file
                dest_path.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(config_path, dest_path)
    
    def _generate_installer_config(self):
        """Generate installer configuration"""
        print("Generating installer configuration...")
        
        config = {
            'product': self.product_info,
            'system_requirements': self.system_requirements,
            'components': self.components,
            'registry_keys': self._get_registry_keys(),
            'services': self._get_service_definitions(),
            'firewall_rules': self._get_firewall_rules(),
            'shortcuts': self._get_shortcut_definitions(),
            'file_associations': self._get_file_associations()
        }
        
        config_file = self.build_dir / "installer_config.json"
        with open(config_file, 'w') as f:
            json.dump(config, f, indent=2)
        
        return config_file
    
    def _get_registry_keys(self):
        """Get registry keys to be created"""
        return [
            {
                'root': 'HKLM',
                'key': 'SOFTWARE\\iBridge\\Antivirus',
                'values': [
                    {'name': 'InstallPath', 'type': 'string', 'value': '[INSTALLDIR]'},
                    {'name': 'Version', 'type': 'string', 'value': self.product_info['version']},
                    {'name': 'RealTimeProtection', 'type': 'dword', 'value': '1'},
                    {'name': 'FirewallEnabled', 'type': 'dword', 'value': '1'}
                ]
            },
            {
                'root': 'HKLM',
                'key': 'SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\{12345678-1234-1234-1234-123456789012}',
                'values': [
                    {'name': 'DisplayName', 'type': 'string', 'value': self.product_info['name']},
                    {'name': 'DisplayVersion', 'type': 'string', 'value': self.product_info['version']},
                    {'name': 'Publisher', 'type': 'string', 'value': self.product_info['manufacturer']},
                    {'name': 'InstallLocation', 'type': 'string', 'value': '[INSTALLDIR]'}
                ]
            }
        ]
    
    def _get_service_definitions(self):
        """Get Windows service definitions"""
        return [
            {
                'name': 'iBridgeAntivirusService',
                'display_name': 'iBridge Antivirus Service',
                'description': 'Real-time antivirus protection service',
                'executable': '[INSTALLDIR]services\\antivirus_service.exe',
                'start_type': 'auto',
                'account': 'LocalSystem',
                'dependencies': []
            },
            {
                'name': 'iBridgeFirewallService',
                'display_name': 'iBridge Firewall Service',
                'description': 'Network firewall protection service',
                'executable': '[INSTALLDIR]services\\firewall_service.exe',
                'start_type': 'auto',
                'account': 'LocalSystem',
                'dependencies': ['iBridgeAntivirusService']
            }
        ]
    
    def _get_firewall_rules(self):
        """Get Windows Firewall rules"""
        return [
            {
                'name': 'iBridge Antivirus Inbound',
                'description': 'Allow inbound connections for antivirus updates',
                'direction': 'in',
                'action': 'allow',
                'protocol': 'TCP',
                'local_port': '443',
                'program': '[INSTALLDIR]antivirus_core\\update_client.exe'
            },
            {
                'name': 'iBridge VPN Client',
                'description': 'Allow VPN client connections',
                'direction': 'out',
                'action': 'allow',
                'protocol': 'UDP',
                'remote_port': '1194',
                'program': '[INSTALLDIR]vpn\\vpn_client.exe'
            }
        ]
    
    def _get_shortcut_definitions(self):
        """Get shortcut definitions"""
        return [
            {
                'name': 'iBridge Antivirus Pro',
                'target': '[INSTALLDIR]main.py',
                'arguments': '',
                'working_directory': '[INSTALLDIR]',
                'icon': '[INSTALLDIR]resources\\antivirus.ico',
                'description': 'Launch iBridge Antivirus Pro',
                'locations': ['desktop', 'start_menu']
            },
            {
                'name': 'iBridge Control Panel',
                'target': '[INSTALLDIR]ui\\control_panel.py',
                'arguments': '',
                'working_directory': '[INSTALLDIR]',
                'icon': '[INSTALLDIR]resources\\control_panel.ico',
                'description': 'iBridge Antivirus Control Panel',
                'locations': ['start_menu']
            }
        ]
    
    def _get_file_associations(self):
        """Get file association definitions"""
        return [
            {
                'extension': '.ibav',
                'content_type': 'application/ibridge-antivirus-vault',
                'description': 'iBridge Antivirus Vault File',
                'icon': '[INSTALLDIR]resources\\vault_file.ico',
                'open_command': '[INSTALLDIR]data_vault\\vault_viewer.exe "%1"'
            }
        ]
    
    def _create_wix_source(self):
        """Create WiX source files"""
        print("Creating WiX source files...")
        
        # Create main WXS file
        wxs_content = self._generate_main_wxs()
        
        wxs_file = self.build_dir / "wix" / "product.wxs"
        with open(wxs_file, 'w', encoding='utf-8') as f:
            f.write(wxs_content)
        
        # Create feature definitions
        features_wxs = self._generate_features_wxs()
        features_file = self.build_dir / "wix" / "features.wxs"
        with open(features_file, 'w', encoding='utf-8') as f:
            f.write(features_wxs)
        
        # Create UI customization
        ui_wxs = self._generate_ui_wxs()
        ui_file = self.build_dir / "wix" / "ui.wxs"
        with open(ui_file, 'w', encoding='utf-8') as f:
            f.write(ui_wxs)
        
        return [wxs_file, features_file, ui_file]
    
    def _generate_main_wxs(self):
        """Generate main WiX source file"""
        install_dir_name = self.product_info['install_dir'].split('\\')[-1]
        return f'''<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="{self.product_info['product_code']}" 
           Name="{self.product_info['name']}" 
           Language="1033" 
           Version="{self.product_info['version']}" 
           Manufacturer="{self.product_info['manufacturer']}" 
           UpgradeCode="{self.product_info['upgrade_code']}">
    
    <Package InstallerVersion="200" 
             Compressed="yes" 
             InstallScope="perMachine" 
             Platform="x64"
             Description="{self.product_info['description']}"
             Comments="{self.product_info['copyright']}" />
    
    <MajorUpgrade DowngradeErrorMessage="A newer version of [ProductName] is already installed." />
    <MediaTemplate EmbedCab="yes" />
    
    <!-- System Requirements -->
    <Condition Message="This application requires Windows 10 or later.">
      <![CDATA[Installed OR (VersionNT >= 1000)]]>
    </Condition>
    
    <Condition Message="This application requires at least 2GB of RAM.">
      <![CDATA[Installed OR (PhysicalMemory >= 2048)]]>
    </Condition>
    
    <!-- Installation Directory -->
    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFiles64Folder">
        <Directory Id="ManufacturerFolder" Name="{self.product_info['manufacturer'].replace(' ', '')}">
          <Directory Id="INSTALLDIR" Name="{install_dir_name}" />
        </Directory>
      </Directory>
      
      <Directory Id="ProgramMenuFolder">
        <Directory Id="ApplicationProgramsFolder" Name="{self.product_info['start_menu_folder']}" />
      </Directory>
      
      <Directory Id="DesktopFolder" Name="Desktop" />
      <Directory Id="StartupFolder" Name="Startup" />
    </Directory>
    
    <!-- Components -->
    <DirectoryRef Id="INSTALLDIR">
      <Component Id="MainExecutable" Guid="{{11111111-1111-1111-1111-111111111111}}">
        <File Id="MainPython" Source="app\\main.py" KeyPath="yes" />
        <File Id="RequirementsTxt" Source="app\\requirements.txt" />
        <File Id="ReadmeMd" Source="app\\README.md" />
        <File Id="LicenseFile" Source="app\\LICENSE" />
      </Component>
      
      <Component Id="RegistryEntries" Guid="{{22222222-2222-2222-2222-222222222222}}">
        <RegistryKey Root="HKLM" Key="SOFTWARE\\iBridge\\Antivirus">
          <RegistryValue Name="InstallPath" Type="string" Value="[INSTALLDIR]" />
          <RegistryValue Name="Version" Type="string" Value="{self.product_info['version']}" />
          <RegistryValue Name="RealTimeProtection" Type="integer" Value="1" />
        </RegistryKey>
      </Component>
    </DirectoryRef>
    
    <!-- Shortcuts -->
    <DirectoryRef Id="ApplicationProgramsFolder">
      <Component Id="ApplicationShortcut" Guid="{{33333333-3333-3333-3333-333333333333}}">
        <Shortcut Id="ApplicationStartMenuShortcut"
                  Name="{self.product_info['name']}"
                  Description="{self.product_info['description']}"
                  Target="[INSTALLDIR]main.py"
                  WorkingDirectory="INSTALLDIR" />
        <RemoveFolder Id="ApplicationProgramsFolder" On="uninstall" />
        <RegistryValue Root="HKCU" Key="Software\\iBridge\\Antivirus" Name="installed" Type="integer" Value="1" KeyPath="yes" />
      </Component>
    </DirectoryRef>
    
    <!-- Services -->
    <Component Id="AntivirusService" Guid="{{44444444-4444-4444-4444-444444444444}}" Directory="INSTALLDIR">
      <File Id="AntivirusServiceExe" Source="app\\services\\antivirus_service.exe" />
      <ServiceInstall Id="AntivirusServiceInstall"
                      Type="ownProcess"
                      Vital="yes"
                      Name="iBridgeAntivirusService"
                      DisplayName="iBridge Antivirus Service"
                      Description="Real-time antivirus protection service"
                      Start="auto"
                      Account="LocalSystem"
                      ErrorControl="ignore"
                      Interactive="no" />
      <ServiceControl Id="StartAntivirusService" Start="install" Stop="both" Remove="uninstall" Name="iBridgeAntivirusService" Wait="yes" />
    </Component>
  </Product>
</Wix>'''
    
    def _generate_features_wxs(self):
        """Generate features WiX source"""
        features_xml = '''<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Fragment>
    <Feature Id="ProductFeature" Title="iBridge Antivirus Pro" Level="1">
      <ComponentRef Id="MainExecutable" />
      <ComponentRef Id="RegistryEntries" />
      <ComponentRef Id="ApplicationShortcut" />
      
      <Feature Id="CoreEngine" Title="Core Engine" Level="1" Description="Essential antivirus engine">
        <ComponentRef Id="AntivirusService" />
      </Feature>
      
      <Feature Id="FirewallProtection" Title="Firewall Protection" Level="1" Description="Network firewall protection">
        <!-- Firewall components would be added here -->
      </Feature>
      
      <Feature Id="VPNClient" Title="VPN Client" Level="2" Description="Secure VPN connectivity">
        <!-- VPN components would be added here -->
      </Feature>
      
      <Feature Id="DataVault" Title="Secure Data Vault" Level="2" Description="Encrypted file storage">
        <!-- Data vault components would be added here -->
      </Feature>
    </Feature>
  </Fragment>
</Wix>'''
        return features_xml
    
    def _generate_ui_wxs(self):
        """Generate UI customization WiX source"""
        ui_xml = '''<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Fragment>
    <UI Id="WixUI_FeatureTree">
      <UIRef Id="WixUI_FeatureTree" />
      <UIRef Id="WixUI_ErrorProgressText" />
      
      <DialogRef Id="LicenseAgreementDlg" />
      <DialogRef Id="FeaturesDlg" />
      <DialogRef Id="InstallDirDlg" />
      
      <!-- Custom welcome dialog -->
      <Publish Dialog="WelcomeDlg" Control="Next" Event="NewDialog" Value="LicenseAgreementDlg">1</Publish>
      <Publish Dialog="LicenseAgreementDlg" Control="Back" Event="NewDialog" Value="WelcomeDlg">1</Publish>
      <Publish Dialog="LicenseAgreementDlg" Control="Next" Event="NewDialog" Value="FeaturesDlg">LicenseAccepted = "1"</Publish>
      
      <!-- Custom images -->
      <Binary Id="WixUIBannerBmp" SourceFile="resources\\banner.bmp" />
      <Binary Id="WixUIDialogBmp" SourceFile="resources\\dialog.bmp" />
      <Binary Id="WixUIExclamationIco" SourceFile="resources\\exclamation.ico" />
      <Binary Id="WixUIInfoIco" SourceFile="resources\\info.ico" />
      <Binary Id="WixUINewIco" SourceFile="resources\\new.ico" />
      <Binary Id="WixUIUpIco" SourceFile="resources\\up.ico" />
    </UI>
    
    <!-- Custom properties -->
    <Property Id="WIXUI_INSTALLDIR" Value="INSTALLDIR" />
    <Property Id="ARPPRODUCTICON" Value="ProductIcon" />
    <Icon Id="ProductIcon" SourceFile="resources\\antivirus.ico" />
  </Fragment>
</Wix>'''
        return ui_xml
    
    def _build_msi_package(self):
        """Build MSI package using WiX"""
        print("Building MSI package...")
        
        try:
            wix_dir = self.build_dir / "wix"
            
            # Compile WiX source files
            wixobj_files = []
            for wxs_file in wix_dir.glob("*.wxs"):
                wixobj_file = wxs_file.with_suffix('.wixobj')
                
                # Mock WiX compilation (in real scenario, would use candle.exe)
                print(f"Compiling {wxs_file.name}...")
                # candle_cmd = f'candle.exe -out "{wixobj_file}" "{wxs_file}"'
                # subprocess.run(candle_cmd, shell=True, check=True)
                
                wixobj_files.append(str(wixobj_file))
            
            # Link MSI package
            msi_name = f"{self.product_info['name'].replace(' ', '_')}_{self.product_info['version']}.msi"
            msi_path = self.output_dir / msi_name
            
            print(f"Linking MSI package: {msi_name}")
            # Mock WiX linking (in real scenario, would use light.exe)
            # light_cmd = f'light.exe -out "{msi_path}" {" ".join(wixobj_files)}'
            # subprocess.run(light_cmd, shell=True, check=True)
            
            # Create mock MSI file for demonstration
            with open(msi_path, 'wb') as f:
                f.write(b'Mock MSI package content')
            
            print(f"MSI package created: {msi_path}")
            return msi_path
            
        except Exception as e:
            print(f"Error building MSI package: {e}")
            raise
    
    def _sign_installer(self, msi_path):
        """Sign installer with digital certificate"""
        print("Signing installer...")
        
        try:
            signed_msi = msi_path.with_name(f"signed_{msi_path.name}")
            
            # Mock signing process (in real scenario, would use signtool.exe)
            print("Applying digital signature...")
            # sign_cmd = f'signtool.exe sign /f certificate.pfx /p password /t http://timestamp.digicert.com "{msi_path}"'
            # subprocess.run(sign_cmd, shell=True, check=True)
            
            # Copy original to signed version for demonstration
            shutil.copy2(msi_path, signed_msi)
            
            print(f"Installer signed: {signed_msi}")
            return signed_msi
            
        except Exception as e:
            print(f"Error signing installer: {e}")
            return msi_path
    
    def _create_installer_bundle(self, msi_path):
        """Create installer bundle with dependencies"""
        print("Creating installer bundle...")
        
        try:
            bundle_name = f"{self.product_info['name'].replace(' ', '_')}_Setup_{self.product_info['version']}.exe"
            bundle_path = self.output_dir / bundle_name
            
            # Create self-extracting archive
            with zipfile.ZipFile(bundle_path, 'w', zipfile.ZIP_DEFLATED) as bundle:
                # Add MSI package
                bundle.write(msi_path, msi_path.name)
                
                # Add prerequisites
                prereq_info = {
                    'python': {
                        'name': 'Python 3.8+',
                        'url': 'https://www.python.org/downloads/',
                        'required': True
                    },
                    'dotnet': {
                        'name': '.NET Framework 4.7.2',
                        'url': 'https://dotnet.microsoft.com/download',
                        'required': True
                    },
                    'vcredist': {
                        'name': 'Visual C++ Redistributable',
                        'url': 'https://aka.ms/vs/17/release/vc_redist.x64.exe',
                        'required': True
                    }
                }
                
                # Add prerequisite information
                bundle.writestr('prerequisites.json', json.dumps(prereq_info, indent=2))
                
                # Add installer bootstrap script
                bootstrap_script = self._generate_bootstrap_script()
                bundle.writestr('setup.py', bootstrap_script)
                
                # Add configuration
                install_config = {
                    'product': self.product_info,
                    'requirements': self.system_requirements,
                    'components': self.components
                }
                bundle.writestr('install_config.json', json.dumps(install_config, indent=2))
            
            print(f"Installer bundle created: {bundle_path}")
            return bundle_path
            
        except Exception as e:
            print(f"Error creating installer bundle: {e}")
            raise
    
    def _generate_bootstrap_script(self):
        """Generate installer bootstrap script"""
        return '''#!/usr/bin/env python3
"""
iBridge Antivirus Pro Installer Bootstrap
"""

import os
import sys
import json
import subprocess
import tempfile
import zipfile
import urllib.request
from pathlib import Path

class InstallerBootstrap:
    def __init__(self):
        self.temp_dir = Path(tempfile.mkdtemp())
        self.config = self.load_config()
    
    def load_config(self):
        """Load installation configuration"""
        try:
            with open('install_config.json', 'r') as f:
                return json.load(f)
        except Exception as e:
            print(f"Error loading configuration: {e}")
            return {}
    
    def check_prerequisites(self):
        """Check system prerequisites"""
        print("Checking system prerequisites...")
        
        # Check Windows version
        if sys.platform != 'win32':
            print("Error: This installer is for Windows only")
            return False
        
        # Check Python version
        if sys.version_info < (3, 8):
            print("Error: Python 3.8 or later is required")
            return False
        
        # Check available disk space
        import shutil
        free_space = shutil.disk_usage('C:').free / (1024 * 1024)
        required_space = self.config.get('requirements', {}).get('disk_space_mb', 500)
        
        if free_space < required_space:
            print(f"Error: Insufficient disk space. Required: {required_space}MB, Available: {free_space:.0f}MB")
            return False
        
        print("Prerequisites check passed")
        return True
    
    def extract_installer(self):
        """Extract MSI installer"""
        print("Extracting installer...")
        
        try:
            # Find MSI file in current directory
            msi_files = [f for f in os.listdir('.') if f.endswith('.msi')]
            if not msi_files:
                print("Error: MSI installer not found")
                return None
            
            msi_path = Path(msi_files[0])
            extracted_msi = self.temp_dir / msi_path.name
            
            import shutil
            shutil.copy2(msi_path, extracted_msi)
            
            return extracted_msi
            
        except Exception as e:
            print(f"Error extracting installer: {e}")
            return None
    
    def run_installer(self, msi_path):
        """Run MSI installer"""
        print("Running installer...")
        
        try:
            # Build msiexec command
            cmd = [
                'msiexec.exe',
                '/i', str(msi_path),
                '/passive',  # Minimal UI
                'ALLUSERS=1'  # Install for all users
            ]
            
            # Run installer
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                print("Installation completed successfully")
                return True
            else:
                print(f"Installation failed: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"Error running installer: {e}")
            return False
    
    def cleanup(self):
        """Clean up temporary files"""
        try:
            import shutil
            shutil.rmtree(self.temp_dir)
        except Exception:
            pass
    
    def run(self):
        """Run installation process"""
        try:
            print("iBridge Antivirus Pro Installer")
            print("=" * 40)
            
            # Check prerequisites
            if not self.check_prerequisites():
                return 1
            
            # Extract installer
            msi_path = self.extract_installer()
            if not msi_path:
                return 1
            
            # Run installer
            if not self.run_installer(msi_path):
                return 1
            
            print("Installation completed successfully!")
            return 0
            
        except KeyboardInterrupt:
            print("\\nInstallation cancelled by user")
            return 1
        except Exception as e:
            print(f"Installation error: {e}")
            return 1
        finally:
            self.cleanup()

if __name__ == "__main__":
    bootstrap = InstallerBootstrap()
    sys.exit(bootstrap.run())
'''
    
    def _generate_checksums(self, bundle_path):
        """Generate checksums for installer files"""
        print("Generating checksums...")
        
        try:
            checksums = {}
            
            # Calculate SHA256 for bundle
            with open(bundle_path, 'rb') as f:
                data = f.read()
                sha256_hash = hashlib.sha256(data).hexdigest()
                checksums[bundle_path.name] = {
                    'sha256': sha256_hash,
                    'size': len(data),
                    'created': datetime.now().isoformat()
                }
            
            # Save checksums file
            checksums_file = bundle_path.with_name(f"{bundle_path.stem}_checksums.json")
            with open(checksums_file, 'w') as f:
                json.dump(checksums, f, indent=2)
            
            print(f"Checksums generated: {checksums_file}")
            return checksums_file
            
        except Exception as e:
            print(f"Error generating checksums: {e}")
            return None
    
    def create_uninstaller(self):
        """Create custom uninstaller"""
        print("Creating uninstaller...")
        
        try:
            uninstaller_content = '''#!/usr/bin/env python3
"""
iBridge Antivirus Pro Uninstaller
"""

import os
import sys
import subprocess
import winreg
from pathlib import Path

class AntivirusUninstaller:
    def __init__(self):
        self.product_code = "{12345678-1234-1234-1234-123456789012}"
        self.install_path = self.get_install_path()
    
    def get_install_path(self):
        """Get installation path from registry"""
        try:
            key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, 
                               "SOFTWARE\\\\iBridge\\\\Antivirus")
            install_path, _ = winreg.QueryValueEx(key, "InstallPath")
            winreg.CloseKey(key)
            return Path(install_path)
        except Exception:
            return None
    
    def stop_services(self):
        """Stop running services"""
        services = [
            "iBridgeAntivirusService",
            "iBridgeFirewallService"
        ]
        
        for service in services:
            try:
                subprocess.run(["sc", "stop", service], 
                             capture_output=True, check=False)
            except Exception:
                pass
    
    def remove_services(self):
        """Remove installed services"""
        services = [
            "iBridgeAntivirusService",
            "iBridgeFirewallService"
        ]
        
        for service in services:
            try:
                subprocess.run(["sc", "delete", service], 
                             capture_output=True, check=False)
            except Exception:
                pass
    
    def clean_registry(self):
        """Clean registry entries"""
        registry_keys = [
            "SOFTWARE\\\\iBridge\\\\Antivirus",
            "SOFTWARE\\\\Microsoft\\\\Windows\\\\CurrentVersion\\\\Uninstall\\\\{12345678-1234-1234-1234-123456789012}"
        ]
        
        for key_path in registry_keys:
            try:
                winreg.DeleteKey(winreg.HKEY_LOCAL_MACHINE, key_path)
            except Exception:
                pass
    
    def remove_files(self):
        """Remove installation files"""
        if self.install_path and self.install_path.exists():
            try:
                import shutil
                shutil.rmtree(self.install_path)
            except Exception as e:
                print(f"Warning: Could not remove all files: {e}")
    
    def uninstall(self):
        """Perform complete uninstallation"""
        print("iBridge Antivirus Pro Uninstaller")
        print("=" * 40)
        
        try:
            print("Stopping services...")
            self.stop_services()
            
            print("Removing services...")
            self.remove_services()
            
            print("Cleaning registry...")
            self.clean_registry()
            
            print("Removing files...")
            self.remove_files()
            
            print("Uninstallation completed successfully!")
            return True
            
        except Exception as e:
            print(f"Uninstallation error: {e}")
            return False

if __name__ == "__main__":
    uninstaller = AntivirusUninstaller()
    success = uninstaller.uninstall()
    sys.exit(0 if success else 1)
'''
            
            uninstaller_file = self.output_dir / "uninstall.py"
            with open(uninstaller_file, 'w') as f:
                f.write(uninstaller_content)
            
            print(f"Uninstaller created: {uninstaller_file}")
            return uninstaller_file
            
        except Exception as e:
            print(f"Error creating uninstaller: {e}")
            return None

def main():
    """Main installer builder function"""
    builder = WindowsInstallerBuilder()
    
    print("iBridge Antivirus Pro - Installer Builder")
    print("=" * 50)
    
    # Create installer package
    bundle_path = builder.create_installer_package()
    
    if bundle_path:
        print(f"\\nInstaller package created successfully!")
        print(f"Location: {bundle_path}")
        
        # Create uninstaller
        uninstaller_path = builder.create_uninstaller()
        if uninstaller_path:
            print(f"Uninstaller created: {uninstaller_path}")
        
        return True
    else:
        print("\\nFailed to create installer package")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)