#!/bin/bash

# Create output directory
mkdir -p output

# Initialize results JSON
echo '{}' > output/results.json

# Function to convert time format to seconds
convert_to_seconds() {
    local time_str=$1
    if [[ $time_str =~ ([0-9]+)m([0-9]+\.[0-9]+)s ]]; then
        local minutes="${BASH_REMATCH[1]}"
        local seconds="${BASH_REMATCH[2]}"
        echo "$minutes * 60 + $seconds" | bc
    elif [[ $time_str =~ ([0-9]+\.[0-9]+)s ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo "0"
    fi
}

# Function to run benchmark for a specific platform
run_benchmark() {
    local platform=$1
    local tag=$2
    
    echo "=== Building and running benchmark for $platform ==="
    
    # Build the image and load it into Docker
    docker buildx build --platform $platform -t docker-benchmark:$tag --load .
    
    # Run the benchmark and capture output while showing it
    echo "Running benchmark for $platform..."
    local output
    output=$(docker run --platform $platform docker-benchmark:$tag | tee /dev/tty)
    
    # Parse results and add to JSON
    while IFS= read -r line; do
        if [[ $line == "=== "* && $line != "=== System Information ===" ]]; then
            current_benchmark=$(echo "$line" | sed 's/=== \(.*\) ===/\1/')
        elif [[ $line == "Real time: "* ]]; then
            real_time=$(echo "$line" | cut -d' ' -f3)
            real_seconds=$(convert_to_seconds "$real_time")
            
            # Update JSON with jq
            jq --arg bench "$current_benchmark" \
               --arg plat "$tag" \
               --argjson time "$real_seconds" \
               '.[$bench] = (.[$bench] // {}) | .[$bench][$plat] = {"real": $time}' \
               output/results.json > output/temp.json
            mv output/temp.json output/results.json
        fi
    done <<< "$output"
    
    echo "----------------------------------------"
}

# Make sure we have buildx
docker buildx create --use

# Run benchmarks for both platforms
run_benchmark "linux/arm64" "arm64"
run_benchmark "linux/amd64" "amd64"

# Cleanup
docker buildx rm

# Generate a summary report
echo "=== Performance Comparison Summary ===" > output/summary.txt
echo "Benchmark | ARM64 | AMD64 | % Difference" >> output/summary.txt
echo "---------|-------|-------|-------------" >> output/summary.txt

jq -r 'to_entries | .[] | 
    [.key, 
     (.value.arm64.real | tostring), 
     (.value.amd64.real | tostring), 
     ((.value.amd64.real / .value.arm64.real * 100 - 100) | tostring + "%")] | 
     join(" | ")' output/results.json >> output/summary.txt

# Create a Python container for graph generation
echo "Generating comparison graphs..."
docker run --rm -v "$(pwd):/app" -w /app python:3.11-slim \
    sh -c "pip install matplotlib numpy && python3 generate_graphs.py"

# Print summary
echo "Benchmark results and graphs have been generated in the output directory."
echo "Check the README.md for links to the generated graphs."
cat output/summary.txt 