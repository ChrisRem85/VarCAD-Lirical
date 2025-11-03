# Docker Guide

Complete guide for containerized execution of VarCAD-Lirical.

## Overview

VarCAD-Lirical provides Docker integration for:
- **Consistent execution environments** across platforms
- **Isolated analysis** without affecting host system
- **Production deployment** on HPC and cloud systems
- **Reproducible results** across different machines

## Docker Architecture

### Image Details
- **Base**: Ubuntu 24.04 LTS
- **Java**: OpenJDK 17
- **Size**: ~1GB (without databases)
- **Name**: `varcad-lirical:latest`

### Volume Mounts
```
Host                          Container
examples/inputs/         →    /app/examples/inputs/     (read-only)
examples/outputs/        →    /app/examples/outputs/    (read-write)
```

## Quick Start

### 1. Build Docker Image
```bash
# Build image with all dependencies
./scripts/setup_lirical.sh docker-build

# Verify image exists
./scripts/setup_lirical.sh docker-status
```

### 2. Run Containerized Analysis
```bash
# Basic analysis in container
./scripts/run_lirical.sh --docker prioritize \
  --observed HP:0001156,HP:0001382 \
  --age P5Y \
  --sex FEMALE \
  -o docker_test \
  -n docker_patient

# Results appear in examples/outputs/docker_test/
```

## Container Management

### Building Images
```bash
# Standard build
./scripts/setup_lirical.sh docker-build

# Rebuild from scratch (no cache)
./scripts/setup_lirical.sh docker-build --no-cache

# Build with specific tag
docker build -t varcad-lirical:v2.2.0 .
```

### Container Status
```bash
# Check all container/image status
./scripts/setup_lirical.sh docker-status

# Manual Docker commands
docker ps -a                          # All containers
docker images | grep varcad-lirical   # Images
```

### Viewing Logs
```bash
# View container logs
./scripts/setup_lirical.sh docker-logs

# Follow logs in real-time
docker logs -f varcad-lirical-container
```

### Cleanup
```bash
# Clean all VarCAD-Lirical containers and images
./scripts/setup_lirical.sh docker-clean

# Manual cleanup
docker container prune -f    # Remove stopped containers
docker image prune -f        # Remove unused images
```

## Advanced Usage

### Custom Docker Commands

#### Interactive Container Shell
```bash
# Start interactive container
docker run -it --rm \
  -v "$(pwd)/examples/inputs:/app/examples/inputs:ro" \
  -v "$(pwd)/examples/outputs:/app/examples/outputs" \
  varcad-lirical:latest bash

# Inside container
./scripts/run_lirical.sh prioritize --observed HP:0001156 -o test -n test
```

#### Batch Processing
```bash
# Process multiple analyses in single container
docker run --rm \
  -v "$(pwd)/examples/inputs:/app/examples/inputs:ro" \
  -v "$(pwd)/examples/outputs:/app/examples/outputs" \
  varcad-lirical:latest bash -c "
    ./scripts/run_lirical.sh prioritize --observed HP:0001156 -o batch1 -n patient1
    ./scripts/run_lirical.sh prioritize --observed HP:0001382 -o batch2 -n patient2
  "
```

### Resource Limits
```bash
# Limit memory and CPU usage
docker run --rm \
  --memory=4g \
  --cpus="2.0" \
  -v "$(pwd)/examples/inputs:/app/examples/inputs:ro" \
  -v "$(pwd)/examples/outputs:/app/examples/outputs" \
  varcad-lirical:latest \
  ./scripts/run_lirical.sh prioritize --observed HP:0001156 -o limited -n limited
```

## Platform-Specific Setup

### Windows with WSL2

#### Docker Desktop Configuration
1. Enable WSL2 integration in Docker Desktop settings
2. Ensure Ubuntu-24.04 is selected for integration
3. Restart Docker Desktop if needed

#### Running from WSL2
```bash
# From WSL2 Ubuntu terminal
cd /mnt/c/Users/<USERNAME>/Documents/VarCAD-Lirical

# Build and run normally
./scripts/setup_lirical.sh docker-build
./scripts/run_lirical.sh --docker prioritize --observed HP:0001156 -o test -n test
```

### Ubuntu Linux

#### Docker Engine Setup
```bash
# Install Docker Engine
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

#### Running on Ubuntu
```bash
# Standard execution
./scripts/setup_lirical.sh docker-build
./scripts/run_lirical.sh --docker prioritize --observed HP:0001156 -o test -n test
```

## Production Deployment

### HPC Clusters

#### Singularity Conversion
```bash
# Convert Docker image to Singularity
singularity build varcad-lirical.sif docker://varcad-lirical:latest

# Run with Singularity
singularity run \
  --bind examples/inputs:/app/examples/inputs \
  --bind examples/outputs:/app/examples/outputs \
  varcad-lirical.sif \
  ./scripts/run_lirical.sh prioritize --observed HP:0001156 -o test -n test
