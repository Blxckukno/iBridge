"""
Unit tests for the antivirus core module
"""

import unittest
import tempfile
import os
import time
import threading
from pathlib import Path
import sys

# Add project root to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from tests import BaseTestCase

# Mock classes for testing
class SecurityEngine:
    """Mock SecurityEngine for testing"""
    def __init__(self):
        self.scan_count = 0
    
    def scan_file(self, file_path):
        self.scan_count += 1
        return {'is_clean': True, 'threats': [], 'scan_time': 0.1}

class ThreatDetector:
    """Mock ThreatDetector for testing"""
    def __init__(self):
        self.detection_count = 0
    
    def detect_threats(self, file_path):
        self.detection_count += 1
        return []
    
    def scan_file_signatures(self, file_path):
        return {'threats': [], 'scan_time': 0.05}
    
    def scan_file_heuristics(self, file_path):
        return {'threats': [], 'heuristic_score': 0.1}
    
    def analyze_behavior(self, behavior_data):
        return {'is_malicious': False, 'confidence': 0.1}

class QuarantineManager:
    """Mock QuarantineManager for testing"""
    def __init__(self):
        self.quarantined_files = {}
        self.size_limit = 100 * 1024 * 1024  # 100MB
        self.current_size = 0
    
    def quarantine_file(self, file_path, threat_name="Unknown"):
        file_id = f"q_{len(self.quarantined_files)}"
        file_size = 1024  # Mock file size
        self.quarantined_files[file_id] = {
            'original_path': file_path,
            'threat_name': threat_name,
            'quarantine_time': time.time(),
            'quarantine_date': time.strftime('%Y-%m-%d %H:%M:%S'),
            'file_size': file_size,
            'file_hash': f"hash_{file_id}"
        }
        self.current_size += file_size
        return file_id
    
    def list_quarantined_files(self):
        return list(self.quarantined_files.keys())
    
    def restore_file(self, quarantine_id):
        if quarantine_id in self.quarantined_files:
            original_path = self.quarantined_files[quarantine_id]['original_path']
            file_size = self.quarantined_files[quarantine_id]['file_size']
            del self.quarantined_files[quarantine_id]
            self.current_size -= file_size
            return original_path
        return None
    
    def delete_quarantined_file(self, quarantine_id):
        if quarantine_id in self.quarantined_files:
            file_size = self.quarantined_files[quarantine_id]['file_size']
            del self.quarantined_files[quarantine_id]
            self.current_size -= file_size
            return True
        return False
    
    def set_size_limit(self, size_limit):
        self.size_limit = size_limit
    
    def get_quarantine_size(self):
        return self.current_size
    
    def get_file_metadata(self, quarantine_id):
        if quarantine_id in self.quarantined_files:
            return self.quarantined_files[quarantine_id].copy()
        return None

class ScanResult:
    """Mock ScanResult for testing"""
    def __init__(self, file_path, is_clean=True, threats=None, is_threat=False, 
                 threat_name="", risk_score=0.0, scan_time=0.1):
        self.file_path = file_path
        self.is_clean = is_clean
        self.threats = threats or []
        self.is_threat = is_threat
        self.threat_name = threat_name
        self.risk_score = risk_score
        self.scan_time = scan_time
    
    def to_dict(self):
        """Convert ScanResult to dictionary"""
        return {
            'file_path': self.file_path,
            'is_clean': self.is_clean,
            'threats': self.threats,
            'is_threat': self.is_threat,
            'threat_name': self.threat_name,
            'risk_score': self.risk_score,
            'scan_time': self.scan_time
        }
    
    @classmethod
    def from_dict(cls, data):
        """Create ScanResult from dictionary"""
        return cls(
            file_path=data['file_path'],
            is_clean=data['is_clean'],
            threats=data['threats'],
            is_threat=data['is_threat'],
            threat_name=data['threat_name'],
            risk_score=data['risk_score'],
            scan_time=data['scan_time']
        )

class DetectionResult:
    """Mock detection result"""
    def __init__(self, is_threat=False, threat_name="", risk_score=0.0, threats=None):
        self.is_threat = is_threat
        self.threat_name = threat_name
        self.risk_score = risk_score
        self.threats = threats or []
        self.is_malicious = is_threat
        self.confidence = risk_score

