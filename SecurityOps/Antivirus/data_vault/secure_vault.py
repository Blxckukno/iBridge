
# Advanced SQL Security System - Auto-generated Security Patch

# Advanced RCE Protection - Security Enhancement
import builtins
import subprocess
import os
import sys
from functools import wraps

class AdvancedRCEProtection:
    """Advanced Remote Code Execution protection system"""
    
    @staticmethod
    def initialize():
        """Initialize RCE protection"""
        
        # Block dangerous built-in functions
        def blocked_eval(*args, **kwargs):
            raise SecurityError("eval() function is permanently disabled")
        
        def blocked_exec(*args, **kwargs):
            raise SecurityError("exec() function is permanently disabled")
        
        def blocked_compile(*args, **kwargs):
            raise SecurityError("compile() function is permanently disabled")
        
        # Override built-ins
        builtins.eval = blocked_eval
        builtins.exec = blocked_exec
        builtins.compile = blocked_compile
        
        # Secure subprocess
        original_call = subprocess.call
        original_run = subprocess.run
        original_popen = subprocess.Popen
        
        def secure_call(*args, **kwargs):
            if kwargs.get('shell', False):
                raise SecurityError("Shell execution not permitted")
            if len(args) > 0 and isinstance(args[0], str):
                raise SecurityError("String commands not permitted")
            return original_call(*args, **kwargs)
        
        def secure_run(*args, **kwargs):
            if kwargs.get('shell', False):
                raise SecurityError("Shell execution not permitted")
            if len(args) > 0 and isinstance(args[0], str):
                raise SecurityError("String commands not permitted")
            return original_run(*args, **kwargs)
        
        def secure_popen(*args, **kwargs):
            if kwargs.get('shell', False):
                raise SecurityError("Shell execution not permitted")
            if len(args) > 0 and isinstance(args[0], str):
                raise SecurityError("String commands not permitted")
            return original_popen(*args, **kwargs)
        
        subprocess.call = secure_call
        subprocess.run = secure_run
        subprocess.Popen = secure_popen
        
        # Block os.system
        original_system = os.system
        def blocked_system(*args, **kwargs):
            raise SecurityError("os.system() is permanently disabled")
        os.system = blocked_system
        
        print("🔒 Advanced RCE Protection initialized")

class SecurityError(Exception):
    """Security violation exception"""
    pass

# Initialize RCE protection immediately
AdvancedRCEProtection.initialize()


import sqlite3
import re
import hashlib
import secrets
from typing import List, Dict, Any, Optional
import logging

