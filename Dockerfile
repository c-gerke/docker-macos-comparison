FROM ubuntu:26.04@sha256:3131b4cc82a783df6c9df078f86e01819a13594b865c2cad47bd1bca2b7063bb

# Install necessary tools
RUN apt-get update && apt-get install -y \
    time \
    gzip \
    bzip2 \
    xz-utils \
    pv \
    openssl \
    python3 \
    python3-pip \
    python3-numpy \
    netcat-openbsd \
    jq \
    bc \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip3 install --break-system-packages numpy matplotlib

# Create a directory for our benchmark scripts
WORKDIR /benchmark

# Copy the benchmark script
COPY benchmark.sh /benchmark/

# Make the script executable
RUN chmod +x /benchmark/benchmark.sh

# Set the entrypoint
ENTRYPOINT ["/benchmark/benchmark.sh"] 