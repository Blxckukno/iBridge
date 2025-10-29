"""
Machine Learning Integration
Provides ML-based threat detection and behavioral analysis
"""

import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier, IsolationForest
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
import joblib
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import json
import pickle
import hashlib

from ..core_engine.config_manager import ConfigManager
from ..logging.security_logger import SecurityLogger


class MLEngine:
    """Machine learning based threat detection"""
    
    def __init__(self, config_manager: ConfigManager, logger: SecurityLogger):
        self.config = config_manager
        self.logger = logger
        
        # ML Models
        self.file_classifier = None
        self.behavior_detector = None
        self.network_analyzer = None
        self.scaler = StandardScaler()
        
        # Model paths
        self.models_dir = Path.home() / ".antivirus_models"
        self.file_model_path = self.models_dir / "file_classifier.joblib"
        self.behavior_model_path = self.models_dir / "behavior_detector.joblib"
        self.network_model_path = self.models_dir / "network_analyzer.joblib"
        self.scaler_path = self.models_dir / "feature_scaler.joblib"
        
        # Feature extraction
        self.feature_extractors = {
            "file": self._extract_file_features,
            "behavior": self._extract_behavior_features,
            "network": self._extract_network_features
        }
        
        # Training data
        self.training_data = {
            "file": {"X": [], "y": []},
            "behavior": {"X": [], "y": []},
            "network": {"X": [], "y": []}
        }
        
        # Statistics
        self.stats = {
            "files_analyzed": 0,
            "behaviors_analyzed": 0,
            "connections_analyzed": 0,
            "threats_detected": 0,
            "last_training": None
        }
    
    async def initialize(self):
        """Initialize ML engine"""
        self.logger.log_info("Initializing machine learning engine")
        
        try:
            # Create models directory
            self.models_dir.mkdir(parents=True, exist_ok=True)
            
            # Load pre-trained models if available
            await self._load_models()
            
            self.logger.log_info("Machine learning engine initialized")
            
        except Exception as e:
            self.logger.log_error(f"Failed to initialize ML engine: {e}")
            raise
    
    async def _load_models(self):
        """Load pre-trained ML models"""
        try:
            if self.file_model_path.exists():
                self.file_classifier = joblib.load(self.file_model_path)
                self.logger.log_info("Loaded file classifier model")
            
            if self.behavior_model_path.exists():
                self.behavior_detector = joblib.load(self.behavior_model_path)
                self.logger.log_info("Loaded behavior detector model")
            
            if self.network_model_path.exists():
                self.network_analyzer = joblib.load(self.network_model_path)
                self.logger.log_info("Loaded network analyzer model")
            
            if self.scaler_path.exists():
                self.scaler = joblib.load(self.scaler_path)
                self.logger.log_info("Loaded feature scaler")
            
        except Exception as e:
            self.logger.log_error(f"Error loading ML models: {e}")
            # Continue with new models if loading fails
            self._initialize_new_models()
    
    def _initialize_new_models(self):
        """Initialize new ML models"""
        self.file_classifier = RandomForestClassifier(
            n_estimators=100,
            max_depth=10,
            random_state=42
        )
        
        self.behavior_detector = IsolationForest(
            n_estimators=100,
            contamination=0.1,
            random_state=42
        )
        
        self.network_analyzer = RandomForestClassifier(
            n_estimators=100,
            max_depth=10,
            random_state=42
        )
    
    async def analyze_file(self, file_path: str) -> Dict:
        """Analyze file using ML"""
        self.stats["files_analyzed"] += 1
        
        try:
            # Extract features
            features = await self._extract_file_features(file_path)
            if not features:
                return {"safe": False, "error": "Failed to extract features"}
            
            # Scale features
            features_scaled = self.scaler.transform([features])
            
            # Predict
            if self.file_classifier:
                prediction = self.file_classifier.predict(features_scaled)[0]
                probability = self.file_classifier.predict_proba(features_scaled)[0]
                
                result = {
                    "safe": prediction == 0,
                    "confidence": float(max(probability)),
                    "features": {
                        "entropy": features[0],
                        "size": features[1],
                        "header_score": features[2],
                        "string_score": features[3]
                    }
                }
                
                if not result["safe"]:
                    self.stats["threats_detected"] += 1
                
                return result
            
            return {"safe": False, "error": "Model not trained"}
            
        except Exception as e:
            self.logger.log_error(f"Error analyzing file: {e}")
            return {"safe": False, "error": str(e)}
    
    async def _extract_file_features(self, file_path: str) -> Optional[List[float]]:
        """Extract features from file"""
        try:
            with open(file_path, 'rb') as f:
                data = f.read()
                
                # Calculate entropy
                entropy = self._calculate_entropy(data)
                
                # File size
                size = len(data)
                
                # Header analysis
                header_score = self._analyze_file_header(data[:256])
                
                # String analysis
                string_score = self._analyze_strings(data)
                
                return [entropy, size, header_score, string_score]
                
        except Exception as e:
            self.logger.log_error(f"Error extracting file features: {e}")
            return None
    
    def _calculate_entropy(self, data: bytes) -> float:
        """Calculate Shannon entropy"""
        if not data:
            return 0.0
        
        entropy = 0
        for x in range(256):
            p_x = data.count(x) / len(data)
            if p_x > 0:
                entropy += -p_x * math.log2(p_x)
        
        return entropy
    
    def _analyze_file_header(self, header: bytes) -> float:
        """Analyze file header"""
        # Common file signatures
        signatures = {
            b'MZ': 1.0,  # EXE
            b'PDF': 0.8,  # PDF
            b'PK': 0.6,  # ZIP
            b'\x89PNG': 0.3,  # PNG
            b'GIF': 0.3,  # GIF
            b'\xFF\xD8': 0.3  # JPEG
        }
        
        for sig, score in signatures.items():
            if header.startswith(sig):
                return score
        
        return 0.0
    
    def _analyze_strings(self, data: bytes) -> float:
        """Analyze strings in binary data"""
        suspicious_patterns = [
            b'cmd.exe', b'powershell', b'wget', b'curl',
            b'http://', b'https://', b'system32', b'admin'
        ]
        
        score = 0.0
        for pattern in suspicious_patterns:
            if pattern in data:
                score += 0.2
        
        return min(score, 1.0)
    
    async def analyze_behavior(self, behavior_data: Dict) -> Dict:
        """Analyze process/system behavior"""
        self.stats["behaviors_analyzed"] += 1
        
        try:
            # Extract features
            features = await self._extract_behavior_features(behavior_data)
            if not features:
                return {"safe": False, "error": "Failed to extract features"}
            
            # Scale features
            features_scaled = self.scaler.transform([features])
            
            # Predict
            if self.behavior_detector:
                # IsolationForest returns -1 for anomalies and 1 for normal behavior
                prediction = self.behavior_detector.predict(features_scaled)[0]
                score = self.behavior_detector.score_samples(features_scaled)[0]
                
                result = {
                    "safe": prediction == 1,
                    "anomaly_score": float(-score),  # Convert to positive anomaly score
                    "features": {
                        "cpu_usage": features[0],
                        "memory_usage": features[1],
                        "file_ops": features[2],
                        "network_ops": features[3]
                    }
                }
                
                if not result["safe"]:
                    self.stats["threats_detected"] += 1
                
                return result
            
            return {"safe": False, "error": "Model not trained"}
            
        except Exception as e:
            self.logger.log_error(f"Error analyzing behavior: {e}")
            return {"safe": False, "error": str(e)}
    
    async def _extract_behavior_features(self, behavior_data: Dict) -> Optional[List[float]]:
        """Extract features from behavior data"""
        try:
            # CPU usage
            cpu_usage = behavior_data.get("cpu_percent", 0.0)
            
            # Memory usage
            memory_usage = behavior_data.get("memory_percent", 0.0)
            
            # File operations count
            file_ops = len(behavior_data.get("file_operations", []))
            
            # Network operations count
            network_ops = len(behavior_data.get("network_connections", []))
            
            return [cpu_usage, memory_usage, file_ops, network_ops]
            
        except Exception as e:
            self.logger.log_error(f"Error extracting behavior features: {e}")
            return None
    
    async def analyze_network(self, connection_data: Dict) -> Dict:
        """Analyze network connection"""
        self.stats["connections_analyzed"] += 1
        
        try:
            # Extract features
            features = await self._extract_network_features(connection_data)
            if not features:
                return {"safe": False, "error": "Failed to extract features"}
            
            # Scale features
            features_scaled = self.scaler.transform([features])
            
            # Predict
            if self.network_analyzer:
                prediction = self.network_analyzer.predict(features_scaled)[0]
                probability = self.network_analyzer.predict_proba(features_scaled)[0]
                
                result = {
                    "safe": prediction == 0,
                    "confidence": float(max(probability)),
                    "features": {
                        "port_risk": features[0],
                        "protocol_risk": features[1],
                        "data_rate": features[2],
                        "connection_pattern": features[3]
                    }
                }
                
                if not result["safe"]:
                    self.stats["threats_detected"] += 1
                
                return result
            
            return {"safe": False, "error": "Model not trained"}
            
        except Exception as e:
            self.logger.log_error(f"Error analyzing network connection: {e}")
            return {"safe": False, "error": str(e)}
    
    async def _extract_network_features(self, connection_data: Dict) -> Optional[List[float]]:
        """Extract features from network connection"""
        try:
            # Port risk score
            port_risk = self._calculate_port_risk(connection_data.get("port", 0))
            
            # Protocol risk score
            protocol_risk = self._calculate_protocol_risk(
                connection_data.get("protocol", "").lower()
            )
            
            # Data transfer rate
            data_rate = connection_data.get("bytes_per_sec", 0.0)
            
            # Connection pattern score
            pattern_score = self._analyze_connection_pattern(
                connection_data.get("history", [])
            )
            
            return [port_risk, protocol_risk, data_rate, pattern_score]
            
        except Exception as e:
            self.logger.log_error(f"Error extracting network features: {e}")
            return None
    
    def _calculate_port_risk(self, port: int) -> float:
        """Calculate risk score for port number"""
        high_risk_ports = {22, 23, 25, 135, 137, 138, 139, 445, 3389}
        medium_risk_ports = {20, 21, 53, 80, 443, 8080}
        
        if port in high_risk_ports:
            return 1.0
        elif port in medium_risk_ports:
            return 0.5
        elif port > 49152:  # Dynamic ports
            return 0.7
        else:
            return 0.3
    
    def _calculate_protocol_risk(self, protocol: str) -> float:
        """Calculate risk score for protocol"""
        risk_scores = {
            "telnet": 1.0,
            "ftp": 0.8,
            "smtp": 0.7,
            "http": 0.5,
            "https": 0.2,
            "ssh": 0.4,
            "dns": 0.3
        }
        
        return risk_scores.get(protocol, 0.6)  # Default score for unknown protocols
    
    def _analyze_connection_pattern(self, history: List[Dict]) -> float:
        """Analyze connection pattern from history"""
        if not history:
            return 0.5
        
        # Calculate features from connection history
        total_connections = len(history)
        unique_ips = len(set(conn.get("remote_ip") for conn in history))
        
        # More unique IPs than connections indicates potential scanning
        if unique_ips > total_connections * 0.8:
            return 1.0
        
        # Calculate average time between connections
        if len(history) > 1:
            times = [conn.get("timestamp", 0) for conn in history]
            intervals = np.diff(times)
            if np.std(intervals) < 0.1:  # Very regular intervals
                return 0.8
        
        return 0.4
    
    async def train_models(self, training_data: Dict):
        """Train ML models with new data"""
        try:
            self.logger.log_info("Starting model training")
            
            # Process training data
            for model_type in ["file", "behavior", "network"]:
                if model_type in training_data:
                    X = training_data[model_type].get("X", [])
                    y = training_data[model_type].get("y", [])
                    
                    if len(X) > 0 and len(X) == len(y):
                        # Split data
                        X_train, X_test, y_train, y_test = train_test_split(
                            X, y, test_size=0.2, random_state=42
                        )
                        
                        # Scale features
                        X_train_scaled = self.scaler.fit_transform(X_train)
                        X_test_scaled = self.scaler.transform(X_test)
                        
                        # Train model
                        if model_type == "file":
                            self.file_classifier.fit(X_train_scaled, y_train)
                            score = self.file_classifier.score(X_test_scaled, y_test)
                            self.logger.log_info(f"File classifier accuracy: {score:.2f}")
                        
                        elif model_type == "behavior":
                            self.behavior_detector.fit(X_train_scaled)
                            # For IsolationForest, we measure performance differently
                            y_pred = self.behavior_detector.predict(X_test_scaled)
                            anomaly_ratio = (y_pred == -1).sum() / len(y_pred)
                            self.logger.log_info(f"Behavior detector anomaly ratio: {anomaly_ratio:.2f}")
                        
                        elif model_type == "network":
                            self.network_analyzer.fit(X_train_scaled, y_train)
                            score = self.network_analyzer.score(X_test_scaled, y_test)
                            self.logger.log_info(f"Network analyzer accuracy: {score:.2f}")
            
            # Save models
            await self._save_models()
            
            self.stats["last_training"] = datetime.now().isoformat()
            self.logger.log_info("Model training completed")
            
        except Exception as e:
            self.logger.log_error(f"Error training models: {e}")
            raise
    
    async def _save_models(self):
        """Save ML models"""
        try:
            if self.file_classifier:
                joblib.dump(self.file_classifier, self.file_model_path)
            
            if self.behavior_detector:
                joblib.dump(self.behavior_detector, self.behavior_model_path)
            
            if self.network_analyzer:
                joblib.dump(self.network_analyzer, self.network_model_path)
            
            joblib.dump(self.scaler, self.scaler_path)
            
        except Exception as e:
            self.logger.log_error(f"Error saving models: {e}")
    
    def add_training_data(self, data_type: str, features: List[float], label: int):
        """Add data point to training set"""
        if data_type in self.training_data:
            self.training_data[data_type]["X"].append(features)
            self.training_data[data_type]["y"].append(label)
    
    def get_model_info(self) -> Dict:
        """Get information about ML models"""
        return {
            "file_classifier": {
                "trained": self.file_classifier is not None,
                "type": type(self.file_classifier).__name__ if self.file_classifier else None
            },
            "behavior_detector": {
                "trained": self.behavior_detector is not None,
                "type": type(self.behavior_detector).__name__ if self.behavior_detector else None
            },
            "network_analyzer": {
                "trained": self.network_analyzer is not None,
                "type": type(self.network_analyzer).__name__ if self.network_analyzer else None
            },
            "training_data_size": {
                "file": len(self.training_data["file"]["X"]),
                "behavior": len(self.training_data["behavior"]["X"]),
                "network": len(self.training_data["network"]["X"])
            },
            **self.stats
        }