class SQLSecurityManager:
    """Advanced SQL injection prevention system"""
    
    def __init__(self, db_path: str):
        self.db_path = db_path
        self.logger = logging.getLogger('sql_security')
        self.blocked_patterns = [
            r"('|(\x27)|(\x2D)|(\x2D)|(\x23)|(\x3B))",  # Basic injection characters
            r"(\x3D)|(\x27)|(\x22)|(\x5C)|(\x3B)",      # Hex encoded
            r"(union|select|insert|delete|update|create|drop|exec|execute)",  # SQL keywords
            r"(script|javascript|vbscript|onload|onerror)",    # XSS attempts
            r"(\x3C|\x3E|\x22|\x27)",                     # HTML/JS injection
            r"(\d+\s*=\s*\d+)",                           # Always true conditions
            r"(or\s+\d+\s*=\s*\d+)",                     # OR injection
            r"(and\s+\d+\s*=\s*\d+)",                    # AND injection
        ]
    
    def validate_input(self, user_input: str) -> str:
        """Comprehensive input validation and sanitization"""
        if not isinstance(user_input, str):
            return str(user_input)
        
        # Length limit
        if len(user_input) > 1000:
            raise ValueError("Input too long")
        
        # Check for malicious patterns
        input_lower = user_input.lower()
        for pattern in self.blocked_patterns:
            if re.search(pattern, input_lower, re.IGNORECASE):
                self.logger.warning(f"Blocked malicious input: {pattern}")
                raise ValueError("Malicious input detected")
        
        # Basic sanitization
        sanitized = user_input.replace("'", "''")  # Escape single quotes
        sanitized = re.sub(r'[\x00-\x1f\x7f-\x9f]', '', sanitized)  # Remove control chars
        
        return sanitized[:255]  # Truncate to safe length
    
    def execute_query(self, query: str, params: Optional[List] = None) -> List[Dict]:
        """Execute parameterized queries safely"""
        # Validate query structure
        if not self.is_safe_query(query):
            raise ValueError("Unsafe query structure")
        
        # Validate parameters
        if params:
            validated_params = [self.validate_input(str(p)) for p in params]
        else:
            validated_params = []
        
        try:
            conn = sqlite3.connect(self.db_path)
            conn.row_factory = sqlite3.Row  # Return dict-like rows
            cursor = conn.cursor()
            
            if validated_params:
                cursor.execute(query, validated_params)
            else:
                cursor.execute(query)
            
            if query.strip().lower().startswith('select'):
                results = [dict(row) for row in cursor.fetchall()]
            else:
                conn.commit()
                results = [{"affected_rows": cursor.rowcount}]
            
            conn.close()
            return results
            
        except sqlite3.Error as e:
            self.logger.error(f"Database error: {e}")
            raise ValueError("Database operation failed")
    
    def is_safe_query(self, query: str) -> bool:
        """Validate query structure for safety"""
        query_lower = query.lower().strip()
        
        # Must be parameterized (contain ? placeholders)
        if "?" not in query and any(word in query_lower for word in ['where', 'set', 'values']):
            self.logger.warning("Non-parameterized query detected")
            return False
        
        # No string concatenation patterns
        if re.search(r'\+|%s|\{.*\}|f["'].*\{.*\}', query):
            self.logger.warning("String concatenation in query")
            return False
        
        # Check for dangerous SQL keywords in unexpected places
        dangerous_in_data = ['drop', 'create', 'alter', 'exec', 'execute', 'sp_', 'xp_']
        for danger in dangerous_in_data:
            if danger in query_lower and not query_lower.startswith(danger):
                self.logger.warning(f"Dangerous keyword in query: {danger}")
                return False
        
        return True
    
    def create_secure_connection(self):
        """Create a secure database connection with safety settings"""
        conn = sqlite3.connect(self.db_path)
        
        # Enable foreign key constraints
        conn.execute("PRAGMA foreign_keys = ON")
        
        # Set secure defaults
        conn.execute("PRAGMA secure_delete = ON")
        conn.execute("PRAGMA auto_vacuum = INCREMENTAL")
        
        return conn

# Global SQL security instance
sql_security = None

def init_sql_security(db_path: str):
    """Initialize SQL security system"""
    global sql_security
    sql_security = SQLSecurityManager(db_path)
    print("🔒 SQL Security System initialized")

def secure_query(query: str, params: Optional[List] = None) -> List[Dict]:
    """Secure query execution wrapper"""
    if sql_security is None:
        raise RuntimeError("SQL security not initialized")
    return sql_security.execute_query(query, params)



# Secure Execution Framework - Auto-generated Security Patch
import subprocess
import shlex
import os
import sys
from pathlib import Path
import logging

# Configure security logging
security_logger = logging.getLogger('security')
security_logger.setLevel(logging.WARNING)
handler = logging.FileHandler('security.log')
handler.setFormatter(logging.Formatter('%(asctime)s - SECURITY - %(message)s'))
security_logger.addHandler(handler)

