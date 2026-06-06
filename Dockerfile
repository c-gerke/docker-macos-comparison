FROM ubuntu:26.04@sha256:f3d28607ddd78734bb7f71f117f3c6706c666b8b76cbff7c9ff6e5718d46ff64

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