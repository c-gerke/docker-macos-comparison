#!/bin/bash

# Create output directory
mkdir -p output

# Initialize results JSON
echo '{}' > output/results.json

# Function to build image for a specific platform
build_image() {
    local platform=$1
    local tag=$2
    
    echo "=== Building image for $platform ==="
    docker buildx build --platform $platform -t docker-benchmark:$tag --load .
    echo "Build complete for $platform"
    echo ""
}

# Function to run benchmark for a specific platform
run_benchmark() {
    local platform=$1
    local tag=$2
    
    echo "=== Running benchmark for $platform ==="
    
    # Run the benchmark and capture output while showing it
    local output
    output=$(docker run --platform $platform docker-benchmark:$tag | tee /dev/tty)
    
    # Extract JSON from output
    local json_data=$(echo "$output" | sed -n '/=== RESULTS_JSON_START ===/,/=== RESULTS_JSON_END ===/p' | sed '1d;$d')
    
    if [ -z "$json_data" ]; then
        echo "Warning: No JSON results found in output for $platform"
        return
    fi
    
    # Merge the JSON data into results.json
    echo "$json_data" | jq --arg plat "$tag" '
        to_entries | map({
            key: .key,
            value: {($plat): .value}
        }) | from_entries
    ' > "output/results_${tag}.json"
    
    # Merge platform results into main results.json
    if [ -s output/results.json ] && [ "$(cat output/results.json)" != "{}" ]; then
        # Merge with existing results - deep merge the nested objects
        jq -s 'reduce (.[1] | to_entries[]) as $item (.[0]; .[$item.key] = ((.[$item.key] // {}) + $item.value))' \
            output/results.json "output/results_${tag}.json" > output/temp.json
        mv output/temp.json output/results.json
    else
        # First platform, just copy the results
        cp "output/results_${tag}.json" output/results.json
    fi
    
    echo "----------------------------------------"
}

# Make sure we have buildx
echo "Creating buildx builder..."
docker buildx create --use

# Build both images first (while buildkit is running)
echo ""
echo "========================================="
echo "PHASE 1: Building Docker images"
echo "========================================="
build_image "linux/arm64" "arm64"
build_image "linux/amd64" "amd64"

# Stop and remove buildx builder before running benchmarks
echo "Stopping buildx builder to prevent interference with benchmarks..."
docker buildx rm
echo ""

# Now run benchmarks without buildkit running
echo "========================================="
echo "PHASE 2: Running benchmarks"
echo "========================================="
echo ""
run_benchmark "linux/arm64" "arm64"
echo ""
run_benchmark "linux/amd64" "amd64"

# Generate a summary report
echo "=== Performance Comparison Summary ===" > output/summary.txt
echo "Benchmark | ARM64 (avg+/-sd) | AMD64 (avg+/-sd) | Slowdown" >> output/summary.txt
echo "----------|------------------|------------------|----------" >> output/summary.txt

jq -r 'to_entries | .[] | 
    [.key, 
     ((.value.arm64.avg | tostring) + "+/-" + (.value.arm64.stddev | tostring)), 
     ((.value.amd64.avg | tostring) + "+/-" + (.value.amd64.stddev | tostring)), 
     ((.value.amd64.avg / .value.arm64.avg) | tostring + "x")] | 
     join(" | ")' output/results.json >> output/summary.txt

# Create a Python container for graph generation
echo "Generating comparison graphs..."
docker run --rm -v "$(pwd):/app" -w /app python:3.11-slim \
    sh -c "pip install matplotlib numpy && python3 generate_graphs.py"

# Print summary
echo "Benchmark results and graphs have been generated in the output directory."
echo "Check the README.md for links to the generated graphs."
cat output/summary.txt 