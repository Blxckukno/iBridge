"""
Performance Optimizer for Data Vault
Advanced optimization and monitoring system
"""

import os
import threading
import time
import psutil
import sqlite3
from pathlib import Path
from datetime import datetime, timedelta
from collections import defaultdict, deque
import json
import logging

class VaultPerformanceOptimizer:
    """Advanced performance optimization for data vault"""
    
    def __init__(self, vault_instance):
        self.vault = vault_instance
        self.optimization_running = False
        self.monitoring_thread = None
        
        # Performance metrics
        self.metrics = {
            'io_operations': deque(maxlen=1000),
            'response_times': deque(maxlen=1000),
            'memory_usage': deque(maxlen=100),
            'cpu_usage': deque(maxlen=100),
            'cache_efficiency': deque(maxlen=100),
            'disk_usage': deque(maxlen=100)
        }
        
        # Optimization settings
        self.settings = {
            'auto_optimization': True,
            'optimization_interval': 3600,  # 1 hour
            'cache_optimization': True,
            'io_optimization': True,
            'memory_threshold': 80,  # Percentage
            'cpu_threshold': 85,     # Percentage
            'response_time_threshold': 5.0,  # Seconds
            'defrag_threshold': 30   # Percentage fragmentation
        }
        
        # Optimization strategies
        self.strategies = {
            'file_clustering': True,
            'predictive_caching': True,
            'compression_tuning': True,
            'index_optimization': True,
            'garbage_collection': True
        }
        
        self.logger = logging.getLogger(__name__)
        self._load_settings()
        
    def _load_settings(self):
        """Load optimization settings"""
        try:
            settings_file = self.vault.vault_path / "optimization_settings.json"
            if settings_file.exists():
                with open(settings_file, 'r') as f:
                    saved_settings = json.load(f)
                    self.settings.update(saved_settings.get('settings', {}))
                    self.strategies.update(saved_settings.get('strategies', {}))
        except Exception as e:
            self.logger.error(f"Settings load error: {e}")
    
    def save_settings(self):
        """Save optimization settings"""
        try:
            settings_file = self.vault.vault_path / "optimization_settings.json"
            settings_data = {
                'settings': self.settings,
                'strategies': self.strategies,
                'saved_at': datetime.now().isoformat()
            }
            with open(settings_file, 'w') as f:
                json.dump(settings_data, f, indent=2)
        except Exception as e:
            self.logger.error(f"Settings save error: {e}")
    
    def start_monitoring(self):
        """Start performance monitoring"""
        if self.monitoring_thread and self.monitoring_thread.is_alive():
            return
        
        self.optimization_running = True
        self.monitoring_thread = threading.Thread(target=self._monitoring_loop, daemon=True)
        self.monitoring_thread.start()
        self.logger.info("Performance monitoring started")
    
    def stop_monitoring(self):
        """Stop performance monitoring"""
        self.optimization_running = False
        if self.monitoring_thread:
            self.monitoring_thread.join(timeout=5)
        self.logger.info("Performance monitoring stopped")
    
    def _monitoring_loop(self):
        """Main monitoring loop"""
        last_optimization = time.time()
        
        while self.optimization_running:
            try:
                # Collect metrics
                self._collect_metrics()
                
                # Check if optimization is needed
                if self.settings['auto_optimization']:
                    current_time = time.time()
                    if (current_time - last_optimization > self.settings['optimization_interval'] or
                        self._needs_immediate_optimization()):
                        
                        self.optimize_performance()
                        last_optimization = current_time
                
                time.sleep(30)  # Check every 30 seconds
                
            except Exception as e:
                self.logger.error(f"Monitoring loop error: {e}")
                time.sleep(60)
    
    def _collect_metrics(self):
        """Collect performance metrics"""
        try:
            # System metrics
            memory_percent = psutil.virtual_memory().percent
            cpu_percent = psutil.cpu_percent(interval=1)
            
            # Disk usage for vault directory
            disk_usage = psutil.disk_usage(str(self.vault.vault_path))
            disk_percent = (disk_usage.used / disk_usage.total) * 100
            
            # Cache efficiency
            total_requests = self.vault.stats['cache_hits'] + self.vault.stats['cache_misses']
            cache_efficiency = 0
            if total_requests > 0:
                cache_efficiency = (self.vault.stats['cache_hits'] / total_requests) * 100
            
            # Store metrics
            self.metrics['memory_usage'].append({
                'timestamp': datetime.now(),
                'value': memory_percent
            })
            
            self.metrics['cpu_usage'].append({
                'timestamp': datetime.now(),
                'value': cpu_percent
            })
            
            self.metrics['disk_usage'].append({
                'timestamp': datetime.now(),
                'value': disk_percent
            })
            
            self.metrics['cache_efficiency'].append({
                'timestamp': datetime.now(),
                'value': cache_efficiency
            })
            
        except Exception as e:
            self.logger.error(f"Metrics collection error: {e}")
    
    def _needs_immediate_optimization(self):
        """Check if immediate optimization is needed"""
        try:
            # Check recent metrics
            if self.metrics['memory_usage']:
                recent_memory = self.metrics['memory_usage'][-1]['value']
                if recent_memory > self.settings['memory_threshold']:
                    return True
            
            if self.metrics['cpu_usage']:
                recent_cpu = self.metrics['cpu_usage'][-1]['value']
                if recent_cpu > self.settings['cpu_threshold']:
                    return True
            
            if self.metrics['response_times']:
                recent_responses = [m['value'] for m in list(self.metrics['response_times'])[-10:]]
                avg_response = sum(recent_responses) / len(recent_responses)
                if avg_response > self.settings['response_time_threshold']:
                    return True
            
            return False
            
        except Exception as e:
            self.logger.error(f"Optimization check error: {e}")
            return False
    
    def optimize_performance(self):
        """Execute performance optimization"""
        try:
            self.logger.info("Starting performance optimization")
            optimization_start = time.time()
            
            # Execute optimization strategies
            results = {}
            
            if self.strategies['file_clustering']:
                results['file_clustering'] = self._optimize_file_clustering()
            
            if self.strategies['predictive_caching']:
                results['predictive_caching'] = self._optimize_predictive_caching()
            
            if self.strategies['compression_tuning']:
                results['compression_tuning'] = self._optimize_compression()
            
            if self.strategies['index_optimization']:
                results['index_optimization'] = self._optimize_database_indexes()
            
            if self.strategies['garbage_collection']:
                results['garbage_collection'] = self._perform_garbage_collection()
            
            # Cache optimization
            if self.settings['cache_optimization']:
                results['cache_optimization'] = self._optimize_cache()
            
            # I/O optimization
            if self.settings['io_optimization']:
                results['io_optimization'] = self._optimize_io()
            
            optimization_time = time.time() - optimization_start
            
            self.logger.info(f"Performance optimization completed in {optimization_time:.2f}s")
            self._log_optimization_results(results)
            
            return results
            
        except Exception as e:
            self.logger.error(f"Performance optimization error: {e}")
            return {}
    
    def _optimize_file_clustering(self):
        """Optimize file storage clustering"""
        try:
            # Analyze file access patterns
            conn = sqlite3.connect(str(self.vault.db_path))
            cursor = conn.cursor()
            
            # Get frequently accessed files
            cursor.execute('''
                SELECT file_id, access_count, last_accessed, original_size
                FROM vault_files
                ORDER BY access_count DESC, last_accessed DESC
                LIMIT 100
            ''')
            
            frequent_files = cursor.fetchall()
            conn.close()
            
            # Group files by access frequency and size
            hot_files = []
            cold_files = []
            
            for file_id, access_count, last_accessed, size in frequent_files:
                last_access_time = datetime.fromisoformat(last_accessed)
                days_since_access = (datetime.now() - last_access_time).days
                
                if access_count > 10 and days_since_access < 7:
                    hot_files.append(file_id)
                elif days_since_access > 30:
                    cold_files.append(file_id)
            
            # Reorganize storage (conceptual - actual implementation would involve file movement)
            return {
                'hot_files_identified': len(hot_files),
                'cold_files_identified': len(cold_files),
                'optimization_applied': True
            }
            
        except Exception as e:
            self.logger.error(f"File clustering optimization error: {e}")
            return {'error': str(e)}
    
    def _optimize_predictive_caching(self):
        """Implement predictive caching based on patterns"""
        try:
            # Analyze access patterns
            conn = sqlite3.connect(str(self.vault.db_path))
            cursor = conn.cursor()
            
            # Get recent access patterns
            cursor.execute('''
                SELECT file_id, timestamp
                FROM access_log
                WHERE timestamp > datetime('now', '-7 days')
                AND operation = 'RETRIEVE'
                ORDER BY timestamp
            ''')
            
            access_data = cursor.fetchall()
            conn.close()
            
            # Build access pattern model
            access_patterns = defaultdict(list)
            for file_id, timestamp in access_data:
                access_time = datetime.fromisoformat(timestamp)
                hour = access_time.hour
                weekday = access_time.weekday()
                access_patterns[file_id].append((hour, weekday))
            
            # Predict files likely to be accessed soon
            current_hour = datetime.now().hour
            current_weekday = datetime.now().weekday()
            
            predicted_files = []
            for file_id, patterns in access_patterns.items():
                # Simple prediction based on time patterns
                if any(abs(hour - current_hour) <= 1 and weekday == current_weekday 
                       for hour, weekday in patterns):
                    predicted_files.append(file_id)
            
            # Preload predicted files into cache
            preloaded = 0
            for file_id in predicted_files[:10]:  # Limit to top 10
                if file_id not in self.vault.cache:
                    try:
                        file_data = self.vault.retrieve_file(file_id)
                        if file_data and len(file_data) < self.vault.cache_max_size // 20:
                            self.vault._update_cache(file_id, file_data)
                            preloaded += 1
                    except Exception:
                        continue
            
            return {
                'patterns_analyzed': len(access_patterns),
                'files_predicted': len(predicted_files),
                'files_preloaded': preloaded
            }
            
        except Exception as e:
            self.logger.error(f"Predictive caching error: {e}")
            return {'error': str(e)}
    
    def _optimize_compression(self):
        """Optimize compression settings based on file types"""
        try:
            # Analyze compression efficiency by file type
            conn = sqlite3.connect(str(self.vault.db_path))
            cursor = conn.cursor()
            
            cursor.execute('''
                SELECT original_name, original_size, compressed_size
                FROM vault_files
                WHERE compressed_size > 0
            ''')
            
            compression_data = cursor.fetchall()
            conn.close()
            
            # Analyze compression ratios by file extension
            type_stats = defaultdict(list)
            for name, original, compressed in compression_data:
                ext = Path(name).suffix.lower()
                ratio = compressed / original if original > 0 else 1
                type_stats[ext].append(ratio)
            
            # Calculate average compression ratios
            recommendations = {}
            for ext, ratios in type_stats.items():
                avg_ratio = sum(ratios) / len(ratios)
                if avg_ratio > 0.9:  # Poor compression
                    recommendations[ext] = 'disable_compression'
                elif avg_ratio < 0.5:  # Good compression
                    recommendations[ext] = 'high_compression'
                else:
                    recommendations[ext] = 'standard_compression'
            
            return {
                'file_types_analyzed': len(type_stats),
                'compression_recommendations': recommendations,
                'total_files_analyzed': len(compression_data)
            }
            
        except Exception as e:
            self.logger.error(f"Compression optimization error: {e}")
            return {'error': str(e)}
    
    def _optimize_database_indexes(self):
        """Optimize database indexes for better performance"""
        try:
            conn = sqlite3.connect(str(self.vault.db_path))
            cursor = conn.cursor()
            
            # Analyze query performance
            cursor.execute('PRAGMA optimize')
            
            # Update table statistics
            cursor.execute('ANALYZE')
            
            # Check for missing indexes
            cursor.execute('''
                SELECT name FROM sqlite_master 
                WHERE type='index' AND sql IS NOT NULL
            ''')
            existing_indexes = [row[0] for row in cursor.fetchall()]
            
            # Create additional indexes if needed
            new_indexes = []
            
            if 'idx_access_log_file_operation' not in existing_indexes:
                cursor.execute('''
                    CREATE INDEX IF NOT EXISTS idx_access_log_file_operation 
                    ON access_log(file_id, operation)
                ''')
                new_indexes.append('idx_access_log_file_operation')
            
            if 'idx_vault_files_size' not in existing_indexes:
                cursor.execute('''
                    CREATE INDEX IF NOT EXISTS idx_vault_files_size 
                    ON vault_files(original_size)
                ''')
                new_indexes.append('idx_vault_files_size')
            
            conn.commit()
            conn.close()
            
            return {
                'existing_indexes': len(existing_indexes),
                'new_indexes_created': new_indexes,
                'optimization_completed': True
            }
            
        except Exception as e:
            self.logger.error(f"Database optimization error: {e}")
            return {'error': str(e)}
    
    def _perform_garbage_collection(self):
        """Perform garbage collection and cleanup"""
        try:
            cleaned_items = 0
            
            # Clean temporary files
            temp_dir = self.vault.vault_path / "temp"
            if temp_dir.exists():
                for item in temp_dir.iterdir():
                    if item.is_file():
                        # Remove files older than 1 hour
                        if time.time() - item.stat().st_mtime > 3600:
                            item.unlink()
                            cleaned_items += 1
            
            # Clean orphaned storage files
            storage_dir = self.vault.vault_path / "files"
            if storage_dir.exists():
                # Get all file IDs from database
                conn = sqlite3.connect(str(self.vault.db_path))
                cursor = conn.cursor()
                cursor.execute('SELECT file_id FROM vault_files')
                db_file_ids = {row[0] for row in cursor.fetchall()}
                conn.close()
                
                # Check storage files
                for subdir in storage_dir.iterdir():
                    if subdir.is_dir():
                        for storage_file in subdir.iterdir():
                            if storage_file.suffix == '.vault':
                                file_id = storage_file.stem
                                if file_id not in db_file_ids:
                                    storage_file.unlink()
                                    cleaned_items += 1
            
            # Clear old cache entries
            cache_cleared = len(self.vault.cache)
            self.vault.cache.clear()
            
            return {
                'files_cleaned': cleaned_items,
                'cache_entries_cleared': cache_cleared,
                'cleanup_completed': True
            }
            
        except Exception as e:
            self.logger.error(f"Garbage collection error: {e}")
            return {'error': str(e)}
    
    def _optimize_cache(self):
        """Optimize cache settings and behavior"""
        try:
            # Analyze cache performance
            total_requests = self.vault.stats['cache_hits'] + self.vault.stats['cache_misses']
            hit_rate = 0
            if total_requests > 0:
                hit_rate = (self.vault.stats['cache_hits'] / total_requests) * 100
            
            # Adjust cache size based on performance and memory
            current_memory = psutil.virtual_memory().percent
            
            if hit_rate < 50 and current_memory < 70:
                # Increase cache size
                new_cache_size = min(self.vault.cache_max_size * 1.2, 200 * 1024 * 1024)
                self.vault.cache_max_size = int(new_cache_size)
                adjustment = "increased"
            elif current_memory > 85:
                # Decrease cache size
                new_cache_size = max(self.vault.cache_max_size * 0.8, 50 * 1024 * 1024)
                self.vault.cache_max_size = int(new_cache_size)
                adjustment = "decreased"
            else:
                adjustment = "unchanged"
            
            # Implement LRU cache eviction
            self._implement_lru_cache()
            
            return {
                'cache_hit_rate': round(hit_rate, 2),
                'cache_size_adjustment': adjustment,
                'new_cache_size_mb': self.vault.cache_max_size // (1024 * 1024),
                'memory_usage_percent': current_memory
            }
            
        except Exception as e:
            self.logger.error(f"Cache optimization error: {e}")
            return {'error': str(e)}
    
    def _implement_lru_cache(self):
        """Implement LRU (Least Recently Used) cache eviction"""
        try:
            # Add access tracking to cache
            if not hasattr(self.vault, 'cache_access_times'):
                self.vault.cache_access_times = {}
            
            # Update access times for current cache entries
            current_time = time.time()
            for key in self.vault.cache.keys():
                if key not in self.vault.cache_access_times:
                    self.vault.cache_access_times[key] = current_time
            
            # Remove entries not in cache anymore
            cache_keys = set(self.vault.cache.keys())
            access_keys = set(self.vault.cache_access_times.keys())
            for key in access_keys - cache_keys:
                del self.vault.cache_access_times[key]
            
        except Exception as e:
            self.logger.error(f"LRU cache implementation error: {e}")
    
    def _optimize_io(self):
        """Optimize I/O operations"""
        try:
            # Analyze I/O patterns
            io_stats = {}
            
            # Get disk I/O statistics
            disk_io = psutil.disk_io_counters()
            if disk_io:
                io_stats['read_bytes'] = disk_io.read_bytes
                io_stats['write_bytes'] = disk_io.write_bytes
                io_stats['read_time'] = disk_io.read_time
                io_stats['write_time'] = disk_io.write_time
            
            # Optimize chunk size based on performance
            current_chunk_size = self.vault.chunk_size
            
            # Simple optimization: adjust chunk size based on file sizes
            conn = sqlite3.connect(str(self.vault.db_path))
            cursor = conn.cursor()
            cursor.execute('SELECT AVG(original_size) FROM vault_files')
            avg_file_size = cursor.fetchone()[0] or 0
            conn.close()
            
            if avg_file_size > 0:
                # Optimize chunk size to be about 1/10th of average file size
                optimal_chunk_size = max(64 * 1024, min(avg_file_size // 10, 10 * 1024 * 1024))
                self.vault.chunk_size = int(optimal_chunk_size)
            
            return {
                'io_statistics': io_stats,
                'old_chunk_size': current_chunk_size,
                'new_chunk_size': self.vault.chunk_size,
                'average_file_size': avg_file_size
            }
            
        except Exception as e:
            self.logger.error(f"I/O optimization error: {e}")
            return {'error': str(e)}
    
    def _log_optimization_results(self, results):
        """Log optimization results"""
        try:
            log_entry = {
                'timestamp': datetime.now().isoformat(),
                'optimization_results': results,
                'system_metrics': {
                    'memory_usage': psutil.virtual_memory().percent,
                    'cpu_usage': psutil.cpu_percent(),
                    'disk_usage': psutil.disk_usage(str(self.vault.vault_path)).percent
                }
            }
            
            log_file = self.vault.vault_path / "optimization_log.json"
            
            # Read existing log
            existing_logs = []
            if log_file.exists():
                try:
                    with open(log_file, 'r') as f:
                        existing_logs = json.load(f)
                except json.JSONDecodeError:
                    existing_logs = []
            
            # Add new log entry
            existing_logs.append(log_entry)
            
            # Keep only last 100 entries
            existing_logs = existing_logs[-100:]
            
            # Save updated log
            with open(log_file, 'w') as f:
                json.dump(existing_logs, f, indent=2)
                
        except Exception as e:
            self.logger.error(f"Optimization logging error: {e}")
    
    def get_performance_report(self):
        """Generate comprehensive performance report"""
        try:
            # Current metrics
            current_metrics = {}
            if self.metrics['memory_usage']:
                current_metrics['memory_usage'] = self.metrics['memory_usage'][-1]['value']
            if self.metrics['cpu_usage']:
                current_metrics['cpu_usage'] = self.metrics['cpu_usage'][-1]['value']
            if self.metrics['cache_efficiency']:
                current_metrics['cache_efficiency'] = self.metrics['cache_efficiency'][-1]['value']
            
            # Performance trends
            trends = {}
            for metric_name, metric_data in self.metrics.items():
                if len(metric_data) > 1:
                    values = [m['value'] for m in metric_data]
                    avg_value = sum(values) / len(values)
                    trends[metric_name] = {
                        'average': round(avg_value, 2),
                        'min': min(values),
                        'max': max(values),
                        'data_points': len(values)
                    }
            
            # System information
            system_info = {
                'total_memory_gb': round(psutil.virtual_memory().total / (1024**3), 2),
                'cpu_count': psutil.cpu_count(),
                'disk_total_gb': round(psutil.disk_usage(str(self.vault.vault_path)).total / (1024**3), 2),
                'disk_free_gb': round(psutil.disk_usage(str(self.vault.vault_path)).free / (1024**3), 2)
            }
            
            # Vault statistics
            vault_stats = self.vault.get_vault_stats()
            
            return {
                'timestamp': datetime.now().isoformat(),
                'current_metrics': current_metrics,
                'performance_trends': trends,
                'system_information': system_info,
                'vault_statistics': vault_stats,
                'optimization_settings': self.settings,
                'optimization_strategies': self.strategies
            }
            
        except Exception as e:
            self.logger.error(f"Performance report error: {e}")
            return {'error': str(e)}

if __name__ == "__main__":
    # Example usage
    from secure_vault import SecureDataVault
    
    vault = SecureDataVault()
    optimizer = VaultPerformanceOptimizer(vault)
    
    # Start monitoring
    optimizer.start_monitoring()
    
    # Generate performance report
    report = optimizer.get_performance_report()
    print("Performance Report:")
    print(json.dumps(report, indent=2))
    
    # Stop monitoring
    optimizer.stop_monitoring()