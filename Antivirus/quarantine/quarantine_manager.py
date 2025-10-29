"""
Quarantine Manager
Handles isolation and removal of detected threats
"""
import asyncio
import os
import shutil
import hashlib
import json
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional
import base64
import zlib

from ..core_engine.config_manager import ConfigManager
from ..logging.security_logger import SecurityLogger


class QuarantineManager:
    """Manages quarantined files and threat removal"""
    
    def __init__(self, config_manager: ConfigManager, logger: SecurityLogger):
        self.config = config_manager
        self.logger = logger
        
        # Get quarantine directory from config
        self.quarantine_dir = self.config.get_quarantine_dir()
        self.quarantine_db_path = self.quarantine_dir / "quarantine.db"
        self.quarantine_info_path = self.quarantine_dir / "quarantine_info.json"
        
        # Quarantine database
        self.quarantine_info = {}
        
        # Statistics
        self.stats = {
            "total_quarantined": 0,
            "active_quarantined": 0,
            "restored_files": 0,
            "removed_files": 0
        }
    
    async def initialize(self):
        """Initialize the quarantine system"""
        self.logger.log_info("Initializing quarantine manager")
        
        # Create quarantine directory if it doesn't exist
        self.quarantine_dir.mkdir(parents=True, exist_ok=True)
        
        # Load quarantine information
        await self._load_quarantine_info()
        
        # Clean up old quarantine entries
        await self._cleanup_quarantine()
        
        self.logger.log_info("Quarantine manager initialized")
    
    async def _load_quarantine_info(self):
        """Load quarantine database"""
        try:
            if self.quarantine_info_path.exists():
                with open(self.quarantine_info_path, 'r') as f:
                    self.quarantine_info = json.load(f)
            else:
                self.quarantine_info = {}
                
        except Exception as e:
            self.logger.log_error(f"Error loading quarantine info: {e}")
            self.quarantine_info = {}
    
    async def _save_quarantine_info(self):
        """Save quarantine database"""
        try:
            with open(self.quarantine_info_path, 'w') as f:
                json.dump(self.quarantine_info, f, indent=2)
                
        except Exception as e:
            self.logger.log_error(f"Error saving quarantine info: {e}")
    
    async def quarantine_file(self, threat_info: Dict) -> bool:
        """Quarantine a malicious file"""
        try:
            file_path = threat_info.get("file_path")
            if not file_path or not Path(file_path).exists():
                return False
            
            file_path = Path(file_path)
            
            # Generate quarantine ID
            quarantine_id = self._generate_quarantine_id(file_path)
            
            # Create quarantine entry
            quarantine_entry = {
                "original_path": str(file_path),
                "quarantine_time": datetime.now().isoformat(),
                "threat_info": threat_info,
                "file_hash": await self._calculate_file_hash(file_path),
                "is_encrypted": True,
                "status": "quarantined"
            }
            
            # Move and encrypt file
            quarantine_file_path = self.quarantine_dir / f"{quarantine_id}.quar"
            await self._encrypt_and_move_file(file_path, quarantine_file_path)
            
            # Update quarantine info
            self.quarantine_info[quarantine_id] = quarantine_entry
            await self._save_quarantine_info()
            
            # Update statistics
            self.stats["total_quarantined"] += 1
            self.stats["active_quarantined"] += 1
            
            self.logger.log_warning(f"File quarantined: {file_path}")
            return True
            
        except Exception as e:
            self.logger.log_error(f"Failed to quarantine file {file_path}: {e}")
            return False
    
    async def restore_file(self, quarantine_id: str) -> bool:
        """Restore a quarantined file to its original location"""
        try:
            if quarantine_id not in self.quarantine_info:
                return False
            
            entry = self.quarantine_info[quarantine_id]
            original_path = Path(entry["original_path"])
            quarantine_file_path = self.quarantine_dir / f"{quarantine_id}.quar"
            
            # Check if original path is safe
            if original_path.exists():
                backup_path = original_path.with_suffix(original_path.suffix + ".bak")
                shutil.move(str(original_path), str(backup_path))
            
            # Decrypt and restore file
            await self._decrypt_and_restore_file(quarantine_file_path, original_path)
            
            # Update entry
            entry["status"] = "restored"
            entry["restore_time"] = datetime.now().isoformat()
            await self._save_quarantine_info()
            
            # Update statistics
            self.stats["active_quarantined"] -= 1
            self.stats["restored_files"] += 1
            
            self.logger.log_info(f"File restored: {original_path}")
            return True
            
        except Exception as e:
            self.logger.log_error(f"Failed to restore quarantined file {quarantine_id}: {e}")
            return False
    
    async def remove_threat(self, quarantine_id: str) -> bool:
        """Permanently remove a quarantined threat"""
        try:
            if quarantine_id not in self.quarantine_info:
                return False
            
            entry = self.quarantine_info[quarantine_id]
            quarantine_file_path = self.quarantine_dir / f"{quarantine_id}.quar"
            
            # Securely delete the quarantined file
            await self._secure_delete_file(quarantine_file_path)
            
            # Update entry
            entry["status"] = "removed"
            entry["removal_time"] = datetime.now().isoformat()
            await self._save_quarantine_info()
            
            # Update statistics
            self.stats["active_quarantined"] -= 1
            self.stats["removed_files"] += 1
            
            self.logger.log_warning(f"Threat removed: {entry['original_path']}")
            return True
            
        except Exception as e:
            self.logger.log_error(f"Failed to remove threat {quarantine_id}: {e}")
            return False
    
    async def _encrypt_and_move_file(self, source_path: Path, dest_path: Path):
        """Encrypt and move file to quarantine"""
        try:
            # Read file content
            with open(source_path, 'rb') as f:
                content = f.read()
            
            # Compress content
            compressed = zlib.compress(content)
            
            # Simple encryption (for demonstration - in production use strong encryption)
            encrypted = base64.b64encode(compressed)
            
            # Write encrypted content
            with open(dest_path, 'wb') as f:
                f.write(encrypted)
            
            # Securely delete original
            await self._secure_delete_file(source_path)
            
        except Exception as e:
            raise Exception(f"Failed to encrypt and move file: {e}")
    
    async def _decrypt_and_restore_file(self, source_path: Path, dest_path: Path):
        """Decrypt and restore quarantined file"""
        try:
            # Read encrypted content
            with open(source_path, 'rb') as f:
                encrypted = f.read()
            
            # Decrypt and decompress
            compressed = base64.b64decode(encrypted)
            content = zlib.decompress(compressed)
            
            # Write restored file
            with open(dest_path, 'wb') as f:
                f.write(content)
                
        except Exception as e:
            raise Exception(f"Failed to decrypt and restore file: {e}")
    
    async def _secure_delete_file(self, file_path: Path):
        """Securely delete a file by overwriting with random data"""
        try:
            if not file_path.exists():
                return
            
            # Get file size
            file_size = file_path.stat().st_size
            
            # Overwrite file content multiple times
            for i in range(3):  # Number of overwrite passes
                with open(file_path, 'wb') as f:
                    # Write random data
                    f.write(os.urandom(file_size))
                    # Flush to disk
                    f.flush()
                    os.fsync(f.fileno())
            
            # Finally delete the file
            file_path.unlink()
            
        except Exception as e:
            raise Exception(f"Failed to securely delete file: {e}")
    
    def _generate_quarantine_id(self, file_path: Path) -> str:
        """Generate a unique quarantine ID for a file"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        file_hash = hashlib.md5(str(file_path).encode()).hexdigest()[:8]
        return f"QUAR_{timestamp}_{file_hash}"
    
    async def _calculate_file_hash(self, file_path: Path) -> str:
        """Calculate SHA-256 hash of a file"""
        sha256_hash = hashlib.sha256()
        
        with open(file_path, 'rb') as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        
        return sha256_hash.hexdigest()
    
    async def _cleanup_quarantine(self):
        """Clean up old quarantine entries"""
        # Remove entries for non-existent files
        removed_entries = []
        
        for qid, entry in self.quarantine_info.items():
            quarantine_file_path = self.quarantine_dir / f"{qid}.quar"
            if not quarantine_file_path.exists() and entry["status"] == "quarantined":
                removed_entries.append(qid)
        
        for qid in removed_entries:
            del self.quarantine_info[qid]
        
        await self._save_quarantine_info()
    
    async def get_quarantine_list(self) -> List[Dict]:
        """Get list of quarantined items"""
        quarantine_list = []
        
        for qid, entry in self.quarantine_info.items():
            if entry["status"] == "quarantined":
                quarantine_list.append({
                    "id": qid,
                    "original_path": entry["original_path"],
                    "quarantine_time": entry["quarantine_time"],
                    "threat_info": entry["threat_info"]
                })
        
        return quarantine_list
    
    async def get_quarantine_count(self) -> int:
        """Get count of actively quarantined items"""
        return self.stats["active_quarantined"]
    
    def get_quarantine_stats(self) -> Dict:
        """Get quarantine statistics"""
        return self.stats.copy()
    
    async def export_quarantine_info(self, export_path: Path):
        """Export quarantine information to file"""
        try:
            with open(export_path, 'w') as f:
                json.dump(self.quarantine_info, f, indent=2)
            
            self.logger.log_info(f"Quarantine information exported to: {export_path}")
            return True
            
        except Exception as e:
            self.logger.log_error(f"Failed to export quarantine info: {e}")
            return False
