#!/bin/bash

# Print system information
echo "=== System Information ==="
echo "CPU Architecture: $(uname -m)"
echo "CPU Model: $(cat /proc/cpuinfo | grep 'model name' | head -n1 | cut -d':' -f2 | xargs)"
echo "CPU Cores: $(nproc)"
echo "Memory: $(free -h | grep Mem | awk '{print $2}')"

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR

# Function to print benchmark results
print_result() {
    echo "=== $1 ==="
    echo "Real time: $2"
    echo "User time: $3"
    echo "System time: $4"
    echo
}

# Benchmark 0: Generate lots of random data
echo "Benchmark 0: Generating 10GB of random data"
{ time dd if=/dev/urandom of=random_data_large bs=1M count=10240 2>&1; } 2> time_output
print_result "Random Data Generation Large" \
    "$(grep real time_output | cut -f2)" \
    "$(grep user time_output | cut -f2)" \
    "$(grep sys time_output | cut -f2)"

# Benchmark 1: Generate random data
echo "Benchmark 1: Generating 1GB of random data"
{ time dd if=/dev/urandom of=random_data bs=1M count=1024 2>&1; } 2> time_output
print_result "Random Data Generation" \
    "$(grep real time_output | cut -f2)" \
    "$(grep user time_output | cut -f2)" \
    "$(grep sys time_output | cut -f2)"

# Create a smaller file for XZ compression
dd if=random_data of=random_data_small bs=1M count=256

# Benchmark 2: Compress with gzip
echo "Benchmark 2: Compressing with gzip"
{ time gzip -k random_data 2>&1; } 2> time_output
print_result "Gzip Compression" \
    "$(grep real time_output | cut -f2)" \
    "$(grep user time_output | cut -f2)" \
    "$(grep sys time_output | cut -f2)"

# Benchmark 3: Compress with bzip2
echo "Benchmark 3: Compressing with bzip2"
{ time bzip2 -k random_data 2>&1; } 2> time_output
print_result "Bzip2 Compression" \
    "$(grep real time_output | cut -f2)" \
    "$(grep user time_output | cut -f2)" \
    "$(grep sys time_output | cut -f2)"

# Benchmark 4: Compress with xz (smaller file)
echo "Benchmark 4: Compressing with xz (256MB file)"
{ time xz -k random_data_small 2>&1; } 2> time_output
print_result "XZ Compression" \
    "$(grep real time_output | cut -f2)" \
    "$(grep user time_output | cut -f2)" \
    "$(grep sys time_output | cut -f2)"

# Benchmark 5: CPU-intensive mathematical operations
echo "Benchmark 5: CPU-intensive mathematical operations"
{ time python3 -c "
import math
for i in range(1000000):
    math.sin(i) * math.cos(i) * math.tan(i)
" 2>&1; } 2> time_output
print_result "Mathematical Operations" \
    "$(grep real time_output | cut -f2)" \
    "$(grep user time_output | cut -f2)" \
    "$(grep sys time_output | cut -f2)"

# Benchmark 6: Memory operations
echo "Benchmark 6: Memory operations"
{ time python3 -c "
import numpy as np
a = np.random.rand(10000, 10000)
b = np.random.rand(10000, 10000)
c = np.dot(a, b)
" 2>&1; } 2> time_output
print_result "Matrix Multiplication" \
    "$(grep real time_output | cut -f2)" \
    "$(grep user time_output | cut -f2)" \
    "$(grep sys time_output | cut -f2)"

# Benchmark 7: File system operations
echo "Benchmark 7: File system operations"
{ time for i in {1..1000}; do
    echo "test" > "test_$i.txt"
    cat "test_$i.txt" > /dev/null
    rm "test_$i.txt"
done 2>&1; } 2> time_output
print_result "File System Operations" \
    "$(grep real time_output | cut -f2)" \
    "$(grep user time_output | cut -f2)" \
    "$(grep sys time_output | cut -f2)"

# Benchmark 8: Process creation and management
echo "Benchmark 8: Process creation and management"
{ time for i in {1..100}; do
    (sleep 0.01) &
done
wait 2>&1; } 2> time_output
print_result "Process Creation" \
    "$(grep real time_output | cut -f2)" \
    "$(grep user time_output | cut -f2)" \
    "$(grep sys time_output | cut -f2)"

# Benchmark 9: Network simulation (using localhost)
echo "Benchmark 9: Network simulation"
{ time for i in {1..100}; do
    nc -z localhost 22 || true
done 2>&1; } 2> time_output
print_result "Network Operations" \
    "$(grep real time_output | cut -f2)" \
    "$(grep user time_output | cut -f2)" \
    "$(grep sys time_output | cut -f2)"

# Cleanup
cd /
rm -rf $TEMP_DIR 