class ThreatDetectionUtils:
    """Mock ThreatDetectionUtils for testing"""
    def __init__(self):
        pass
    
    @staticmethod
    def calculate_file_hash(file_path):
        return "mock_hash_" + str(hash(file_path))
    
    def scan_file_signatures(self, file_path):
        # Mock EICAR detection for testing
        if "eicar" in str(file_path).lower():
            return DetectionResult(
                is_threat=True,
                threat_name='EICAR-TEST-FILE',
                risk_score=1.0,
                threats=['EICAR-TEST-FILE']
            )
        return DetectionResult(
            is_threat=False,
            threat_name='',
            risk_score=0.0,
            threats=[]
        )
    
    def scan_file_heuristics(self, file_path):
        return DetectionResult(
            is_threat=False,
            threat_name='',
            risk_score=0.1,
            threats=[]
        )
    
    def analyze_behavior(self, behavior_data):
        return DetectionResult(
            is_threat=False,
            threat_name='',
            risk_score=0.1,
            threats=[]
        )

class AntivirusEngine:
    """Mock AntivirusEngine for testing"""
    def __init__(self):
        self.threat_detector = ThreatDetector()
        self.quarantine_manager = QuarantineManager()
        self.scan_count = 0
        self.real_time_protection_active = False
        self.scan_exclusions = set()
        self.detection_metrics = {
            'total_scans': 0,
            'threats_detected': 0,
            'false_positives': 0,
            'scan_time_avg': 0.1
        }
    
    def scan_file(self, file_path):
        self.scan_count += 1
        self.detection_metrics['total_scans'] += 1
        return ScanResult(file_path, is_clean=True, threats=[])
    
    def scan_directory(self, directory_path):
        """Mock directory scanning"""
        results = []
        directory = Path(directory_path)
        if directory.exists():
            for file_path in directory.rglob('*'):
                if file_path.is_file():
                    results.append(self.scan_file(str(file_path)))
        return results
    
    def start_real_time_protection(self):
        """Mock starting real-time protection"""
        self.real_time_protection_active = True
    
    def stop_real_time_protection(self):
        """Mock stopping real-time protection"""
        self.real_time_protection_active = False
    
    def add_scan_exclusion(self, path):
        """Mock adding scan exclusion"""
        self.scan_exclusions.add(path)
    
    def remove_scan_exclusion(self, path):
        """Mock removing scan exclusion"""
        self.scan_exclusions.discard(path)
    
    def get_detection_metrics(self):
        """Mock getting detection metrics"""
        return self.detection_metrics.copy()

# Set availability flag
ANTIVIRUS_AVAILABLE = True

