# Docker Desktop Performance Benchmark

This project provides a benchmarking tool to measure Docker Desktop performance on macOS, specifically comparing native ARM64 and AMD64 (via Rosetta 2) execution.

## Prerequisites

- Docker Desktop for Mac
- macOS (tested on Apple Silicon and Intel Macs)
- Python 3 with matplotlib and numpy (for graph generation)
- jq (for JSON processing)

## Benchmark Operations

The benchmark performs the following operations:
1. Generates 1GB and 20GB of random data
2. Compresses the data using gzip, bzip2, and xz
3. Performs CPU-intensive mathematical operations
4. Executes memory-intensive matrix multiplication
5. Tests file system operations
6. Measures process creation performance
7. Simulates network operations

Each operation is timed and the results are displayed, showing:
- Real time (wall clock time)
- User time (CPU time spent in user mode)
- System time (CPU time spent in kernel mode)

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
   - Shows all benchmark results for both platforms

2. [CPU-Intensive Operations](output/cpu_comparison.png)
   - Focuses on mathematical and compression operations

3. [I/O Operations](output/io_comparison.png)
   - Compares file system and network performance

4. [System Operations](output/sys_comparison.png)
   - Shows process creation and management performance

## Interpreting Results

- Compare the execution times between ARM64 and AMD64 platforms
- Higher times in the AMD64 platform indicate the performance impact of Rosetta 2 emulation
- The benchmark provides both CPU-intensive and I/O-intensive operations
- Graphs show relative performance differences between architectures

## Notes

- The benchmark uses a 1GB file size for most operations to ensure meaningful timing results
- All operations are performed in a temporary directory that is cleaned up after completion
- The benchmark uses standard Linux tools to ensure consistent results across platforms
- Results are saved in JSON format in `output/results.json` for further analysis 