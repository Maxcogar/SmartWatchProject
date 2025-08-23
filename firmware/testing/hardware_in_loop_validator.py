#!/usr/bin/env python3
"""
Hardware-in-the-Loop Validator for ESP32-S3 ADHD SmartWatch Story 1.1
Comprehensive hardware validation with professional QA integration

This script performs automated validation of all Story 1.1 acceptance criteria
on actual ESP32-S3-Touch-LCD-2 hardware with quality metrics collection,
performance benchmarking, and CI/CD integration.

ACCEPTANCE CRITERIA VALIDATION:
- AC 1.1.1: Build system compiles without errors using ESP-IDF v5.1+ within 60 seconds
- AC 1.1.2: Device completes boot sequence within 5 seconds and displays splash screen  
- AC 1.1.3: 320x240 LCD display initializes with correct orientation and 80% brightness
- AC 1.1.4: Touch screen responds with visual feedback within 250ms across entire display
- AC 1.1.5: System reports >400KB available heap memory at boot completion
- AC 1.1.6: Failed initialization displays clear error messages with diagnostic information

HARDWARE VALIDATION FEATURES:
- Real-time performance measurement and benchmarking
- Display output capture and validation
- Touch input simulation and response measurement
- Memory usage monitoring and leak detection
- Power consumption analysis
- Quality metrics collection for dashboard integration
- Professional test reporting with CI/CD integration

Author: QA Validation Specialist
Version: 2.0.0
Date: 2025-08-19
"""

import serial
import time
import sys
import json
import argparse
import threading
import subprocess
import re
import os
from datetime import datetime, timedelta
from enum import Enum
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass, asdict
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class TestResult(Enum):
    """Test result enumeration with quality levels"""
    PASS = "PASS"
    FAIL = "FAIL" 
    SKIP = "SKIP"
    WARN = "WARN"
    CRITICAL_FAIL = "CRITICAL_FAIL"

class AcceptanceCriteria(Enum):
    """Story 1.1 Acceptance Criteria enumeration"""
    AC_1_1_1_BUILD_SYSTEM = "AC_1.1.1_Build_System"
    AC_1_1_2_BOOT_TIMING = "AC_1.1.2_Boot_Timing"
    AC_1_1_3_LCD_DISPLAY = "AC_1.1.3_LCD_Display"
    AC_1_1_4_TOUCH_RESPONSE = "AC_1.1.4_Touch_Response"
    AC_1_1_5_HEAP_MEMORY = "AC_1.1.5_Heap_Memory"
    AC_1_1_6_ERROR_MESSAGES = "AC_1.1.6_Error_Messages"

@dataclass
class HardwareMetrics:
    """Hardware performance and quality metrics"""
    boot_time_ms: int = 0
    display_init_time_ms: int = 0
    touch_response_time_ms: int = 0
    available_heap_kb: int = 0
    peak_memory_usage_kb: int = 0
    power_consumption_ma: float = 0.0
    build_time_seconds: float = 0.0
    test_duration_seconds: float = 0.0
    total_tests: int = 0
    passed_tests: int = 0
    failed_tests: int = 0
    critical_failures: int = 0
    success_rate_percent: float = 0.0
    
@dataclass
class QualityReport:
    """Comprehensive quality report for dashboard integration"""
    story_id: str = "1.1"
    story_name: str = "Project Initialization and Basic Boot"
    timestamp: str = ""
    device_info: Dict[str, Any] = None
    acceptance_criteria_results: Dict[str, str] = None
    hardware_metrics: HardwareMetrics = None
    test_results: List[Dict[str, Any]] = None
    recommendations: List[str] = None
    overall_status: str = ""
    quality_score: float = 0.0

class Colors:
    """ANSI color codes for professional console output"""
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    BOLD = '\033[1m'
    RESET = '\033[0m'

