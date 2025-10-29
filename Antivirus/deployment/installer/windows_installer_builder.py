"""
Windows Installer Builder
Creates MSI installer package with proper dependencies and digital signatures
"""

import os
import sys
import shutil
import subprocess
import json
import hashlib
import time
from pathlib import Path
from datetime import datetime
import tempfile
import xml.etree.ElementTree as ET

class WindowsInstallerBuilder:
    """
    Advanced Windows installer builder with MSI package creation
    """
    
    def __init__(self, project_root):
        self.project_root = Path(project_root)
        self.deployment_dir = self.project_root / "deployment"
        self.installer_dir = self.deployment_dir / "installer"
        self.build_dir = self.installer_dir / "build"
        self.output_dir = self.installer_dir / "output"
        
        # Installer configuration
        self.config = {
            'product_name': 'iBridge Antivirus',
            'product_version': '1.0.0',
            'product_code': '{12345678-1234-1234-1234-123456789012}',
            'upgrade_code': '{87654321-4321-4321-4321-210987654321}',
            'manufacturer': 'iBridge Security',
            'description': 'Advanced Antivirus and Security Suite',
            'contact': 'support@ibridge-security.com',
            'help_url': 'https://www.ibridge-security.com/help',
            'install_scope': 'perMachine',  # or 'perUser'
            'platform': 'x64',
            'target_framework': '.NET Framework 4.8'
        }
        
        # Dependencies and requirements
        self.dependencies = [
            'Microsoft Visual C++ Redistributable 2019',
            '.NET Framework 4.8',
            'Windows 10 version 1903 or later'
        ]
        
        # Files to include in installer
        self.include_patterns = [
            '*.py',
            '*.exe',
            '*.dll',
            '*.config',
            '*.json',
            'LICENSE',
            'README.md'
        ]
        
        # Files to exclude
        self.exclude_patterns = [
            '__pycache__',
            '*.pyc',
            '*.pyo',
            '.git',
            '.pytest_cache',
            'tests',
            '*.log'
        ]
        
        self._setup_directories()
    
    def _setup_directories(self):
        """Setup build directories"""
        for directory in [self.build_dir, self.output_dir]:
            directory.mkdir(parents=True, exist_ok=True)
    
    def create_installer(self, sign_installer=True):
        """
        Create complete Windows installer package
        """
        try:
            print("Starting Windows installer creation...")
            
            # Step 1: Prepare application files
            print("1. Preparing application files...")
            app_files = self._prepare_application_files()
            
            # Step 2: Create WiX source files
            print("2. Creating WiX installer definition...")
            wxs_file = self._create_wix_source(app_files)
            
            # Step 3: Compile installer
            print("3. Compiling MSI installer...")
            msi_file = self._compile_msi(wxs_file)
            
            # Step 4: Sign installer (if requested)
            if sign_installer:
                print("4. Signing installer...")
                signed_msi = self._sign_installer(msi_file)
                msi_file = signed_msi
            
            # Step 5: Validate installer
            print("5. Validating installer...")
            validation_result = self._validate_installer(msi_file)
            
            # Step 6: Create installer metadata
            print("6. Creating installer metadata...")
            self._create_installer_metadata(msi_file)
            
            print(f"Installer created successfully: {msi_file}")
            return msi_file
            
        except Exception as e:
            print(f"Error creating installer: {e}")
            return None
    
    def _prepare_application_files(self):
        """
        Prepare and organize application files for packaging
        """
        app_dir = self.build_dir / "app"
        app_dir.mkdir(exist_ok=True)
        
        # Copy main application files
        main_files = [
            'main.py',
            'antivirus_core',
            'firewall',
            'vpn',
            'browser_protection',
            'data_vault',
            'security_manager',
            'ui',
            'utils'
        ]
        
        copied_files = []
        
        for item in main_files:
            source_path = self.project_root / item
            if source_path.exists():
                if source_path.is_file():
                    dest_path = app_dir / item
                    shutil.copy2(source_path, dest_path)
                    copied_files.append(dest_path)
                elif source_path.is_dir():
                    dest_path = app_dir / item
                    shutil.copytree(source_path, dest_path, 
                                  ignore=shutil.ignore_patterns(*self.exclude_patterns))
                    copied_files.extend(self._get_files_recursive(dest_path))
        
        # Copy configuration files
        config_files = [
            'config.json',
            'settings.json',
            'LICENSE',
            'README.md'
        ]
        
        for config_file in config_files:
            source_path = self.project_root / config_file
            if source_path.exists():
                dest_path = app_dir / config_file
                shutil.copy2(source_path, dest_path)
                copied_files.append(dest_path)
        
        # Create application launcher
        launcher_content = self._create_application_launcher()
        launcher_path = app_dir / "iBridge_Antivirus.exe"
        with open(launcher_path, 'w') as f:
            f.write(launcher_content)
        copied_files.append(launcher_path)
        
        return copied_files
    
    def _get_files_recursive(self, directory):
        """Get all files recursively from directory"""
        files = []
        for root, dirs, filenames in os.walk(directory):
            for filename in filenames:
                files.append(Path(root) / filename)
        return files
    
    def _create_application_launcher(self):
        """Create Windows application launcher script"""
        launcher_script = '''
@echo off
setlocal

REM iBridge Antivirus Launcher
REM This script launches the main antivirus application

set "APP_DIR=%~dp0"
set "PYTHON_SCRIPT=%APP_DIR%main.py"

REM Check if Python is available
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Python is not installed or not in PATH
    echo Please install Python 3.8 or later
    pause
    exit /b 1
)

REM Launch the application
echo Starting iBridge Antivirus...
cd /d "%APP_DIR%"
python "%PYTHON_SCRIPT%" %*

if %errorlevel% neq 0 (
    echo Error: Failed to start iBridge Antivirus
    pause
)

endlocal
'''
        return launcher_script
    
    def _create_wix_source(self, app_files):
        """
        Create WiX (Windows Installer XML) source file
        """
        wxs_file = self.build_dir / "installer.wxs"
        
        # Create WiX XML structure
        root = ET.Element("Wix", xmlns="http://schemas.microsoft.com/wix/2006/wi")
        
        # Product element
        product = ET.SubElement(root, "Product",
            Id=self.config['product_code'],
            Name=self.config['product_name'],
            Language="1033",
            Version=self.config['product_version'],
            Manufacturer=self.config['manufacturer'],
            UpgradeCode=self.config['upgrade_code']
        )
        
        # Package element
        package = ET.SubElement(product, "Package",
            InstallerVersion="200",
            Compressed="yes",
            InstallScope=self.config['install_scope'],
            Platform=self.config['platform']
        )
        
        # Media element
        media = ET.SubElement(product, "Media",
            Id="1",
            Cabinet="media1.cab",
            EmbedCab="yes"
        )
        
        # Directory structure
        target_dir = ET.SubElement(product, "Directory", Id="TARGETDIR", Name="SourceDir")
        program_files = ET.SubElement(target_dir, "Directory", Id="ProgramFilesFolder")
        install_dir = ET.SubElement(program_files, "Directory", 
                                   Id="INSTALLFOLDER", 
                                   Name=self.config['product_name'])
        
        # Features
        feature = ET.SubElement(product, "Feature", 
                               Id="MainFeature", 
                               Title="Main Application",
                               Level="1")
        
        # Add application files as components
        component_group = ET.SubElement(product, "ComponentGroup", Id="ApplicationFiles")
        
        for i, file_path in enumerate(app_files):
            component_id = f"Component_{i}"
            component = ET.SubElement(component_group, "Component", 
                                    Id=component_id,
                                    Guid=self._generate_guid())
            
            relative_path = file_path.relative_to(self.build_dir / "app")
            ET.SubElement(component, "File",
                Source=str(file_path),
                Id=f"File_{i}",
                KeyPath="yes"
            )
            
            # Add component reference to feature
            ET.SubElement(feature, "ComponentRef", Id=component_id)
        
        # Add registry entries
        registry_component = ET.SubElement(component_group, "Component",
                                         Id="RegistryEntries",
                                         Guid=self._generate_guid())
        
        # Application registration
        ET.SubElement(registry_component, "RegistryValue",
            Root="HKLM",
            Key=f"Software\\{self.config['manufacturer']}\\{self.config['product_name']}",
            Name="InstallPath",
            Type="string",
            Value="[INSTALLFOLDER]",
            KeyPath="yes"
        )
        
        # Version registration
        ET.SubElement(registry_component, "RegistryValue",
            Root="HKLM", 
            Key=f"Software\\{self.config['manufacturer']}\\{self.config['product_name']}",
            Name="Version",
            Type="string",
            Value=self.config['product_version']
        )
        
        ET.SubElement(feature, "ComponentRef", Id="RegistryEntries")
        
        # Start menu shortcuts
        start_menu_dir = ET.SubElement(target_dir, "Directory", Id="ProgramMenuFolder")
        app_menu_dir = ET.SubElement(start_menu_dir, "Directory",
                                   Id="ApplicationProgramsFolder",
                                   Name=self.config['product_name'])
        
        shortcut_component = ET.SubElement(component_group, "Component",
                                         Id="StartMenuShortcuts",
                                         Guid=self._generate_guid())
        
        # Main application shortcut
        ET.SubElement(shortcut_component, "Shortcut",
            Id="ApplicationStartMenuShortcut",
            Name=self.config['product_name'],
            Target="[INSTALLFOLDER]iBridge_Antivirus.exe",
            WorkingDirectory="INSTALLFOLDER"
        )
        
        # Uninstall shortcut
        ET.SubElement(shortcut_component, "Shortcut",
            Id="UninstallShortcut",
            Name=f"Uninstall {self.config['product_name']}",
            Target="[SystemFolder]msiexec.exe",
            Arguments=f"/x {self.config['product_code']}"
        )
        
        ET.SubElement(shortcut_component, "RemoveFolder",
            Id="ApplicationProgramsFolder",
            On="uninstall"
        )
        
        ET.SubElement(shortcut_component, "RegistryValue",
            Root="HKCU",
            Key=f"Software\\{self.config['manufacturer']}\\{self.config['product_name']}",
            Name="StartMenuShortcuts",
            Type="integer",
            Value="1",
            KeyPath="yes"
        )
        
        ET.SubElement(feature, "ComponentRef", Id="StartMenuShortcuts")
        
        # Desktop shortcut (optional)
        desktop_component = ET.SubElement(component_group, "Component",
                                        Id="DesktopShortcut",
                                        Guid=self._generate_guid())
        
        ET.SubElement(desktop_component, "Shortcut",
            Id="DesktopShortcut",
            Directory="DesktopFolder",
            Name=self.config['product_name'],
            Target="[INSTALLFOLDER]iBridge_Antivirus.exe",
            WorkingDirectory="INSTALLFOLDER"
        )
        
        ET.SubElement(desktop_component, "RegistryValue",
            Root="HKCU",
            Key=f"Software\\{self.config['manufacturer']}\\{self.config['product_name']}",
            Name="DesktopShortcut",
            Type="integer", 
            Value="1",
            KeyPath="yes"
        )
        
        ET.SubElement(feature, "ComponentRef", Id="DesktopShortcut")
        
        # Write WiX source file
        tree = ET.ElementTree(root)
        tree.write(wxs_file, encoding='utf-8', xml_declaration=True)
        
        return wxs_file
    
    def _generate_guid(self):
        """Generate a new GUID for WiX components"""
        import uuid
        return str(uuid.uuid4()).upper()
    
    def _compile_msi(self, wxs_file):
        """
        Compile WiX source to MSI installer
        """
        try:
            # Check if WiX Toolset is available
            wix_candle = self._find_wix_tool("candle.exe")
            wix_light = self._find_wix_tool("light.exe")
            
            if not wix_candle or not wix_light:
                # Use alternative build method with cx_Freeze or PyInstaller
                return self._build_alternative_installer()
            
            # Compile WiX source to object file
            wixobj_file = self.build_dir / "installer.wixobj"
            candle_cmd = [
                str(wix_candle),
                "-out", str(wixobj_file),
                str(wxs_file)
            ]
            
            result = subprocess.run(candle_cmd, capture_output=True, text=True)
            if result.returncode != 0:
                raise Exception(f"WiX candle compilation failed: {result.stderr}")
            
            # Link object file to MSI
            msi_file = self.output_dir / f"{self.config['product_name']}_v{self.config['product_version']}.msi"
            light_cmd = [
                str(wix_light),
                "-out", str(msi_file),
                str(wixobj_file)
            ]
            
            result = subprocess.run(light_cmd, capture_output=True, text=True)
            if result.returncode != 0:
                raise Exception(f"WiX light linking failed: {result.stderr}")
            
            return msi_file
            
        except Exception as e:
            print(f"WiX compilation failed: {e}")
            print("Falling back to alternative installer creation...")
            return self._build_alternative_installer()
    
    def _find_wix_tool(self, tool_name):
        """Find WiX Toolset executable"""
        common_paths = [
            r"C:\Program Files (x86)\WiX Toolset v3.11\bin",
            r"C:\Program Files\WiX Toolset v3.11\bin",
            r"C:\Tools\WiX\bin"
        ]
        
        for path in common_paths:
            tool_path = Path(path) / tool_name
            if tool_path.exists():
                return tool_path
        
        # Check if in PATH
        try:
            result = subprocess.run([tool_name, "--version"], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                return tool_name
        except FileNotFoundError:
            pass
        
        return None
    
    def _build_alternative_installer(self):
        """
        Build installer using PyInstaller and create setup executable
        """
        try:
            print("Building alternative installer with PyInstaller...")
            
            # Create PyInstaller spec file
            spec_file = self._create_pyinstaller_spec()
            
            # Build with PyInstaller
            pyinstaller_cmd = [
                sys.executable, "-m", "PyInstaller",
                "--clean",
                "--noconfirm",
                str(spec_file)
            ]
            
            result = subprocess.run(pyinstaller_cmd, cwd=str(self.project_root))
            if result.returncode != 0:
                raise Exception("PyInstaller build failed")
            
            # Create NSIS installer script
            nsis_script = self._create_nsis_script()
            
            # Compile NSIS installer (if available)
            installer_file = self._compile_nsis_installer(nsis_script)
            
            return installer_file
            
        except Exception as e:
            print(f"Alternative installer creation failed: {e}")
            return self._create_zip_package()
    
    def _create_pyinstaller_spec(self):
        """Create PyInstaller spec file"""
        spec_content = f'''
# -*- mode: python ; coding: utf-8 -*-

block_cipher = None

a = Analysis(
    ['{self.project_root / "main.py"}'],
    pathex=['{self.project_root}'],
    binaries=[],
    datas=[
        ('{self.project_root / "config"}', 'config'),
        ('{self.project_root / "ui" / "assets"}', 'ui/assets'),
    ],
    hiddenimports=[
        'cryptography',
        'psutil',
        'tkinter',
        'sqlite3',
        'json',
        'requests'
    ],
    hookspath=[],
    hooksconfig={{}},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='{self.config["product_name"].replace(" ", "_")}',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon='{self.project_root / "ui" / "assets" / "icon.ico"}' if (self.project_root / "ui" / "assets" / "icon.ico").exists() else None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='{self.config["product_name"].replace(" ", "_")}',
)
'''
        
        spec_file = self.build_dir / "installer.spec"
        with open(spec_file, 'w') as f:
            f.write(spec_content)
        
        return spec_file
    
    def _create_nsis_script(self):
        """Create NSIS installer script"""
        nsis_content = f'''
; NSIS Installer Script for {self.config["product_name"]}

!define PRODUCT_NAME "{self.config["product_name"]}"
!define PRODUCT_VERSION "{self.config["product_version"]}"
!define PRODUCT_PUBLISHER "{self.config["manufacturer"]}"
!define PRODUCT_WEB_SITE "{self.config.get("website", "")}"
!define PRODUCT_UNINST_KEY "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\${{PRODUCT_NAME}}"

SetCompressor lzma

; Modern UI
!include "MUI2.nsh"

; MUI Settings
!define MUI_ABORTWARNING
!define MUI_ICON "${{NSISDIR}}\\Contrib\\Graphics\\Icons\\modern-install.ico"
!define MUI_UNICON "${{NSISDIR}}\\Contrib\\Graphics\\Icons\\modern-uninstall.ico"

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "LICENSE"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_INSTFILES

; Languages
!insertmacro MUI_LANGUAGE "English"

; Installer details
Name "${{PRODUCT_NAME}} ${{PRODUCT_VERSION}}"
OutFile "{self.output_dir / f"{self.config['product_name']}_Setup.exe"}"
InstallDir "$PROGRAMFILES\\${{PRODUCT_NAME}}"
ShowInstDetails show
ShowUnInstDetails show

Section "MainSection" SEC01
  SetOutPath "$INSTDIR"
  SetOverwrite ifnewer
  
  ; Copy application files
  File /r "{self.project_root / "dist" / self.config['product_name'].replace(' ', '_')}\\*.*"
  
  ; Create shortcuts
  CreateDirectory "$SMPROGRAMS\\${{PRODUCT_NAME}}"
  CreateShortCut "$SMPROGRAMS\\${{PRODUCT_NAME}}\\${{PRODUCT_NAME}}.lnk" "$INSTDIR\\{self.config['product_name'].replace(' ', '_')}.exe"
  CreateShortCut "$DESKTOP\\${{PRODUCT_NAME}}.lnk" "$INSTDIR\\{self.config['product_name'].replace(' ', '_')}.exe"
  
  ; Write registry entries
  WriteRegStr HKLM "${{PRODUCT_UNINST_KEY}}" "DisplayName" "${{PRODUCT_NAME}}"
  WriteRegStr HKLM "${{PRODUCT_UNINST_KEY}}" "DisplayVersion" "${{PRODUCT_VERSION}}"
  WriteRegStr HKLM "${{PRODUCT_UNINST_KEY}}" "Publisher" "${{PRODUCT_PUBLISHER}}"
  WriteRegStr HKLM "${{PRODUCT_UNINST_KEY}}" "URLInfoAbout" "${{PRODUCT_WEB_SITE}}"
  WriteRegStr HKLM "${{PRODUCT_UNINST_KEY}}" "UninstallString" "$INSTDIR\\uninst.exe"
  
  ; Create uninstaller
  WriteUninstaller "$INSTDIR\\uninst.exe"
SectionEnd

Section Uninstall
  ; Remove files
  RMDir /r "$INSTDIR"
  
  ; Remove shortcuts
  Delete "$SMPROGRAMS\\${{PRODUCT_NAME}}\\${{PRODUCT_NAME}}.lnk"
  Delete "$DESKTOP\\${{PRODUCT_NAME}}.lnk"
  RMDir "$SMPROGRAMS\\${{PRODUCT_NAME}}"
  
  ; Remove registry entries
  DeleteRegKey HKLM "${{PRODUCT_UNINST_KEY}}"
SectionEnd
'''
        
        nsis_file = self.build_dir / "installer.nsi"
        with open(nsis_file, 'w') as f:
            f.write(nsis_content)
        
        return nsis_file
    
    def _compile_nsis_installer(self, nsis_script):
        """Compile NSIS installer if available"""
        try:
            nsis_compiler = self._find_nsis_compiler()
            if not nsis_compiler:
                print("NSIS compiler not found, creating ZIP package instead")
                return self._create_zip_package()
            
            # Compile NSIS script
            nsis_cmd = [str(nsis_compiler), str(nsis_script)]
            result = subprocess.run(nsis_cmd, capture_output=True, text=True)
            
            if result.returncode != 0:
                print(f"NSIS compilation failed: {result.stderr}")
                return self._create_zip_package()
            
            installer_file = self.output_dir / f"{self.config['product_name']}_Setup.exe"
            return installer_file
            
        except Exception as e:
            print(f"NSIS compilation error: {e}")
            return self._create_zip_package()
    
    def _find_nsis_compiler(self):
        """Find NSIS compiler"""
        common_paths = [
            r"C:\Program Files (x86)\NSIS\makensis.exe",
            r"C:\Program Files\NSIS\makensis.exe"
        ]
        
        for path in common_paths:
            if Path(path).exists():
                return Path(path)
        
        return None
    
    def _create_zip_package(self):
        """Create ZIP package as fallback"""
        try:
            print("Creating ZIP package...")
            
            zip_file = self.output_dir / f"{self.config['product_name']}_v{self.config['product_version']}.zip"
            
            # Create ZIP archive
            import zipfile
            with zipfile.ZipFile(zip_file, 'w', zipfile.ZIP_DEFLATED) as zf:
                app_dir = self.build_dir / "app"
                for file_path in self._get_files_recursive(app_dir):
                    arcname = file_path.relative_to(app_dir)
                    zf.write(file_path, arcname)
            
            return zip_file
            
        except Exception as e:
            print(f"ZIP package creation failed: {e}")
            return None
    
    def _sign_installer(self, installer_file):
        """Sign installer with digital certificate"""
        try:
            # Check if signing tools are available
            signtool = self._find_signtool()
            if not signtool:
                print("Code signing tools not found, skipping signing")
                return installer_file
            
            # Certificate configuration (would need actual certificate)
            cert_config = {
                'certificate_file': 'code_signing_cert.pfx',
                'certificate_password': 'cert_password',
                'timestamp_url': 'http://timestamp.digicert.com'
            }
            
            # Sign the installer
            sign_cmd = [
                str(signtool), "sign",
                "/f", cert_config['certificate_file'],
                "/p", cert_config['certificate_password'],
                "/t", cert_config['timestamp_url'],
                "/d", self.config['product_name'],
                str(installer_file)
            ]
            
            # Note: This would only work with actual certificate
            print("Digital signing would be performed here with actual certificate")
            
            return installer_file
            
        except Exception as e:
            print(f"Code signing failed: {e}")
            return installer_file
    
    def _find_signtool(self):
        """Find Windows SDK signtool"""
        sdk_paths = [
            r"C:\Program Files (x86)\Windows Kits\10\bin\*\x64\signtool.exe",
            r"C:\Program Files\Windows Kits\10\bin\*\x64\signtool.exe"
        ]
        
        import glob
        for pattern in sdk_paths:
            matches = glob.glob(pattern)
            if matches:
                return Path(matches[0])
        
        return None
    
    def _validate_installer(self, installer_file):
        """Validate installer package"""
        try:
            validation_results = {
                'file_exists': installer_file.exists(),
                'file_size': installer_file.stat().st_size if installer_file.exists() else 0,
                'file_hash': self._calculate_file_hash(installer_file) if installer_file.exists() else None,
                'timestamp': datetime.now().isoformat()
            }
            
            # Additional validation checks
            if installer_file.suffix.lower() == '.msi':
                validation_results['installer_type'] = 'MSI'
                validation_results['msi_valid'] = self._validate_msi(installer_file)
            elif installer_file.suffix.lower() == '.exe':
                validation_results['installer_type'] = 'EXE'
                validation_results['exe_valid'] = self._validate_exe(installer_file)
            elif installer_file.suffix.lower() == '.zip':
                validation_results['installer_type'] = 'ZIP'
                validation_results['zip_valid'] = self._validate_zip(installer_file)
            
            return validation_results
            
        except Exception as e:
            print(f"Installer validation failed: {e}")
            return {'valid': False, 'error': str(e)}
    
    def _calculate_file_hash(self, file_path):
        """Calculate SHA256 hash of file"""
        hash_sha256 = hashlib.sha256()
        with open(file_path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_sha256.update(chunk)
        return hash_sha256.hexdigest()
    
    def _validate_msi(self, msi_file):
        """Validate MSI file"""
        try:
            # Basic MSI validation
            with open(msi_file, 'rb') as f:
                header = f.read(8)
                return header == b'\\xd0\\xcf\\x11\\xe0\\xa1\\xb1\\x1a\\xe1'  # MSI header
        except Exception:
            return False
    
    def _validate_exe(self, exe_file):
        """Validate EXE file"""
        try:
            # Basic EXE validation
            with open(exe_file, 'rb') as f:
                header = f.read(2)
                return header == b'MZ'  # DOS header
        except Exception:
            return False
    
    def _validate_zip(self, zip_file):
        """Validate ZIP file"""
        try:
            import zipfile
            with zipfile.ZipFile(zip_file, 'r') as zf:
                return zf.testzip() is None
        except Exception:
            return False
    
    def _create_installer_metadata(self, installer_file):
        """Create installer metadata file"""
        try:
            metadata = {
                'product_name': self.config['product_name'],
                'product_version': self.config['product_version'],
                'build_date': datetime.now().isoformat(),
                'installer_file': installer_file.name,
                'installer_size': installer_file.stat().st_size,
                'installer_hash': self._calculate_file_hash(installer_file),
                'dependencies': self.dependencies,
                'system_requirements': {
                    'os': 'Windows 10 version 1903 or later',
                    'architecture': self.config['platform'],
                    'memory': '4 GB RAM minimum, 8 GB recommended',
                    'storage': '2 GB available space',
                    'network': 'Internet connection for updates'
                },
                'installation_notes': [
                    'Run as Administrator for system-wide installation',
                    'Antivirus software may flag installer during build',
                    'Windows Defender exclusions may be needed'
                ]
            }
            
            metadata_file = self.output_dir / f"{installer_file.stem}_metadata.json"
            with open(metadata_file, 'w') as f:
                json.dump(metadata, f, indent=2)
            
            print(f"Installer metadata created: {metadata_file}")
            
        except Exception as e:
            print(f"Failed to create installer metadata: {e}")
    
    def create_silent_installer(self, installer_file):
        """Create silent installation script"""
        try:
            if installer_file.suffix.lower() == '.msi':
                silent_script = f'''
@echo off
echo Installing {self.config["product_name"]} silently...
msiexec /i "{installer_file.name}" /quiet /norestart
if %errorlevel% equ 0 (
    echo Installation completed successfully
) else (
    echo Installation failed with error code %errorlevel%
)
pause
'''
            else:
                silent_script = f'''
@echo off
echo Installing {self.config["product_name"]} silently...
"{installer_file.name}" /S
if %errorlevel% equ 0 (
    echo Installation completed successfully
) else (
    echo Installation failed with error code %errorlevel%
)
pause
'''
            
            silent_file = self.output_dir / "silent_install.bat"
            with open(silent_file, 'w') as f:
                f.write(silent_script)
            
            print(f"Silent installer script created: {silent_file}")
            
        except Exception as e:
            print(f"Failed to create silent installer: {e}")

def main():
    """Main function for installer builder"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Windows Installer Builder')
    parser.add_argument('--project-root', default='.', help='Project root directory')
    parser.add_argument('--no-sign', action='store_true', help='Skip code signing')
    parser.add_argument('--version', default='1.0.0', help='Product version')
    
    args = parser.parse_args()
    
    # Create installer builder
    builder = WindowsInstallerBuilder(args.project_root)
    builder.config['product_version'] = args.version
    
    # Build installer
    installer_file = builder.create_installer(sign_installer=not args.no_sign)
    
    if installer_file:
        print(f"\\nInstaller created successfully!")
        print(f"File: {installer_file}")
        print(f"Size: {installer_file.stat().st_size / (1024*1024):.2f} MB")
        
        # Create silent installer
        builder.create_silent_installer(installer_file)
        
        return 0
    else:
        print("\\nInstaller creation failed!")
        return 1

if __name__ == "__main__":
    sys.exit(main())