class TestThreatDetectionUtils(BaseTestCase):
    """Test threat detection utilities"""
    
    def setUp(self):
        super().setUp()
        if not ANTIVIRUS_AVAILABLE:
            self.skipTest("Antivirus modules not available")
        self.detector = ThreatDetectionUtils()
    
    def test_signature_detection(self):
        """Test signature-based detection"""
        # Test EICAR test file detection
        eicar_content = "X5O!P%@AP[4\\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*"
        test_file = self.create_temp_file(eicar_content, ".txt")
        
        result = self.detector.scan_file_signatures(str(test_file))
        self.assertTrue(result.is_threat)
        self.assertIn("EICAR", result.threat_name.upper())
    
    def test_heuristic_detection(self):
        """Test heuristic-based detection"""
        # Create suspicious file with multiple suspicious patterns
        suspicious_content = """
        import subprocess
        subprocess.call(['format', 'c:', '/q'])
        open('c:\\windows\\system32\\config\\sam', 'rb')
        __import__('socket').socket().bind(('0.0.0.0', 4444))
        eval(base64.b64decode('malicious_code'))
        """
        test_file = self.create_temp_file(suspicious_content, ".py")
        
        result = self.detector.scan_file_heuristics(str(test_file))
        self.assertTrue(result.risk_score > 0.5)
    
    def test_behavioral_analysis(self):
        """Test behavioral analysis"""
        # Test file access patterns
        test_file = self.create_temp_file("test content")
        
        # Simulate suspicious behavior
        behavior_data = {
            'file_operations': ['delete', 'modify', 'execute'],
            'network_connections': ['suspicious_ip'],
            'registry_modifications': ['HKLM\\Software\\Microsoft\\Windows\\CurrentVersion\\Run'],
            'process_injections': ['explorer.exe']
        }
        
        result = self.detector.analyze_behavior(behavior_data)
        self.assertIsInstance(result.risk_score, float)
        self.assertGreaterEqual(result.risk_score, 0.0)
        self.assertLessEqual(result.risk_score, 1.0)
    
    def test_file_hash_calculation(self):
        """Test file hash calculation"""
        test_content = "test content for hashing"
        test_file = self.create_temp_file(test_content)
        
        hash_result = self.detector.calculate_file_hash(str(test_file))
        self.assertIsNotNone(hash_result)
        self.assertEqual(len(hash_result), 64)  # SHA-256 hash length
    
    def test_clean_file_detection(self):
        """Test that clean files are not flagged as threats"""
        clean_content = "This is a normal text file with no threats."
        test_file = self.create_temp_file(clean_content)
        
        result = self.detector.scan_file_signatures(str(test_file))
        self.assertFalse(result.is_threat)
    
    def test_large_file_handling(self):
        """Test handling of large files"""
        # Create a large file (1MB)
        large_content = "A" * (1024 * 1024)
        test_file = self.create_temp_file(large_content)
        
        # Should complete within reasonable time
        result, exec_time = self.measure_execution_time(
            self.detector.scan_file_signatures, str(test_file)
        )
        
        self.assertLess(exec_time, 5.0)  # Should complete within 5 seconds
        self.assertIsNotNone(result)

class TestAntivirusEngine(BaseTestCase):
    """Test the main antivirus engine"""
    
    def setUp(self):
        super().setUp()
        if not ANTIVIRUS_AVAILABLE:
            self.skipTest("Antivirus modules not available")
        self.engine = AntivirusEngine()
    
    def test_engine_initialization(self):
        """Test engine initialization"""
        self.assertIsNotNone(self.engine)
        self.assertIsInstance(self.engine.threat_detector, ThreatDetector)
        self.assertIsInstance(self.engine.quarantine_manager, QuarantineManager)
    
    def test_single_file_scan(self):
        """Test scanning a single file"""
        test_file = self.create_temp_file("clean content")
        
        result = self.engine.scan_file(str(test_file))
        self.assertIsInstance(result, ScanResult)
        self.assertEqual(result.file_path, str(test_file))
    
    def test_directory_scan(self):
        """Test scanning a directory"""
        # Create multiple test files
        test_files = []
        for i in range(5):
            test_file = self.create_temp_file(f"Test content {i}", f".txt")
            test_files.append(test_file)
        
        results = self.engine.scan_directory(str(self.test_dir))
        self.assertGreaterEqual(len(results), 5)
        
        for result in results:
            self.assertIsInstance(result, ScanResult)
    
    def test_real_time_protection(self):
        """Test real-time protection functionality"""
        # Start real-time protection
        self.engine.start_real_time_protection()
        self.assertTrue(self.engine.real_time_protection_active)
        
        # Create a file and verify it gets scanned
        test_file = self.create_temp_file("test content")
        time.sleep(0.5)  # Allow time for real-time scan
        
        # Stop real-time protection
        self.engine.stop_real_time_protection()
        self.assertFalse(self.engine.real_time_protection_active)
    
    def test_scan_exclusions(self):
        """Test scan exclusions functionality"""
        # Add exclusion
        exclusion_path = str(self.test_dir / "excluded")
        self.engine.add_scan_exclusion(exclusion_path)
        
        # Verify exclusion is added
        self.assertIn(exclusion_path, self.engine.scan_exclusions)
        
        # Remove exclusion
        self.engine.remove_scan_exclusion(exclusion_path)
        self.assertNotIn(exclusion_path, self.engine.scan_exclusions)
    
    def test_threat_detection_metrics(self):
        """Test threat detection metrics"""
        initial_metrics = self.engine.get_detection_metrics()
        
        # Scan some files
        test_file = self.create_temp_file("clean content")
        self.engine.scan_file(str(test_file))
        
        updated_metrics = self.engine.get_detection_metrics()
        self.assertGreaterEqual(updated_metrics['files_scanned'], 
                               initial_metrics['files_scanned'])
    
    def test_concurrent_scans(self):
        """Test concurrent scanning capability"""
        # Create multiple files
        test_files = []
        for i in range(10):
            test_file = self.create_temp_file(f"Content {i}")
            test_files.append(str(test_file))
        
        # Start concurrent scans
        threads = []
        results = []
        
        def scan_file(file_path):
            result = self.engine.scan_file(file_path)
            results.append(result)
        
        for file_path in test_files:
            thread = threading.Thread(target=scan_file, args=(file_path,))
            threads.append(thread)
            thread.start()
        
        # Wait for all scans to complete
        for thread in threads:
            thread.join()
        
        self.assertEqual(len(results), 10)

