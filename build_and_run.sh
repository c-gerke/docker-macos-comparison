#!/bin/bash

# Create output directory
mkdir -p output

# Initialize results JSON
echo '{}' > output/results.json

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
    jq -s --arg plat "$tag" '
        reduce .[1] as $new (.[0]; 
            . * ($new | to_entries | map({
                key: .key,
                value: {($plat): .value[($plat)]}
            }) | from_entries | 
            with_entries(.value = (.[0][.key] // {}) + .value))
        )
    ' output/results.json "output/results_${tag}.json" > output/temp.json
    mv output/temp.json output/results.json
    
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
echo "Benchmark | ARM64 (avg±σ) | AMD64 (avg±σ) | Slowdown" >> output/summary.txt
echo "----------|---------------|---------------|----------" >> output/summary.txt

jq -r 'to_entries | .[] | 
    [.key, 
     ((.value.arm64.avg | tostring) + "±" + (.value.arm64.stddev | tostring)), 
     ((.value.amd64.avg | tostring) + "±" + (.value.amd64.stddev | tostring)), 
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