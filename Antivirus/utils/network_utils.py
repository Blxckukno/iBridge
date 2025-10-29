"""
Network utilities module
Provides common network-related utility functions
"""

import socket
import ipaddress
import platform
import subprocess
from typing import List, Dict, Tuple, Optional, Union, Any

class NetworkUtils:
    """Network utility functions"""
    
    @staticmethod
    def is_valid_ip(ip_address: str) -> bool:
        """Check if IP address is valid"""
        try:
            ipaddress.ip_address(ip_address)
            return True
        except ValueError:
            return False
    
    @staticmethod
    def is_valid_port(port: Union[int, str]) -> bool:
        """Check if port number is valid"""
        try:
            port_num = int(port)
            return 1 <= port_num <= 65535
        except (ValueError, TypeError):
            return False
    
    @staticmethod
    def is_private_ip(ip_address: str) -> bool:
        """Check if IP address is private"""
        try:
            ip = ipaddress.ip_address(ip_address)
            return ip.is_private
        except ValueError:
            return False
    
    @staticmethod
    def is_local_ip(ip_address: str) -> bool:
        """Check if IP address is local/loopback"""
        try:
            ip = ipaddress.ip_address(ip_address)
            return ip.is_loopback
        except ValueError:
            return False
    
    @staticmethod
    def get_local_ip() -> str:
        """Get local IP address"""
        try:
            # Connect to a remote address to determine local IP
            with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
                s.connect(("8.8.8.8", 80))
                return s.getsockname()[0]
        except Exception:
            return "127.0.0.1"
    
    @staticmethod
    def get_network_interfaces() -> List[Dict[str, str]]:
        """Get network interface information"""
        interfaces = []
        try:
            # Simplified fallback method without psutil
            hostname = socket.gethostname()
            local_ip = socket.gethostbyname(hostname)
            interfaces.append({
                'name': 'default',
                'ip': local_ip,
                'netmask': '255.255.255.0',
                'broadcast': ''
            })
        except Exception:
            pass
        
        return interfaces
    
    @staticmethod
    def ip_in_subnet(ip_address: str, subnet: str) -> bool:
        """Check if IP address is in subnet"""
        try:
            ip = ipaddress.ip_address(ip_address)
            network = ipaddress.ip_network(subnet, strict=False)
            return ip in network
        except ValueError:
            return False
    
    @staticmethod
    def ip_in_range(ip_address: str, start_ip: str, end_ip: str) -> bool:
        """Check if IP address is in range"""
        try:
            ip = ipaddress.ip_address(ip_address)
            start = ipaddress.ip_address(start_ip)
            end = ipaddress.ip_address(end_ip)
            
            # Convert to integers for comparison
            ip_int = int(ip)
            start_int = int(start)
            end_int = int(end)
            
            return start_int <= ip_int <= end_int
        except ValueError:
            return False
    
    @staticmethod
    def calculate_subnet_info(network: str) -> Dict[str, str]:
        """Calculate subnet information"""
        try:
            net = ipaddress.ip_network(network, strict=False)
            return {
                'network': str(net.network_address),
                'broadcast': str(net.broadcast_address),
                'netmask': str(net.netmask),
                'prefix_length': str(net.prefixlen),
                'num_addresses': str(net.num_addresses),
                'hostmask': str(net.hostmask)
            }
        except ValueError:
            return {}
    
    @staticmethod
    def resolve_hostname(hostname: str) -> Optional[str]:
        """Resolve hostname to IP address"""
        try:
            return socket.gethostbyname(hostname)
        except socket.gaierror:
            return None
    
    @staticmethod
    def reverse_dns_lookup(ip_address: str) -> Optional[str]:
        """Perform reverse DNS lookup"""
        try:
            return socket.gethostbyaddr(ip_address)[0]
        except (socket.herror, socket.gaierror):
            return None
    
    @staticmethod
    def is_port_open(host: str, port: int, timeout: float = 3.0) -> bool:
        """Check if port is open on host"""
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
                sock.settimeout(timeout)
                result = sock.connect_ex((host, port))
                return result == 0
        except Exception:
            return False
    
    @staticmethod
    def get_open_ports(host: str, port_range: Tuple[int, int] = (1, 1024), 
                      timeout: float = 1.0) -> List[int]:
        """Get list of open ports on host"""
        open_ports = []
        start_port, end_port = port_range
        
        for port in range(start_port, min(end_port + 1, 65536)):
            if NetworkUtils.is_port_open(host, port, timeout):
                open_ports.append(port)
        
        return open_ports
    
    @staticmethod
    def ping_host(host: str, count: int = 1, timeout: int = 3) -> Dict[str, Any]:
        """Ping host and return results"""
        system = platform.system().lower()
        
        if system == "windows":
            cmd = ["ping", "-n", str(count), "-w", str(timeout * 1000), host]
        else:
            cmd = ["ping", "-c", str(count), "-W", str(timeout), host]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            return {
                'success': result.returncode == 0,
                'output': result.stdout,
                'error': result.stderr
            }
        except subprocess.TimeoutExpired:
            return {
                'success': False,
                'output': '',
                'error': 'Timeout'
            }
        except Exception as e:
            return {
                'success': False,
                'output': '',
                'error': str(e)
            }
    
    @staticmethod
    def get_network_stats() -> Dict[str, Any]:
        """Get network statistics"""
        # Simplified version without psutil
        return {
            'bytes_sent': 0,
            'bytes_recv': 0,
            'packets_sent': 0,
            'packets_recv': 0,
            'errin': 0,
            'errout': 0,
            'dropin': 0,
            'dropout': 0
        }
    
    @staticmethod
    def get_active_connections() -> List[Dict[str, Any]]:
        """Get active network connections"""
        # Simplified version without psutil
        return []
    
    @staticmethod
    def validate_cidr(cidr: str) -> bool:
        """Validate CIDR notation"""
        try:
            ipaddress.ip_network(cidr, strict=False)
            return True
        except ValueError:
            return False
    
    @staticmethod
    def expand_cidr(cidr: str) -> List[str]:
        """Expand CIDR to list of IP addresses"""
        try:
            network = ipaddress.ip_network(cidr, strict=False)
            return [str(ip) for ip in network.hosts()]
        except ValueError:
            return []
    
    @staticmethod
    def get_subnet_mask(prefix_length: int) -> str:
        """Convert prefix length to subnet mask"""
        try:
            network = ipaddress.IPv4Network(f"0.0.0.0/{prefix_length}")
            return str(network.netmask)
        except ValueError:
            return ""
    
    @staticmethod
    def get_prefix_length(subnet_mask: str) -> int:
        """Convert subnet mask to prefix length"""
        try:
            network = ipaddress.IPv4Network(f"0.0.0.0/{subnet_mask}")
            return network.prefixlen
        except ValueError:
            return 0