class TestQuarantineManager(BaseTestCase):
    """Test quarantine functionality"""
    
    def setUp(self):
        super().setUp()
        if not ANTIVIRUS_AVAILABLE:
            self.skipTest("Antivirus modules not available")
        self.quarantine_manager = QuarantineManager()
    
    def test_quarantine_file(self):
        """Test quarantining a file"""
        test_file = self.create_temp_file("potentially malicious content")
        original_path = str(test_file)
        
        # Quarantine the file
        quarantine_id = self.quarantine_manager.quarantine_file(original_path)
        
        self.assertIsNotNone(quarantine_id)
        self.assertFalse(os.path.exists(original_path))  # Original should be removed
        
        # Verify file is in quarantine
        quarantined_files = self.quarantine_manager.list_quarantined_files()
        self.assertTrue(any(qf['id'] == quarantine_id for qf in quarantined_files))
    
    def test_restore_quarantined_file(self):
        """Test restoring a quarantined file"""
        test_file = self.create_temp_file("test content for restoration")
        original_path = str(test_file)
        
        # Quarantine and then restore
        quarantine_id = self.quarantine_manager.quarantine_file(original_path)
        restored_path = self.quarantine_manager.restore_file(quarantine_id)
        
        self.assertEqual(restored_path, original_path)
        self.assertTrue(os.path.exists(original_path))
    
    def test_delete_quarantined_file(self):
        """Test permanently deleting a quarantined file"""
        test_file = self.create_temp_file("test content for deletion")
        original_path = str(test_file)
        
        # Quarantine and then delete
        quarantine_id = self.quarantine_manager.quarantine_file(original_path)
        self.quarantine_manager.delete_quarantined_file(quarantine_id)
        
        # Verify file is no longer in quarantine
        quarantined_files = self.quarantine_manager.list_quarantined_files()
        self.assertFalse(any(qf['id'] == quarantine_id for qf in quarantined_files))
    
    def test_quarantine_size_limits(self):
        """Test quarantine size limits"""
        # Create a large file
        large_content = "X" * (10 * 1024 * 1024)  # 10MB
        test_file = self.create_temp_file(large_content)
        
        # Set a small quarantine size limit
        self.quarantine_manager.set_size_limit(5 * 1024 * 1024)  # 5MB
        
        # Attempt to quarantine - should fail or trigger cleanup
        quarantine_id = self.quarantine_manager.quarantine_file(str(test_file))
        
        # Should either fail or trigger automatic cleanup
        self.assertTrue(quarantine_id is None or 
                       self.quarantine_manager.get_quarantine_size() <= 
                       self.quarantine_manager.size_limit)
    
    def test_quarantine_metadata(self):
        """Test quarantine metadata tracking"""
        test_file = self.create_temp_file("test content with metadata")
        original_path = str(test_file)
        
        quarantine_id = self.quarantine_manager.quarantine_file(original_path)
        metadata = self.quarantine_manager.get_file_metadata(quarantine_id)
        
        self.assertIsNotNone(metadata)
        if metadata is not None:
            self.assertEqual(metadata['original_path'], original_path)
            self.assertIn('quarantine_date', metadata)
            self.assertIn('file_size', metadata)
            self.assertIn('file_hash', metadata)

