#!/bin/bash

# VarCAD-Lirical: Setup Script
# This script helps set up the VarCAD-Lirical environment

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
RESOURCES_DIR="$APP_DIR/resources"
EXAMPLES_DIR="$APP_DIR/examples"

# LIRICAL configuration
LIRICAL_LATEST_RELEASE="v2.2.0"
LIRICAL_DOWNLOAD_URL="https://github.com/TheJacksonLaboratory/LIRICAL/releases/download"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Function to display usage
show_usage() {
    cat << EOF
VarCAD-Lirical Setup Script

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    all           Complete setup (download LIRICAL, setup directories, download databases)
    download      Download LIRICAL distribution
    directories   Create required directories
    databases     Download LIRICAL databases
    examples      Create example files
    docker        Build Docker image
    help          Show this help message

Options:
    --version VER    LIRICAL version to download (default: $LIRICAL_LATEST_RELEASE)
    --force          Force overwrite existing files

Examples:
    $0 all
    $0 download --version v2.2.0
    $0 examples
    $0 docker

EOF
}

# Function to check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if running in WSL2
    if grep -q Microsoft /proc/version 2>/dev/null; then
        log_info "Detected WSL2 environment"
        log_info "Ensuring script permissions are correct..."
        chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true
    fi
    
    # Check for required commands
    local required_commands=("wget" "unzip" "java")
    local missing_commands=()
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_error "Missing required commands: ${missing_commands[*]}"
        if grep -q Microsoft /proc/version 2>/dev/null; then
            log_error "In WSL2, install missing packages with: sudo apt update && sudo apt install ${missing_commands[*]}"
        else
            log_error "Please install the missing commands and try again"
        fi
        exit 1
    fi
    
    # Check Java version
    local java_version
    java_version=$(java -version 2>&1 | head -n1 | cut -d'"' -f2)
    log_info "Java version: $java_version"
    
    # Check Docker availability
    if command -v docker &>/dev/null; then
        if docker info &>/dev/null; then
            log_info "Docker is available and running"
        else
            log_warn "Docker command found but daemon not accessible"
            if grep -q Microsoft /proc/version 2>/dev/null; then
                log_warn "In WSL2, ensure Docker Desktop is running on Windows"
            fi
        fi
    else
        log_warn "Docker not found - containerized features will not be available"
    fi
    
    log_success "Prerequisites check passed"
}

# Function to create directories
create_directories() {
    log_info "Creating required directories..."
    
    local directories=(
        "$RESOURCES_DIR"
        "$RESOURCES_DIR/data"
        "$EXAMPLES_DIR"
        "$EXAMPLES_DIR/inputs"
        "$EXAMPLES_DIR/outputs"
    )
    
    for dir in "${directories[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_info "Created directory: $dir"
        else
            log_info "Directory already exists: $dir"
        fi
    done
    
    log_success "Directory setup completed"
}

# Function to download LIRICAL
download_lirical() {
    local version="${1:-$LIRICAL_LATEST_RELEASE}"
    local force="${2:-false}"
    
    log_info "Downloading LIRICAL $version..."
    
    local filename="lirical-cli-${version#v}-distribution.zip"
    local download_url="$LIRICAL_DOWNLOAD_URL/$version/$filename"
    local target_file="$RESOURCES_DIR/$filename"
    
    # Check if file already exists
    if [[ -f "$target_file" && "$force" != "true" ]]; then
        log_warn "LIRICAL distribution already exists: $target_file"
        log_info "Use --force to overwrite"
        return 0
    fi
    
    log_info "Downloading from: $download_url"
    log_info "Target file: $target_file"
    
    # Download the file
    if wget -O "$target_file" "$download_url"; then
        log_success "LIRICAL distribution downloaded successfully"
        
        # Verify the file
        if [[ -f "$target_file" ]]; then
            local file_size
            file_size=$(stat -c%s "$target_file" 2>/dev/null || stat -f%z "$target_file" 2>/dev/null || echo "unknown")
            log_info "Downloaded file size: $file_size bytes"
        fi
    else
        log_error "Failed to download LIRICAL distribution"
        log_error "Please check the version number and your internet connection"
        exit 1
    fi
}

