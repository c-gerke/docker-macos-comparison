#!/usr/bin/env python3

import matplotlib.pyplot as plt
import numpy as np
import json
import os
import sys

def load_results():
    try:
        with open('output/results.json', 'r') as f:
            content = f.read()
            return json.loads(content)
    except FileNotFoundError as e:
        print(f"Error: Could not find the results file: {e}")
        return {}
    except json.JSONDecodeError as e:
        print(f"Error: Failed to parse JSON: {e}")
        return {}
    except Exception as e:
        print(f"Unexpected error: {e}")
        return {}

def create_bar_chart(data, title, filename, benchmarks_filter=None):
    try:
        if not data:
            print(f"Warning: No data available for chart {title}")
            return
            
        # Filter benchmarks if specified
        if benchmarks_filter:
            filtered_data = {k: v for k, v in data.items() if k in benchmarks_filter}
            if not filtered_data:
                print(f"Warning: No matching benchmarks for {title}")
                return
            data = filtered_data
        
        benchmarks = list(data.keys())
        
        # Check if we have the expected structure
        missing_data = False
        arm_times = []
        amd_times = []
        arm_errors = []
        amd_errors = []
        
        for b in benchmarks:
            if 'arm64' not in data[b] or 'amd64' not in data[b]:
                print(f"Warning: Missing architecture data for {b}")
                missing_data = True
                break
            if 'avg' not in data[b]['arm64'] or 'avg' not in data[b]['amd64']:
                print(f"Warning: Missing 'avg' time data for {b}")
                missing_data = True
                break
            
            arm_times.append(data[b]['arm64']['avg'])
            amd_times.append(data[b]['amd64']['avg'])
            arm_errors.append(data[b]['arm64'].get('stddev', 0))
            amd_errors.append(data[b]['amd64'].get('stddev', 0))
        
        if missing_data:
            print(f"Skipping chart {title} due to missing data")
            return
        
        x = np.arange(len(benchmarks))
        width = 0.35
        
        fig, ax = plt.subplots(figsize=(14, 8))
        
        # Create bars with error bars
        rects1 = ax.bar(x - width/2, arm_times, width, label='ARM64 (Native)', 
                       yerr=arm_errors, capsize=5, color='#2ecc71', alpha=0.8)
        rects2 = ax.bar(x + width/2, amd_times, width, label='AMD64 (Rosetta 2)', 
                       yerr=amd_errors, capsize=5, color='#e74c3c', alpha=0.8)
        
        # Add value labels on bars
        def autolabel(rects, errors):
            for i, rect in enumerate(rects):
                height = rect.get_height()
                ax.annotate(f'{height:.2f}s',
                           xy=(rect.get_x() + rect.get_width() / 2, height),
                           xytext=(0, 3 + errors[i]),
                           textcoords="offset points",
                           ha='center', va='bottom', fontsize=8, rotation=0)
        
        autolabel(rects1, arm_errors)
        autolabel(rects2, amd_errors)
        
        # Calculate and display performance differences
        for i, benchmark in enumerate(benchmarks):
            slowdown = amd_times[i] / arm_times[i]
            percentage = (slowdown - 1) * 100
            ax.text(i, max(arm_times[i], amd_times[i]) + max(arm_errors[i], amd_errors[i]) + 0.5,
                   f'{slowdown:.2f}x\n({percentage:+.1f}%)',
                   ha='center', va='bottom', fontsize=9, fontweight='bold',
                   bbox=dict(boxstyle='round,pad=0.3', facecolor='yellow', alpha=0.5))
        
        ax.set_ylabel('Time (seconds)', fontsize=12, fontweight='bold')
        ax.set_xlabel('Benchmark', fontsize=12, fontweight='bold')
        ax.set_title(title, fontsize=14, fontweight='bold', pad=20)
        ax.set_xticks(x)
        ax.set_xticklabels(benchmarks, rotation=45, ha='right', fontsize=10)
        ax.legend(fontsize=11, loc='upper left')
        ax.grid(axis='y', alpha=0.3, linestyle='--')
        
        fig.tight_layout()
        
        os.makedirs('output', exist_ok=True)
        plt.savefig(f'output/{filename}.png', dpi=300, bbox_inches='tight')
        plt.close()
        
        print(f"Created chart: {filename}.png")
    except Exception as e:
        print(f"Error creating chart {title}: {e}")
        import traceback
        traceback.print_exc()

