# VarCAD-Lirical Docker Image
# Base: Ubuntu 24.04 LTS with Java runtime for LIRICAL

FROM ubuntu:24.04

# Metadata
LABEL maintainer="ChrisRem85"
LABEL description="Docker image for running LIRICAL (LIkelihood Ratio Interpretation of Clinical AbnormaLities)"
LABEL version="1.0"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV LIRICAL_HOME=/opt/lirical
ENV PATH=$PATH:$LIRICAL_HOME/bin

# Install system dependencies
RUN apt-get update && apt-get install -y \
    openjdk-17-jre-headless \
    wget \
    curl \
    unzip \
    bash \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create application directories
RUN mkdir -p $LIRICAL_HOME \
    && mkdir -p /app/resources \
    && mkdir -p /app/examples/inputs \
    && mkdir -p /app/examples/outputs \
    && mkdir -p /app/scripts

# Set working directory
WORKDIR /app

# Copy bash scripts
COPY scripts/ /app/scripts/
RUN chmod +x /app/scripts/*.sh

# Copy resources (LIRICAL distribution and databases)
# Note: Resources directory should be populated before building the image
COPY resources/ /app/resources/

# Setup LIRICAL
RUN if [ -f /app/resources/lirical-cli-*-distribution.zip ]; then \
        cd /app/resources && \
        unzip -o -q lirical-cli-*-distribution.zip && \
        cp -r lirical-cli-*/* $LIRICAL_HOME/ && \
        echo "LIRICAL installed from ZIP distribution"; \
    elif [ -d /app/resources/lirical-cli-* ]; then \
        cd /app/resources && \
        cp -r lirical-cli-*/* $LIRICAL_HOME/ && \
        echo "LIRICAL installed from extracted directory"; \
    else \
        echo "WARNING: LIRICAL distribution not found in resources/"; \
    fi

# Create symbolic link for easier access
RUN if [ -f $LIRICAL_HOME/bin/lirical.sh ]; then \
        ln -sf $LIRICAL_HOME/bin/lirical.sh /usr/local/bin/lirical; \
    fi

# Set up volumes for input/output
VOLUME ["/app/examples/inputs", "/app/examples/outputs"]

# Default command
CMD ["/app/scripts/run_lirical.sh", "--help"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD java -version || exit 1