```

#### SLURM Integration
```bash
#!/bin/bash
#SBATCH --job-name=varcad-lirical
#SBATCH --time=01:00:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=2

# Load modules
module load docker

# Run analysis
docker run --rm \
  -v "${PWD}/examples/inputs:/app/examples/inputs:ro" \
  -v "${PWD}/examples/outputs:/app/examples/outputs" \
  varcad-lirical:latest \
  ./scripts/run_lirical.sh prioritize \
    --observed HP:0001156,HP:0001382 \
    --age P5Y \
    --sex FEMALE \
    -o slurm_analysis \
    -n ${SLURM_JOB_ID}
```

### Cloud Deployment

#### AWS Batch
```json
{
  "jobDefinition": {
    "jobDefinitionName": "varcad-lirical-job",
    "type": "container",
    "containerProperties": {
      "image": "varcad-lirical:latest",
      "vcpus": 2,
      "memory": 4096,
      "mountPoints": [
        {
          "sourceVolume": "inputs",
          "containerPath": "/app/examples/inputs",
          "readOnly": true
        },
        {
          "sourceVolume": "outputs", 
          "containerPath": "/app/examples/outputs"
        }
      ]
    }
  }
}
```

#### Docker Compose
```yaml
version: '3.8'
services:
  varcad-lirical:
    image: varcad-lirical:latest
    volumes:
      - ./examples/inputs:/app/examples/inputs:ro
      - ./examples/outputs:/app/examples/outputs
    command: >
      ./scripts/run_lirical.sh prioritize
        --observed HP:0001156,HP:0001382
        --age P5Y
        --sex FEMALE
        -o compose_analysis
        -n compose_patient
```

## Security Considerations

### User Permissions
```bash
# Run container as non-root user
docker run --rm \
  --user $(id -u):$(id -g) \
  -v "$(pwd)/examples/inputs:/app/examples/inputs:ro" \
  -v "$(pwd)/examples/outputs:/app/examples/outputs" \
  varcad-lirical:latest \
  ./scripts/run_lirical.sh prioritize --observed HP:0001156 -o secure -n secure
```

### Network Security
```bash
# Disable networking (for isolated analysis)
docker run --rm \
  --network none \
  -v "$(pwd)/examples/inputs:/app/examples/inputs:ro" \
  -v "$(pwd)/examples/outputs:/app/examples/outputs" \
  varcad-lirical:latest \
  ./scripts/run_lirical.sh prioritize --observed HP:0001156 -o isolated -n isolated
```

## Troubleshooting

### Common Issues

#### Docker Build Failures
```bash
# Clear build cache
docker builder prune -a

# Build with verbose output
docker build --progress=plain -t varcad-lirical:latest .

# Check Dockerfile syntax
docker build --dry-run .
```

#### Permission Errors
```bash
# Fix file permissions
sudo chown -R $USER:$USER examples/

# Run with correct user
docker run --user $(id -u):$(id -g) ...
```

#### Volume Mount Issues
```bash
# Verify paths exist
ls -la examples/inputs/
ls -la examples/outputs/

# Use absolute paths
docker run -v "/absolute/path/to/inputs:/app/examples/inputs:ro" ...
```

#### Memory Issues
```bash
# Increase Docker memory limit in Docker Desktop
# Or use resource limits
docker run --memory=8g ...
```

### Debugging

#### Container Inspection
```bash
# Inspect container configuration
docker inspect varcad-lirical:latest

# Check running processes
docker exec varcad-lirical-container ps aux

# View filesystem
docker exec varcad-lirical-container ls -la /app/
```

#### Log Analysis
```bash
# Container logs
./scripts/setup_lirical.sh docker-logs

# Build logs
docker build --progress=plain . 2>&1 | tee build.log

# Runtime debugging
docker run -it --rm varcad-lirical:latest bash
```

## Performance Optimization

### Image Size Reduction
```dockerfile
# Multi-stage build example
FROM ubuntu:24.04 as builder
# Build dependencies
...

FROM ubuntu:24.04 as runtime
# Only runtime dependencies
COPY --from=builder /app /app
```

### Caching Strategies
```bash
# Pre-pull base images
docker pull ubuntu:24.04

# Use BuildKit for better caching
export DOCKER_BUILDKIT=1
docker build -t varcad-lirical:latest .
```

### Resource Management
```bash
# Monitor resource usage
docker stats varcad-lirical-container

# Optimize for available resources
docker run --cpus="$(nproc)" --memory="$(free -m | awk 'NR==2{printf "%.0f", $7*0.8}')m" ...
```

## Next Steps

- **Installation**: See [installation.md](installation.md) for Docker setup
- **Commands**: See [commands.md](commands.md) for Docker command details  
- **Examples**: See [usage-examples.md](usage-examples.md) for Docker analysis examples
- **Troubleshooting**: See [troubleshooting.md](troubleshooting.md) for Docker-specific issues