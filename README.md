# Docker Desktop Performance Benchmark

This project provides a benchmarking tool to measure Docker Desktop performance on macOS, specifically comparing native ARM64 and AMD64 (via Rosetta 2) execution.

## Prerequisites

- Docker Desktop for Mac
- macOS (using Apple Silicon)
- Python 3 with matplotlib and numpy (for graph generation)
- jq (for JSON processing)

## Benchmark Operations

The benchmark performs 15 different tests, each run **3 times** to calculate reliable averages and standard deviations:

### CPU-Intensive Tests (show emulation overhead)
1. **Integer Arithmetic** - Pure integer math operations
2. **Floating Point Math** - Mathematical functions (sin, cos, sqrt)
3. **Gzip Compression** - Fast compression algorithm
4. **Bzip2 Compression** - CPU-intensive compression
5. **XZ Compression** - Very CPU-intensive compression
6. **Matrix Multiplication** - Large matrix operations (5000x5000)
7. **Crypto Operations** - AES-256 encryption with OpenSSL
8. **C Compilation** - GCC compilation overhead
9. **Binary Execution** - Native binary execution performance

### System & I/O Tests (show translation overhead)
10. **System Call Intensive** - Frequent system calls (file create/read/delete)
11. **File I/O Operations** - Large file operations
12. **Process Creation** - Fork/exec overhead
13. **Context Switching** - Multi-process context switching
14. **String Processing** - Memory and string manipulation
15. **JSON Parsing** - Mixed workload with jq

Each benchmark reports:
- **Average time** across all iterations
- **Minimum time** (best case)
- **Maximum time** (worst case)
- **Standard deviation** (consistency metric)

## Usage

1. Make the build script executable:
   ```bash
   chmod +x build_and_run.sh
   ```

2. Run the benchmark:
   ```bash
   ./build_and_run.sh
   ```

The script will:
- Build the Docker image for both ARM64 and AMD64 platforms
- Run the benchmark on each platform
- Generate comparison graphs in the `output` directory
- Display the results for comparison

## Generated Graphs

The benchmark generates several comparison graphs in the `output` directory:

1. [Overall Performance Comparison](output/performance_comparison.png)
   - Shows all benchmarks with error bars (standard deviation)
   - Displays slowdown factors for each test

2. [Rosetta 2 Impact](output/rosetta2_impact.png)
   - Horizontal bar chart showing relative performance impact
   - Sorted by slowdown factor (worst to best)

3. [CPU-Intensive Operations](output/cpu_comparison.png)
   - Compilation, compression, crypto, and math operations
   - Highlights emulation overhead

4. [I/O & System Operations](output/io_sys_comparison.png)
   - File I/O, system calls, and process management
   - Shows translation overhead

All graphs include:
- Error bars showing standard deviation
- Performance ratio labels (e.g., "2.5x slower")
- Color coding (green for ARM64, red for AMD64/Rosetta 2)

## Interpreting Results

### Understanding the Metrics
- **ARM64**: Native execution on Apple Silicon (baseline)
- **AMD64**: Execution through Rosetta 2 translation
- **Slowdown Factor**: AMD64 time / ARM64 time (e.g., 2.0x = twice as slow)
- **Error Bars**: Show consistency (smaller = more reliable)

### Expected Performance Patterns
- **CPU-bound tests**: Typically 1.3x - 2.5x slower under Rosetta 2
- **System call heavy**: May show higher overhead (2x - 3x)
- **I/O bound**: Usually less impact (1.1x - 1.5x)
- **Compilation**: Shows toolchain overhead

### What to Look For
- Tests with **high slowdown + low stddev**: Consistent Rosetta 2 penalty
- Tests with **high stddev**: Inconsistent performance, may need investigation
- **Average slowdown**: Overall Rosetta 2 impact on your workloads
- **Worst case tests**: Identify workloads to optimize or avoid

## Notes

- Each benchmark runs **3 iterations** to calculate reliable averages
- Statistical analysis includes mean, min, max, and standard deviation
- All operations are performed in a temporary directory that is cleaned up after completion
- Results are saved in JSON format in `output/results.json` with full statistics
- The benchmark takes approximately **20-40 minutes** to complete both architectures
- Tests are designed to stress different aspects of the emulation layer

## Customization

You can adjust the number of iterations by editing `benchmark.sh`:
```bash
# Near the top of the file
ITERATIONS=3  # Change to 5 or 10 for more reliable statistics
```

For quicker testing (single iteration, less comprehensive):
```bash
ITERATIONS=1  # Faster but less statistically reliable
``` 