class SecureExecutionFramework:
    """Secure command execution with comprehensive validation"""
    
    ALLOWED_COMMANDS = {
        'git': ['status', 'add', 'commit', 'push', 'pull', 'clone'],
        'python': ['-m', '-c'],
        'pip': ['install', 'list', 'show', 'freeze'],
        'node': ['--version'],
        'npm': ['install', 'list', 'audit']
    }
    
    @staticmethod
    def validate_command(command, args=None):
        """Validate command against whitelist"""
        if command not in SecureExecutionFramework.ALLOWED_COMMANDS:
            security_logger.warning(f"Blocked unauthorized command: {command}")
            return False
        
        if args:
            allowed_args = SecureExecutionFramework.ALLOWED_COMMANDS[command]
            for arg in args:
                if not any(arg.startswith(allowed) for allowed in allowed_args):
                    security_logger.warning(f"Blocked unauthorized argument: {arg}")
                    return False
        
        return True
    
    @staticmethod
    def secure_execute(command, args=None, cwd=None):
        """Execute command securely"""
        if not SecureExecutionFramework.validate_command(command, args):
            raise SecurityError(f"Command not allowed: {command}")
        
        # Sanitize arguments
        if args:
            safe_args = [shlex.quote(str(arg)) for arg in args if arg]
            cmd_list = [command] + safe_args
        else:
            cmd_list = [command]
        
        try:
            result = subprocess.run(
                cmd_list,
                cwd=cwd,
                capture_output=True,
                text=True,
                timeout=30,
                check=False,
                shell=False  # Never use shell=True
            )
            
            if result.returncode != 0:
                security_logger.warning(f"Command failed: {command} - {result.stderr}")
            
            return result
            
        except subprocess.TimeoutExpired:
            security_logger.error(f"Command timeout: {command}")
            raise SecurityError("Command execution timeout")
        except Exception as e:
            security_logger.error(f"Command execution error: {e}")
            raise SecurityError(f"Execution failed: {e}")

class SecurityError(Exception):
    """Custom security exception"""
    pass

# Disable dangerous functions
def blocked_eval(*args, **kwargs):
    security_logger.error("Attempt to use eval() - BLOCKED")
    raise SecurityError("eval() function is disabled for security")

def blocked_exec(*args, **kwargs):
    security_logger.error("Attempt to use exec() - BLOCKED")
    raise SecurityError("exec() function is disabled for security")

def blocked_compile(*args, **kwargs):
    security_logger.error("Attempt to use compile() - BLOCKED")
    raise SecurityError("compile() function is disabled for security")

# Override dangerous built-ins
import builtins
builtins.eval = blocked_eval
builtins.exec = blocked_exec
builtins.compile = blocked_compile

# Secure subprocess wrapper
original_call = subprocess.call
original_run = subprocess.run
original_popen = subprocess.Popen

def secure_call(*args, **kwargs):
    if kwargs.get('shell', False):
        security_logger.error("Blocked subprocess.call with shell=True")
        raise SecurityError("shell=True not permitted")
    return original_call(*args, **kwargs)

def secure_run(*args, **kwargs):
    if kwargs.get('shell', False):
        security_logger.error("Blocked subprocess.run with shell=True")
        raise SecurityError("shell=True not permitted")
    return original_run(*args, **kwargs)

def secure_popen(*args, **kwargs):
    if kwargs.get('shell', False):
        security_logger.error("Blocked subprocess.Popen with shell=True")
        raise SecurityError("shell=True not permitted")
    return original_popen(*args, **kwargs)

subprocess.call = secure_call
subprocess.run = secure_run
subprocess.Popen = secure_popen

print("🔒 Secure Execution Framework loaded")


"""
Secure Data Vault System
Advanced encrypted file storage with performance optimization
"""

import os
import hashlib
import sqlite3
import threading
import time
import json
import zlib
from pathlib import Path
from datetime import datetime, timedelta
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend
import secrets
import logging
import shutil
import mmap

