#!/bin/bash

# VarCAD-Lirical: Database Build Script
# This script builds the required LIRICAL databases for hg38 genome assembly

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
LIRICAL_HOME="${LIRICAL_HOME:-/opt/lirical}"
LIRICAL_JAR="$LIRICAL_HOME/lib/lirical-cli.jar"
RESOURCES_DIR="$APP_DIR/resources"

# Default data directory
DEFAULT_DATA_DIR="$RESOURCES_DIR/data"
DATA_DIR="${1:-$DEFAULT_DATA_DIR}"

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
VarCAD-Lirical Database Builder

Usage: $0 [DATA_DIR]

Arguments:
    DATA_DIR    Directory to store database files (default: $DEFAULT_DATA_DIR)

This script builds the required LIRICAL databases for hg38 genome assembly:
- Downloads Exomiser database files
- Downloads HPO (Human Phenotype Ontology) files
- Downloads additional required resources
- Configures databases for hg38 assembly

The process may take several hours and requires:
- Significant disk space (~4-6 GB)
- Stable internet connection
- Java 11+ runtime

Examples:
    $0                              # Use default data directory
    $0 /path/to/custom/data/dir     # Use custom data directory

EOF
}

# Function to check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites for database build..."
    
    # Check if LIRICAL JAR exists
    if [[ ! -f "$LIRICAL_JAR" ]]; then
        log_error "LIRICAL JAR not found at: $LIRICAL_JAR"
        log_error "Please ensure LIRICAL is properly installed"
        exit 1
    fi
    
    # Check Java version
    if ! java -version &>/dev/null; then
        log_error "Java not found. Please ensure Java 11+ is installed"
        exit 1
    fi
    
    local java_version
    java_version=$(java -version 2>&1 | head -n1 | cut -d'"' -f2 | cut -d'.' -f1)
    if [[ "$java_version" -lt 11 ]]; then
        log_error "Java 11 or higher is required. Found version: $java_version"
        exit 1
    fi
    
    # Check available disk space
    local available_space
    if command -v df &>/dev/null; then
        available_space=$(df -BG "$(dirname "$DATA_DIR")" | tail -1 | awk '{print $4}' | sed 's/G//')
        if [[ "$available_space" -lt 10 ]]; then
            log_warn "Low disk space detected: ${available_space}GB available"
            log_warn "Database build requires approximately 6GB of free space"
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Database build cancelled"
                exit 0
            fi
        fi
    fi
    
    log_success "Prerequisites check passed"
}

# Function to create data directory structure
setup_data_directory() {
    log_info "Setting up data directory structure..."
    
    mkdir -p "$DATA_DIR"
    
    # Create subdirectories for organized storage
    local subdirs=(
        "$DATA_DIR/exomiser"
        "$DATA_DIR/hpo"
        "$DATA_DIR/phenotype"
        "$DATA_DIR/disease"
        "$DATA_DIR/genome"
    )
    
    for dir in "${subdirs[@]}"; do
        mkdir -p "$dir"
        log_info "Created directory: $dir"
    done
    
    log_success "Data directory structure created: $DATA_DIR"
}

# Function to download core database files
download_core_databases() {
    log_info "Downloading core LIRICAL database files for hg38..."
    log_info "This process may take 30-60 minutes depending on your internet connection"
    
    local cmd=(java -jar "$LIRICAL_JAR")
    cmd+=(download)
    cmd+=(-d "$DATA_DIR")
    cmd+=(--assembly hg38)
    cmd+=(--overwrite)
    
    log_info "Executing: ${cmd[*]}"
    
    # Create a log file for the download process
    local log_file="$DATA_DIR/download.log"
    
    if "${cmd[@]}" 2>&1 | tee "$log_file"; then
        log_success "Core database download completed"
    else
        log_error "Core database download failed"
        log_error "Check log file: $log_file"
        exit 1
    fi
}

