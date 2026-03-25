#!/usr/bin/env python3
"""
Memory Analysis Script
Analyzes memory usage patterns and detects potential leaks
"""

import json
import sys
import os
import re
from pathlib import Path

# Memory thresholds (in MB)
# These thresholds are designed for production monitoring.
# Test runs with short durations will skip rate-based checks.
MEMORY_THRESHOLDS = {
    'initial_heap_size': 100,     # MB (generous for test environment)
    'peak_heap_size': 300,        # MB
    'heap_growth_rate': 10,       # MB per minute (only for runs > 1 minute)
    'gc_frequency': 5,            # GCs per minute (only for runs > 1 minute)
    'memory_leak_threshold': 5,   # MB growth over 5 minutes
}

# Minimum duration (in seconds) required for rate-based analysis
MIN_DURATION_FOR_RATE_ANALYSIS = 60  # 1 minute

def analyze_memory_logs():
    """Analyze memory logs from Flutter tests"""
    
    log_files = list(Path('test_results').glob('**/memory_*.log'))
    
    if not log_files:
        print("❌ No memory log files found")
        return False
    
    memory_data = []
    
    for log_file in log_files:
        try:
            with open(log_file, 'r') as f:
                for line in f:
                    # Parse memory usage lines
                    # Format: [TIMESTAMP] MEMORY: heap=123.45MB, gc=2
                    match = re.search(r'MEMORY: heap=([\d.]+)MB, gc=(\d+)', line)
                    if match:
                        heap_size = float(match.group(1))
                        gc_count = int(match.group(2))
                        timestamp = line.split(']')[0].strip('[')
                        
                        memory_data.append({
                            'timestamp': timestamp,
                            'heap_size': heap_size,
                            'gc_count': gc_count
                        })
        except Exception as e:
            print(f"⚠️  Error reading {log_file}: {e}")
    
    if not memory_data:
        print("❌ No memory data found in logs")
        return False
    
    return analyze_memory_patterns(memory_data)

def analyze_memory_patterns(memory_data):
    """Analyze memory usage patterns"""

    if len(memory_data) < 2:
        print("⚠️  Insufficient memory data for analysis")
        return True

    # Calculate metrics
    initial_heap = memory_data[0]['heap_size']
    peak_heap = max(data['heap_size'] for data in memory_data)

    # Calculate heap growth rate
    first_time = memory_data[0]['timestamp']
    last_time = memory_data[-1]['timestamp']
    time_diff = parse_time_diff(last_time) - parse_time_diff(first_time)

    if time_diff > 0:
        heap_growth = (memory_data[-1]['heap_size'] - initial_heap)
        growth_rate = heap_growth / (time_diff / 60)  # MB per minute
    else:
        growth_rate = 0

    # Calculate GC frequency
    total_gc = sum(data['gc_count'] for data in memory_data)
    gc_frequency = total_gc / (time_diff / 60) if time_diff > 0 else 0

    # Check for memory leaks
    memory_leak_detected = detect_memory_leak(memory_data)

    # Determine if this is a short test run
    is_short_run = time_diff < MIN_DURATION_FOR_RATE_ANALYSIS

    # Print analysis results
    print(f"📊 Memory Analysis Results:")
    print(f"   Initial Heap: {initial_heap:.2f} MB")
    print(f"   Peak Heap: {peak_heap:.2f} MB")
    print(f"   Duration: {time_diff:.2f} seconds")
    if is_short_run:
        print(f"   Note: Short test run ({time_diff:.1f}s < {MIN_DURATION_FOR_RATE_ANALYSIS}s), skipping rate-based checks")
    else:
        print(f"   Growth Rate: {growth_rate:.2f} MB/min")
        print(f"   GC Frequency: {gc_frequency:.2f} GCs/min")
    print(f"   Memory Leak: {'Detected' if memory_leak_detected else 'None detected'}")

    # Check thresholds
    failed_checks = []

    if initial_heap > MEMORY_THRESHOLDS['initial_heap_size']:
        failed_checks.append(f"Initial heap size {initial_heap:.2f}MB > {MEMORY_THRESHOLDS['initial_heap_size']}MB")

    if peak_heap > MEMORY_THRESHOLDS['peak_heap_size']:
        failed_checks.append(f"Peak heap size {peak_heap:.2f}MB > {MEMORY_THRESHOLDS['peak_heap_size']}MB")

    # Only check rate-based metrics for longer runs
    if not is_short_run:
        if growth_rate > MEMORY_THRESHOLDS['heap_growth_rate']:
            failed_checks.append(f"Growth rate {growth_rate:.2f}MB/min > {MEMORY_THRESHOLDS['heap_growth_rate']}MB/min")

        if gc_frequency > MEMORY_THRESHOLDS['gc_frequency']:
            failed_checks.append(f"GC frequency {gc_frequency:.2f}/min > {MEMORY_THRESHOLDS['gc_frequency']}/min")

    if memory_leak_detected:
        failed_checks.append("Memory leak detected")

    if failed_checks:
        print("❌ Memory thresholds exceeded:")
        for check in failed_checks:
            print(f"   - {check}")
        return False

    print("✅ All memory metrics within thresholds")
    return True

def detect_memory_leak(memory_data):
    """Detect potential memory leaks"""
    
    if len(memory_data) < 10:
        return False
    
    # Check for consistent memory growth over time
    window_size = min(10, len(memory_data) // 2)
    
    for i in range(len(memory_data) - window_size):
        window_start = memory_data[i]
        window_end = memory_data[i + window_size]
        
        memory_growth = window_end['heap_size'] - window_start['heap_size']
        time_diff = parse_time_diff(window_end['timestamp']) - parse_time_diff(window_start['timestamp'])
        
        if time_diff > 300:  # 5 minutes
            growth_rate = memory_growth / (time_diff / 60)
            if growth_rate > MEMORY_THRESHOLDS['memory_leak_threshold']:
                return True
    
    return False

def parse_time_diff(timestamp_str):
    """Parse timestamp string to seconds"""
    # Simple timestamp parsing - adjust based on actual format
    try:
        # Assuming format like "2024-01-01T12:00:00.000"
        parts = timestamp_str.split(':')
        hours = int(parts[0].split('T')[1]) if 'T' in parts[0] else 0
        minutes = int(parts[1])
        seconds = float(parts[2])
        return hours * 3600 + minutes * 60 + seconds
    except:
        return 0

def generate_memory_report():
    """Generate memory analysis report"""
    
    report = {
        'timestamp': os.environ.get('BUILD_TIMESTAMP', 'unknown'),
        'commit': os.environ.get('GITHUB_SHA', 'unknown'),
        'branch': os.environ.get('GITHUB_REF_NAME', 'unknown'),
        'thresholds': MEMORY_THRESHOLDS,
        'status': 'passed' if analyze_memory_logs() else 'failed'
    }
    
    # Save report
    report_path = Path('test_results/memory_analysis_report.json')
    report_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(report_path, 'w') as f:
        json.dump(report, f, indent=2)
    
    print(f"📊 Memory analysis report saved to {report_path}")

if __name__ == "__main__":
    print("🧠 Running memory analysis...")
    
    if analyze_memory_logs():
        generate_memory_report()
        print("✅ Memory analysis passed")
        sys.exit(0)
    else:
        print("❌ Memory analysis failed")
        sys.exit(1)
