#!/usr/bin/env python3
"""
Performance Check Script
Validates performance metrics against thresholds
"""

import json
import sys
import os
from pathlib import Path

# Performance thresholds
PERFORMANCE_THRESHOLDS = {
    'app_startup_time': 2000,  # milliseconds
    'frame_render_time': 16,   # milliseconds (60fps)
    'memory_usage': 200,       # MB
    'cpu_usage': 50,           # percentage
    'network_latency': 500,    # milliseconds
    'ui_jank_frames': 5,       # percentage
}

def check_performance_metrics():
    """Check performance metrics against thresholds"""
    
    # Look for performance test results
    test_results_path = Path('test_results/performance_metrics.json')
    
    if not test_results_path.exists():
        print("❌ Performance test results not found")
        return False
    
    try:
        with open(test_results_path, 'r') as f:
            metrics = json.load(f)
    except Exception as e:
        print(f"❌ Error reading performance results: {e}")
        return False
    
    failed_checks = []
    
    for metric, threshold in PERFORMANCE_THRESHOLDS.items():
        if metric in metrics:
            value = metrics[metric]
            
            # For time-based metrics, lower is better
            if 'time' in metric or 'latency' in metric:
                if value > threshold:
                    failed_checks.append(f"{metric}: {value}ms > {threshold}ms")
            # For usage metrics, lower is better
            elif 'usage' in metric or 'jank' in metric:
                if value > threshold:
                    failed_checks.append(f"{metric}: {value}% > {threshold}%")
            else:
                if value > threshold:
                    failed_checks.append(f"{metric}: {value} > {threshold}")
        else:
            print(f"⚠️  Metric {metric} not found in test results")
    
    if failed_checks:
        print("❌ Performance thresholds exceeded:")
        for check in failed_checks:
            print(f"   - {check}")
        return False
    
    print("✅ All performance metrics within thresholds")
    return True

def generate_performance_report():
    """Generate detailed performance report"""
    
    report = {
        'timestamp': os.environ.get('BUILD_TIMESTAMP', 'unknown'),
        'commit': os.environ.get('GITHUB_SHA', 'unknown'),
        'branch': os.environ.get('GITHUB_REF_NAME', 'unknown'),
        'thresholds': PERFORMANCE_THRESHOLDS,
        'status': 'passed' if check_performance_metrics() else 'failed'
    }
    
    # Save report
    report_path = Path('test_results/performance_report.json')
    report_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(report_path, 'w') as f:
        json.dump(report, f, indent=2)
    
    print(f"📊 Performance report saved to {report_path}")

if __name__ == "__main__":
    print("🚀 Running performance checks...")
    
    if check_performance_metrics():
        generate_performance_report()
        print("✅ Performance checks passed")
        sys.exit(0)
    else:
        print("❌ Performance checks failed")
        sys.exit(1)