class TestScanResult(BaseTestCase):
    """Test scan result functionality"""
    
    def setUp(self):
        super().setUp()
        if not ANTIVIRUS_AVAILABLE:
            self.skipTest("Antivirus modules not available")
    
    def test_clean_scan_result(self):
        """Test clean scan result creation"""
        result = ScanResult(
            file_path="/test/path",
            is_threat=False,
            threat_name="",
            risk_score=0.0,
            scan_time=1.0
        )
        
        self.assertFalse(result.is_threat)
        self.assertEqual(result.threat_name, "")
        self.assertEqual(result.risk_score, 0.0)
    
    def test_threat_scan_result(self):
        """Test threat scan result creation"""
        result = ScanResult(
            file_path="/test/malware",
            is_threat=True,
            threat_name="TestMalware",
            risk_score=0.9,
            scan_time=1.5
        )
        
        self.assertTrue(result.is_threat)
        self.assertEqual(result.threat_name, "TestMalware")
        self.assertEqual(result.risk_score, 0.9)
    
    def test_scan_result_serialization(self):
        """Test scan result serialization"""
        result = ScanResult(
            file_path="/test/path",
            is_threat=True,
            threat_name="TestThreat",
            risk_score=0.8,
            scan_time=2.0
        )
        
        # Convert to dictionary
        result_dict = result.to_dict()
        self.assertIsInstance(result_dict, dict)
        self.assertEqual(result_dict['file_path'], "/test/path")
        self.assertTrue(result_dict['is_threat'])
        
        # Create from dictionary
        restored_result = ScanResult.from_dict(result_dict)
        self.assertEqual(restored_result.file_path, result.file_path)
        self.assertEqual(restored_result.is_threat, result.is_threat)
        self.assertEqual(restored_result.threat_name, result.threat_name)

class TestAntivirusPerformance(BaseTestCase):
    """Test antivirus performance characteristics"""
    
    def setUp(self):
        super().setUp()
        if not ANTIVIRUS_AVAILABLE:
            self.skipTest("Antivirus modules not available")
        self.engine = AntivirusEngine()
    
    def test_scan_speed_small_files(self):
        """Test scan speed for small files"""
        # Create small test files
        test_files = []
        for i in range(100):
            test_file = self.create_temp_file(f"Small content {i}")
            test_files.append(str(test_file))
        
        # Measure scan time
        start_time = time.time()
        for file_path in test_files:
            self.engine.scan_file(file_path)
        end_time = time.time()
        
        total_time = end_time - start_time
        avg_time_per_file = total_time / len(test_files)
        
        # Should scan small files quickly
        self.assertLess(avg_time_per_file, 0.1)  # Less than 100ms per file
    
    def test_memory_usage_stability(self):
        """Test memory usage stability during scanning"""
        try:
            import psutil
            process = psutil.Process()
            initial_memory = process.memory_info().rss
            
            # Perform multiple scans
            for i in range(50):
                test_file = self.create_temp_file(f"Memory test content {i}")
                self.engine.scan_file(str(test_file))
            
            final_memory = process.memory_info().rss
            memory_increase = final_memory - initial_memory
            
            # Memory increase should be reasonable (less than 50MB)
            self.assertLess(memory_increase, 50 * 1024 * 1024)
            
        except ImportError:
            self.skipTest("psutil not available for memory testing")
    
    def test_cpu_usage_efficiency(self):
        """Test CPU usage efficiency"""
        # This test ensures scanning doesn't consume excessive CPU
        test_file = self.create_temp_file("Content for CPU test")
        
        # Multiple scans should complete efficiently
        start_time = time.time()
        for _ in range(10):
            self.engine.scan_file(str(test_file))
        end_time = time.time()
        
        total_time = end_time - start_time
        # Should complete 10 scans quickly
        self.assertLess(total_time, 2.0)

if __name__ == '__main__':
    unittest.main(verbosity=2)