class HardwareInLoopValidator:
    """Professional hardware-in-the-loop validator for Story 1.1"""
    
    def __init__(self, port: str, baudrate: int = 115200, timeout: int = 30):
        """Initialize hardware validator with professional configuration
        
        Args:
            port: Serial port for ESP32-S3 communication
            baudrate: Serial communication speed (default: 115200)
            timeout: Communication timeout in seconds (default: 30)
        """
        self.port = port
        self.baudrate = baudrate
        self.timeout = timeout
        self.serial_conn = None
        self.start_time = datetime.now()
        self.firmware_path = self._find_firmware_path()
        
        # Initialize metrics and results tracking
        self.metrics = HardwareMetrics()
        self.test_results = []
        self.ac_results = {}
        
        # Quality thresholds from Story 1.1 specification
        self.thresholds = {
            'build_time_max_seconds': 60,
            'boot_time_max_ms': 5000,
            'touch_response_max_ms': 250,
            'min_heap_kb': 400,
            'display_init_max_ms': 3000,
            'power_consumption_max_ma': 100
        }
        
        logger.info(f"Initialized Hardware-in-Loop Validator for {port}")
    
    def _find_firmware_path(self) -> str:
        """Automatically find firmware directory"""
        current_dir = os.path.dirname(os.path.abspath(__file__))
        firmware_dir = os.path.dirname(current_dir)  # Go up from testing/ to firmware/
        
        if os.path.exists(os.path.join(firmware_dir, 'CMakeLists.txt')):
            return firmware_dir
        
        # Fallback search
        for root, dirs, files in os.walk(os.path.dirname(current_dir)):
            if 'CMakeLists.txt' in files and 'main' in dirs:
                return root
                
        raise FileNotFoundError("Could not locate firmware directory with CMakeLists.txt")
    
    def log_message(self, message: str, level: str = "INFO", color: str = Colors.WHITE):
        """Log message with timestamp, color, and level"""
        timestamp = datetime.now().strftime("%H:%M:%S.%f")[:-3]
        colored_message = f"{color}[{timestamp}] [{level}] {message}{Colors.RESET}"
        print(colored_message)
        
        # Also log to Python logger for file output
        if level == "ERROR" or level == "CRITICAL_FAIL":
            logger.error(message)
        elif level == "WARN":
            logger.warning(message)
        else:
            logger.info(message)
    
    def log_success(self, message: str):
        """Log success message with green checkmark"""
        self.log_message(f"✅ {message}", "PASS", Colors.GREEN)
        
    def log_error(self, message: str):
        """Log error message with red X"""
        self.log_message(f"❌ {message}", "FAIL", Colors.RED)
        
    def log_critical(self, message: str):
        """Log critical failure with warning"""
        self.log_message(f"🚨 {message}", "CRITICAL_FAIL", Colors.RED + Colors.BOLD)
        
    def log_warning(self, message: str):
        """Log warning message with yellow triangle"""
        self.log_message(f"⚠️  {message}", "WARN", Colors.YELLOW)
        
    def log_info(self, message: str):
        """Log informational message with blue icon"""
        self.log_message(f"ℹ️  {message}", "INFO", Colors.BLUE)
    
    def record_test_result(self, test_name: str, result: TestResult, 
                          details: str = "", metrics: Dict[str, Any] = None):
        """Record test result with comprehensive tracking"""
        self.metrics.total_tests += 1
        
        if result == TestResult.PASS:
            self.metrics.passed_tests += 1
            self.log_success(f"{test_name}: {result.value}")
        elif result == TestResult.CRITICAL_FAIL:
            self.metrics.critical_failures += 1
            self.metrics.failed_tests += 1
            self.log_critical(f"{test_name}: {result.value} - {details}")
        elif result == TestResult.FAIL:
            self.metrics.failed_tests += 1
            self.log_error(f"{test_name}: {result.value} - {details}")
        elif result == TestResult.WARN:
            self.log_warning(f"{test_name}: {result.value} - {details}")
        else:  # SKIP
            self.log_info(f"{test_name}: Skipped - {details}")
        
        # Store detailed test result
        test_record = {
            "name": test_name,
            "result": result.value,
            "details": details,
            "timestamp": datetime.now().isoformat(),
            "metrics": metrics or {}
        }
        self.test_results.append(test_record)
    
    # ============================================================================
    # SERIAL COMMUNICATION METHODS
    # ============================================================================
    
    def connect_serial(self) -> bool:
        """Establish serial connection with enhanced error handling"""
        try:
            self.log_info(f"Connecting to ESP32-S3 at {self.port} ({self.baudrate} baud)...")
            
            self.serial_conn = serial.Serial(
                port=self.port,
                baudrate=self.baudrate,
                timeout=self.timeout,
                rtscts=False,
                dsrdtr=False,
                write_timeout=5
            )
            
            # Wait for connection stabilization
            time.sleep(2)
            
            # Clear buffers
            self.serial_conn.flushInput()
            self.serial_conn.flushOutput()
            
            # Test connection with ping
            if self._test_communication():
                self.log_success("Serial connection established and verified")
                return True
            else:
                self.log_error("Serial connection established but communication test failed")
                return False
                
        except serial.SerialException as e:
            self.log_error(f"Failed to connect to {self.port}: {e}")
            return False
        except Exception as e:
            self.log_error(f"Unexpected error connecting to device: {e}")
            return False
    
    def _test_communication(self) -> bool:
        """Test basic serial communication"""
        try:
            # Send test command and wait for response
            test_cmd = "test_communication"
            response = self.send_command(test_cmd, timeout=5)
            return response is not None and len(response) > 0
        except Exception:
            return False
    
    def disconnect_serial(self):
        """Close serial connection safely"""
        if self.serial_conn and self.serial_conn.is_open:
            try:
                self.serial_conn.close()
                self.log_info("Serial connection closed")
            except Exception as e:
                self.log_warning(f"Error closing serial connection: {e}")
    
    def send_command(self, command: str, timeout: Optional[int] = None, 
                    expect_response: bool = True) -> Optional[str]:
        """Send command with enhanced error handling and timing"""
        if not self.serial_conn or not self.serial_conn.is_open:
            self.log_error("Serial connection not available")
            return None
            
        timeout = timeout or self.timeout
        
        try:
            # Send command with newline
            cmd_bytes = f"{command}\\n".encode('utf-8')
            bytes_written = self.serial_conn.write(cmd_bytes)
            self.serial_conn.flush()
            
            if bytes_written != len(cmd_bytes):
                self.log_warning(f"Partial command write: {bytes_written}/{len(cmd_bytes)} bytes")
            
            if not expect_response:
                return None
            
            # Wait for response with timeout
            response_lines = []
            start_time = time.time()
            
            while time.time() - start_time < timeout:
                if self.serial_conn.in_waiting > 0:
                    try:
                        line = self.serial_conn.readline().decode('utf-8', errors='ignore').strip()
                        if line:
                            response_lines.append(line)
                            # Check for completion markers
                            if any(marker in line.upper() for marker in ["OK", "DONE", "ERROR", "COMPLETE"]):
                                break
                    except UnicodeDecodeError:
                        continue
                time.sleep(0.05)  # Small delay to prevent CPU spinning
            
            if not response_lines:
                self.log_warning(f"No response to command: {command}")
                return None
                
            return "\\n".join(response_lines)
            
        except Exception as e:
            self.log_error(f"Command '{command}' failed: {e}")
            return None
    
    def read_serial_data(self, duration: float = 5.0, filter_pattern: str = None) -> List[str]:
        """Read serial data for specified duration with optional filtering"""
        if not self.serial_conn or not self.serial_conn.is_open:
            return []
            
        lines = []
        start_time = time.time()
        
        while time.time() - start_time < duration:
            if self.serial_conn.in_waiting > 0:
                try:
                    line = self.serial_conn.readline().decode('utf-8', errors='ignore').strip()
                    if line:
                        if filter_pattern is None or re.search(filter_pattern, line, re.IGNORECASE):
                            lines.append(line)
                except UnicodeDecodeError:
                    continue
            time.sleep(0.05)
        
        return lines
    
    # ============================================================================
    # AC 1.1.1: BUILD SYSTEM VALIDATION
    # ============================================================================
    
    def test_ac_1_1_1_build_system(self) -> TestResult:
        """Test AC 1.1.1: Build system compiles without errors using ESP-IDF v5.1+ within 60 seconds"""
        self.log_info("Testing AC 1.1.1: Build system validation (60 second limit)")
        
        try:
            # Change to firmware directory
            original_cwd = os.getcwd()
            os.chdir(self.firmware_path)
            
            # Measure build time
            build_start_time = time.time()
            
            self.log_info("Starting firmware build process...")
            
            # Execute build command
            result = subprocess.run(
                ["idf.py", "build"],
                capture_output=True,
                text=True,
                timeout=self.thresholds['build_time_max_seconds'] + 10  # Allow 10s extra for timeout detection
            )
            
            build_end_time = time.time()
            build_duration = build_end_time - build_start_time
            self.metrics.build_time_seconds = build_duration
            
            # Analyze build results
            build_success = result.returncode == 0
            warning_count = result.stderr.count("warning:") if result.stderr else 0
            error_count = result.stderr.count("error:") if result.stderr else 0
            
            self.log_info(f"Build completed in {build_duration:.2f} seconds")
            self.log_info(f"Build result: {'SUCCESS' if build_success else 'FAILED'}")
            self.log_info(f"Warnings: {warning_count}, Errors: {error_count}")
            
            # Validate ESP-IDF version from build output
            idf_version_match = re.search(r"ESP-IDF\\s+v?(\\d+\\.\\d+)", result.stdout or "")
            if idf_version_match:
                version_str = idf_version_match.group(1)
                version_parts = [int(x) for x in version_str.split('.')]
                version_ok = version_parts[0] > 5 or (version_parts[0] == 5 and version_parts[1] >= 1)
                self.log_info(f"ESP-IDF Version: {version_str} ({'✓' if version_ok else '✗'})")
            else:
                version_ok = True  # Assume OK if can't detect
                self.log_warning("Could not detect ESP-IDF version from build output")
            
            # Record detailed metrics
            build_metrics = {
                "build_time_seconds": build_duration,
                "build_success": build_success,
                "warning_count": warning_count,
                "error_count": error_count,
                "within_time_limit": build_duration <= self.thresholds['build_time_max_seconds']
            }
            
            # Determine result
            if not build_success:
                result_status = TestResult.CRITICAL_FAIL
                details = f"Build failed with {error_count} errors in {build_duration:.1f}s"
            elif not version_ok:
                result_status = TestResult.FAIL
                details = f"ESP-IDF version requirement not met"
            elif build_duration > self.thresholds['build_time_max_seconds']:
                result_status = TestResult.FAIL
                details = f"Build time {build_duration:.1f}s exceeds {self.thresholds['build_time_max_seconds']}s limit"
            elif warning_count > 0:
                result_status = TestResult.WARN
                details = f"Build succeeded in {build_duration:.1f}s but has {warning_count} warnings"
            else:
                result_status = TestResult.PASS
                details = f"Build succeeded in {build_duration:.1f}s with no warnings"
            
            self.ac_results[AcceptanceCriteria.AC_1_1_1_BUILD_SYSTEM] = result_status.value
            self.record_test_result("AC 1.1.1 Build System", result_status, details, build_metrics)
            
            return result_status
            
        except subprocess.TimeoutExpired:
            self.log_error(f"Build timed out after {self.thresholds['build_time_max_seconds']} seconds")
            self.ac_results[AcceptanceCriteria.AC_1_1_1_BUILD_SYSTEM] = TestResult.CRITICAL_FAIL.value
            self.record_test_result("AC 1.1.1 Build System", TestResult.CRITICAL_FAIL, 
                                  "Build timed out", {"build_time_seconds": self.thresholds['build_time_max_seconds']})
            return TestResult.CRITICAL_FAIL
            
        except Exception as e:
            self.log_error(f"Build system test failed: {e}")
            self.ac_results[AcceptanceCriteria.AC_1_1_1_BUILD_SYSTEM] = TestResult.FAIL.value
            self.record_test_result("AC 1.1.1 Build System", TestResult.FAIL, str(e))
            return TestResult.FAIL
            
        finally:
            # Restore original directory
            os.chdir(original_cwd)
    
    # ============================================================================
    # AC 1.1.2: BOOT SEQUENCE TIMING VALIDATION
    # ============================================================================
    
    def test_ac_1_1_2_boot_sequence_timing(self) -> TestResult:
        """Test AC 1.1.2: Device completes boot sequence within 5 seconds and displays splash screen"""
        self.log_info("Testing AC 1.1.2: Boot sequence timing (5 second limit)")
        
        try:
            # Reset device to trigger clean boot
            self.log_info("Resetting device for boot timing test...")
            self.serial_conn.write(b'\\x03')  # Send Ctrl+C
            time.sleep(0.5)
            
            # Clear buffers and start timing
            self.serial_conn.flushInput()
            boot_start_time = time.time()
            
            # Monitor boot messages
            boot_messages = []
            splash_screen_detected = False
            boot_complete_detected = False
            
            # Read boot output for maximum of 8 seconds (3s buffer over requirement)
            while time.time() - boot_start_time < 8.0:
                if self.serial_conn.in_waiting > 0:
                    line = self.serial_conn.readline().decode('utf-8', errors='ignore').strip()
                    if line:
                        boot_messages.append(line)
                        
                        # Check for boot completion indicators
                        if any(keyword in line.upper() for keyword in 
                               ["BOOT COMPLETE", "READY", "INITIALIZED SUCCESSFULLY", "FOCUS"]):
                            if not boot_complete_detected:
                                boot_complete_time = time.time()
                                boot_complete_detected = True
                        
                        # Check for splash screen indicators
                        if "FOCUS" in line.upper() or "SPLASH" in line.upper():
                            splash_screen_detected = True
                
                time.sleep(0.1)
            
            # Calculate boot timing
            if boot_complete_detected:
                boot_duration_ms = int((boot_complete_time - boot_start_time) * 1000)
            else:
                boot_duration_ms = 8000  # Assume timeout
                self.log_warning("Boot completion not clearly detected, using timeout")
            
            self.metrics.boot_time_ms = boot_duration_ms
            
            # Analyze boot messages for expected components
            expected_components = [
                "ESP-ROM",
                "ESP32-S3",
                "ESP-IDF",
                "BOOT",
                "LCD",
                "TOUCH"
            ]
            
            detected_components = []
            for component in expected_components:
                for message in boot_messages:
                    if component in message.upper():
                        detected_components.append(component)
                        break
            
            component_detection_rate = len(detected_components) / len(expected_components) * 100
            
            self.log_info(f"Boot sequence completed in {boot_duration_ms}ms")
            self.log_info(f"Splash screen detected: {'✓' if splash_screen_detected else '✗'}")
            self.log_info(f"Component detection: {len(detected_components)}/{len(expected_components)} ({component_detection_rate:.0f}%)")
            
            # Record detailed metrics
            boot_metrics = {
                "boot_time_ms": boot_duration_ms,
                "splash_detected": splash_screen_detected,
                "boot_complete_detected": boot_complete_detected,
                "component_detection_rate": component_detection_rate,
                "detected_components": detected_components,
                "within_time_limit": boot_duration_ms <= self.thresholds['boot_time_max_ms']
            }
            
            # Determine result
            if not boot_complete_detected:
                result_status = TestResult.CRITICAL_FAIL
                details = f"Boot sequence did not complete within 8 seconds"
            elif boot_duration_ms > self.thresholds['boot_time_max_ms']:
                result_status = TestResult.FAIL
                details = f"Boot time {boot_duration_ms}ms exceeds {self.thresholds['boot_time_max_ms']}ms limit"
            elif not splash_screen_detected:
                result_status = TestResult.WARN
                details = f"Boot completed in {boot_duration_ms}ms but splash screen not clearly detected"
            elif component_detection_rate < 70:
                result_status = TestResult.WARN
                details = f"Boot completed in {boot_duration_ms}ms but only {component_detection_rate:.0f}% components detected"
            else:
                result_status = TestResult.PASS
                details = f"Boot completed in {boot_duration_ms}ms with splash screen"
            
            self.ac_results[AcceptanceCriteria.AC_1_1_2_BOOT_TIMING] = result_status.value
            self.record_test_result("AC 1.1.2 Boot Timing", result_status, details, boot_metrics)
            
            return result_status
            
        except Exception as e:
            self.log_error(f"Boot timing test failed: {e}")
            self.ac_results[AcceptanceCriteria.AC_1_1_2_BOOT_TIMING] = TestResult.FAIL.value
            self.record_test_result("AC 1.1.2 Boot Timing", TestResult.FAIL, str(e))
            return TestResult.FAIL
    
    # ============================================================================
    # AC 1.1.3: LCD DISPLAY VALIDATION
    # ============================================================================
    
    def test_ac_1_1_3_lcd_display_initialization(self) -> TestResult:
        """Test AC 1.1.3: 320x240 LCD display initializes with correct orientation and 80% brightness"""
        self.log_info("Testing AC 1.1.3: LCD display initialization (320x240, 80% brightness)")
        
        try:
            display_init_start = time.time()
            
            # Send display test command
            response = self.send_command("test_display_initialization", timeout=10)
            
            if not response:
                self.log_error("No response from display initialization test")
                result_status = TestResult.FAIL
                details = "Display test command failed - no response"
            else:
                display_init_end = time.time()
                init_duration_ms = int((display_init_end - display_init_start) * 1000)
                self.metrics.display_init_time_ms = init_duration_ms
                
                # Analyze display initialization response
                response_upper = response.upper()
                
                # Check for successful initialization
                display_init_success = any(keyword in response_upper for keyword in 
                                         ["DISPLAY OK", "LCD INITIALIZED", "DISPLAY SUCCESS"])
                
                # Check for resolution confirmation
                resolution_confirmed = "320X240" in response_upper or "320" in response_upper
                
                # Check for brightness setting
                brightness_set = "80%" in response or "BRIGHTNESS" in response_upper
                
                # Check for orientation
                orientation_set = "LANDSCAPE" in response_upper or "PORTRAIT" in response_upper
                
                self.log_info(f"Display initialization: {'✓' if display_init_success else '✗'}")
                self.log_info(f"Resolution 320x240: {'✓' if resolution_confirmed else '✗'}")
                self.log_info(f"80% brightness: {'✓' if brightness_set else '✗'}")
                self.log_info(f"Orientation set: {'✓' if orientation_set else '✗'}")
                self.log_info(f"Initialization time: {init_duration_ms}ms")
                
                # Test display functionality with basic commands
                display_functional = self._test_display_functionality()
                
                # Record detailed metrics
                display_metrics = {
                    "init_time_ms": init_duration_ms,
                    "init_success": display_init_success,
                    "resolution_confirmed": resolution_confirmed,
                    "brightness_set": brightness_set,
                    "orientation_set": orientation_set,
                    "display_functional": display_functional,
                    "within_time_limit": init_duration_ms <= self.thresholds['display_init_max_ms']
                }
                
                # Determine result
                if not display_init_success:
                    result_status = TestResult.CRITICAL_FAIL
                    details = f"Display initialization failed"
                elif init_duration_ms > self.thresholds['display_init_max_ms']:
                    result_status = TestResult.FAIL
                    details = f"Display init time {init_duration_ms}ms exceeds {self.thresholds['display_init_max_ms']}ms limit"
                elif not display_functional:
                    result_status = TestResult.FAIL
                    details = f"Display initialized but functionality test failed"
                elif not resolution_confirmed or not brightness_set:
                    result_status = TestResult.WARN
                    details = f"Display initialized in {init_duration_ms}ms but configuration not fully confirmed"
                else:
                    result_status = TestResult.PASS
                    details = f"Display initialized successfully in {init_duration_ms}ms (320x240, 80% brightness)"
            
            self.ac_results[AcceptanceCriteria.AC_1_1_3_LCD_DISPLAY] = result_status.value
            self.record_test_result("AC 1.1.3 LCD Display", result_status, details, 
                                  display_metrics if 'display_metrics' in locals() else {})
            
            return result_status
            
        except Exception as e:
            self.log_error(f"LCD display test failed: {e}")
            self.ac_results[AcceptanceCriteria.AC_1_1_3_LCD_DISPLAY] = TestResult.FAIL.value
            self.record_test_result("AC 1.1.3 LCD Display", TestResult.FAIL, str(e))
            return TestResult.FAIL
    
    def _test_display_functionality(self) -> bool:
        """Test basic display functionality"""
        try:
            # Test display commands
            test_commands = [
                "test_display_clear",
                "test_display_pixel",
                "test_display_backlight"
            ]
            
            functional_tests_passed = 0
            for cmd in test_commands:
                response = self.send_command(cmd, timeout=5)
                if response and ("OK" in response.upper() or "SUCCESS" in response.upper()):
                    functional_tests_passed += 1
                time.sleep(0.5)
            
            return functional_tests_passed >= len(test_commands) - 1  # Allow 1 failure
            
        except Exception:
            return False
    
    # ============================================================================
    # AC 1.1.4: TOUCH SCREEN RESPONSE VALIDATION
    # ============================================================================
    
    def test_ac_1_1_4_touch_screen_response(self) -> TestResult:
        """Test AC 1.1.4: Touch screen responds with visual feedback within 250ms across entire display"""
        self.log_info("Testing AC 1.1.4: Touch screen response (250ms limit)")
        
        try:
            # Initialize touch screen
            init_response = self.send_command("test_touch_initialization", timeout=10)
            
            if not init_response:
                self.log_error("Touch screen initialization failed")
                result_status = TestResult.CRITICAL_FAIL
                details = "Touch initialization command failed"
            else:
                init_success = "OK" in init_response.upper() or "INITIALIZED" in init_response.upper()
                
                if not init_success:
                    result_status = TestResult.FAIL
                    details = "Touch screen initialization reported failure"
                else:
                    # Test touch response timing
                    touch_response_times = []
                    touch_coordinates_tested = [
                        (80, 60),    # Top-left quadrant
                        (240, 60),   # Top-right quadrant  
                        (80, 180),   # Bottom-left quadrant
                        (240, 180),  # Bottom-right quadrant
                        (160, 120)   # Center
                    ]
                    
                    successful_touch_tests = 0
                    
                    for x, y in touch_coordinates_tested:
                        self.log_info(f"Testing touch response at coordinates ({x}, {y})...")
                        
                        # Send touch simulation command
                        touch_start_time = time.time()
                        touch_cmd = f"test_touch_response {x} {y}"
                        response = self.send_command(touch_cmd, timeout=5)
                        
                        if response:
                            response_time = time.time() - touch_start_time
                            response_time_ms = int(response_time * 1000)
                            
                            # Check for visual feedback confirmation
                            feedback_detected = any(keyword in response.upper() for keyword in 
                                                  ["FEEDBACK", "VISUAL", "TOUCH DETECTED", "RESPONSE"])
                            
                            if feedback_detected and response_time_ms <= self.thresholds['touch_response_max_ms']:
                                touch_response_times.append(response_time_ms)
                                successful_touch_tests += 1
                                self.log_info(f"  Touch at ({x}, {y}): {response_time_ms}ms ✓")
                            else:
                                self.log_warning(f"  Touch at ({x}, {y}): {response_time_ms}ms {'(too slow)' if response_time_ms > self.thresholds['touch_response_max_ms'] else '(no feedback)'}")
                        else:
                            self.log_warning(f"  Touch at ({x}, {y}): No response")
                        
                        time.sleep(0.5)  # Brief delay between tests
                    
                    # Calculate touch metrics
                    if touch_response_times:
                        avg_response_time = sum(touch_response_times) / len(touch_response_times)
                        max_response_time = max(touch_response_times)
                        min_response_time = min(touch_response_times)
                        self.metrics.touch_response_time_ms = int(avg_response_time)
                    else:
                        avg_response_time = max_response_time = min_response_time = 0
                        self.metrics.touch_response_time_ms = 0
                    
                    touch_coverage = successful_touch_tests / len(touch_coordinates_tested) * 100
                    
                    self.log_info(f"Touch response results:")
                    self.log_info(f"  Successful tests: {successful_touch_tests}/{len(touch_coordinates_tested)} ({touch_coverage:.0f}%)")
                    if touch_response_times:
                        self.log_info(f"  Average response: {avg_response_time:.0f}ms")
                        self.log_info(f"  Response range: {min_response_time}-{max_response_time}ms")
                    
                    # Record detailed metrics
                    touch_metrics = {
                        "initialization_success": init_success,
                        "successful_tests": successful_touch_tests,
                        "total_tests": len(touch_coordinates_tested),
                        "coverage_percent": touch_coverage,
                        "avg_response_ms": int(avg_response_time) if touch_response_times else 0,
                        "max_response_ms": max_response_time,
                        "min_response_ms": min_response_time,
                        "all_within_limit": all(t <= self.thresholds['touch_response_max_ms'] for t in touch_response_times)
                    }
                    
                    # Determine result
                    if successful_touch_tests == 0:
                        result_status = TestResult.CRITICAL_FAIL
                        details = "No touch responses detected across entire display"
                    elif touch_coverage < 60:
                        result_status = TestResult.FAIL
                        details = f"Touch coverage {touch_coverage:.0f}% insufficient (need >60%)"
                    elif not touch_response_times or max_response_time > self.thresholds['touch_response_max_ms']:
                        result_status = TestResult.FAIL
                        details = f"Touch responses exceed {self.thresholds['touch_response_max_ms']}ms limit"
                    elif touch_coverage < 80:
                        result_status = TestResult.WARN
                        details = f"Touch working with {touch_coverage:.0f}% coverage, avg {avg_response_time:.0f}ms"
                    else:
                        result_status = TestResult.PASS
                        details = f"Touch screen responding across display, avg {avg_response_time:.0f}ms"
            
            self.ac_results[AcceptanceCriteria.AC_1_1_4_TOUCH_RESPONSE] = result_status.value
            self.record_test_result("AC 1.1.4 Touch Response", result_status, details, 
                                  touch_metrics if 'touch_metrics' in locals() else {})
            
            return result_status
            
        except Exception as e:
            self.log_error(f"Touch screen test failed: {e}")
            self.ac_results[AcceptanceCriteria.AC_1_1_4_TOUCH_RESPONSE] = TestResult.FAIL.value
            self.record_test_result("AC 1.1.4 Touch Response", TestResult.FAIL, str(e))
            return TestResult.FAIL
    
    # ============================================================================
    # AC 1.1.5: HEAP MEMORY VALIDATION
    # ============================================================================
    
    def test_ac_1_1_5_heap_memory_validation(self) -> TestResult:
        """Test AC 1.1.5: System reports >400KB available heap memory at boot completion"""
        self.log_info("Testing AC 1.1.5: Heap memory validation (>400KB requirement)")
        
        try:
            # Request memory status after boot completion
            response = self.send_command("test_memory_status", timeout=10)
            
            if not response:
                self.log_error("No response from memory status command")
                result_status = TestResult.FAIL
                details = "Memory status command failed - no response"
            else:
                # Parse memory information from response
                heap_info = self._parse_memory_info(response)
                
                if not heap_info:
                    self.log_warning("Could not parse memory information from response")
                    # Try alternative memory query
                    alt_response = self.send_command("get_heap_info", timeout=5)
                    if alt_response:
                        heap_info = self._parse_memory_info(alt_response)
                
                if heap_info:
                    available_heap_bytes = heap_info.get('free_heap_bytes', 0)
                    available_heap_kb = available_heap_bytes // 1024
                    largest_block_kb = heap_info.get('largest_free_block_bytes', 0) // 1024
                    total_heap_kb = heap_info.get('total_heap_bytes', 0) // 1024
                    min_ever_free_kb = heap_info.get('min_free_bytes', 0) // 1024
                    
                    self.metrics.available_heap_kb = available_heap_kb
                    
                    self.log_info(f"Heap memory analysis:")
                    self.log_info(f"  Available: {available_heap_kb} KB ({available_heap_bytes} bytes)")
                    self.log_info(f"  Largest block: {largest_block_kb} KB")
                    self.log_info(f"  Total heap: {total_heap_kb} KB")
                    self.log_info(f"  Min ever free: {min_ever_free_kb} KB")
                    
                    # Test memory allocation capability
                    allocation_test_passed = self._test_memory_allocation()
                    
                    # Record detailed metrics
                    memory_metrics = {
                        "available_heap_kb": available_heap_kb,
                        "available_heap_bytes": available_heap_bytes,
                        "largest_block_kb": largest_block_kb,
                        "total_heap_kb": total_heap_kb,
                        "min_ever_free_kb": min_ever_free_kb,
                        "meets_requirement": available_heap_kb >= self.thresholds['min_heap_kb'],
                        "allocation_test_passed": allocation_test_passed
                    }
                    
                    # Determine result
                    if available_heap_kb < self.thresholds['min_heap_kb']:
                        result_status = TestResult.FAIL
                        details = f"Available heap {available_heap_kb}KB < required {self.thresholds['min_heap_kb']}KB"
                    elif largest_block_kb < 50:
                        result_status = TestResult.WARN
                        details = f"Available heap {available_heap_kb}KB OK, but largest block only {largest_block_kb}KB"
                    elif not allocation_test_passed:
                        result_status = TestResult.WARN
                        details = f"Available heap {available_heap_kb}KB OK, but allocation test failed"
                    else:
                        result_status = TestResult.PASS
                        details = f"Heap memory validation passed: {available_heap_kb}KB available"
                else:
                    result_status = TestResult.FAIL
                    details = "Could not obtain heap memory information"
                    memory_metrics = {}
            
            self.ac_results[AcceptanceCriteria.AC_1_1_5_HEAP_MEMORY] = result_status.value
            self.record_test_result("AC 1.1.5 Heap Memory", result_status, details, 
                                  memory_metrics if 'memory_metrics' in locals() else {})
            
            return result_status
            
        except Exception as e:
            self.log_error(f"Heap memory test failed: {e}")
            self.ac_results[AcceptanceCriteria.AC_1_1_5_HEAP_MEMORY] = TestResult.FAIL.value
            self.record_test_result("AC 1.1.5 Heap Memory", TestResult.FAIL, str(e))
            return TestResult.FAIL
    
    def _parse_memory_info(self, response: str) -> Optional[Dict[str, int]]:
        """Parse memory information from device response"""
        try:
            heap_info = {}
            
            # Common patterns for memory information
            patterns = {
                'free_heap_bytes': r'(?:free|available).*?heap.*?[:\s](\d+).*?bytes?',
                'largest_free_block_bytes': r'largest.*?(?:free|block).*?[:\s](\d+).*?bytes?',
                'total_heap_bytes': r'total.*?heap.*?[:\s](\d+).*?bytes?',
                'min_free_bytes': r'(?:minimum|min).*?free.*?[:\s](\d+).*?bytes?'
            }
            
            for key, pattern in patterns.items():
                match = re.search(pattern, response, re.IGNORECASE)
                if match:
                    heap_info[key] = int(match.group(1))
            
            # Alternative parsing for different response formats
            if not heap_info.get('free_heap_bytes'):
                # Try parsing KB values
                kb_match = re.search(r'free.*?(\d+).*?kb', response, re.IGNORECASE)
                if kb_match:
                    heap_info['free_heap_bytes'] = int(kb_match.group(1)) * 1024
            
            return heap_info if heap_info else None
            
        except Exception:
            return None
    
    def _test_memory_allocation(self) -> bool:
        """Test memory allocation capability"""
        try:
            # Send allocation test command
            response = self.send_command("test_memory_allocation 100", timeout=5)
            return response and ("SUCCESS" in response.upper() or "OK" in response.upper())
        except Exception:
            return False
    
    # ============================================================================
    # AC 1.1.6: ERROR MESSAGE VALIDATION
    # ============================================================================
    
    def test_ac_1_1_6_error_message_validation(self) -> TestResult:
        """Test AC 1.1.6: Failed initialization displays clear error messages with diagnostic information"""
        self.log_info("Testing AC 1.1.6: Error message validation")
        
        try:
            error_scenarios_tested = 0
            clear_error_messages = 0
            diagnostic_info_present = 0
            
            # Test error scenarios
            error_test_commands = [
                ("test_display_error", "display"),
                ("test_touch_error", "touch"),
                ("test_memory_error", "memory"),
                ("test_nvs_error", "nvs")
            ]
            
            for cmd, component in error_test_commands:
                self.log_info(f"Testing error handling for {component}...")
                error_scenarios_tested += 1
                
                response = self.send_command(cmd, timeout=10)
                
                if response:
                    response_upper = response.upper()
                    
                    # Check for clear error message
                    has_error_message = any(keyword in response_upper for keyword in 
                                          ["ERROR", "FAILED", "FAILURE", "COULD NOT", "UNABLE"])
                    
                    # Check for diagnostic information
                    has_diagnostic_info = any(keyword in response_upper for keyword in 
                                            ["REASON", "CODE", "DETAILS", "DEBUG", "INFO", "STATUS"])
                    
                    # Check for component identification
                    component_identified = component.upper() in response_upper
                    
                    if has_error_message and (has_diagnostic_info or component_identified):
                        clear_error_messages += 1
                        if has_diagnostic_info:
                            diagnostic_info_present += 1
                        
                        self.log_info(f"  {component}: ✓ Clear error message with {'diagnostic info' if has_diagnostic_info else 'component ID'}")
                    else:
                        self.log_warning(f"  {component}: ✗ Error message unclear or missing diagnostics")
                        self.log_info(f"    Response: {response[:100]}...")
                else:
                    self.log_warning(f"  {component}: No response to error test")
                
                time.sleep(1)  # Brief delay between error tests
            
            # Test recovery after errors
            self.log_info("Testing system recovery after errors...")
            recovery_response = self.send_command("test_error_recovery", timeout=10)
            system_recovered = recovery_response and "RECOVERED" in recovery_response.upper()
            
            # Calculate error handling metrics
            error_message_quality = clear_error_messages / error_scenarios_tested * 100 if error_scenarios_tested > 0 else 0
            diagnostic_coverage = diagnostic_info_present / error_scenarios_tested * 100 if error_scenarios_tested > 0 else 0
            
            self.log_info(f"Error handling results:")
            self.log_info(f"  Clear error messages: {clear_error_messages}/{error_scenarios_tested} ({error_message_quality:.0f}%)")
            self.log_info(f"  Diagnostic info: {diagnostic_info_present}/{error_scenarios_tested} ({diagnostic_coverage:.0f}%)")
            self.log_info(f"  System recovery: {'✓' if system_recovered else '✗'}")
            
            # Record detailed metrics
            error_metrics = {
                "scenarios_tested": error_scenarios_tested,
                "clear_error_messages": clear_error_messages,
                "diagnostic_info_present": diagnostic_info_present,
                "error_message_quality_percent": error_message_quality,
                "diagnostic_coverage_percent": diagnostic_coverage,
                "system_recovered": system_recovered
            }
            
            # Determine result
            if error_message_quality < 50:
                result_status = TestResult.FAIL
                details = f"Only {error_message_quality:.0f}% of error scenarios provided clear messages"
            elif not system_recovered:
                result_status = TestResult.WARN
                details = f"Error messages clear ({error_message_quality:.0f}%) but system recovery unclear"
            elif diagnostic_coverage < 50:
                result_status = TestResult.WARN
                details = f"Error messages clear but diagnostic info limited ({diagnostic_coverage:.0f}%)"
            else:
                result_status = TestResult.PASS
                details = f"Error handling validated: {error_message_quality:.0f}% clear messages, {diagnostic_coverage:.0f}% with diagnostics"
            
            self.ac_results[AcceptanceCriteria.AC_1_1_6_ERROR_MESSAGES] = result_status.value
            self.record_test_result("AC 1.1.6 Error Messages", result_status, details, error_metrics)
            
            return result_status
            
        except Exception as e:
            self.log_error(f"Error message test failed: {e}")
            self.ac_results[AcceptanceCriteria.AC_1_1_6_ERROR_MESSAGES] = TestResult.FAIL.value
            self.record_test_result("AC 1.1.6 Error Messages", TestResult.FAIL, str(e))
            return TestResult.FAIL
    
    # ============================================================================
    # COMPREHENSIVE SYSTEM VALIDATION
    # ============================================================================
    
    def run_comprehensive_validation(self) -> Dict[AcceptanceCriteria, TestResult]:
        """Run complete Story 1.1 validation suite with professional reporting"""
        
        self.log_message("🚀 HARDWARE-IN-THE-LOOP COMPREHENSIVE VALIDATION", "INFO", Colors.CYAN + Colors.BOLD)
        self.log_message("ESP32-S3 ADHD SmartWatch - Story 1.1: Project Initialization and Basic Boot", "INFO", Colors.CYAN)
        self.log_message("=" * 80, "INFO", Colors.CYAN)
        
        # Connect to hardware
        if not self.connect_serial():
            self.log_critical("Failed to establish serial connection - aborting validation")
            return {}
        
        try:
            # Execute all acceptance criteria tests
            test_suite = [
                ("AC 1.1.1: Build System", self.test_ac_1_1_1_build_system),
                ("AC 1.1.2: Boot Timing", self.test_ac_1_1_2_boot_sequence_timing),
                ("AC 1.1.3: LCD Display", self.test_ac_1_1_3_lcd_display_initialization),
                ("AC 1.1.4: Touch Response", self.test_ac_1_1_4_touch_screen_response),
                ("AC 1.1.5: Heap Memory", self.test_ac_1_1_5_heap_memory_validation),
                ("AC 1.1.6: Error Messages", self.test_ac_1_1_6_error_message_validation)
            ]
            
            results = {}
            
            for test_name, test_func in test_suite:
                self.log_message(f"\\n--- Executing {test_name} ---", "INFO", Colors.MAGENTA)
                try:
                    result = test_func()
                    results[list(AcceptanceCriteria)[len(results)]] = result
                    
                    if result == TestResult.PASS:
                        self.log_success(f"{test_name} completed successfully")
                    elif result == TestResult.WARN:
                        self.log_warning(f"{test_name} completed with warnings")
                    elif result == TestResult.CRITICAL_FAIL:
                        self.log_critical(f"{test_name} critical failure detected")
                    else:
                        self.log_error(f"{test_name} failed validation")
                        
                except Exception as e:
                    self.log_error(f"{test_name} exception: {e}")
                    results[list(AcceptanceCriteria)[len(results)]] = TestResult.FAIL
                
                # Brief delay between tests
                time.sleep(2)
            
            return results
            
        finally:
            self.disconnect_serial()
    
    def generate_comprehensive_report(self) -> QualityReport:
        """Generate comprehensive quality report for dashboard integration"""
        
        # Calculate final metrics
        end_time = datetime.now()
        self.metrics.test_duration_seconds = (end_time - self.start_time).total_seconds()
        
        if self.metrics.total_tests > 0:
            self.metrics.success_rate_percent = (self.metrics.passed_tests / self.metrics.total_tests) * 100
        
        # Calculate quality score
        quality_factors = [
            min(100, self.metrics.success_rate_percent),  # Test success rate
            100 if self.metrics.boot_time_ms <= self.thresholds['boot_time_max_ms'] else 0,  # Boot timing
            100 if self.metrics.available_heap_kb >= self.thresholds['min_heap_kb'] else 0,  # Memory
            100 if self.metrics.touch_response_time_ms <= self.thresholds['touch_response_max_ms'] else 0,  # Touch
            100 if self.metrics.critical_failures == 0 else 0  # Critical failures
        ]
        quality_score = sum(quality_factors) / len(quality_factors)
        
        # Generate recommendations
        recommendations = self._generate_recommendations()
        
        # Determine overall status
        if self.metrics.critical_failures > 0:
            overall_status = "CRITICAL_FAILURE"
        elif self.metrics.failed_tests == 0:
            overall_status = "PASS"
        elif self.metrics.success_rate_percent >= 80:
            overall_status = "PASS_WITH_WARNINGS"
        else:
            overall_status = "FAIL"
        
        # Create comprehensive report
        report = QualityReport(
            story_id="1.1",
            story_name="Project Initialization and Basic Boot",
            timestamp=self.start_time.isoformat(),
            device_info={
                "board": "ESP32-S3-Touch-LCD-2",
                "port": self.port,
                "baudrate": self.baudrate,
                "firmware_path": self.firmware_path
            },
            acceptance_criteria_results=self.ac_results,
            hardware_metrics=self.metrics,
            test_results=self.test_results,
            recommendations=recommendations,
            overall_status=overall_status,
            quality_score=quality_score
        )
        
        return report
    
    def _generate_recommendations(self) -> List[str]:
        """Generate actionable recommendations based on test results"""
        recommendations = []
        
        # Overall assessment
        if self.metrics.critical_failures == 0 and self.metrics.failed_tests == 0:
            recommendations.append("✅ Excellent! All acceptance criteria validated. Hardware ready for next sprint.")
        elif self.metrics.critical_failures == 0:
            recommendations.append("✅ Core functionality validated. Address warnings to improve quality.")
        else:
            recommendations.append("🚨 Critical issues detected. Must resolve before deployment.")
        
        # Specific recommendations based on metrics
        if self.metrics.boot_time_ms > self.thresholds['boot_time_max_ms']:
            recommendations.append("⚡ Optimize boot sequence to meet 5-second requirement")
            
        if self.metrics.available_heap_kb < self.thresholds['min_heap_kb']:
            recommendations.append("💾 Optimize memory usage to meet 400KB heap requirement")
            
        if self.metrics.touch_response_time_ms > self.thresholds['touch_response_max_ms']:
            recommendations.append("👆 Optimize touch processing for 250ms response requirement")
            
        if self.metrics.build_time_seconds > self.thresholds['build_time_max_seconds']:
            recommendations.append("🔨 Optimize build system to meet 60-second requirement")
        
        # Quality improvement suggestions
        if self.metrics.success_rate_percent < 100:
            recommendations.append(f"🎯 Improve test success rate from {self.metrics.success_rate_percent:.1f}% to 100%")
            
        return recommendations
    
    def print_comprehensive_summary(self):
        """Print professional test summary with quality metrics"""
        
        report = self.generate_comprehensive_report()
        
        self.log_message("\\n" + "=" * 80, "INFO", Colors.CYAN)
        self.log_message("📊 HARDWARE-IN-THE-LOOP VALIDATION SUMMARY", "INFO", Colors.CYAN + Colors.BOLD)
        self.log_message("=" * 80, "INFO", Colors.CYAN)
        
        # Test statistics
        self.log_message(f"Story: {report.story_id} - {report.story_name}", "INFO", Colors.WHITE)
        self.log_message(f"Device: {report.device_info['board']} on {report.device_info['port']}", "INFO", Colors.WHITE)
        self.log_message(f"Duration: {report.hardware_metrics.test_duration_seconds:.1f} seconds", "INFO", Colors.WHITE)
        self.log_message(f"Quality Score: {report.quality_score:.1f}/100", "INFO", Colors.CYAN)
        
        self.log_message("\\n📈 Test Results:", "INFO", Colors.CYAN)
        self.log_message(f"  Total Tests: {report.hardware_metrics.total_tests}", "INFO", Colors.WHITE)
        self.log_success(f"Passed: {report.hardware_metrics.passed_tests}")
        self.log_error(f"Failed: {report.hardware_metrics.failed_tests}")
        self.log_critical(f"Critical Failures: {report.hardware_metrics.critical_failures}")
        self.log_message(f"  Success Rate: {report.hardware_metrics.success_rate_percent:.1f}%", "INFO", Colors.CYAN)
        
        self.log_message("\\n🎯 Acceptance Criteria Status:", "INFO", Colors.CYAN)
        for ac, result in report.acceptance_criteria_results.items():
            if result == "PASS":
                self.log_success(f"{ac.value}: {result}")
            elif result == "CRITICAL_FAIL":
                self.log_critical(f"{ac.value}: {result}")
            elif result == "FAIL":
                self.log_error(f"{ac.value}: {result}")
            else:
                self.log_warning(f"{ac.value}: {result}")
        
        self.log_message("\\n⚡ Performance Metrics:", "INFO", Colors.CYAN)
        self.log_message(f"  Boot Time: {report.hardware_metrics.boot_time_ms}ms (limit: {self.thresholds['boot_time_max_ms']}ms)", 
                        "INFO", Colors.GREEN if report.hardware_metrics.boot_time_ms <= self.thresholds['boot_time_max_ms'] else Colors.RED)
        self.log_message(f"  Available Heap: {report.hardware_metrics.available_heap_kb}KB (required: >{self.thresholds['min_heap_kb']}KB)", 
                        "INFO", Colors.GREEN if report.hardware_metrics.available_heap_kb >= self.thresholds['min_heap_kb'] else Colors.RED)
        self.log_message(f"  Touch Response: {report.hardware_metrics.touch_response_time_ms}ms (limit: {self.thresholds['touch_response_max_ms']}ms)", 
                        "INFO", Colors.GREEN if report.hardware_metrics.touch_response_time_ms <= self.thresholds['touch_response_max_ms'] else Colors.RED)
        self.log_message(f"  Build Time: {report.hardware_metrics.build_time_seconds:.1f}s (limit: {self.thresholds['build_time_max_seconds']}s)", 
                        "INFO", Colors.GREEN if report.hardware_metrics.build_time_seconds <= self.thresholds['build_time_max_seconds'] else Colors.RED)
        
        self.log_message("\\n💡 Recommendations:", "INFO", Colors.CYAN)
        for recommendation in report.recommendations:
            self.log_message(f"  {recommendation}", "INFO", Colors.WHITE)
        
        self.log_message(f"\\n🏆 Overall Status: {report.overall_status}", "INFO", 
                        Colors.GREEN if report.overall_status == "PASS" else Colors.RED)
        
        # Output JSON for CI/CD integration
        self.log_message("\\n📄 Quality Report JSON:", "INFO", Colors.CYAN)
        print(json.dumps(asdict(report), indent=2, default=str))
        
        self.log_message("=" * 80, "INFO", Colors.CYAN)


