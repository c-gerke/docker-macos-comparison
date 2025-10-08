#!/bin/bash

# Number of iterations for each benchmark
ITERATIONS=1

# Print system information
echo "=== System Information ==="
echo "CPU Architecture: $(uname -m)"
echo "CPU Model: $(cat /proc/cpuinfo | grep 'model name' | head -n1 | cut -d':' -f2 | xargs)"
echo "CPU Cores: $(nproc)"
echo "Memory: $(free -h | grep Mem | awk '{print $2}')"
echo

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR

# Initialize results array
declare -A results

# Function to run a benchmark multiple times and calculate statistics
run_benchmark_iterations() {
    local name="$1"
    local command="$2"
    
    echo "=== Running Benchmark: $name (${ITERATIONS} iterations) ==="
    
    local times=()
    local sum=0
    
    for i in $(seq 1 $ITERATIONS); do
        echo "  Iteration $i/$ITERATIONS..."
        local start=$(date +%s.%N)
        eval "$command" > /dev/null 2>&1
        local end=$(date +%s.%N)
        local elapsed=$(echo "$end - $start" | bc)
        times+=($elapsed)
        sum=$(echo "$sum + $elapsed" | bc)
    done
    
    # Calculate average
    local avg=$(echo "scale=3; $sum / $ITERATIONS" | bc)
    
    # Calculate min and max
    local min=${times[0]}
    local max=${times[0]}
    for t in "${times[@]}"; do
        if (( $(echo "$t < $min" | bc -l) )); then
            min=$t
        fi
        if (( $(echo "$t > $max" | bc -l) )); then
            max=$t
        fi
    done
    
    # Calculate standard deviation
    local variance_sum=0
    for t in "${times[@]}"; do
        local diff=$(echo "$t - $avg" | bc)
        local sq=$(echo "$diff * $diff" | bc)
        variance_sum=$(echo "$variance_sum + $sq" | bc)
    done
    local variance=$(echo "scale=6; $variance_sum / $ITERATIONS" | bc)
    local stddev=$(echo "scale=3; sqrt($variance)" | bc)
    
    echo "  Average: ${avg}s, Min: ${min}s, Max: ${max}s, StdDev: ${stddev}s"
    
    # Store results
    results["$name,avg"]=$avg
    results["$name,min"]=$min
    results["$name,max"]=$max
    results["$name,stddev"]=$stddev
    echo
}

# Benchmark 1: Integer arithmetic operations (CPU-bound, shows emulation overhead)
echo "Preparing Benchmark 1: Integer arithmetic..."
run_benchmark_iterations "Integer Arithmetic" \
    'for i in {1..5000000}; do ((result = i * 2 + 3 - 1)); done'

# Benchmark 2: Floating point operations
echo "Preparing Benchmark 2: Floating point math..."
run_benchmark_iterations "Floating Point Math" \
    'python3 -c "
import math
for i in range(2000000):
    x = math.sqrt(i) * math.sin(i) * math.cos(i)
"'

# Benchmark 3: System call intensive (shows translation overhead)
echo "Preparing Benchmark 3: System calls..."
run_benchmark_iterations "System Call Intensive" \
    'for i in {1..2000}; do
        echo "test" > test_$i.txt
        cat test_$i.txt > /dev/null
        rm test_$i.txt
    done'

# Generate test data files
echo "Generating test data files..."
dd if=/dev/urandom of=data_1gb bs=1M count=1024 2>/dev/null
dd if=/dev/urandom of=data_256mb bs=1M count=256 2>/dev/null

# Benchmark 4: Gzip compression
echo "Preparing Benchmark 4: Gzip compression..."
run_benchmark_iterations "Gzip Compression" \
    'gzip -k -c data_1gb > /dev/null'

# Benchmark 5: Bzip2 compression (CPU intensive)
echo "Preparing Benchmark 5: Bzip2 compression..."
run_benchmark_iterations "Bzip2 Compression" \
    'bzip2 -k -c data_1gb > /dev/null'

# Benchmark 6: XZ compression (very CPU intensive)
echo "Preparing Benchmark 6: XZ compression..."
run_benchmark_iterations "XZ Compression" \
    'xz -k -c data_256mb > /dev/null'

# Benchmark 7: Memory-intensive matrix multiplication
echo "Preparing Benchmark 7: Matrix multiplication..."
run_benchmark_iterations "Matrix Multiplication" \
    'python3 -c "