# Function to verify database integrity
verify_databases() {
    log_info "Verifying database integrity..."
    
    # List of expected files/directories after download
    local expected_files=(
        "$DATA_DIR"
    )
    
    local missing_files=()
    
    for file in "${expected_files[@]}"; do
        if [[ ! -e "$file" ]]; then
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        log_warn "Some expected files/directories are missing:"
        for file in "${missing_files[@]}"; do
            log_warn "  - $file"
        done
    fi
    
    # Check data directory size
    if command -v du &>/dev/null; then
        local data_size
        data_size=$(du -sh "$DATA_DIR" | cut -f1)
        log_info "Total database size: $data_size"
        
        # Expect at least 2GB of data
        local size_gb
        size_gb=$(du -sg "$DATA_DIR" | cut -f1)
        if [[ "$size_gb" -lt 2 ]]; then
            log_warn "Database size seems small ($data_size). Build may be incomplete."
        else
            log_success "Database size looks reasonable: $data_size"
        fi
    fi
    
    log_success "Database verification completed"
}

# Function to create database summary
create_database_summary() {
    log_info "Creating database summary..."
    
    local summary_file="$DATA_DIR/database_info.txt"
    
    cat > "$summary_file" << EOF
VarCAD-Lirical Database Build Summary
=====================================

Build Date: $(date)
Genome Assembly: hg38
LIRICAL JAR: $LIRICAL_JAR
Data Directory: $DATA_DIR

Database Components:
- Exomiser databases for variant annotation
- HPO (Human Phenotype Ontology) files
- Disease-gene associations
- Population frequency data
- Pathogenicity prediction databases

Usage:
To use these databases with LIRICAL, specify the data directory:
--exomiser-data-directory "$DATA_DIR"

For more information, see:
https://thejacksonlaboratory.github.io/LIRICAL/stable/

EOF
    
    # Add directory listing
    echo "" >> "$summary_file"
    echo "Directory Structure:" >> "$summary_file"
    echo "===================" >> "$summary_file"
    
    if command -v tree &>/dev/null; then
        tree -L 2 "$DATA_DIR" >> "$summary_file" 2>/dev/null || ls -la "$DATA_DIR" >> "$summary_file"
    else
        ls -la "$DATA_DIR" >> "$summary_file"
    fi
    
    # Add size information
    echo "" >> "$summary_file"
    echo "Size Information:" >> "$summary_file"
    echo "=================" >> "$summary_file"
    
    if command -v du &>/dev/null; then
        du -sh "$DATA_DIR"/* >> "$summary_file" 2>/dev/null || echo "Size calculation failed" >> "$summary_file"
    fi
    
    log_success "Database summary created: $summary_file"
}

# Function to set proper permissions
set_permissions() {
    log_info "Setting proper permissions..."
    
    # Make sure the data directory is readable
    chmod -R u+rw "$DATA_DIR"
    
    # Make databases readable by group if running in multi-user environment
    if [[ -w "$DATA_DIR" ]]; then
        chmod -R g+r "$DATA_DIR" 2>/dev/null || true
    fi
    
    log_success "Permissions set"
}

# Function to run complete database build
run_complete_build() {
    log_info "Starting complete LIRICAL database build for hg38..."
    log_info "Target directory: $DATA_DIR"
    
    local start_time=$(date +%s)
    
    check_prerequisites
    setup_data_directory
    download_core_databases
    verify_databases
    create_database_summary
    set_permissions
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local hours=$((duration / 3600))
    local minutes=$(((duration % 3600) / 60))
    
    log_success "Database build completed successfully!"
    log_info "Build time: ${hours}h ${minutes}m"
    log_info "Database location: $DATA_DIR"
    log_info "Summary file: $DATA_DIR/database_info.txt"
    
    echo
    log_info "You can now run LIRICAL analysis with:"
    log_info "./scripts/run_lirical.sh prioritize --observed HP:0001156 -o test_output --data-dir \"$DATA_DIR\""
}

# Main function
main() {
    case "${1:-build}" in
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            run_complete_build
            ;;
    esac
}

# Run main function
main "$@"