# Function to download databases
download_databases() {
    log_info "Setting up LIRICAL databases..."
    
    # First check if LIRICAL is available
    local lirical_jar
    lirical_jar=$(find "$RESOURCES_DIR" -name "lirical-cli*.jar" -type f 2>/dev/null | head -n1)
    
    if [[ -z "$lirical_jar" ]]; then
        # Try to extract from distribution zip
        local lirical_zip
        lirical_zip=$(find "$RESOURCES_DIR" -name "lirical-cli-*-distribution.zip" -type f 2>/dev/null | head -n1)
        
        if [[ -z "$lirical_zip" ]]; then
            log_error "LIRICAL distribution not found"
            log_error "Please run: $0 download"
            exit 1
        fi
        
        log_info "Extracting LIRICAL distribution..."
        cd "$RESOURCES_DIR"
        unzip -q "$lirical_zip"
        
        # Find the JAR file
        lirical_jar=$(find . -name "lirical-cli*.jar" -type f 2>/dev/null | head -n1)
        if [[ -z "$lirical_jar" ]]; then
            log_error "Could not find LIRICAL JAR file after extraction"
            exit 1
        fi
        
        lirical_jar="$RESOURCES_DIR/$lirical_jar"
    fi
    
    log_info "Using LIRICAL JAR: $lirical_jar"
    
    # Download databases
    local data_dir="$RESOURCES_DIR/data"
    mkdir -p "$data_dir"
    
    log_info "Downloading databases to: $data_dir"
    
    if java -jar "$lirical_jar" download -d "$data_dir"; then
        log_success "Database download completed successfully"
    else
        log_error "Database download failed"
        exit 1
    fi
}

# Function to create example files
create_examples() {
    log_info "Creating example files..."
    
    # Create example target diseases file
    cat > "$EXAMPLES_DIR/inputs/example_target_diseases.txt" << 'EOF'
# Example Target Diseases for LIRICAL Analysis
# This file contains candidate diseases identified from WGS/WES analysis
# Format: One OMIM ID per line

# Connective tissue disorders
OMIM:154700  # Marfan syndrome
OMIM:130050  # Ehlers-Danlos syndrome, classical type
OMIM:166200  # Osteogenesis imperfecta type I

# Skeletal dysplasias  
OMIM:100800  # Achondroplasia
OMIM:183900  # Thanatophoric dysplasia type I

# Additional candidates based on phenotype overlap
OMIM:102200  # Alagille syndrome 1
OMIM:118220  # Cornelia de Lange syndrome 1
EOF
    
    # Create example commands script
    cat > "$EXAMPLES_DIR/inputs/example_commands.sh" << 'EOF'
#!/bin/bash

# VarCAD-Lirical Example Commands
# This script demonstrates various LIRICAL analysis scenarios

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${BLUE}VarCAD-Lirical Example Commands${NC}"
echo "================================="
echo

echo -e "${GREEN}1. Basic Phenotype Analysis${NC}"
echo "Patient: 5-year-old female with brachydactyly and joint hypermobility"
echo "Command:"
echo "./scripts/run_lirical.sh prioritize \\"
echo "  --observed HP:0001156,HP:0001382 \\"
echo "  --age P5Y \\"
echo "  --sex FEMALE \\"
echo "  -o basic_analysis \\"
echo "  -n patient1"
echo

echo -e "${GREEN}2. Analysis with Negated Phenotypes${NC}"
echo "Patient: Adult male with tall stature, explicitly NO scoliosis or intellectual disability"
echo "Command:"
echo "./scripts/run_lirical.sh prioritize \\"
echo "  --observed HP:0000098 \\"
echo "  --negated HP:0002650,HP:0001249 \\"
echo "  --age adult \\"
echo "  --sex MALE \\"
echo "  -o negated_analysis \\"
echo "  -n patient2"
echo

echo -e "${GREEN}3. Target Diseases Analysis (WGS/WES)${NC}"
echo "Patient: 10-year-old female with candidate diseases from genomic analysis"
echo "Command:"
echo "./scripts/run_lirical.sh target-diseases \\"
echo "  --target-diseases example_target_diseases.txt \\"
echo "  --vcf patient_variants.vcf \\"
echo "  --observed HP:0001156,HP:0001382 \\"
echo "  --age P10Y \\"
echo "  --sex FEMALE \\"
echo "  -o genomic_analysis \\"
echo "  -n patient3"
echo

echo -e "${GREEN}Setup Commands:${NC}"
echo "# Download and setup LIRICAL"
echo "./scripts/setup.sh all"
echo
echo "# Build databases for hg38"
echo "./scripts/build_databases.sh"
echo

echo -e "${GREEN}HPO Terms Reference:${NC}"
echo "HP:0001156 - Brachydactyly (short fingers/toes)"
echo "HP:0001382 - Joint hypermobility"
echo "HP:0000098 - Tall stature"
echo "HP:0002650 - Scoliosis"
echo "HP:0001249 - Intellectual disability"
echo "HP:0000316 - Hypertelorism (widely spaced eyes)"
echo "HP:0002007 - Frontal bossing"
echo "HP:0000218 - High palate"
EOF
    
    chmod +x "$EXAMPLES_DIR/inputs/example_commands.sh"
    
    # Create README for examples
    cat > "$EXAMPLES_DIR/inputs/README.md" << 'EOF'
# Example Input Files

This directory contains example input files for testing LIRICAL CLI-based analysis.

## Files:

### example_target_diseases.txt
A sample target diseases file containing candidate diseases from WGS/WES analysis:
- OMIM:154700 (Marfan syndrome)
- OMIM:130050 (Ehlers-Danlos syndrome)
- OMIM:166200 (Osteogenesis imperfecta)

### example_commands.sh
Executable script with example LIRICAL commands demonstrating different analysis types.

## Sample Analysis Commands:

### Basic Phenotype Analysis
```bash
# Analyze patient with brachydactyly and joint hypermobility
./scripts/run_lirical.sh prioritize \
  --observed HP:0001156,HP:0001382 \
  --age P5Y \
  --sex FEMALE \
  -o basic_analysis \
  -n patient1
```

### Analysis with Negated Phenotypes
```bash
# Patient with tall stature but NO scoliosis or intellectual disability
./scripts/run_lirical.sh prioritize \
  --observed HP:0000098 \
  --negated HP:0002650,HP:0001249 \
  --age adult \
  --sex MALE \
  -o negated_analysis \
  -n patient2
```

### Target Diseases Analysis (requires VCF file)
```bash
# Analyze specific candidate diseases from genomic sequencing
./scripts/run_lirical.sh target-diseases \
  --target-diseases example_target_diseases.txt \
  --vcf patient_variants.vcf \
  --observed HP:0001156,HP:0001382 \
  --age P10Y \
  --sex FEMALE \
  -o genomic_analysis \
  -n patient3
```

## HPO Terms Reference:
- HP:0001156 - Brachydactyly (short fingers/toes)
- HP:0001382 - Joint hypermobility
- HP:0000098 - Tall stature  
- HP:0002650 - Scoliosis
- HP:0001249 - Intellectual disability
- HP:0000316 - Hypertelorism (widely spaced eyes)
- HP:0002007 - Frontal bossing
- HP:0000218 - High palate

## Age Format Examples:
- P5Y = 5 years old
- P2Y6M = 2 years 6 months old
- P6M = 6 months old
- adult = Adult age
- child = Child age

## Adding Your Own Files:

1. Place VCF files (.vcf or .vcf.gz) in this directory for genomic analysis
2. Create target disease files (.txt) with one OMIM ID per line for candidate disease analysis
3. Run analysis using the CLI commands shown above

All analyses use hg38 genome assembly by default.
EOF
    
    log_success "Example files created successfully"
}

