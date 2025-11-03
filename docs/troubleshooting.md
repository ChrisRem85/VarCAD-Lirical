# Troubleshooting Guide

Common issues and solutions for VarCAD-Lirical.

## Installation Issues

### Java Not Found
```
Error: Java not found. Please ensure Java 11+ is installed
```

**Solution:**
```bash
# Check Java version
java -version

# Install Java 17 (Ubuntu/WSL)
sudo apt update
sudo apt install openjdk-17-jdk

# Set JAVA_HOME (if needed)
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
```

### Docker Installation Issues

#### Docker Not Found (Windows)
```
Error: Docker is not installed or not in PATH
```

**Solution:**
1. Install Docker Desktop for Windows
2. Enable WSL2 integration in Docker Desktop settings
3. Restart Docker Desktop
4. Verify in WSL2: `docker --version`

#### Docker Permission Denied (Linux)
```
Error: permission denied while trying to connect to Docker daemon
```

**Solution:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and log back in, or run:
newgrp docker

# Test access
docker ps
```

### Download Failures

#### Network/Firewall Issues
```
Error: Failed to download LIRICAL distribution
```

**Solutions:**
```bash
# Check network connectivity
curl -I https://github.com/TheJacksonLaboratory/LIRICAL/releases

# Configure proxy (if needed)
export https_proxy=http://proxy.company.com:8080

# Manual download if automatic fails
wget https://github.com/TheJacksonLaboratory/LIRICAL/releases/download/v2.2.0/lirical-cli-2.2.0-distribution.zip
```

#### Insufficient Disk Space
```
Error: No space left on device
```

**Solution:**
```bash
# Check available space
df -h

