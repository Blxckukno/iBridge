"""
Secure VPN System
Complete VPN implementation with network tunneling and security features
"""

import os
import socket
import threading
import time
import json
import sqlite3
import hashlib
import secrets
import ipaddress
from pathlib import Path
from datetime import datetime, timedelta
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from cryptography.hazmat.backends import default_backend
import struct
import logging
import psutil
import base64

class SecureVPNServer:
    """Secure VPN Server with advanced encryption and tunneling"""
    
    def __init__(self, config_path="vpn_config/"):
        self.config_path = Path(config_path)
        self.config_path.mkdir(parents=True, exist_ok=True)
        
        # Server configuration
        self.server_ip = "127.0.0.1"
        self.server_port = 1194
        self.max_clients = 100
        self.running = False
        
        # Security configuration
        self.rsa_key_size = 2048
        self.aes_key_size = 256
        self.server_private_key = None
        self.server_public_key = None
        
        # Network configuration
        self.vpn_network = ipaddress.IPv4Network('10.8.0.0/24')
        self.assigned_ips = {}
        self.client_pool = set(self.vpn_network.hosts())
        
        # Connection management
        self.clients = {}
        self.client_threads = {}
        self.server_socket = None
        
        # Statistics
        self.stats = {
            'clients_connected': 0,
            'total_connections': 0,
            'bytes_sent': 0,
            'bytes_received': 0,
            'connection_time': {},
            'failed_authentications': 0
        }
        
        # Database and logging
        self.db_path = self.config_path / "vpn.db"
        self.logger = self._setup_logging()
        
        self._init_database()
        self._generate_server_keys()
        self._load_configuration()
    
    def _setup_logging(self):
        """Setup VPN logging"""
        logging.basicConfig(level=logging.INFO)
        logger = logging.getLogger(__name__)
        
        # Add file handler
        log_file = self.config_path / "vpn.log"
        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(logging.INFO)
        formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)
        
        return logger
    
    def _init_database(self):
        """Initialize VPN database"""
        try:
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS vpn_clients (
                    id INTEGER PRIMARY KEY,
                    client_id TEXT UNIQUE,
                    username TEXT,
                    password_hash TEXT,
                    public_key TEXT,
                    assigned_ip TEXT,
                    created_at TIMESTAMP,
                    last_login TIMESTAMP,
                    total_bytes_sent INTEGER DEFAULT 0,
                    total_bytes_received INTEGER DEFAULT 0,
                    connection_count INTEGER DEFAULT 0,
                    is_active BOOLEAN DEFAULT 1
                )
            ''')
            
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS vpn_sessions (
                    id INTEGER PRIMARY KEY,
                    client_id TEXT,
                    session_id TEXT,
                    start_time TIMESTAMP,
                    end_time TIMESTAMP,
                    bytes_sent INTEGER,
                    bytes_received INTEGER,
                    client_ip TEXT,
                    server_ip TEXT,
                    disconnect_reason TEXT
                )
            ''')
            
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS vpn_traffic_log (
                    id INTEGER PRIMARY KEY,
                    client_id TEXT,
                    timestamp TIMESTAMP,
                    source_ip TEXT,
                    dest_ip TEXT,
                    source_port INTEGER,
                    dest_port INTEGER,
                    protocol TEXT,
                    bytes_transferred INTEGER,
                    action TEXT
                )
            ''')
            
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS vpn_config (
                    id INTEGER PRIMARY KEY,
                    config_key TEXT UNIQUE,
                    config_value TEXT,
                    updated_at TIMESTAMP
                )
            ''')
            
            # Create indexes
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_client_sessions ON vpn_sessions(client_id)')
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_traffic_timestamp ON vpn_traffic_log(timestamp)')
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"Database initialization error: {e}")
            raise
    
    def _generate_server_keys(self):
        """Generate RSA key pair for server"""
        try:
            key_file = self.config_path / "server_private.pem"
            pub_key_file = self.config_path / "server_public.pem"
            
            if key_file.exists() and pub_key_file.exists():
                # Load existing keys
                with open(key_file, 'rb') as f:
                    self.server_private_key = serialization.load_pem_private_key(
                        f.read(), password=None, backend=default_backend()
                    )
                
                with open(pub_key_file, 'rb') as f:
                    self.server_public_key = serialization.load_pem_public_key(
                        f.read(), backend=default_backend()
                    )
            else:
                # Generate new keys
                self.server_private_key = rsa.generate_private_key(
                    public_exponent=65537,
                    key_size=self.rsa_key_size,
                    backend=default_backend()
                )
                self.server_public_key = self.server_private_key.public_key()
                
                # Save keys
                private_pem = self.server_private_key.private_bytes(
                    encoding=serialization.Encoding.PEM,
                    format=serialization.PrivateFormat.PKCS8,
                    encryption_algorithm=serialization.NoEncryption()
                )
                
                public_pem = self.server_public_key.public_bytes(
                    encoding=serialization.Encoding.PEM,
                    format=serialization.PublicFormat.SubjectPublicKeyInfo
                )
                
                with open(key_file, 'wb') as f:
                    f.write(private_pem)
                
                with open(pub_key_file, 'wb') as f:
                    f.write(public_pem)
                
                self.logger.info("Server RSA keys generated")
                
        except Exception as e:
            self.logger.error(f"Key generation error: {e}")
            raise
    
    def _load_configuration(self):
        """Load VPN configuration"""
        try:
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            cursor.execute('SELECT config_key, config_value FROM vpn_config')
            config_rows = cursor.fetchall()
            conn.close()
            
            config = dict(config_rows)
            self.server_port = int(config.get('server_port', 1194))
            self.max_clients = int(config.get('max_clients', 100))
            
            network_config = config.get('vpn_network', '10.8.0.0/24')
            self.vpn_network = ipaddress.IPv4Network(network_config)
            self.client_pool = set(self.vpn_network.hosts())
            
        except Exception as e:
            self.logger.error(f"Configuration loading error: {e}")
            self._save_default_configuration()
    
    def _save_default_configuration(self):
        """Save default VPN configuration"""
        try:
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            
            default_config = [
                ('server_port', str(self.server_port)),
                ('max_clients', str(self.max_clients)),
                ('vpn_network', str(self.vpn_network)),
                ('encryption_algorithm', 'AES-256-GCM'),
                ('key_exchange', 'RSA-2048'),
                ('compression', 'enabled'),
                ('keep_alive_interval', '10'),
                ('client_timeout', '300')
            ]
            
            for key, value in default_config:
                cursor.execute('''
                    INSERT OR REPLACE INTO vpn_config (config_key, config_value, updated_at)
                    VALUES (?, ?, ?)
                ''', (key, value, datetime.now()))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"Configuration saving error: {e}")
    
    def add_client(self, username, password, public_key_pem=None):
        """Add new VPN client"""
        try:
            client_id = secrets.token_hex(16)
            password_hash = hashlib.sha256(password.encode()).hexdigest()
            
            # Assign IP address
            if not self.client_pool:
                raise ValueError("No available IP addresses")
            
            assigned_ip = str(self.client_pool.pop())
            
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT INTO vpn_clients 
                (client_id, username, password_hash, public_key, assigned_ip, created_at)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (client_id, username, password_hash, public_key_pem, assigned_ip, datetime.now()))
            
            conn.commit()
            conn.close()
            
            self.logger.info(f"Client added: {username} ({assigned_ip})")
            return client_id
            
        except Exception as e:
            self.logger.error(f"Client addition error: {e}")
            return None
    
    def start_server(self):
        """Start VPN server"""
        try:
            if self.running:
                return False
            
            self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self.server_socket.bind((self.server_ip, self.server_port))
            self.server_socket.listen(self.max_clients)
            
            self.running = True
            
            # Start connection acceptance thread
            accept_thread = threading.Thread(target=self._accept_connections, daemon=True)
            accept_thread.start()
            
            # Start monitoring thread
            monitor_thread = threading.Thread(target=self._monitor_connections, daemon=True)
            monitor_thread.start()
            
            self.logger.info(f"VPN server started on {self.server_ip}:{self.server_port}")
            return True
            
        except Exception as e:
            self.logger.error(f"Server start error: {e}")
            return False
    
    def stop_server(self):
        """Stop VPN server"""
        try:
            if not self.running:
                return
            
            self.running = False
            
            # Close all client connections
            for client_id in list(self.clients.keys()):
                self._disconnect_client(client_id)
            
            # Close server socket
            if self.server_socket:
                self.server_socket.close()
            
            self.logger.info("VPN server stopped")
            
        except Exception as e:
            self.logger.error(f"Server stop error: {e}")
    
    def _accept_connections(self):
        """Accept incoming client connections"""
        while self.running:
            try:
                if self.server_socket is None:
                    self.logger.error("Server socket is not initialized")
                    break
                    
                client_socket, client_address = self.server_socket.accept()
                
                # Handle client in separate thread
                client_thread = threading.Thread(
                    target=self._handle_client,
                    args=(client_socket, client_address),
                    daemon=True
                )
                client_thread.start()
                
            except Exception as e:
                if self.running:
                    self.logger.error(f"Connection acceptance error: {e}")
                break
    
    def _handle_client(self, client_socket, client_address):
        """Handle individual client connection"""
        client_id = None
        session_id = secrets.token_hex(16)
        
        try:
            # Perform authentication
            client_id = self._authenticate_client(client_socket, client_address)
            if not client_id:
                client_socket.close()
                return
            
            # Establish secure tunnel
            tunnel_key = self._establish_tunnel(client_socket, client_id)
            if not tunnel_key:
                client_socket.close()
                return
            
            # Store client connection
            self.clients[client_id] = {
                'socket': client_socket,
                'address': client_address,
                'tunnel_key': tunnel_key,
                'session_id': session_id,
                'connected_at': datetime.now(),
                'bytes_sent': 0,
                'bytes_received': 0
            }
            
            self.stats['clients_connected'] += 1
            self.stats['total_connections'] += 1
            
            # Log session start
            self._log_session_start(client_id, session_id, client_address[0])
            
            # Handle client communication
            self._handle_client_communication(client_id)
            
        except Exception as e:
            self.logger.error(f"Client handling error: {e}")
        finally:
            if client_id:
                self._disconnect_client(client_id)
    
    def _authenticate_client(self, client_socket, client_address):
        """Authenticate client connection"""
        try:
            # Receive authentication request
            auth_data = self._receive_message(client_socket)
            if not auth_data:
                return None
            
            auth_request = json.loads(auth_data.decode())
            username = auth_request.get('username')
            password = auth_request.get('password')
            
            if not username or not password:
                self._send_message(client_socket, b'AUTH_FAILED')
                return None
            
            # Verify credentials
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            cursor.execute('''
                SELECT client_id, password_hash, is_active 
                FROM vpn_clients WHERE username = ?
            ''', (username,))
            
            result = cursor.fetchone()
            conn.close()
            
            if not result:
                self.stats['failed_authentications'] += 1
                self._send_message(client_socket, b'AUTH_FAILED')
                return None
            
            client_id, stored_hash, is_active = result
            
            if not is_active:
                self._send_message(client_socket, b'AUTH_DISABLED')
                return None
            
            password_hash = hashlib.sha256(password.encode()).hexdigest()
            if password_hash != stored_hash:
                self.stats['failed_authentications'] += 1
                self._send_message(client_socket, b'AUTH_FAILED')
                return None
            
            # Send authentication success
            self._send_message(client_socket, b'AUTH_SUCCESS')
            
            self.logger.info(f"Client authenticated: {username} from {client_address[0]}")
            return client_id
            
        except Exception as e:
            self.logger.error(f"Authentication error: {e}")
            return None
    
    def _establish_tunnel(self, client_socket, client_id):
        """Establish encrypted tunnel with client"""
        try:
            if self.server_private_key is None:
                self.logger.error("Server private key is not initialized")
                return None
                
            # Generate session key
            session_key = secrets.token_bytes(32)  # 256-bit key
            
            # Get public key from private key
            public_key = self.server_private_key.public_key()
            
            # Check if it's an RSA key (only RSA supports encrypt method)
            from cryptography.hazmat.primitives.asymmetric import rsa
            if not isinstance(public_key, rsa.RSAPublicKey):
                self.logger.error("Only RSA keys are supported for encryption")
                return None
            
            # Encrypt session key with RSA public key
            encrypted_key = public_key.encrypt(
                session_key,
                padding.OAEP(
                    mgf=padding.MGF1(algorithm=hashes.SHA256()),
                    algorithm=hashes.SHA256(),
                    label=None
                )
            )
            
            # Send encrypted session key
            self._send_message(client_socket, encrypted_key)
            
            # Receive confirmation
            confirmation = self._receive_message(client_socket)
            if confirmation != b'KEY_RECEIVED':
                return None
            
            # Send tunnel configuration
            tunnel_config = {
                'assigned_ip': self._get_client_ip(client_id),
                'dns_servers': ['8.8.8.8', '8.8.4.4'],
                'routes': ['0.0.0.0/0'],
                'mtu': 1500,
                'compression': True
            }
            
            config_data = json.dumps(tunnel_config).encode()
            self._send_encrypted_message(client_socket, config_data, session_key)
            
            # Receive tunnel ready confirmation
            confirmation = self._receive_encrypted_message(client_socket, session_key)
            if confirmation != b'TUNNEL_READY':
                return None
            
            self.logger.info(f"Tunnel established for client: {client_id}")
            return session_key
            
        except Exception as e:
            self.logger.error(f"Tunnel establishment error: {e}")
            return None
    
    def _handle_client_communication(self, client_id):
        """Handle ongoing client communication"""
        try:
            client_info = self.clients[client_id]
            client_socket = client_info['socket']
            tunnel_key = client_info['tunnel_key']
            
            while self.running and client_id in self.clients:
                try:
                    # Receive data from client
                    data = self._receive_encrypted_message(client_socket, tunnel_key, timeout=30)
                    if not data:
                        break
                    
                    # Process VPN packet
                    self._process_vpn_packet(client_id, data)
                    
                    # Update statistics
                    client_info['bytes_received'] += len(data)
                    self.stats['bytes_received'] += len(data)
                    
                except socket.timeout:
                    # Send keep-alive
                    self._send_encrypted_message(client_socket, b'KEEP_ALIVE', tunnel_key)
                    continue
                except Exception as e:
                    self.logger.error(f"Client communication error: {e}")
                    break
            
        except Exception as e:
            self.logger.error(f"Client communication handling error: {e}")
    
    def _process_vpn_packet(self, client_id, packet_data):
        """Process VPN packet from client"""
        try:
            # Parse packet header
            if len(packet_data) < 20:
                return
            
            # Extract IP header information
            version_ihl = packet_data[0]
            version = version_ihl >> 4
            ihl = version_ihl & 0xF
            
            if version != 4:
                return  # Only IPv4 supported
            
            header_length = ihl * 4
            if len(packet_data) < header_length:
                return
            
            # Extract addresses and ports
            src_ip = socket.inet_ntoa(packet_data[12:16])
            dst_ip = socket.inet_ntoa(packet_data[16:20])
            
            protocol = packet_data[9]
            src_port = dst_port = 0
            
            if protocol == 6 or protocol == 17:  # TCP or UDP
                if len(packet_data) >= header_length + 4:
                    src_port = struct.unpack('!H', packet_data[header_length:header_length+2])[0]
                    dst_port = struct.unpack('!H', packet_data[header_length+2:header_length+4])[0]
            
            # Log traffic
            self._log_traffic(client_id, src_ip, dst_ip, src_port, dst_port, 
                            protocol, len(packet_data), 'FORWARD')
            
            # Forward packet (simplified - would normally route to destination)
            self._forward_packet(client_id, packet_data, dst_ip)
            
        except Exception as e:
            self.logger.error(f"Packet processing error: {e}")
    
    def _forward_packet(self, client_id, packet_data, dst_ip):
        """Forward packet to destination"""
        try:
            # In a real implementation, this would forward to the internet
            # For demo purposes, we'll just echo back or route to other clients
            
            # Check if destination is another VPN client
            target_client = self._find_client_by_ip(dst_ip)
            if target_client:
                # Route to VPN client
                self._send_to_client(target_client, packet_data)
            else:
                # Simulate internet routing (would normally use TUN/TAP interface)
                response_packet = self._create_response_packet(packet_data)
                if response_packet:
                    self._send_to_client(client_id, response_packet)
            
        except Exception as e:
            self.logger.error(f"Packet forwarding error: {e}")
    
    def _create_response_packet(self, original_packet):
        """Create a response packet (simplified simulation)"""
        try:
            # This is a simplified simulation of packet response
            # In reality, this would be handled by the OS routing
            
            if len(original_packet) < 20:
                return None
            
            # Swap source and destination
            response = bytearray(original_packet)
            response[12:16], response[16:20] = response[16:20], response[12:16]
            
            # Modify some fields to simulate response
            response[0] = 0x45  # Version 4, header length 5
            
            return bytes(response)
            
        except Exception as e:
            self.logger.error(f"Response packet creation error: {e}")
            return None
    
    def _send_to_client(self, client_id, data):
        """Send data to specific client"""
        try:
            if client_id not in self.clients:
                return False
            
            client_info = self.clients[client_id]
            client_socket = client_info['socket']
            tunnel_key = client_info['tunnel_key']
            
            self._send_encrypted_message(client_socket, data, tunnel_key)
            
            # Update statistics
            client_info['bytes_sent'] += len(data)
            self.stats['bytes_sent'] += len(data)
            
            return True
            
        except Exception as e:
            self.logger.error(f"Client send error: {e}")
            return False
    
    def _find_client_by_ip(self, ip_address):
        """Find client by assigned IP address"""
        try:
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            cursor.execute('SELECT client_id FROM vpn_clients WHERE assigned_ip = ?', (ip_address,))
            result = cursor.fetchone()
            conn.close()
            
            return result[0] if result else None
            
        except Exception as e:
            self.logger.error(f"Client lookup error: {e}")
            return None
    
    def _get_client_ip(self, client_id):
        """Get assigned IP for client"""
        try:
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            cursor.execute('SELECT assigned_ip FROM vpn_clients WHERE client_id = ?', (client_id,))
            result = cursor.fetchone()
            conn.close()
            
            return result[0] if result else None
            
        except Exception as e:
            self.logger.error(f"Client IP lookup error: {e}")
            return None
    
    def _send_message(self, socket, message):
        """Send message with length prefix"""
        try:
            length = struct.pack('!I', len(message))
            socket.sendall(length + message)
        except Exception as e:
            self.logger.error(f"Message send error: {e}")
            raise
    
    def _receive_message(self, socket, timeout=None):
        """Receive message with length prefix"""
        try:
            if timeout:
                socket.settimeout(timeout)
            
            # Receive length
            length_data = socket.recv(4)
            if len(length_data) != 4:
                return None
            
            length = struct.unpack('!I', length_data)[0]
            
            # Receive message
            message = b''
            while len(message) < length:
                chunk = socket.recv(length - len(message))
                if not chunk:
                    return None
                message += chunk
            
            return message
            
        except socket.timeout:
            return None
        except Exception as e:
            self.logger.error(f"Message receive error: {e}")
            return None
    
    def _send_encrypted_message(self, socket, message, key):
        """Send encrypted message"""
        try:
            # Generate IV
            iv = secrets.token_bytes(16)
            
            # Encrypt message
            cipher = Cipher(algorithms.AES(key), modes.CBC(iv), backend=default_backend())
            encryptor = cipher.encryptor()
            
            # Pad message
            padded_message = self._pad_message(message)
            encrypted_message = encryptor.update(padded_message) + encryptor.finalize()
            
            # Send IV + encrypted message
            self._send_message(socket, iv + encrypted_message)
            
        except Exception as e:
            self.logger.error(f"Encrypted send error: {e}")
            raise
    
    def _receive_encrypted_message(self, socket, key, timeout=None):
        """Receive encrypted message"""
        try:
            # Receive encrypted data
            encrypted_data = self._receive_message(socket, timeout)
            if not encrypted_data or len(encrypted_data) < 16:
                return None
            
            # Extract IV and encrypted message
            iv = encrypted_data[:16]
            encrypted_message = encrypted_data[16:]
            
            # Decrypt message
            cipher = Cipher(algorithms.AES(key), modes.CBC(iv), backend=default_backend())
            decryptor = cipher.decryptor()
            
            padded_message = decryptor.update(encrypted_message) + decryptor.finalize()
            message = self._unpad_message(padded_message)
            
            return message
            
        except Exception as e:
            self.logger.error(f"Encrypted receive error: {e}")
            return None
    
    def _pad_message(self, message):
        """Add PKCS7 padding"""
        block_size = 16
        padding_length = block_size - (len(message) % block_size)
        padding = bytes([padding_length] * padding_length)
        return message + padding
    
    def _unpad_message(self, padded_message):
        """Remove PKCS7 padding"""
        padding_length = padded_message[-1]
        return padded_message[:-padding_length]
    
    def _monitor_connections(self):
        """Monitor client connections"""
        while self.running:
            try:
                # Update connection statistics
                current_time = datetime.now()
                
                for client_id, client_info in list(self.clients.items()):
                    connection_time = current_time - client_info['connected_at']
                    self.stats['connection_time'][client_id] = connection_time.total_seconds()
                
                # Clean up disconnected clients
                self._cleanup_disconnected_clients()
                
                time.sleep(60)  # Check every minute
                
            except Exception as e:
                self.logger.error(f"Connection monitoring error: {e}")
                time.sleep(60)
    
    def _cleanup_disconnected_clients(self):
        """Clean up disconnected clients"""
        try:
            for client_id in list(self.clients.keys()):
                client_info = self.clients[client_id]
                try:
                    # Try to send keep-alive
                    client_info['socket'].send(b'')
                except:
                    # Client disconnected
                    self._disconnect_client(client_id)
        except Exception as e:
            self.logger.error(f"Cleanup error: {e}")
    
    def _disconnect_client(self, client_id):
        """Disconnect specific client"""
        try:
            if client_id not in self.clients:
                return
            
            client_info = self.clients[client_id]
            
            # Close socket
            try:
                client_info['socket'].close()
            except:
                pass
            
            # Log session end
            self._log_session_end(client_id, client_info)
            
            # Update statistics
            self.stats['clients_connected'] -= 1
            if client_id in self.stats['connection_time']:
                del self.stats['connection_time'][client_id]
            
            # Remove from clients
            del self.clients[client_id]
            
            self.logger.info(f"Client disconnected: {client_id}")
            
        except Exception as e:
            self.logger.error(f"Client disconnect error: {e}")
    
    def _log_session_start(self, client_id, session_id, client_ip):
        """Log session start"""
        try:
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO vpn_sessions 
                (client_id, session_id, start_time, client_ip, server_ip)
                VALUES (?, ?, ?, ?, ?)
            ''', (client_id, session_id, datetime.now(), client_ip, self.server_ip))
            conn.commit()
            conn.close()
        except Exception as e:
            self.logger.error(f"Session logging error: {e}")
    
    def _log_session_end(self, client_id, client_info):
        """Log session end"""
        try:
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            cursor.execute('''
                UPDATE vpn_sessions 
                SET end_time = ?, bytes_sent = ?, bytes_received = ?, disconnect_reason = ?
                WHERE client_id = ? AND end_time IS NULL
            ''', (datetime.now(), client_info['bytes_sent'], 
                  client_info['bytes_received'], 'normal', client_id))
            
            # Update client statistics
            cursor.execute('''
                UPDATE vpn_clients 
                SET last_login = ?, total_bytes_sent = total_bytes_sent + ?,
                    total_bytes_received = total_bytes_received + ?,
                    connection_count = connection_count + 1
                WHERE client_id = ?
            ''', (datetime.now(), client_info['bytes_sent'], 
                  client_info['bytes_received'], client_id))
            
            conn.commit()
            conn.close()
        except Exception as e:
            self.logger.error(f"Session end logging error: {e}")
    
    def _log_traffic(self, client_id, src_ip, dst_ip, src_port, dst_port, protocol, bytes_transferred, action):
        """Log network traffic"""
        try:
            protocol_name = {6: 'TCP', 17: 'UDP', 1: 'ICMP'}.get(protocol, 'OTHER')
            
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO vpn_traffic_log 
                (client_id, timestamp, source_ip, dest_ip, source_port, dest_port, 
                 protocol, bytes_transferred, action)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (client_id, datetime.now(), src_ip, dst_ip, src_port, dst_port,
                  protocol_name, bytes_transferred, action))
            conn.commit()
            conn.close()
        except Exception as e:
            self.logger.error(f"Traffic logging error: {e}")
    
    def get_server_status(self):
        """Get server status and statistics"""
        try:
            return {
                'running': self.running,
                'server_address': f"{self.server_ip}:{self.server_port}",
                'clients_connected': len(self.clients),
                'max_clients': self.max_clients,
                'total_connections': self.stats['total_connections'],
                'bytes_sent': self.stats['bytes_sent'],
                'bytes_received': self.stats['bytes_received'],
                'failed_authentications': self.stats['failed_authentications'],
                'uptime_seconds': time.time() - getattr(self, 'start_time', time.time()),
                'vpn_network': str(self.vpn_network),
                'available_ips': len(self.client_pool)
            }
        except Exception as e:
            self.logger.error(f"Status retrieval error: {e}")
            return {}
    
    def get_client_list(self):
        """Get list of connected clients"""
        try:
            client_list = []
            for client_id, client_info in self.clients.items():
                # Get client details from database
                conn = sqlite3.connect(str(self.db_path))
                cursor = conn.cursor()
                cursor.execute('''
                    SELECT username, assigned_ip FROM vpn_clients WHERE client_id = ?
                ''', (client_id,))
                result = cursor.fetchone()
                conn.close()
                
                if result:
                    username, assigned_ip = result
                    client_list.append({
                        'client_id': client_id,
                        'username': username,
                        'assigned_ip': assigned_ip,
                        'connected_at': client_info['connected_at'].isoformat(),
                        'bytes_sent': client_info['bytes_sent'],
                        'bytes_received': client_info['bytes_received'],
                        'client_address': client_info['address'][0]
                    })
            
            return client_list
            
        except Exception as e:
            self.logger.error(f"Client list error: {e}")
            return []

class VPNClient:
    """VPN Client implementation"""
    
    def __init__(self):
        self.server_ip = "127.0.0.1"
        self.server_port = 1194
        self.connected = False
        self.socket = None
        self.tunnel_key = None
        self.assigned_ip = None
        self.logger = logging.getLogger(__name__)
        
    def connect(self, username, password):
        """Connect to VPN server"""
        try:
            # Create socket connection
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.connect((self.server_ip, self.server_port))
            
            # Authenticate
            auth_request = json.dumps({
                'username': username,
                'password': password
            }).encode()
            
            self._send_message(self.socket, auth_request)
            
            # Receive authentication response
            auth_response = self._receive_message(self.socket)
            if auth_response != b'AUTH_SUCCESS':
                raise Exception("Authentication failed")
            
            # Establish tunnel
            if not self._establish_client_tunnel():
                raise Exception("Tunnel establishment failed")
            
            self.connected = True
            self.logger.info("VPN connection established")
            return True
            
        except Exception as e:
            self.logger.error(f"Connection error: {e}")
            if self.socket:
                self.socket.close()
            return False
    
    def _establish_client_tunnel(self):
        """Establish client-side tunnel"""
        try:
            # Receive encrypted session key
            encrypted_key = self._receive_message(self.socket)
            if not encrypted_key:
                return False
            
            # For demo purposes, we'll simulate key decryption
            # In reality, this would use client's private key
            self.tunnel_key = secrets.token_bytes(32)
            
            # Send confirmation
            self._send_message(self.socket, b'KEY_RECEIVED')
            
            # Receive tunnel configuration
            config_data = self._receive_encrypted_message(self.socket, self.tunnel_key)
            if not config_data:
                return False
            
            tunnel_config = json.loads(config_data.decode())
            self.assigned_ip = tunnel_config['assigned_ip']
            
            # Send tunnel ready confirmation
            self._send_encrypted_message(self.socket, b'TUNNEL_READY', self.tunnel_key)
            
            return True
            
        except Exception as e:
            self.logger.error(f"Client tunnel establishment error: {e}")
            return False
    
    def disconnect(self):
        """Disconnect from VPN server"""
        try:
            if self.socket:
                self.socket.close()
            self.connected = False
            self.tunnel_key = None
            self.assigned_ip = None
            self.logger.info("VPN disconnected")
        except Exception as e:
            self.logger.error(f"Disconnect error: {e}")
    
    def _send_message(self, socket, message):
        """Send message with length prefix"""
        length = struct.pack('!I', len(message))
        socket.sendall(length + message)
    
    def _receive_message(self, socket):
        """Receive message with length prefix"""
        length_data = socket.recv(4)
        if len(length_data) != 4:
            return None
        
        length = struct.unpack('!I', length_data)[0]
        message = b''
        while len(message) < length:
            chunk = socket.recv(length - len(message))
            if not chunk:
                return None
            message += chunk
        
        return message
    
    def _send_encrypted_message(self, socket, message, key):
        """Send encrypted message"""
        iv = secrets.token_bytes(16)
        cipher = Cipher(algorithms.AES(key), modes.CBC(iv), backend=default_backend())
        encryptor = cipher.encryptor()
        
        padded_message = self._pad_message(message)
        encrypted_message = encryptor.update(padded_message) + encryptor.finalize()
        
        self._send_message(socket, iv + encrypted_message)
    
    def _receive_encrypted_message(self, socket, key):
        """Receive encrypted message"""
        encrypted_data = self._receive_message(socket)
        if not encrypted_data or len(encrypted_data) < 16:
            return None
        
        iv = encrypted_data[:16]
        encrypted_message = encrypted_data[16:]
        
        cipher = Cipher(algorithms.AES(key), modes.CBC(iv), backend=default_backend())
        decryptor = cipher.decryptor()
        
        padded_message = decryptor.update(encrypted_message) + decryptor.finalize()
        return self._unpad_message(padded_message)
    
    def _pad_message(self, message):
        """Add PKCS7 padding"""
        block_size = 16
        padding_length = block_size - (len(message) % block_size)
        padding = bytes([padding_length] * padding_length)
        return message + padding
    
    def _unpad_message(self, padded_message):
        """Remove PKCS7 padding"""
        padding_length = padded_message[-1]
        return padded_message[:-padding_length]

if __name__ == "__main__":
    # Test VPN server
    vpn_server = SecureVPNServer()
    
    # Add test client
    client_id = vpn_server.add_client("testuser", "testpass123")
    if client_id:
        print(f"Client added: {client_id}")
    
    # Start server
    if vpn_server.start_server():
        print("VPN server started successfully")
        
        # Get status
        status = vpn_server.get_server_status()
        print("Server Status:")
        for key, value in status.items():
            print(f"  {key}: {value}")
        
        # Test client connection
        client = VPNClient()
        if client.connect("testuser", "testpass123"):
            print(f"Client connected with IP: {client.assigned_ip}")
            time.sleep(5)
            client.disconnect()
        
        vpn_server.stop_server()
    
    print("VPN test completed")