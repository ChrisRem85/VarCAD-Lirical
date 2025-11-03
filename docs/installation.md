# Installation Guide

Complete setup instructions for VarCAD-Lirical on different platforms.

## System Requirements

### Development Environment (Windows)
- **Windows 11** with WSL2 enabled
- **Docker Desktop** for Windows
- **WSL2 Ubuntu** distribution
- **Git** for version control

### Production Environment (Linux)
- **Ubuntu 20.04+** or compatible Linux distribution
- **Docker Engine** or Docker Desktop
- **Bash** shell environment
- **Java 11+** runtime (Java 17 recommended)

### Hardware Requirements
- **CPU**: Multi-core processor (4+ cores recommended)
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 25GB+ free space
  - ~1GB for application and container
  - ~6GB for LIRICAL databases (hg38)
  - ~22GB for Exomiser databases (optional, for VCF analysis)

## Platform-Specific Setup

### Windows 11 with WSL2

#### 1. Install WSL2 and Ubuntu
```powershell
# Enable WSL2 (run as Administrator)
wsl --install -d Ubuntu-24.04

# Restart computer when prompted
```

#### 2. Install Docker Desktop
1. Download from [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)
2. Install and enable WSL2 integration
3. Configure Docker to use WSL2 backend

#### 3. Setup in WSL2
```bash
# Open Ubuntu WSL2 terminal
cd /mnt/c/Users/<USERNAME>/Documents

# Clone repository
git clone https://github.com/ChrisRem85/VarCAD-Lirical.git
cd VarCAD-Lirical

# Make scripts executable
chmod +x scripts/*.sh

# Complete setup
./scripts/setup_lirical.sh all
```

### Ubuntu Linux (Native)

#### 1. Install Docker
```bash
# Install Docker Engine
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Test Docker installation
docker run hello-world
```

#### 2. Install Java (if not present)
```bash
# Install Java 17 (recommended)
sudo apt update
sudo apt install openjdk-17-jdk

# Verify installation
java -version
```

#### 3. Setup VarCAD-Lirical
```bash
# Clone repository
git clone https://github.com/ChrisRem85/VarCAD-Lirical.git
cd VarCAD-Lirical

# Complete setup
./scripts/setup_lirical.sh all
```

## Setup Process Details

### Automatic Setup (Recommended)
```bash
# Complete end-to-end setup
./scripts/setup_lirical.sh all

# This performs:
# 1. Downloads LIRICAL distribution
# 2. Downloads/builds hg38 databases
# 3. Sets up directory structure
# 4. Validates installation
```

### Manual Setup Steps

#### 1. Download LIRICAL
```bash
./scripts/setup_lirical.sh download
```

#### 2. Build Databases
```bash
# For phenotype-only analysis (required)
./scripts/setup_lirical.sh build-db

# For VCF analysis (optional, large download)
./scripts/build_databases.sh --exomiser
```

#### 3. Docker Setup (Optional)
```bash
# Build Docker image
./scripts/setup_lirical.sh docker-build

# Test Docker execution
./scripts/run_lirical.sh --docker prioritize --observed HP:0001156 -o test -n test
```

## Verification

### Test Installation
```bash
# Run comprehensive test suite
./scripts/test_lirical.sh

# Expected tests:
# Test 1-6: Core functionality
# Test 7-9: Docker integration (if Docker available)
```

### Verify Components
```bash
# Check LIRICAL installation
ls -la resources/lirical-cli-*/

# Check databases
ls -la resources/data/

# Check examples structure
ls -la examples/
```

### Quick Analysis Test
```bash
# Basic phenotype analysis
./scripts/run_lirical.sh prioritize \
  --observed HP:0001156,HP:0001382 \
  --age P5Y \
  --sex FEMALE \
  -o installation_test \
  -n installation_test

# Check results
ls -la examples/outputs/installation_test/
open examples/outputs/installation_test/lirical.html
```

## Directory Structure After Installation

```
VarCAD-Lirical/
├── resources/
│   ├── lirical-cli-2.2.0/           # LIRICAL application (auto-downloaded)
│   │   ├── lib/
│   │   └── lirical-cli-2.2.0.jar
│   └── data/                        # Database files (auto-built)
│       ├── 2019-06-17_hpo.obo
│       ├── Homo_sapiens_gene_info.gz
│       ├── mim2gene_medgen
│       └── phenotype.hpoa
├── examples/
│   ├── inputs/                      # Input files for testing
│   │   ├── official_examples/       # LDS2 examples
│   │   └── documentation/           # Command examples
│   └── outputs/                     # Analysis results
└── docs/                           # Documentation files
```

## Troubleshooting Installation

### Common Issues

#### WSL2 Docker Connection
```bash
# If Docker commands fail in WSL2
# Ensure Docker Desktop is running
# Check WSL2 integration settings in Docker Desktop
```

#### Permission Issues
```bash
# Fix script permissions
chmod +x scripts/*.sh

# Fix Docker permissions (Linux)
sudo usermod -aG docker $USER
newgrp docker
```

#### Java Version Issues
```bash
# Check Java version
java -version

# Install correct Java version
sudo apt install openjdk-17-jdk
```

#### Download Failures
```bash
# Retry with verbose output
./scripts/setup_lirical.sh download --verbose

# Manual download if needed
# Check firewall/proxy settings
```

### Getting Help

If you encounter issues:

1. **Check Requirements**: Verify all system requirements are met
2. **Review Logs**: Check script output for error messages
3. **Test Components**: Run individual setup steps to isolate issues
4. **Consult Documentation**: See [troubleshooting.md](troubleshooting.md) for detailed solutions
5. **Report Issues**: Create GitHub issue with system details and error logs

## Next Steps

After successful installation:

1. **Review Examples**: See [usage-examples.md](usage-examples.md)
2. **Learn Commands**: See [commands.md](commands.md)
3. **Run Analysis**: Follow Quick Start in main README
4. **Configure Docker**: See [docker.md](docker.md) for containerized workflows