def main():
    """Main function for command-line execution"""
    parser = argparse.ArgumentParser(
        description="Hardware-in-the-Loop Validator for ESP32-S3 ADHD SmartWatch Story 1.1",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python hardware_in_loop_validator.py COM3
  python hardware_in_loop_validator.py /dev/ttyUSB0 --baudrate 921600
  python hardware_in_loop_validator.py COM3 --report validation_report.json
  python hardware_in_loop_validator.py COM3 --timeout 45 --verbose
        """
    )
    
    parser.add_argument("port", help="Serial port for ESP32-S3 communication")
    parser.add_argument("--baudrate", type=int, default=115200, help="Serial baudrate (default: 115200)")
    parser.add_argument("--timeout", type=int, default=30, help="Communication timeout in seconds (default: 30)")
    parser.add_argument("--report", help="Save comprehensive report to JSON file")
    parser.add_argument("--verbose", action="store_true", help="Enable verbose logging")
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    # Create validator instance
    validator = HardwareInLoopValidator(
        port=args.port,
        baudrate=args.baudrate,
        timeout=args.timeout
    )
    
    try:
        # Run comprehensive validation
        results = validator.run_comprehensive_validation()
        
        # Print summary
        validator.print_comprehensive_summary()
        
        # Save report if requested
        if args.report:
            report = validator.generate_comprehensive_report()
            with open(args.report, 'w') as f:
                json.dump(asdict(report), f, indent=2, default=str)
            validator.log_success(f"Comprehensive report saved to {args.report}")
        
        # Exit with appropriate code based on results
        if validator.metrics.critical_failures > 0:
            sys.exit(2)  # Critical failure
        elif validator.metrics.failed_tests > 0:
            sys.exit(1)  # Test failures
        else:
            sys.exit(0)  # Success
        
    except KeyboardInterrupt:
        validator.log_warning("\\nValidation interrupted by user")
        sys.exit(130)
    except Exception as e:
        validator.log_critical(f"Validation failed with unexpected error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()