# Function to build Docker image
build_docker() {
    log_info "Building Docker image..."
    
    cd "$APP_DIR"
    
    if [[ ! -f "Dockerfile" ]]; then
        log_error "Dockerfile not found"
        exit 1
    fi
    
    # Check if Docker is available
    if ! command -v docker &>/dev/null; then
        log_error "Docker not found. Please install Docker and try again"
        exit 1
    fi
    
    if docker build -t varcad-lirical:latest .; then
        log_success "Docker image built successfully"
    else
        log_error "Docker build failed"
        exit 1
    fi
}

# Function to run complete setup
complete_setup() {
    local version="${1:-$LIRICAL_LATEST_RELEASE}"
    local force="${2:-false}"
    
    log_info "Running complete VarCAD-Lirical setup..."
    
    check_prerequisites
    create_directories
    download_lirical "$version" "$force"
    download_databases
    create_examples
    
    log_success "Complete setup finished successfully!"
    log_info "You can now:"
    log_info "1. Run analysis: ./scripts/run_lirical.sh phenopacket -i example_phenopacket.json -o test_output -n test"
    log_info "2. Build Docker image: ./scripts/setup.sh docker"
    log_info "3. Use Docker: ./scripts/docker_helper.sh run phenopacket -i example_phenopacket.json -o test_output"
}

# Main function
main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 0
    fi
    
    local command="$1"
    shift
    
    local version="$LIRICAL_LATEST_RELEASE"
    local force="false"
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --version)
                version="$2"
                shift 2
                ;;
            --force)
                force="true"
                shift
                ;;
            *)
                break
                ;;
        esac
    done
    
    case "$command" in
        "all")
            complete_setup "$version" "$force"
            ;;
        "download")
            check_prerequisites
            create_directories
            download_lirical "$version" "$force"
            ;;
        "directories")
            create_directories
            ;;
        "databases")
            download_databases
            ;;
        "examples")
            create_directories
            create_examples
            ;;
        "docker")
            build_docker
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"