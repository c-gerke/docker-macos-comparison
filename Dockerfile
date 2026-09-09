FROM ubuntu:26.04@sha256:513c074113a871b51a8d16ab445c88779d6452d937a164fb5cc479f32668a41d

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