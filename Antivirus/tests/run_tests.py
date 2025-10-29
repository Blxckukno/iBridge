"""
Enhanced Test Runner Script
Comprehensive test execution, configuration, reporting, and management
for the antivirus system testing framework
"""

import sys
import os
import argparse
import time
import json
import re
import textwrap
import logging
import importlib
import traceback
import unittest
import webbrowser
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Any, Optional, Set, Tuple

# Add project root to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from tests import TestFramework
from tests.config_manager import ConfigurationManager

# ANSI color codes for terminal output
class Colors:
    RESET = "\033[0m"
    BOLD = "\033[1m"
    RED = "\033[31m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    BLUE = "\033[34m"
    MAGENTA = "\033[35m"
    CYAN = "\033[36m"
    GRAY = "\033[90m"
    
    # Combined styles
    ERROR = RED + BOLD
    SUCCESS = GREEN + BOLD
    WARNING = YELLOW + BOLD
    INFO = BLUE + BOLD

def colored(text: str, color: str) -> str:
    """Apply color to text if terminal supports it"""
    if sys.platform == "win32" and not os.environ.get("TERM", "").lower().startswith(("xterm", "vt")):
        return text  # No color on regular Windows console
    return f"{color}{text}{Colors.RESET}"

class EnhancedTestRunner:
    """Enhanced test runner with additional features"""
    
    def __init__(self):
        """Initialize the test runner"""
        self.framework = TestFramework()
        self.test_modules = {}
        self.start_time = None
        self.end_time = None
        
        # Initialize configuration manager
        self.config_manager = ConfigurationManager()
        self.config = self.config_manager.get_config()
        
        # Set up logger
        self.logger = logging.getLogger("TestRunner")
        self._configure_logger()
        
        # Set up test directories
        self.test_dirs = {
            'unit': Path(__file__).parent / 'unit',
            'integration': Path(__file__).parent / 'integration',
            'security': Path(__file__).parent / 'security',
            'performance': Path(__file__).parent / 'performance',
        }
        
        # Reports directory
        self.reports_dir = Path(__file__).parent / 'reports'
        self.reports_dir.mkdir(exist_ok=True)
    
    def _configure_logger(self):
        """Configure the test runner logger"""
        log_level = getattr(logging, self.config.get('log_level', 'INFO'))
        self.logger.setLevel(log_level)
        
        # Console handler
        console_handler = logging.StreamHandler()
        console_handler.setLevel(log_level)
        
        # Formatter
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        console_handler.setFormatter(formatter)
        
        # Clear existing handlers if any
        if self.logger.handlers:
            self.logger.handlers.clear()
            
        self.logger.addHandler(console_handler)
        
        # Add file handler if output file specified
        output_file = self.config.get('output_file')
        if output_file:
            try:
                file_handler = logging.FileHandler(output_file)
                file_handler.setLevel(log_level)
                file_handler.setFormatter(formatter)
                self.logger.addHandler(file_handler)
                self.logger.info(f"Logging to file: {output_file}")
            except Exception as e:
                self.logger.warning(f"Failed to set up file logging to {output_file}: {str(e)}")
    
    def load_config_from_file(self, config_file: str) -> bool:
        """Load configuration from a JSON file"""
        try:
            config_path = Path(config_file)
            if not config_path.exists():
                self.logger.warning(f"Config file not found: {config_file}")
                return False
            
            with open(config_path, 'r') as f:
                file_config = json.load(f)
            
            # Update config with file values
            self.config.update(file_config)
            self.logger.info(f"Loaded configuration from {config_file}")
            return True
            
        except Exception as e:
            self.logger.error(f"Error loading config file: {str(e)}")
            return False
    
    def update_config_from_args(self, args: argparse.Namespace) -> None:
        """Update configuration based on command line arguments"""
        # First, load config file if specified
        if args.config:
            self.config_manager.load_config(args.config)
            self.config = self.config_manager.get_config()
        
        # Create config updates dictionary
        config_updates = {}
        
        # Test types to run
        if args.unit:
            config_updates.update({
                'run_unit_tests': True,
                'run_integration_tests': False,
                'run_security_tests': False,
                'run_performance_tests': False
            })
        elif args.integration:
            config_updates.update({
                'run_unit_tests': False,
                'run_integration_tests': True,
                'run_security_tests': False,
                'run_performance_tests': False
            })
        elif args.security:
            config_updates.update({
                'run_unit_tests': False,
                'run_integration_tests': False,
                'run_security_tests': True,
                'run_performance_tests': False
            })
        elif args.performance:
            config_updates.update({
                'run_unit_tests': False,
                'run_integration_tests': False,
                'run_security_tests': False,
                'run_performance_tests': True
            })
        
        # Other options
        if args.verbose:
            config_updates['verbose_output'] = True
        
        if args.no_report:
            config_updates['create_test_report'] = False
        
        if args.open_browser:
            config_updates['open_report_browser'] = True
        
        if args.parallel:
            config_updates['parallel_tests'] = True
        
        if args.timeout is not None:
            config_updates['test_timeout'] = args.timeout
        
        if args.retry is not None:
            config_updates['retry_failed_tests'] = args.retry
        
        if args.fail_fast:
            config_updates['fail_fast'] = True
        
        if args.include:
            config_updates['include_patterns'] = args.include
        
        if args.exclude:
            config_updates['exclude_patterns'] = args.exclude
        
        if args.report_format:
            config_updates['report_format'] = args.report_format
        
        if args.no_cleanup:
            config_updates['cleanup_after_tests'] = False
        
        if args.coverage:
            config_updates['coverage_enabled'] = True
        
        if args.output_file:
            config_updates['output_file'] = args.output_file
            
        # Apply updates
        if config_updates:
            self.config_manager.update_config(config_updates)
            self.config = self.config_manager.get_config()
            
        # Update framework config
        self._sync_framework_config()
    
    def _sync_framework_config(self) -> None:
        """Synchronize configuration with the TestFramework"""
        for key in ['run_unit_tests', 'run_integration_tests', 'run_security_tests',
                   'run_performance_tests', 'verbose_output', 'create_test_report',
                   'test_timeout', 'parallel_tests', 'cleanup_after_tests']:
            if key in self.config:
                self.framework.config[key] = self.config[key]
    
    def discover_test_modules(self) -> bool:
        """Discover and categorize available test modules"""
        try:
            for category, directory in self.test_dirs.items():
                if not directory.exists():
                    continue
                
                self.test_modules[category] = []
                
                # Find test files
                for file_path in directory.glob('test_*.py'):
                    module_name = file_path.stem
                    self.test_modules[category].append(module_name)
            
            return True
            
        except Exception as e:
            self.logger.error(f"Error discovering test modules: {str(e)}")
            return False
    
    def filter_tests(self, tests: unittest.TestSuite) -> unittest.TestSuite:
        """Filter tests based on include/exclude patterns"""
        if not (self.config['include_patterns'] or self.config['exclude_patterns']):
            return tests
        
        filtered_suite = unittest.TestSuite()
        
        for test in tests:
            if isinstance(test, unittest.TestSuite):
                # Recursively filter test suites
                filtered_subsuite = self.filter_tests(test)
                if filtered_subsuite.countTestCases() > 0:
                    filtered_suite.addTest(filtered_subsuite)
            else:
                test_name = f"{test.__class__.__module__}.{test.__class__.__name__}.{test._testMethodName}"
                
                # Check exclude patterns first
                excluded = any(re.search(pattern, test_name) for pattern in self.config['exclude_patterns'])
                if excluded:
                    continue
                
                # Then check include patterns
                included = True
                if self.config['include_patterns']:
                    included = any(re.search(pattern, test_name) for pattern in self.config['include_patterns'])
                
                if included:
                    filtered_suite.addTest(test)
        
        return filtered_suite
    
    def run_specific_test(self, test_path: str) -> bool:
        """Run a specific test module, class, or method"""
        try:
            # Parse test path (e.g., "unit.test_firewall.TestFirewallRule.test_rule_creation")
            parts = test_path.split('.')
            
            if len(parts) == 1:
                # Just category (unit, integration, etc.)
                category = parts[0]
                if category == 'unit':
                    return self.run_tests(run_unit=True, run_integration=False, run_security=False, run_performance=False)
                elif category == 'integration':
                    return self.run_tests(run_unit=False, run_integration=True, run_security=False, run_performance=False)
                elif category == 'security':
                    return self.run_tests(run_unit=False, run_integration=False, run_security=True, run_performance=False)
                elif category == 'performance':
                    return self.run_tests(run_unit=False, run_integration=False, run_security=False, run_performance=True)
                else:
                    self.logger.error(f"Unknown test category: {category}")
                    return False
            
            # Adjust test path based on the number of parts
            if len(parts) == 2:
                # Category and module (e.g., "unit.test_firewall")
                category, module = parts
                test_path = f"tests.{category}.{module}"
            elif len(parts) >= 3:
                # Category, module, class, and possibly method
                category, module = parts[0], parts[1]
                test_path = f"tests.{category}.{module}.{'.'.join(parts[2:])}"
            
            self.logger.info(f"Running specific test: {test_path}")
            
            # Load the test
            suite = unittest.TestLoader().loadTestsFromName(test_path)
            
            if suite.countTestCases() == 0:
                self.logger.error(f"No tests found for: {test_path}")
                return False
            
            # Run the test
            runner = unittest.TextTestRunner(verbosity=2 if self.config['verbose_output'] else 1)
            result = runner.run(suite)
            
            return result.wasSuccessful()
            
        except Exception as e:
            self.logger.error(f"Error running specific test: {str(e)}")
            traceback.print_exc()
            return False
    
    def list_available_tests(self) -> None:
        """List all available tests"""
        if not self.discover_test_modules():
            self.logger.error("Failed to discover test modules")
            return
        
        print(colored("\n=== AVAILABLE TESTS ===", Colors.BOLD))
        
        for category, modules in sorted(self.test_modules.items()):
            print(colored(f"\n{category.upper()} TESTS:", Colors.INFO))
            
            if not modules:
                print(colored("  No test modules found", Colors.GRAY))
                continue
            
            for module in sorted(modules):
                print(f"  - {module}")
                
                # Try to load the module and list test classes
                try:
                    # Import the module
                    full_module_name = f"tests.{category}.{module}"
                    module_obj = importlib.import_module(full_module_name)
                    
                    # Find all test classes
                    test_cases = []
                    for attr_name in dir(module_obj):
                        attr = getattr(module_obj, attr_name)
                        if isinstance(attr, type) and issubclass(attr, unittest.TestCase) and attr.__module__ == full_module_name:
                            test_methods = [m for m in dir(attr) if m.startswith('test_')]
                            test_cases.append((attr_name, test_methods))
                    
                    # Print test classes and methods
                    for class_name, methods in sorted(test_cases):
                        print(f"    • {class_name}")
                        for method in sorted(methods):
                            print(f"      ◦ {method}")
                            
                except Exception as e:
                    print(colored(f"    Error loading module: {str(e)}", Colors.ERROR))
    
    def generate_test_report(self) -> Optional[str]:
        """Generate test report based on the configured format"""
        if not self.config['create_test_report']:
            return None
        
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        report_format = self.config['report_format'].lower()
        
        if report_format == 'html':
            report_file = self.reports_dir / f"test_report_{timestamp}.html"
            with open(report_file, 'w') as f:
                f.write(self.framework._generate_html_report())
        elif report_format == 'json':
            report_file = self.reports_dir / f"test_report_{timestamp}.json"
            with open(report_file, 'w') as f:
                json.dump(self.framework.test_results, f, indent=2, default=str)
        elif report_format == 'xml':
            report_file = self.reports_dir / f"test_report_{timestamp}.xml"
            self._generate_junit_xml(report_file)
        else:
            self.logger.warning(f"Unsupported report format: {report_format}")
            return None
        
        self.logger.info(f"Test report generated: {report_file}")
        
        if self.config['open_report_browser'] and report_format == 'html':
            try:
                webbrowser.open(f"file://{report_file}")
            except Exception as e:
                self.logger.warning(f"Failed to open report in browser: {str(e)}")
        
        return str(report_file)
    
    def _generate_junit_xml(self, file_path: Path) -> None:
        """Generate JUnit XML report for CI integration"""
        import xml.etree.ElementTree as ET
        from xml.dom import minidom
        
        test_results = self.framework.test_results
        stats = test_results['summary']
        
        # Create root element
        testsuite = ET.Element('testsuite')
        testsuite.set('name', 'Antivirus System Tests')
        testsuite.set('tests', str(stats['total_tests']))
        testsuite.set('failures', str(stats['failed_tests']))
        testsuite.set('errors', str(stats['error_tests']))
        testsuite.set('skipped', str(stats['skipped_tests']))
        testsuite.set('time', str(stats['duration']))
        testsuite.set('timestamp', datetime.now().isoformat())
        
        # Add properties
        properties = ET.SubElement(testsuite, 'properties')
        for key, value in self.config.items():
            prop = ET.SubElement(properties, 'property')
            prop.set('name', key)
            prop.set('value', str(value))
        
        # Add test failures
        for failure in test_results.get('failures', []):
            testcase = ET.SubElement(testsuite, 'testcase')
            testcase.set('name', str(failure['test']))
            testcase.set('classname', str(failure['test']).split(' ')[0])
            
            failure_elem = ET.SubElement(testcase, 'failure')
            failure_elem.set('type', 'AssertionError')
            failure_elem.set('message', 'Test failed')
            failure_elem.text = failure['traceback']
        
        # Add test errors
        for error in test_results.get('errors', []):
            testcase = ET.SubElement(testsuite, 'testcase')
            testcase.set('name', str(error['test']))
            testcase.set('classname', str(error['test']).split(' ')[0])
            
            error_elem = ET.SubElement(testcase, 'error')
            error_elem.set('type', 'Error')
            error_elem.set('message', 'Test error')
            error_elem.text = error['traceback']
        
        # Add skipped tests
        for skipped in test_results.get('skipped', []):
            testcase = ET.SubElement(testsuite, 'testcase')
            testcase.set('name', str(skipped['test']))
            testcase.set('classname', str(skipped['test']).split(' ')[0])
            
            skipped_elem = ET.SubElement(testcase, 'skipped')
            skipped_elem.set('message', skipped['reason'])
        
        # Write to file with pretty formatting
        rough_string = ET.tostring(testsuite, 'utf-8')
        reparsed = minidom.parseString(rough_string)
        with open(file_path, 'w') as f:
            f.write(reparsed.toprettyxml(indent="  "))
    
    def run_coverage_analysis(self) -> Tuple[bool, float]:
        """Run tests with coverage analysis"""
        try:
            import coverage
        except ImportError:
            self.logger.error("Coverage analysis requires the 'coverage' package. Install with: pip install coverage")
            return False, 0.0
        
        # Configure coverage
        cov = coverage.Coverage(
            source=['antivirus', 'firewall', 'data_vault', 'vpn', 'browser_protection', 
                    'security_manager', 'ui', 'utils'],
            omit=['tests/*', '*/test_*.py', '*/__init__.py'],
            config_file=str(Path(__file__).parent / '.coveragerc')
        )
        
        # Start coverage
        cov.start()
        
        # Run tests
        success = self.framework.run_tests()
        
        # Stop coverage
        cov.stop()
        cov.save()
        
        # Generate report
        total_coverage = cov.report()
        
        # Generate HTML report
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        coverage_dir = self.reports_dir / f'coverage_{timestamp}'
        coverage_dir.mkdir(exist_ok=True)
        
        cov.html_report(directory=str(coverage_dir))
        
        coverage_html = coverage_dir / 'index.html'
        self.logger.info(f"Coverage report generated: {coverage_html}")
        
        if self.config['open_report_browser']:
            try:
                webbrowser.open(f"file://{coverage_html}")
            except Exception as e:
                self.logger.warning(f"Failed to open coverage report in browser: {str(e)}")
        
        # Check if coverage meets threshold
        threshold_met = total_coverage >= self.config['coverage_threshold']
        if not threshold_met:
            self.logger.warning(
                f"Coverage {total_coverage:.1f}% below threshold {self.config['coverage_threshold']}%")
        
        return success and threshold_met, total_coverage
    
    def print_test_summary(self) -> None:
        """Print detailed test execution summary"""
        stats = self.framework.stats
        total_time = self.end_time - self.start_time if self.end_time and self.start_time else 0
        
        print("\n" + colored("="*60, Colors.BOLD))
        print(colored("TEST EXECUTION SUMMARY", Colors.BOLD))
        print(colored("="*60, Colors.BOLD))
        
        print(f"Total Execution Time: {total_time:.2f} seconds")
        print(f"Tests Run: {colored(str(stats['total_tests']), Colors.BOLD)}")
        print(f"Passed: {colored(str(stats['passed_tests']) + ' ✓', Colors.SUCCESS)}")
        print(f"Failed: {colored(str(stats['failed_tests']) + ' ✗', Colors.ERROR)}")
        print(f"Errors: {colored(str(stats['error_tests']) + ' ⚠', Colors.WARNING)}")
        print(f"Skipped: {colored(str(stats['skipped_tests']) + ' ⊘', Colors.GRAY)}")
        
        if stats['total_tests'] > 0:
            success_rate = (stats['passed_tests'] / stats['total_tests']) * 100
            color = Colors.SUCCESS if success_rate >= 90 else Colors.WARNING if success_rate >= 75 else Colors.ERROR
            print(f"Success Rate: {colored(f'{success_rate:.1f}%', color)}")
        
        print(colored("-"*60, Colors.BOLD))
        
        # Print failures and errors if any
        if stats['failed_tests'] > 0 or stats['error_tests'] > 0:
            print(colored("\nTEST FAILURES AND ERRORS:", Colors.ERROR))
            
            if 'failures' in self.framework.test_results:
                for i, failure in enumerate(self.framework.test_results['failures'], 1):
                    print(colored(f"\nFAILURE {i}: {failure['test']}", Colors.ERROR))
                    # Print first few lines of traceback for context
                    traceback_lines = failure['traceback'].strip().split('\n')
                    for j, line in enumerate(traceback_lines):
                        if j < 5 or j >= len(traceback_lines) - 3:
                            print(colored(line, Colors.RED))
                        elif j == 5:
                            print(colored("...", Colors.RED))
            
            if 'errors' in self.framework.test_results:
                for i, error in enumerate(self.framework.test_results['errors'], 1):
                    print(colored(f"\nERROR {i}: {error['test']}", Colors.ERROR))
                    # Print first few lines of traceback for context
                    traceback_lines = error['traceback'].strip().split('\n')
                    for j, line in enumerate(traceback_lines):
                        if j < 5 or j >= len(traceback_lines) - 3:
                            print(colored(line, Colors.RED))
                        elif j == 5:
                            print(colored("...", Colors.RED))
    
    def run_tests(self, run_unit=True, run_integration=True, run_security=True, run_performance=True) -> bool:
        """Run tests with the configured settings"""
        # Update test types if specified
        if run_unit is not None:
            self.framework.config['run_unit_tests'] = run_unit
        if run_integration is not None:
            self.framework.config['run_integration_tests'] = run_integration
        if run_security is not None:
            self.framework.config['run_security_tests'] = run_security
        if run_performance is not None:
            self.framework.config['run_performance_tests'] = run_performance
        
        # Print configuration
        test_types = []
        if self.framework.config['run_unit_tests']:
            test_types.append("Unit")
        if self.framework.config['run_integration_tests']:
            test_types.append("Integration")
        if self.framework.config['run_security_tests']:
            test_types.append("Security")
        if self.framework.config['run_performance_tests']:
            test_types.append("Performance")
        
        print(colored("="*60, Colors.BOLD))
        print(colored("ANTIVIRUS SYSTEM TEST RUNNER", Colors.BOLD))
        print(colored("="*60, Colors.BOLD))
        print(f"Running Tests: {colored(', '.join(test_types), Colors.INFO)}")
        print(f"Verbose Output: {colored('Yes' if self.config['verbose_output'] else 'No', Colors.BLUE)}")
        print(f"Generate Report: {colored('Yes' if self.config['create_test_report'] else 'No', Colors.BLUE)}")
        print(f"Parallel Execution: {colored('Yes' if self.config['parallel_tests'] else 'No', Colors.BLUE)}")
        print(f"Fail Fast: {colored('Yes' if self.config['fail_fast'] else 'No', Colors.BLUE)}")
        print(f"Retry Failed Tests: {colored(str(self.config['retry_failed_tests']), Colors.BLUE)}")
        print(f"Coverage Enabled: {colored('Yes' if self.config['coverage_enabled'] else 'No', Colors.BLUE)}")
        print(colored("-"*60, Colors.BOLD))
        
        # Create test data
        print("Creating test data...")
        if not self.framework.create_test_data():
            print(colored("ERROR: Failed to create test data", Colors.ERROR))
            return False
        
        # Discover tests
        print("Discovering tests...")
        if not self.framework.discover_tests():
            print(colored("ERROR: Failed to discover tests", Colors.ERROR))
            return False
        
        # Filter tests if include/exclude patterns provided
        if self.config['include_patterns'] or self.config['exclude_patterns']:
            print("Filtering tests...")
            self.framework.test_suite = self.filter_tests(self.framework.test_suite)
            if self.framework.test_suite.countTestCases() == 0:
                print(colored("WARNING: No tests match the specified patterns", Colors.WARNING))
        
        # Run tests (with or without coverage)
        print("Executing tests...")
        self.start_time = time.time()
        
        if self.config['coverage_enabled']:
            success, coverage_percentage = self.run_coverage_analysis()
            print(f"Code Coverage: {colored(f'{coverage_percentage:.1f}%', Colors.INFO)}")
        else:
            success = self.framework.run_tests()
        
        self.end_time = time.time()
        
        # Generate test report if enabled
        if self.config['create_test_report']:
            report_file = self.generate_test_report()
            if report_file:
                print(f"Test report generated: {colored(report_file, Colors.INFO)}")
        
        # Print detailed summary
        self.print_test_summary()
        
        # Cleanup
        if self.framework.config['cleanup_after_tests']:
            print("Cleaning up test data...")
            self.framework.cleanup_test_data()
        
        return success

def main():
    """Main entry point for the test runner"""
    # Parse command line arguments
    parser = argparse.ArgumentParser(
        description='Enhanced Antivirus System Test Runner',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=textwrap.dedent('''
        Examples:
          # Run all tests with default settings
          python run_tests.py --all
          
          # Run only unit tests
          python run_tests.py --unit
          
          # Run specific test (category.module.class.method)
          python run_tests.py --specific unit.test_firewall.TestFirewallRule.test_rule_creation
          
          # Run tests with coverage analysis
          python run_tests.py --all --coverage
          
          # List all available tests
          python run_tests.py --list
          
          # Run tests matching a pattern
          python run_tests.py --all --include "test_firewall.*" "test_antivirus_core.*"
          
          # Run tests excluding a pattern
          python run_tests.py --all --exclude ".*performance.*" ".*stress_test.*"
          
          # Load configuration from file
          python run_tests.py --all --config test_config.json
        ''')
    )
    
    # Test type options
    test_group = parser.add_argument_group('Test Selection')
    test_group.add_argument('--all', action='store_true', help='Run all tests (default)')
    test_group.add_argument('--unit', action='store_true', help='Run unit tests only')
    test_group.add_argument('--integration', action='store_true', help='Run integration tests only')
    test_group.add_argument('--security', action='store_true', help='Run security tests only')
    test_group.add_argument('--performance', action='store_true', help='Run performance tests only')
    test_group.add_argument('--specific', metavar='PATH', help='Run a specific test (format: category.module.class.method)')
    
    # Output options
    output_group = parser.add_argument_group('Output Options')
    output_group.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    output_group.add_argument('--no-report', action='store_true', help='Skip report generation')
    output_group.add_argument('--report-format', choices=['html', 'json', 'xml'], default='html', help='Report format (default: html)')
    output_group.add_argument('--open-browser', action='store_true', help='Open report in browser when completed')
    output_group.add_argument('--output-file', help='Save test output to a file')
    
    # Execution options
    exec_group = parser.add_argument_group('Execution Options')
    exec_group.add_argument('--parallel', action='store_true', help='Run tests in parallel')
    exec_group.add_argument('--timeout', type=int, help='Test timeout in seconds (default: 300)')
    exec_group.add_argument('--retry', type=int, help='Number of retries for failed tests (default: 1)')
    exec_group.add_argument('--fail-fast', action='store_true', help='Stop on first test failure')
    exec_group.add_argument('--no-cleanup', action='store_true', help='Skip cleanup of test data')
    
    # Filtering options
    filter_group = parser.add_argument_group('Test Filtering')
    filter_group.add_argument('--include', nargs='+', help='Include tests matching these patterns')
    filter_group.add_argument('--exclude', nargs='+', help='Exclude tests matching these patterns')
    
    # Special options
    special_group = parser.add_argument_group('Special Options')
    special_group.add_argument('--list', action='store_true', help='List available tests and exit')
    special_group.add_argument('--config', help='Load configuration from JSON file')
    special_group.add_argument('--coverage', action='store_true', help='Run tests with coverage analysis')
    
    args = parser.parse_args()
    
    # Create test runner
    runner = EnhancedTestRunner()
    
    # Load config from file if specified
    if args.config:
        runner.load_config_from_file(args.config)
    
    # Update config from command line arguments
    runner.update_config_from_args(args)
    
    # Handle special commands
    if args.list:
        runner.list_available_tests()
        return 0
    
    # Run specific test if requested
    if args.specific:
        success = runner.run_specific_test(args.specific)
        return 0 if success else 1
    
    # Run tests with the configured settings
    success = runner.run_tests()
    
    # Return appropriate exit code
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())