import numpy as np
a = np.random.rand(5000, 5000)
b = np.random.rand(5000, 5000)
c = np.dot(a, b)
"'

# Benchmark 8: String processing (mixed CPU/memory)
echo "Preparing Benchmark 8: String processing..."
run_benchmark_iterations "String Processing" \
    'python3 -c "
text = \"test string \" * 1000000
result = text.upper().lower().replace(\"test\", \"TEST\").split()
"'

# Benchmark 9: File I/O operations
echo "Preparing Benchmark 9: File I/O..."
run_benchmark_iterations "File I/O Operations" \
    'for i in {1..500}; do
        dd if=/dev/urandom of=file_$i bs=1M count=10 2>/dev/null
        cat file_$i > /dev/null
        rm file_$i
    done'

# Benchmark 10: Process creation and management
echo "Preparing Benchmark 10: Process creation..."
run_benchmark_iterations "Process Creation" \
    'for i in {1..200}; do
        (sleep 0.01) &
    done
    wait'

# Benchmark 11: Context switching
echo "Preparing Benchmark 11: Context switching..."
run_benchmark_iterations "Context Switching" \
    'for i in {1..100}; do
        (for j in {1..100}; do echo $j > /dev/null; done) &
    done
    wait'

# Benchmark 12: OpenSSL encryption (shows crypto performance)
echo "Preparing Benchmark 12: Crypto operations..."
run_benchmark_iterations "Crypto Operations" \
    'openssl enc -aes-256-cbc -in data_256mb -out /dev/null -pass pass:test -pbkdf2'

# Benchmark 13: JSON parsing (mixed workload)
echo "Preparing Benchmark 13: JSON parsing..."
cat > large.json <<'EOF'
{"data": [
EOF
for i in {1..10000}; do
    echo "{\"id\": $i, \"name\": \"item_$i\", \"value\": $(($i * 2))}, " >> large.json
done
echo '{}]}' >> large.json

run_benchmark_iterations "JSON Parsing" \
    'jq ".data | length" large.json > /dev/null'

# Benchmark 14: Compilation test (shows toolchain overhead)
echo "Preparing Benchmark 14: Compilation test..."
cat > test.c <<'EOF'
#include <stdio.h>
#include <math.h>

int main() {
    double sum = 0;
    for (int i = 0; i < 10000000; i++) {
        sum += sqrt(i) * sin(i);
    }
    return 0;
}
EOF

run_benchmark_iterations "C Compilation" \
    'gcc -O2 test.c -o test -lm'

# Benchmark 15: Binary execution (of compiled code)
echo "Preparing Benchmark 15: Binary execution..."
gcc -O2 test.c -o test -lm
run_benchmark_iterations "Binary Execution" \
    './test'

# Output results in JSON format
echo "=== RESULTS_JSON_START ==="
echo "{"

# Collect all benchmark names first
benchmark_names=()
for key in "${!results[@]}"; do
    IFS=',' read -r name metric <<< "$key"
    if [ "$metric" == "avg" ]; then
        benchmark_names+=("$name")
    fi
done

# Sort benchmark names
IFS=$'\n' sorted_names=($(sort <<<"${benchmark_names[*]}"))
unset IFS

# Output JSON for each benchmark
first=true
for name in "${sorted_names[@]}"; do
    if [ "$first" = true ]; then
        first=false
    else
        echo ","
    fi
    
    # Ensure numbers have leading zeros for valid JSON
    avg="${results["$name,avg"]}"
    min="${results["$name,min"]}"
    max="${results["$name,max"]}"
    stddev="${results["$name,stddev"]}"
    
    # Add leading zero if number starts with decimal point
    [[ "$avg" =~ ^\. ]] && avg="0$avg"
    [[ "$min" =~ ^\. ]] && min="0$min"
    [[ "$max" =~ ^\. ]] && max="0$max"
    [[ "$stddev" =~ ^\. ]] && stddev="0$stddev"
    
    echo -n "  \"$name\": {\"avg\": $avg, \"min\": $min, \"max\": $max, \"stddev\": $stddev}"
done

echo ""
echo "}"
echo "=== RESULTS_JSON_END ==="

# Cleanup
cd /
rm -rf $TEMP_DIR
echo "Benchmark complete!"