class SecureDataVault:
    """Advanced secure file storage system"""
    
    def __init__(self, vault_path="secure_vault/"):
        self.vault_path = Path(vault_path)
        self.vault_path.mkdir(parents=True, exist_ok=True)
        
        # Database and configuration
        self.db_path = self.vault_path / "vault.db"
        self.config_path = self.vault_path / "vault_config.json"
        self.key_derivation_iterations = 100000
        
        # Master key and encryption
        self.master_key = None
        self.vault_cipher = None
        self.compression_enabled = True
        self.chunk_size = 1024 * 1024  # 1MB chunks
        
        # Performance optimization
        self.memory_mapped_files = {}
        self.cache = {}
        self.cache_max_size = 100 * 1024 * 1024  # 100MB cache
        self.background_tasks = []
        
        # Statistics
        self.stats = {
            'files_stored': 0,
            'total_size_original': 0,
            'total_size_compressed': 0,
            'total_size_encrypted': 0,
            'cache_hits': 0,
            'cache_misses': 0
        }
        
        self.logger = self._setup_logging()
        self._init_database()
        self._load_configuration()
    
    def _setup_logging(self):
        """Setup logging for vault operations"""
        logging.basicConfig(level=logging.INFO)
        logger = logging.getLogger(__name__)
        
        # Add file handler
        log_file = self.vault_path / "vault.log"
        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(logging.INFO)
        formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)
        
        return logger
    
    def _init_database(self):
        """Initialize vault database"""
        try:
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS vault_files (
                    id INTEGER PRIMARY KEY,
                    file_id TEXT UNIQUE,
                    original_path TEXT,
                    original_name TEXT,
                    file_hash TEXT,
                    original_size INTEGER,
                    compressed_size INTEGER,
                    encrypted_size INTEGER,
                    encryption_method TEXT,
                    compression_method TEXT,
                    storage_path TEXT,
                    created_at TIMESTAMP,
                    last_accessed TIMESTAMP,
                    access_count INTEGER DEFAULT 0,
                    metadata TEXT,
                    tags TEXT
                )
            ''')
            
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS vault_keys (
                    id INTEGER PRIMARY KEY,
                    key_id TEXT UNIQUE,
                    salt BLOB,
                    key_derivation_method TEXT,
                    iterations INTEGER,
                    created_at TIMESTAMP,
                    last_used TIMESTAMP
                )
            ''')
            
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS access_log (
                    id INTEGER PRIMARY KEY,
                    file_id TEXT,
                    operation TEXT,
                    timestamp TIMESTAMP,
                    user_info TEXT,
                    ip_address TEXT,
                    success BOOLEAN
                )
            ''')
            
            # Create indexes for performance
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_file_hash ON vault_files(file_hash)')
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_file_id ON vault_files(file_id)')
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_access_timestamp ON access_log(timestamp)')
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"Database initialization error: {e}")
            raise
    
    def _load_configuration(self):
        """Load vault configuration"""
        try:
            if self.config_path.exists():
                with open(self.config_path, 'r') as f:
                    config = json.load(f)
                    self.compression_enabled = config.get('compression_enabled', True)
                    self.chunk_size = config.get('chunk_size', 1024 * 1024)
                    self.cache_max_size = config.get('cache_max_size', 100 * 1024 * 1024)
                    self.key_derivation_iterations = config.get('key_derivation_iterations', 100000)
            else:
                self._save_configuration()
        except Exception as e:
            self.logger.error(f"Configuration loading error: {e}")
    
    def _save_configuration(self):
        """Save vault configuration"""
        try:
            config = {
                'compression_enabled': self.compression_enabled,
                'chunk_size': self.chunk_size,
                'cache_max_size': self.cache_max_size,
                'key_derivation_iterations': self.key_derivation_iterations,
                'created_at': datetime.now().isoformat(),
                'version': '1.0.0'
            }
            with open(self.config_path, 'w') as f:
                json.dump(config, f, indent=2)
        except Exception as e:
            self.logger.error(f"Configuration saving error: {e}")
    
    def initialize_vault(self, password):
        """Initialize vault with master password"""
        try:
            # Generate salt
            salt = secrets.token_bytes(32)
            
            # Derive key from password
            kdf = PBKDF2HMAC(
                algorithm=hashes.SHA256(),
                length=32,
                salt=salt,
                iterations=self.key_derivation_iterations,
                backend=default_backend()
            )
            key = kdf.derive(password.encode())
            
            # Store key information
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            
            key_id = hashlib.sha256(salt).hexdigest()[:16]
            cursor.execute('''
                INSERT OR REPLACE INTO vault_keys 
                (key_id, salt, key_derivation_method, iterations, created_at, last_used)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (key_id, salt, 'PBKDF2HMAC-SHA256', self.key_derivation_iterations,
                  datetime.now(), datetime.now()))
            
            conn.commit()
            conn.close()
            
            # Set master key
            self.master_key = key
            self.vault_cipher = Fernet(Fernet.generate_key())
            
            self.logger.info("Vault initialized successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Vault initialization error: {e}")
            return False
    
    def unlock_vault(self, password):
        """Unlock vault with password"""
        try:
            # Get stored salt
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            cursor.execute('SELECT salt, iterations FROM vault_keys ORDER BY created_at DESC LIMIT 1')
            result = cursor.fetchone()
            conn.close()
            
            if not result:
                self.logger.error("No vault key found")
                return False
            
            salt, iterations = result
            
            # Derive key
            kdf = PBKDF2HMAC(
                algorithm=hashes.SHA256(),
                length=32,
                salt=salt,
                iterations=iterations,
                backend=default_backend()
            )
            key = kdf.derive(password.encode())
            
            # Verify key (could implement key verification)
            self.master_key = key
            self.vault_cipher = Fernet(Fernet.generate_key())
            
            self.logger.info("Vault unlocked successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Vault unlock error: {e}")
            return False
    
    def store_file(self, file_path, tags=None, metadata=None):
        """Store file in secure vault"""
        file_id = None  # Initialize to prevent unbound variable
        try:
            if not self.master_key:
                raise ValueError("Vault not unlocked")
            
            if not os.path.exists(file_path):
                raise ValueError(f"File not found: {file_path}")
            
            # Generate unique file ID
            file_id = secrets.token_hex(16)
            original_path = str(file_path)
            original_name = os.path.basename(file_path)
            
            # Calculate file hash
            file_hash = self._calculate_file_hash(file_path)
            
            # Check for duplicate
            if self._is_duplicate(file_hash):
                self.logger.info(f"File already exists in vault: {file_hash}")
                return self._get_file_id_by_hash(file_hash)
            
            # Get file size
            original_size = os.path.getsize(file_path)
            
            # Process file (compress, encrypt, store)
            storage_info = self._process_and_store_file(file_path, file_id)
            
            # Store metadata in database
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT INTO vault_files 
                (file_id, original_path, original_name, file_hash, 
                 original_size, compressed_size, encrypted_size,
                 encryption_method, compression_method, storage_path,
                 created_at, last_accessed, metadata, tags)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                file_id, original_path, original_name, file_hash,
                original_size, storage_info['compressed_size'], storage_info['encrypted_size'],
                storage_info['encryption_method'], storage_info['compression_method'],
                storage_info['storage_path'], datetime.now(), datetime.now(),
                json.dumps(metadata or {}), json.dumps(tags or [])
            ))
            
            conn.commit()
            conn.close()
            
            # Update statistics
            self.stats['files_stored'] += 1
            self.stats['total_size_original'] += original_size
            self.stats['total_size_compressed'] += storage_info['compressed_size']
            self.stats['total_size_encrypted'] += storage_info['encrypted_size']
            
            # Log access
            self._log_access(file_id, 'STORE', True)
            
            self.logger.info(f"File stored successfully: {file_id}")
            return file_id
            
        except Exception as e:
            self.logger.error(f"File storage error: {e}")
            self._log_access(file_id if 'file_id' in locals() else 'unknown', 'STORE', False)
            return None
    
    def retrieve_file(self, file_id, output_path=None):
        """Retrieve file from vault"""
        try:
            if not self.master_key:
                raise ValueError("Vault not unlocked")
            
            # Check cache first
            if file_id in self.cache:
                self.stats['cache_hits'] += 1
                cache_data = self.cache[file_id]
                if output_path:
                    with open(output_path, 'wb') as f:
                        f.write(cache_data)
                    return output_path
                return cache_data
            
            self.stats['cache_misses'] += 1
            
            # Get file info from database
            file_info = self._get_file_info(file_id)
            if not file_info:
                raise ValueError(f"File not found: {file_id}")
            
            # Retrieve and decrypt file
            decrypted_data = self._retrieve_and_decrypt_file(file_info)
            
            # Update cache if file is small enough
            if len(decrypted_data) < self.cache_max_size // 10:
                self._update_cache(file_id, decrypted_data)
            
            # Update access info
            self._update_access_info(file_id)
            
            # Save to output path if specified
            if output_path:
                os.makedirs(os.path.dirname(output_path), exist_ok=True)
                with open(output_path, 'wb') as f:
                    f.write(decrypted_data)
                
                self._log_access(file_id, 'RETRIEVE', True)
                return output_path
            
            self._log_access(file_id, 'RETRIEVE', True)
            return decrypted_data
            
        except Exception as e:
            self.logger.error(f"File retrieval error: {e}")
            self._log_access(file_id, 'RETRIEVE', False)
            return None
    
    def delete_file(self, file_id, secure_delete=True):
        """Delete file from vault"""
        try:
            if not self.master_key:
                raise ValueError("Vault not unlocked")
            
            # Get file info
            file_info = self._get_file_info(file_id)
            if not file_info:
                raise ValueError(f"File not found: {file_id}")
            
            # Remove from cache
            if file_id in self.cache:
                del self.cache[file_id]
            
            # Secure delete file
            if secure_delete:
                self._secure_delete_file(file_info['storage_path'])
            else:
                os.remove(file_info['storage_path'])
            
            # Remove from database
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            cursor.execute('DELETE FROM vault_files WHERE file_id = ?', (file_id,))
            cursor.execute('DELETE FROM access_log WHERE file_id = ?', (file_id,))
            conn.commit()
            conn.close()
            
            # Update statistics
            self.stats['files_stored'] -= 1
            self.stats['total_size_original'] -= file_info['original_size']
            self.stats['total_size_compressed'] -= file_info['compressed_size']
            self.stats['total_size_encrypted'] -= file_info['encrypted_size']
            
            self._log_access(file_id, 'DELETE', True)
            self.logger.info(f"File deleted successfully: {file_id}")
            return True
            
        except Exception as e:
            self.logger.error(f"File deletion error: {e}")
            self._log_access(file_id, 'DELETE', False)
            return False
    
    def _process_and_store_file(self, file_path, file_id):
        """Process file with compression and encryption"""
        try:
            # Create storage directory
            storage_dir = self.vault_path / "files" / file_id[:2]
            storage_dir.mkdir(parents=True, exist_ok=True)
            storage_path = storage_dir / f"{file_id}.vault"
            
            with open(file_path, 'rb') as input_file:
                # Read file data
                file_data = input_file.read()
                original_size = len(file_data)
                
                # Compress if enabled
                if self.compression_enabled:
                    compressed_data = zlib.compress(file_data, level=9)
                    compression_method = 'zlib'
                    compressed_size = len(compressed_data)
                    data_to_encrypt = compressed_data
                else:
                    compression_method = 'none'
                    compressed_size = original_size
                    data_to_encrypt = file_data
                
                # Encrypt data
                if self.master_key is None:
                    raise ValueError("Vault is locked. Master key is not available.")
                iv = secrets.token_bytes(16)
                cipher = Cipher(
                    algorithms.AES(self.master_key),
                    modes.CBC(iv),
                    backend=default_backend()
                )
                encryptor = cipher.encryptor()
                
                # Pad data to block size
                padded_data = self._pad_data(data_to_encrypt)
                encrypted_data = encryptor.update(padded_data) + encryptor.finalize()
                
                # Write encrypted file
                with open(storage_path, 'wb') as output_file:
                    output_file.write(iv)  # Write IV first
                    output_file.write(encrypted_data)
                
                encrypted_size = len(encrypted_data) + 16  # Include IV
                
                return {
                    'storage_path': str(storage_path),
                    'compressed_size': compressed_size,
                    'encrypted_size': encrypted_size,
                    'compression_method': compression_method,
                    'encryption_method': 'AES-256-CBC'
                }
                
        except Exception as e:
            self.logger.error(f"File processing error: {e}")
            raise
    
    def _retrieve_and_decrypt_file(self, file_info):
        """Retrieve and decrypt file data"""
        try:
            storage_path = file_info['storage_path']
            
            with open(storage_path, 'rb') as encrypted_file:
                iv = encrypted_file.read(16)  # Read the IV from the start of the file
                encrypted_data = encrypted_file.read()
                
                # Decrypt data
                if self.master_key is None:
                    raise ValueError("Vault is locked. Master key is not available.")
                cipher = Cipher(
                    algorithms.AES(self.master_key),
                    modes.CBC(iv),
                    backend=default_backend()
                )
                decryptor = cipher.decryptor()
                
                padded_data = decryptor.update(encrypted_data) + decryptor.finalize()
                decrypted_data = self._unpad_data(padded_data)
                
                # Decompress if needed
                if file_info['compression_method'] == 'zlib':
                    final_data = zlib.decompress(decrypted_data)
                else:
                    final_data = decrypted_data
                
                return final_data
                
        except Exception as e:
            self.logger.error(f"File decryption error: {e}")
            raise
    
    def _pad_data(self, data):
        """Pad data to AES block size"""
        block_size = 16
        padding_length = block_size - (len(data) % block_size)
        padding = bytes([padding_length] * padding_length)
        return data + padding
    
    def _unpad_data(self, padded_data):
        """Remove padding from data"""
        padding_length = padded_data[-1]
        return padded_data[:-padding_length]
    
    def _calculate_file_hash(self, file_path):
        """Calculate SHA256 hash of file"""
        hasher = hashlib.sha256()
        with open(file_path, 'rb') as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hasher.update(chunk)
        return hasher.hexdigest()
    
    def _is_duplicate(self, file_hash):
        """Check if file already exists in vault"""
        try:
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            cursor.execute('SELECT COUNT(*) FROM vault_files WHERE file_hash = ?', (file_hash,))
            count = cursor.fetchone()[0]
            conn.close()
            return count > 0
        except Exception:
            return False
    
    def _get_file_id_by_hash(self, file_hash):
        """Get file ID by hash"""
        try:
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            cursor.execute('SELECT file_id FROM vault_files WHERE file_hash = ?', (file_hash,))
            result = cursor.fetchone()
            conn.close()
            return result[0] if result else None
        except Exception:
            return None
    
    def _get_file_info(self, file_id):
        """Get file information from database"""
        try:
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            cursor.execute('''
                SELECT original_path, original_name, file_hash, original_size,
                       compressed_size, encrypted_size, encryption_method,
                       compression_method, storage_path, created_at, metadata, tags
                FROM vault_files WHERE file_id = ?
            ''', (file_id,))
            
            result = cursor.fetchone()
            conn.close()
            
            if result:
                return {
                    'original_path': result[0],
                    'original_name': result[1],
                    'file_hash': result[2],
                    'original_size': result[3],
                    'compressed_size': result[4],
                    'encrypted_size': result[5],
                    'encryption_method': result[6],
                    'compression_method': result[7],
                    'storage_path': result[8],
                    'created_at': result[9],
                    'metadata': json.loads(result[10]) if result[10] else {},
                    'tags': json.loads(result[11]) if result[11] else []
                }
            return None
            
        except Exception as e:
            self.logger.error(f"Database query error: {e}")
            return None
    
    def _update_cache(self, file_id, data):
        """Update file cache with size management"""
        try:
            # Check cache size and clean if necessary
            current_cache_size = sum(len(v) for v in self.cache.values())
            
            while current_cache_size + len(data) > self.cache_max_size and self.cache:
                # Remove least recently used (simple implementation)
                oldest_key = next(iter(self.cache))
                del self.cache[oldest_key]
                current_cache_size = sum(len(v) for v in self.cache.values())
            
            self.cache[file_id] = data
            
        except Exception as e:
            self.logger.error(f"Cache update error: {e}")
    
    def _update_access_info(self, file_id):
        """Update file access information"""
        try:
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            cursor.execute('''
                UPDATE vault_files 
                SET last_accessed = ?, access_count = access_count + 1
                WHERE file_id = ?
            ''', (datetime.now(), file_id))
            conn.commit()
            conn.close()
        except Exception as e:
            self.logger.error(f"Access info update error: {e}")
    
    def _log_access(self, file_id, operation, success):
        """Log file access"""
        try:
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO access_log 
                (file_id, operation, timestamp, user_info, success)
                VALUES (?, ?, ?, ?, ?)
            ''', (file_id, operation, datetime.now(), 
                  os.getenv('USERNAME', 'system'), success))
            conn.commit()
            conn.close()
        except Exception as e:
            self.logger.error(f"Access logging error: {e}")
    
    def _secure_delete_file(self, file_path):
        """Securely delete file by overwriting"""
        try:
            if os.path.exists(file_path):
                file_size = os.path.getsize(file_path)
                
                # Overwrite with random data multiple times
                with open(file_path, 'r+b') as f:
                    for _ in range(3):
                        f.seek(0)
                        f.write(secrets.token_bytes(file_size))
                        f.flush()
                        os.fsync(f.fileno())
                
                # Finally remove the file
                os.remove(file_path)
                
        except Exception as e:
            self.logger.error(f"Secure delete error: {e}")
    
    def list_files(self, tags=None, search_term=None):
        """List files in vault with optional filtering"""
        try:
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            
            query = '''
                SELECT file_id, original_name, original_size, created_at, 
                       last_accessed, access_count, tags
                FROM vault_files
            '''
            params = []
            
            if search_term:
                query += ' WHERE original_name LIKE ?'
                params.append(f'%{search_term}%')
            
            query += ' ORDER BY created_at DESC'
            
            cursor.execute(query, params)
            results = cursor.fetchall()
            conn.close()
            
            files = []
            for row in results:
                file_tags = json.loads(row[6]) if row[6] else []
                
                # Filter by tags if specified
                if tags and not any(tag in file_tags for tag in tags):
                    continue
                
                files.append({
                    'file_id': row[0],
                    'original_name': row[1],
                    'original_size': row[2],
                    'created_at': row[3],
                    'last_accessed': row[4],
                    'access_count': row[5],
                    'tags': file_tags
                })
            
            return files
            
        except Exception as e:
            self.logger.error(f"File listing error: {e}")
            return []
    
    def get_vault_stats(self):
        """Get vault statistics"""
        try:
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            
            # Get file counts
            cursor.execute('SELECT COUNT(*) FROM vault_files')
            file_count = cursor.fetchone()[0]
            
            # Get size statistics
            cursor.execute('''
                SELECT SUM(original_size), SUM(compressed_size), SUM(encrypted_size)
                FROM vault_files
            ''')
            sizes = cursor.fetchone()
            
            # Get access statistics
            cursor.execute('''
                SELECT COUNT(*) FROM access_log 
                WHERE timestamp > datetime('now', '-24 hours')
            ''')
            recent_access = cursor.fetchone()[0]
            
            conn.close()
            
            compression_ratio = 0
            if sizes[0] and sizes[1]:
                compression_ratio = (1 - sizes[1] / sizes[0]) * 100
            
            return {
                'total_files': file_count,
                'total_original_size': sizes[0] or 0,
                'total_compressed_size': sizes[1] or 0,
                'total_encrypted_size': sizes[2] or 0,
                'compression_ratio_percent': round(compression_ratio, 2),
                'cache_size': len(self.cache),
                'cache_hits': self.stats['cache_hits'],
                'cache_misses': self.stats['cache_misses'],
                'recent_access_24h': recent_access,
                'vault_locked': self.master_key is None
            }
            
        except Exception as e:
            self.logger.error(f"Stats calculation error: {e}")
            return {}
    
    def optimize_vault(self):
        """Optimize vault performance and storage"""
        try:
            self.logger.info("Starting vault optimization")
            
            # Clean up old access logs
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            
            # Remove access logs older than 90 days
            cursor.execute('''
                DELETE FROM access_log 
                WHERE timestamp < datetime('now', '-90 days')
            ''')
            
            # Vacuum database
            cursor.execute('VACUUM')
            
            conn.commit()
            conn.close()
            
            # Clear cache to free memory
            self.cache.clear()
            
            # Remove empty directories
            self._cleanup_empty_directories()
            
            self.logger.info("Vault optimization completed")
            return True
            
        except Exception as e:
            self.logger.error(f"Vault optimization error: {e}")
            return False
    
    def _cleanup_empty_directories(self):
        """Remove empty directories in vault"""
        try:
            files_dir = self.vault_path / "files"
            if files_dir.exists():
                for item in files_dir.iterdir():
                    if item.is_dir() and not any(item.iterdir()):
                        item.rmdir()
        except Exception as e:
            self.logger.error(f"Directory cleanup error: {e}")
    
    def close_vault(self):
        """Close and lock vault"""
        try:
            # Clear sensitive data
            self.master_key = None
            self.vault_cipher = None
            self.cache.clear()
            
            # Stop background tasks
            for task in self.background_tasks:
                if hasattr(task, 'stop'):
                    task.stop()
            
            self.logger.info("Vault closed and locked")
            
        except Exception as e:
            self.logger.error(f"Vault closing error: {e}")

if __name__ == "__main__":
    # Test the secure vault
    vault = SecureDataVault()
    
    # Initialize with password
    if vault.initialize_vault("test_password_123"):
        print("Vault initialized successfully")
        
        # Get stats
        stats = vault.get_vault_stats()
        print("Vault Statistics:")
        for key, value in stats.items():
            print(f"  {key}: {value}")
    
    vault.close_vault()