# Clean up space
docker system prune -a    # Remove unused Docker data
rm -rf /tmp/*            # Clear temporary files

# Move to different partition if needed
export LIRICAL_DATA_DIR=/path/to/larger/partition
```

## Runtime Issues

### Analysis Execution Failures

#### Invalid HPO Terms
```
Error: Invalid HPO term format: HP:0001
```

**Solution:**
```bash
# HPO terms must be 7-digit format
# Incorrect: HP:0001
# Correct: HP:0001156

# Verify HPO terms at: http://www.human-phenotype-ontology.org/
```

#### Missing Database Files
```
Error: LIRICAL JAR not found at: resources/lirical-cli-2.2.0/lirical-cli-2.2.0.jar
```

**Solution:**
```bash
# Complete setup process
./scripts/setup_lirical.sh all

# Or manual steps
./scripts/setup_lirical.sh download
./scripts/setup_lirical.sh build-db
```

#### VCF File Issues
```
Error: VCF file not found: examples/inputs/patient.vcf
```

**Solution:**
```bash
# Ensure VCF file is in correct location
ls examples/inputs/

# Check file permissions
chmod 644 examples/inputs/patient.vcf

# Verify VCF format
head examples/inputs/patient.vcf
```

### Memory Issues

#### Java Out of Memory
```
Error: java.lang.OutOfMemoryError: Java heap space
```

**Solution:**
```bash
# Increase Java memory
export JAVA_OPTS="-Xmx8g"
./scripts/run_lirical.sh prioritize ...

# For Docker
docker run --memory=8g varcad-lirical:latest ...
```

#### System Memory Issues
```
Error: Cannot allocate memory
```

**Solution:**
```bash
# Check available memory
free -h

# Close other applications
# Use smaller datasets for testing
# Consider using swap space

# Add swap space (Linux)
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## Docker-Specific Issues

### Build Failures

#### Docker Build Context Too Large
```
Error: build context too large
```

**Solution:**
```bash
# Check .dockerignore file exists
ls -la .dockerignore

# Exclude large directories
echo "examples/" >> .dockerignore
echo "resources/" >> .dockerignore

# Clean build context
docker builder prune -a
```

#### Base Image Pull Failures
```
Error: failed to pull image ubuntu:24.04
```

**Solution:**
```bash
# Test Docker connectivity
docker run hello-world

# Try different registry
docker pull docker.io/ubuntu:24.04

# Use cached image if available
docker images | grep ubuntu
```

### Runtime Issues

#### Volume Mount Problems
```
Error: volume mount failed
```

**Solution (Windows WSL2):**
```bash
# Use WSL2 paths, not Windows paths
# Incorrect: /mnt/c/Users/username/...
# Correct: /home/username/... or $(pwd)

# Fix permissions
sudo chown -R $USER:$USER examples/
```

**Solution (Linux):**
```bash
# Use absolute paths
docker run -v "$(pwd)/examples/inputs:/app/examples/inputs:ro" ...

# Check SELinux context (if applicable)
ls -Z examples/
```

#### Container Networking Issues
```
Error: container cannot resolve DNS
```

**Solution:**
```bash
# Check Docker daemon DNS
docker run --rm alpine nslookup google.com

# Configure DNS (if needed)
echo '{"dns": ["8.8.8.8", "8.8.4.4"]}' | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker
```

## Performance Issues

### Slow Analysis
- **Large VCF files**: Consider filtering variants first
- **Many phenotype terms**: This is expected for comprehensive analysis
- **System resources**: Ensure adequate CPU/memory available

**Optimization:**
```bash
# Use parallel processing for batch analyses
for patient in patient_001 patient_002; do
  ./scripts/run_lirical.sh prioritize --observed HP:0001156 -o ${patient} -n ${patient} &
done
wait

# Optimize Java settings
export JAVA_OPTS="-Xmx4g -XX:+UseG1GC -XX:MaxGCPauseMillis=200"
```

### Disk I/O Issues
```bash
# Monitor disk usage during analysis
iostat -x 1

# Use faster storage for temporary files
export TMPDIR=/path/to/fast/storage

# Consider SSD for database files
```

## File Permission Issues

### Script Execution Permissions
```
Error: Permission denied: ./scripts/run_lirical.sh
```

**Solution:**
```bash
# Fix script permissions
chmod +x scripts/*.sh

# Verify permissions
ls -la scripts/
```

### Output Directory Permissions
```
Error: cannot create directory 'examples/outputs/analysis'
```

**Solution:**
```bash
# Fix directory permissions
chmod 755 examples/
chmod 755 examples/outputs/

# Create directory manually if needed
mkdir -p examples/outputs/analysis
```

## Platform-Specific Issues

### Windows WSL2 Issues

#### Line Ending Problems
```
Error: $'\r': command not found
```

**Solution:**
```bash
# Convert line endings
dos2unix scripts/*.sh

# Configure Git to handle line endings
git config core.autocrlf input
```

#### Path Translation Issues
```bash
# Use WSL2 paths consistently
cd /mnt/c/Users/<username>/Documents/VarCAD-Lirical
# Not: cd C:\Users\<username>\Documents\VarCAD-Lirical
```

### Ubuntu Specific

#### Package Dependencies
```bash
# Install required packages
sudo apt update
sudo apt install wget unzip curl default-jdk

# For building from source
sudo apt install build-essential
```

## Database Issues

### Corrupted Database Files
```
Error: Database file appears to be corrupted
```

**Solution:**
```bash
# Rebuild databases
rm -rf resources/data/
./scripts/setup_lirical.sh build-db

# Or download fresh copy
./scripts/setup_lirical.sh download
```

### Database Version Mismatches
```
Error: Database version incompatible with LIRICAL 2.2.0
```

**Solution:**
```bash
# Update to matching database version
./scripts/build_databases.sh --data-version 2508

# Or use compatible LIRICAL version
```

## Testing and Validation

### Test Suite Failures

#### Individual Test Debugging
```bash
# Run single test manually
./scripts/run_lirical.sh prioritize \
  --observed HP:0001156,HP:0001382 \
  --age P5Y \
  --sex FEMALE \
  -o debug_test \
  -n debug_test

# Check specific output
ls -la examples/outputs/debug_test/
cat examples/outputs/debug_test/lirical.html
```

#### Docker Test Failures
```bash
# Test Docker separately
./scripts/setup_lirical.sh docker-status
./scripts/setup_lirical.sh docker-build
docker run --rm varcad-lirical:latest ./scripts/run_lirical.sh help
```

## Log Analysis

### Enabling Verbose Output
```bash
# Bash debugging
bash -x ./scripts/run_lirical.sh prioritize ...

# Java debugging
export JAVA_OPTS="-verbose:gc -XX:+PrintGCDetails"

# Docker build debugging
docker build --progress=plain --no-cache .
```

### Log Locations
- **Script output**: Console/terminal
- **Docker logs**: `./scripts/setup_lirical.sh docker-logs`
- **Java logs**: Typically in temporary directories
- **Build logs**: Docker build output

## Getting Help

### Diagnostic Information Collection
```bash
# System information
uname -a
java -version
docker --version

# VarCAD-Lirical status
ls -la resources/
ls -la examples/
./scripts/setup_lirical.sh docker-status

# Recent logs
./scripts/setup_lirical.sh docker-logs | tail -50
```

### Reporting Issues
When reporting issues, include:

1. **System details**: OS, Java version, Docker version
2. **Error messages**: Complete error text
3. **Command used**: Exact command that failed
4. **Log output**: Relevant log excerpts
5. **File structure**: Output of `ls -la` for relevant directories

### Community Resources
- **GitHub Issues**: https://github.com/ChrisRem85/VarCAD-Lirical/issues
- **LIRICAL Documentation**: https://thejacksonlaboratory.github.io/LIRICAL/stable/
- **HPO Documentation**: http://www.human-phenotype-ontology.org/

## Emergency Recovery

### Complete Reset
```bash
# Stop all Docker containers
docker stop $(docker ps -q)

# Clean all VarCAD-Lirical data
./scripts/setup_lirical.sh docker-clean
rm -rf resources/
rm -rf examples/outputs/

# Fresh installation
./scripts/setup_lirical.sh all
```

### Backup Important Data
```bash
# Before major changes
cp -r examples/outputs/ examples/outputs_backup_$(date +%Y%m%d)
cp -r resources/ resources_backup_$(date +%Y%m%d)
```

This troubleshooting guide should help resolve most common issues. For complex problems, consult the detailed documentation in other guide files or seek community support.