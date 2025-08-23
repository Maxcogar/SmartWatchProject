#!/usr/bin/env python3
"""
Hardware Validation Script for ESP32-S3 ADHD SmartWatch
Comprehensive testing of all hardware components and functionality

This script performs automated testing of:
- Display functionality and backlight control
- Touch screen responsiveness and calibration
- Power management and battery monitoring
- BLE communication and advertising
- System boot and component initialization

Author: ESP32-S3 Development Team
Version: 1.0.0
Date: 2025-08-19
"""

import serial
import time
import sys
import json
import argparse
import threading
from datetime import datetime
from enum import Enum
from typing import Dict, List, Optional, Tuple

class TestResult(Enum):
    """Test result enumeration"""
    PASS = "PASS"
    FAIL = "FAIL"
    SKIP = "SKIP"
    WARN = "WARN"

class Colors:
    """ANSI color codes for console output"""
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

class HardwareValidator:
    """Main hardware validation class"""
    
    def __init__(self, port: str, baudrate: int = 115200, timeout: int = 10):
        """Initialize hardware validator
        
        Args:
            port: Serial port for communication
            baudrate: Serial communication speed
            timeout: Communication timeout in seconds
        """
        self.port = port
        self.baudrate = baudrate
        self.timeout = timeout
        self.serial_conn = None
        self.test_results = {}
        self.start_time = datetime.now()
        
    def log_message(self, message: str, level: str = "INFO", color: str = Colors.WHITE):
        """Log message with timestamp and color"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        print(f"{color}[{timestamp}] [{level}] {message}{Colors.RESET}")
        
    def log_success(self, message: str):
        """Log success message"""
        self.log_message(f"✅ {message}", "PASS", Colors.GREEN)
        
    def log_error(self, message: str):
        """Log error message"""
        self.log_message(f"❌ {message}", "FAIL", Colors.RED)
        
    def log_warning(self, message: str):
        """Log warning message"""
        self.log_message(f"⚠️  {message}", "WARN", Colors.YELLOW)
        
    def log_info(self, message: str):
        """Log info message"""
        self.log_message(f"ℹ️  {message}", "INFO", Colors.BLUE)
        
    def connect_serial(self) -> bool:
        """Establish serial connection to ESP32-S3"""
        try:
            self.log_info(f"Connecting to {self.port} at {self.baudrate} baud...")
            self.serial_conn = serial.Serial(
                port=self.port,
                baudrate=self.baudrate,
                timeout=self.timeout,
                rtscts=False,
                dsrdtr=False
            )
            
            # Wait for connection to stabilize
            time.sleep(2)
            
            # Clear any existing data
            self.serial_conn.flushInput()
            self.serial_conn.flushOutput()
            
            self.log_success("Serial connection established")
            return True
            
        except serial.SerialException as e:
            self.log_error(f"Failed to connect to {self.port}: {e}")
            return False
        except Exception as e:
            self.log_error(f"Unexpected error connecting to device: {e}")
            return False
    
    def disconnect_serial(self):
        """Close serial connection"""
        if self.serial_conn and self.serial_conn.is_open:
            self.serial_conn.close()
            self.log_info("Serial connection closed")
    
    def send_command(self, command: str, expect_response: bool = True) -> Optional[str]:
        """Send command to device and wait for response
        
        Args:
            command: Command string to send
            expect_response: Whether to wait for response
            
        Returns:
            Response string or None if no response expected/received
        """
        try:
            # Send command
            cmd_bytes = f"{command}\\n".encode('utf-8')
            self.serial_conn.write(cmd_bytes)
            self.serial_conn.flush()
            
            if not expect_response:
                return None
            
            # Wait for response
            response_lines = []
            start_time = time.time()
            
            while time.time() - start_time < self.timeout:
                if self.serial_conn.in_waiting > 0:
                    line = self.serial_conn.readline().decode('utf-8', errors='ignore').strip()
                    if line:
                        response_lines.append(line)
                        # Check for command completion markers
                        if "OK" in line or "DONE" in line or "ERROR" in line:
                            break
                time.sleep(0.1)
            
            return "\\n".join(response_lines)
            
        except Exception as e:
            self.log_error(f"Command '{command}' failed: {e}")
            return None
    
    def read_serial_output(self, duration: float = 5.0) -> List[str]:
        """Read serial output for specified duration
        
        Args:
            duration: Time to read output in seconds
            
        Returns:
            List of output lines
        """
        lines = []
        start_time = time.time()
        
        while time.time() - start_time < duration:
            if self.serial_conn.in_waiting > 0:
                line = self.serial_conn.readline().decode('utf-8', errors='ignore').strip()
                if line:
                    lines.append(line)
            time.sleep(0.1)
        
        return lines
    
    def test_device_boot(self) -> TestResult:
        """Test device boot sequence and initialization"""
        self.log_info("Testing device boot and initialization...")
        
        try:
            # Reset device (send Ctrl+C to interrupt, then reset)
            self.serial_conn.write(b'\\x03')
            time.sleep(0.5)
            
            # Read boot messages
            boot_messages = self.read_serial_output(10.0)
            
            # Check for expected boot messages
            expected_messages = [
                "ESP-ROM",
                "esp32s3",
                "ESP-IDF",
                "ADHD SmartWatch",
                "initialized successfully"
            ]
            
            found_messages = 0
            for expected in expected_messages:
                for line in boot_messages:
                    if expected.lower() in line.lower():
                        found_messages += 1
                        break
            
            if found_messages >= len(expected_messages) - 1:  # Allow one missing message
                self.log_success("Device boot test passed")
                return TestResult.PASS
            else:
                self.log_error(f"Boot test failed: Found {found_messages}/{len(expected_messages)} expected messages")
                return TestResult.FAIL
                
        except Exception as e:
            self.log_error(f"Boot test failed with exception: {e}")
            return TestResult.FAIL
    
    def test_display_functionality(self) -> TestResult:
        """Test display initialization and basic functionality"""
        self.log_info("Testing display functionality...")
        
        try:
            # Send display test command
            response = self.send_command("test_display")
            
            if response and ("display initialized" in response.lower() or "lcd ok" in response.lower()):
                self.log_success("Display initialization test passed")
                
                # Test backlight control
                backlight_response = self.send_command("test_backlight")
                if backlight_response and "backlight ok" in backlight_response.lower():
                    self.log_success("Backlight control test passed")
                    return TestResult.PASS
                else:
                    self.log_warning("Backlight control test failed")
                    return TestResult.WARN
            else:
                self.log_error("Display initialization failed")
                return TestResult.FAIL
                
        except Exception as e:
            self.log_error(f"Display test failed with exception: {e}")
            return TestResult.FAIL
    
    def test_touch_functionality(self) -> TestResult:
        """Test touch screen functionality"""
        self.log_info("Testing touch screen functionality...")
        
        try:
            # Send touch test command
            response = self.send_command("test_touch")
            
            if response and ("touch initialized" in response.lower() or "cst816" in response.lower()):
                self.log_success("Touch controller initialization passed")
                
                # Interactive touch test
                self.log_info("Please touch the screen within 10 seconds...")
                touch_response = self.read_serial_output(10.0)
                
                touch_detected = False
                for line in touch_response:
                    if "touch" in line.lower() and ("x:" in line.lower() or "pressed" in line.lower()):
                        touch_detected = True
                        break
                
                if touch_detected:
                    self.log_success("Touch detection test passed")
                    return TestResult.PASS
                else:
                    self.log_warning("No touch input detected - please verify manually")
                    return TestResult.WARN
            else:
                self.log_error("Touch controller initialization failed")
                return TestResult.FAIL
                
        except Exception as e:
            self.log_error(f"Touch test failed with exception: {e}")
            return TestResult.FAIL
    
    def test_power_management(self) -> TestResult:
        """Test power management and battery monitoring"""
        self.log_info("Testing power management...")
        
        try:
            # Test battery reading
            response = self.send_command("test_battery")
            
            battery_ok = False
            if response:
                for line in response.split('\\n'):
                    if "battery" in line.lower() and ("%" in line or "voltage" in line.lower()):
                        battery_ok = True
                        self.log_info(f"Battery status: {line.strip()}")
                        break
            
            if battery_ok:
                self.log_success("Battery monitoring test passed")
                
                # Test power profile switching
                power_response = self.send_command("test_power_profile")
                if power_response and "power profile" in power_response.lower():
                    self.log_success("Power profile test passed")
                    return TestResult.PASS
                else:
                    self.log_warning("Power profile test inconclusive")
                    return TestResult.WARN
            else:
                self.log_error("Battery monitoring test failed")
                return TestResult.FAIL
                
        except Exception as e:
            self.log_error(f"Power management test failed with exception: {e}")
            return TestResult.FAIL
    
    def test_ble_functionality(self) -> TestResult:
        """Test Bluetooth Low Energy functionality"""
        self.log_info("Testing BLE functionality...")
        
        try:
            # Test BLE initialization
            response = self.send_command("test_ble")
            
            if response and ("ble initialized" in response.lower() or "nimble" in response.lower()):
                self.log_success("BLE stack initialization passed")
                
                # Test advertising
                adv_response = self.send_command("test_ble_advertising")
                if adv_response and ("advertising" in adv_response.lower() or "started" in adv_response.lower()):
                    self.log_success("BLE advertising test passed")
                    return TestResult.PASS
                else:
                    self.log_warning("BLE advertising test inconclusive")
                    return TestResult.WARN
            else:
                self.log_error("BLE initialization failed")
                return TestResult.FAIL
                
        except Exception as e:
            self.log_error(f"BLE test failed with exception: {e}")
            return TestResult.FAIL
    
    def test_memory_usage(self) -> TestResult:
        """Test memory usage and heap status"""
        self.log_info("Testing memory usage...")
        
        try:
            response = self.send_command("test_memory")
            
            if response:
                heap_info = []
                for line in response.split('\\n'):
                    if "heap" in line.lower() or "memory" in line.lower():
                        heap_info.append(line.strip())
                        self.log_info(f"Memory info: {line.strip()}")
                
                if heap_info:
                    self.log_success("Memory usage test passed")
                    return TestResult.PASS
                else:
                    self.log_warning("No memory information available")
                    return TestResult.WARN
            else:
                self.log_error("Memory test failed - no response")
                return TestResult.FAIL
                
        except Exception as e:
            self.log_error(f"Memory test failed with exception: {e}")
            return TestResult.FAIL
    
    def test_component_communication(self) -> TestResult:
        """Test inter-component communication"""
        self.log_info("Testing component communication...")
        
        try:
            # Test service layer communication
            response = self.send_command("test_services")
            
            if response:
                services_ok = 0
                expected_services = ["NVS", "Bluetooth", "WiFi", "State Manager"]
                
                for service in expected_services:
                    if service.lower() in response.lower():
                        services_ok += 1
                        self.log_info(f"{service} service: OK")
                
                if services_ok >= len(expected_services) - 1:
                    self.log_success("Component communication test passed")
                    return TestResult.PASS
                else:
                    self.log_warning(f"Some services not responding ({services_ok}/{len(expected_services)})")
                    return TestResult.WARN
            else:
                self.log_error("Service communication test failed")
                return TestResult.FAIL
                
        except Exception as e:
            self.log_error(f"Component communication test failed with exception: {e}")
            return TestResult.FAIL
    
    def run_all_tests(self) -> Dict[str, TestResult]:
        """Run all hardware validation tests
        
        Returns:
            Dictionary of test results
        """
        self.log_message("🚀 Starting ESP32-S3 ADHD SmartWatch Hardware Validation", "INFO", Colors.CYAN + Colors.BOLD)
        self.log_message("="*60, "INFO", Colors.CYAN)
        
        # Test suite definition
        tests = [
            ("Device Boot", self.test_device_boot),
            ("Display Functionality", self.test_display_functionality),
            ("Touch Functionality", self.test_touch_functionality),
            ("Power Management", self.test_power_management),
            ("BLE Functionality", self.test_ble_functionality),
            ("Memory Usage", self.test_memory_usage),
            ("Component Communication", self.test_component_communication)
        ]
        
        # Connect to device
        if not self.connect_serial():
            return {"Connection": TestResult.FAIL}
        
        # Run tests
        for test_name, test_func in tests:
            self.log_message(f"\\n--- Running {test_name} Test ---", "INFO", Colors.MAGENTA)
            try:
                result = test_func()
                self.test_results[test_name] = result
                
                if result == TestResult.PASS:
                    self.log_success(f"{test_name} test completed successfully")
                elif result == TestResult.WARN:
                    self.log_warning(f"{test_name} test completed with warnings")
                else:
                    self.log_error(f"{test_name} test failed")
                    
            except Exception as e:
                self.log_error(f"{test_name} test failed with exception: {e}")
                self.test_results[test_name] = TestResult.FAIL
        
        # Disconnect
        self.disconnect_serial()
        
        return self.test_results
    
    def generate_report(self) -> Dict:
        """Generate detailed test report"""
        end_time = datetime.now()
        duration = end_time - self.start_time
        
        # Count results
        pass_count = sum(1 for result in self.test_results.values() if result == TestResult.PASS)
        warn_count = sum(1 for result in self.test_results.values() if result == TestResult.WARN)
        fail_count = sum(1 for result in self.test_results.values() if result == TestResult.FAIL)
        total_count = len(self.test_results)
        
        report = {
            "timestamp": self.start_time.isoformat(),
            "duration_seconds": duration.total_seconds(),
            "device_info": {
                "port": self.port,
                "baudrate": self.baudrate,
                "board": "ESP32-S3-Touch-LCD-2"
            },
            "test_summary": {
                "total_tests": total_count,
                "passed": pass_count,
                "warnings": warn_count,
                "failed": fail_count,
                "success_rate": (pass_count / total_count * 100) if total_count > 0 else 0
            },
            "test_results": {name: result.value for name, result in self.test_results.items()},
            "recommendations": self._generate_recommendations()
        }
        
        return report
    
    def _generate_recommendations(self) -> List[str]:
        """Generate recommendations based on test results"""
        recommendations = []
        
        fail_count = sum(1 for result in self.test_results.values() if result == TestResult.FAIL)
        warn_count = sum(1 for result in self.test_results.values() if result == TestResult.WARN)
        
        if fail_count == 0 and warn_count == 0:
            recommendations.append("✅ All tests passed! Hardware is ready for development.")
        elif fail_count == 0:
            recommendations.append("⚠️ All critical tests passed, but some warnings need attention.")
        else:
            recommendations.append("❌ Critical hardware issues detected. Address failed tests before development.")
        
        # Specific recommendations based on test results
        if "Display Functionality" in self.test_results and self.test_results["Display Functionality"] == TestResult.FAIL:
            recommendations.append("Check display connections and power supply voltage.")
            
        if "Touch Functionality" in self.test_results and self.test_results["Touch Functionality"] == TestResult.FAIL:
            recommendations.append("Verify touch controller I2C connections and interrupt pin.")
            
        if "BLE Functionality" in self.test_results and self.test_results["BLE Functionality"] == TestResult.FAIL:
            recommendations.append("Check BLE stack configuration and antenna connections.")
            
        return recommendations
    
    def print_summary(self):
        """Print test summary to console"""
        self.log_message("\\n" + "="*60, "INFO", Colors.CYAN)
        self.log_message("📊 HARDWARE VALIDATION SUMMARY", "INFO", Colors.CYAN + Colors.BOLD)
        self.log_message("="*60, "INFO", Colors.CYAN)
        
        report = self.generate_report()
        summary = report["test_summary"]
        
        self.log_message(f"Total Tests: {summary['total_tests']}", "INFO", Colors.WHITE)
        self.log_message(f"Passed: {summary['passed']}", "PASS", Colors.GREEN)
        self.log_message(f"Warnings: {summary['warnings']}", "WARN", Colors.YELLOW)
        self.log_message(f"Failed: {summary['failed']}", "FAIL", Colors.RED)
        self.log_message(f"Success Rate: {summary['success_rate']:.1f}%", "INFO", Colors.CYAN)
        self.log_message(f"Duration: {report['duration_seconds']:.1f} seconds", "INFO", Colors.WHITE)
        
        self.log_message("\\n📋 Detailed Results:", "INFO", Colors.CYAN)
        for test_name, result in self.test_results.items():
            if result == TestResult.PASS:
                self.log_success(f"{test_name}: {result.value}")
            elif result == TestResult.WARN:
                self.log_warning(f"{test_name}: {result.value}")
            else:
                self.log_error(f"{test_name}: {result.value}")
        
        self.log_message("\\n💡 Recommendations:", "INFO", Colors.CYAN)
        for recommendation in report["recommendations"]:
            self.log_message(f"  {recommendation}", "INFO", Colors.WHITE)


def main():
    """Main function for command-line execution"""
    parser = argparse.ArgumentParser(
        description="ESP32-S3 ADHD SmartWatch Hardware Validation Tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python hardware_validation.py COM3
  python hardware_validation.py /dev/ttyUSB0 --baudrate 921600
  python hardware_validation.py COM3 --report validation_report.json
        """
    )
    
    parser.add_argument("port", help="Serial port for ESP32-S3 communication")
    parser.add_argument("--baudrate", type=int, default=115200, help="Serial baudrate (default: 115200)")
    parser.add_argument("--timeout", type=int, default=10, help="Communication timeout in seconds (default: 10)")
    parser.add_argument("--report", help="Save detailed report to JSON file")
    parser.add_argument("--verbose", action="store_true", help="Enable verbose logging")
    
    args = parser.parse_args()
    
    # Create validator instance
    validator = HardwareValidator(
        port=args.port,
        baudrate=args.baudrate,
        timeout=args.timeout
    )
    
    try:
        # Run validation tests
        results = validator.run_all_tests()
        
        # Print summary
        validator.print_summary()
        
        # Save report if requested
        if args.report:
            report = validator.generate_report()
            with open(args.report, 'w') as f:
                json.dump(report, f, indent=2)
            validator.log_success(f"Detailed report saved to {args.report}")
        
        # Exit with appropriate code
        fail_count = sum(1 for result in results.values() if result == TestResult.FAIL)
        sys.exit(0 if fail_count == 0 else 1)
        
    except KeyboardInterrupt:
        validator.log_warning("\\nValidation interrupted by user")
        sys.exit(1)
    except Exception as e:
        validator.log_error(f"Validation failed with unexpected error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()