def create_speedup_chart(data, filename):
    """Create a chart showing the speedup/slowdown ratio"""
    try:
        if not data:
            return
            
        benchmarks = list(data.keys())
        ratios = []
        
        for b in benchmarks:
            if 'arm64' in data[b] and 'amd64' in data[b]:
                ratio = data[b]['amd64']['avg'] / data[b]['arm64']['avg']
                ratios.append(ratio)
        
        if not ratios:
            return
        
        # Sort by ratio
        sorted_pairs = sorted(zip(benchmarks, ratios), key=lambda x: x[1], reverse=True)
        benchmarks, ratios = zip(*sorted_pairs)
        
        fig, ax = plt.subplots(figsize=(12, 8))
        
        colors = ['#e74c3c' if r > 1 else '#2ecc71' for r in ratios]
        bars = ax.barh(range(len(benchmarks)), ratios, color=colors, alpha=0.7)
        
        # Add value labels
        for i, (bar, ratio) in enumerate(zip(bars, ratios)):
            label = f'{ratio:.2f}x ({(ratio-1)*100:+.1f}%)'
            ax.text(ratio + 0.05, i, label, va='center', fontweight='bold')
        
        # Add reference line at 1.0x
        ax.axvline(x=1.0, color='black', linestyle='--', linewidth=2, label='Equal Performance')
        
        ax.set_yticks(range(len(benchmarks)))
        ax.set_yticklabels(benchmarks, fontsize=10)
        ax.set_xlabel('Slowdown Factor (AMD64/ARM64)', fontsize=12, fontweight='bold')
        ax.set_title('Rosetta 2 Performance Impact by Benchmark', fontsize=14, fontweight='bold')
        ax.legend(fontsize=10)
        ax.grid(axis='x', alpha=0.3, linestyle='--')
        
        fig.tight_layout()
        plt.savefig(f'output/{filename}.png', dpi=300, bbox_inches='tight')
        plt.close()
        
        print(f"Created chart: {filename}.png")
    except Exception as e:
        print(f"Error creating speedup chart: {e}")

def main():
    os.makedirs('output', exist_ok=True)
    
    results = load_results()
    
    if not results:
        print("No valid benchmark results found.")
        return
    
    print(f"Loaded {len(results)} benchmarks: {list(results.keys())}")
    
    # Create overall performance comparison
    create_bar_chart(results, 'Overall Performance Comparison: ARM64 vs AMD64 (Rosetta 2)', 
                    'performance_comparison')
    
    # Create speedup/slowdown chart
    create_speedup_chart(results, 'rosetta2_impact')
    
    # Create CPU-intensive operations comparison
    cpu_benchmarks = [
        'Integer Arithmetic', 'Floating Point Math', 'Matrix Multiplication',
        'Gzip Compression', 'Bzip2 Compression', 'XZ Compression',
        'C Compilation', 'Binary Execution', 'Crypto Operations'
    ]
    create_bar_chart(results, 'CPU-Intensive Operations: ARM64 vs AMD64', 
                    'cpu_comparison', cpu_benchmarks)
    
    # Create I/O and System operations comparison
    io_sys_benchmarks = [
        'File I/O Operations', 'System Call Intensive', 'String Processing',
        'JSON Parsing', 'Context Switching', 'Process Creation'
    ]
    create_bar_chart(results, 'I/O & System Operations: ARM64 vs AMD64', 
                    'io_sys_comparison', io_sys_benchmarks)
    
    # Print summary statistics
    print("\n=== Summary Statistics ===")
    slowdowns = []
    for name, data in results.items():
        if 'arm64' in data and 'amd64' in data:
            slowdown = data['amd64']['avg'] / data['arm64']['avg']
            slowdowns.append((name, slowdown))
            print(f"{name}: {slowdown:.2f}x slower on Rosetta 2")
    
    if slowdowns:
        avg_slowdown = np.mean([s[1] for s in slowdowns])
        max_slowdown = max(slowdowns, key=lambda x: x[1])
        min_slowdown = min(slowdowns, key=lambda x: x[1])
        
        print(f"\nAverage slowdown: {avg_slowdown:.2f}x")
        print(f"Worst case: {max_slowdown[0]} at {max_slowdown[1]:.2f}x")
        print(f"Best case: {min_slowdown[0]} at {min_slowdown[1]:.2f}x")

if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f"Unhandled exception: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
