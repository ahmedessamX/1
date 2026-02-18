#!/usr/bin/env python3
"""
Simple status check script to verify the system is operational.
"""
import os
import subprocess
import sys


def check_system_status():
    """
    Performs a basic system status check and returns the result.
    
    Returns:
        dict: System status information
    """
    components = {}
    all_operational = True
    
    # Check if we're in a git repository
    try:
        result = subprocess.run(['git', 'rev-parse', '--git-dir'], 
                              capture_output=True, text=True, check=True)
        components['repository'] = 'active'
    except (subprocess.CalledProcessError, FileNotFoundError):
        components['repository'] = 'error'
        all_operational = False
    
    # Check if Python is working (if we got here, it is!)
    components['python_runtime'] = 'functional'
    
    # Check if we can read/write files
    try:
        test_file = '.status_test'
        with open(test_file, 'w') as f:
            f.write('test')
        os.remove(test_file)
        components['file_operations'] = 'operational'
    except (IOError, OSError):
        components['file_operations'] = 'error'
        all_operational = False
    
    status = {
        'operational': all_operational,
        'message': 'System is working correctly' if all_operational else 'Some components have errors',
        'components': components
    }
    return status


def main():
    """Main function to run the status check."""
    status = check_system_status()
    
    print("=" * 50)
    print("SYSTEM STATUS CHECK")
    print("=" * 50)
    print(f"\nOperational: {status['operational']}")
    print(f"Message: {status['message']}")
    print("\nComponent Status:")
    for component, state in status['components'].items():
        print(f"  - {component}: {state}")
    print("\n" + "=" * 50)
    
    return 0 if status['operational'] else 1


if __name__ == '__main__':
    exit(main())
