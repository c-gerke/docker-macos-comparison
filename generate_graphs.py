#!/usr/bin/env python3

import matplotlib.pyplot as plt
import numpy as np
import json
import os
import sys

def load_results():
    try:
        print(f"Current directory: {os.getcwd()}")
        print(f"Files in output directory: {os.listdir('output')}")
        
        with open('output/results.json', 'r') as f:
            content = f.read()
            print(f"Raw JSON content: {content[:100]}...")  # Print first 100 chars
            return json.loads(content)
    except FileNotFoundError as e:
        print(f"Error: Could not find the results file: {e}")
        return {}
    except json.JSONDecodeError as e:
        print(f"Error: Failed to parse JSON: {e}")
        # Attempt to create a minimal JSON to continue
        return {}
    except Exception as e:
        print(f"Unexpected error: {e}")
        return {}

def create_bar_chart(data, title, filename):
    try:
        if not data:
            print(f"Warning: No data available for chart {title}")
            return
            
        benchmarks = list(data.keys())
        
        # Check if we have the expected structure
        missing_data = False
        arm_times = []
        amd_times = []
        
        for b in benchmarks:
            if 'arm64' not in data[b] or 'amd64' not in data[b]:
                print(f"Warning: Missing architecture data for {b}")
                missing_data = True
                break
            if 'real' not in data[b]['arm64'] or 'real' not in data[b]['amd64']:
                print(f"Warning: Missing 'real' time data for {b}")
                missing_data = True
                break
            arm_times.append(data[b]['arm64']['real'])
            amd_times.append(data[b]['amd64']['real'])
        
        if missing_data:
            print(f"Skipping chart {title} due to missing data")
            return
        
        x = np.arange(len(benchmarks))
        width = 0.35
        
        fig, ax = plt.subplots(figsize=(12, 6))
        rects1 = ax.bar(x - width/2, arm_times, width, label='ARM64')
        rects2 = ax.bar(x + width/2, amd_times, width, label='AMD64')
        
        ax.set_ylabel('Time (seconds)')
        ax.set_title(title)
        ax.set_xticks(x)
        ax.set_xticklabels(benchmarks, rotation=45, ha='right')
        ax.legend()
        
        fig.tight_layout()
        
        os.makedirs('output', exist_ok=True)
        plt.savefig(f'output/{filename}.png', dpi=300, bbox_inches='tight')
        plt.close()
        
        print(f"Created chart: {filename}.png")
    except Exception as e:
        print(f"Error creating chart {title}: {e}")

def main():
    # Create output directory if it doesn't exist
    os.makedirs('output', exist_ok=True)
    
    # Load results
    results = load_results()
    
    if not results:
        print("No valid benchmark results found. Creating placeholder chart.")
        # Create a placeholder chart
        placeholder = {
            'Placeholder': {
                'arm64': {'real': 1.0},
                'amd64': {'real': 1.5}
            }
        }
        create_bar_chart(placeholder, 'No Valid Benchmark Data', 'placeholder')
        return
    
    # Print what we loaded
    print(f"Loaded benchmarks: {list(results.keys())}")
    
    # Create overall performance comparison
    create_bar_chart(results, 'Performance Comparison: ARM64 vs AMD64', 'performance_comparison')
    
    # Create CPU-intensive operations comparison 
    cpu_benchmarks = {}
    for benchmark in ['Mathematical Operations', 'Matrix Multiplication', 
                     'Gzip Compression', 'Bzip2 Compression', 'XZ Compression']:
        if benchmark in results:
            cpu_benchmarks[benchmark] = results[benchmark]
    
    if cpu_benchmarks:
        create_bar_chart(cpu_benchmarks, 'CPU-Intensive Operations Comparison', 'cpu_comparison')
    
    # Create I/O operations comparison
    io_benchmarks = {}
    for benchmark in ['File System Operations', 'Network Operations', 'Random Data Generation']:
        if benchmark in results:
            io_benchmarks[benchmark] = results[benchmark]
    
    if io_benchmarks:
        create_bar_chart(io_benchmarks, 'I/O Operations Comparison', 'io_comparison')
    
    # Create system operations comparison
    sys_benchmarks = {}
    if 'Process Creation' in results:
        sys_benchmarks['Process Creation'] = results['Process Creation']
    
    if sys_benchmarks:
        create_bar_chart(sys_benchmarks, 'System Operations Comparison', 'sys_comparison')

if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f"Unhandled exception: {e}")
        sys.exit(1) 