#!/bin/bash

# VarCAD-Lirical: Exomiser Database Download Helper
# This script helps download Exomiser databases for genomic analysis

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
RESOURCES_DIR="$APP_DIR/resources"

# Exomiser configuration
EXOMISER_DATA_VERSION="${EXOMISER_DATA_VERSION:-2508}"
EXOMISER_BASE_URL="https://github.com/exomiser/Exomiser/releases/download"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
VarCAD-Lirical Exomiser Database Download Helper

Usage: $0 [OPTIONS]

Options:
    --version VER       Exomiser data release version (default: $EXOMISER_DATA_VERSION)
    --assembly ASM      Genome assembly (hg19|hg38, default: hg38)
    --data-dir DIR      Target directory (default: $RESOURCES_DIR/data)
    --help              Show this help message

This script helps download Exomiser databases required for genomic analysis.

Requirements:
    - wget or curl for downloading
    - unzip for extraction
    - ~4-6GB free disk space

Examples:
    $0                              # Download hg38 databases for v$EXOMISER_DATA_VERSION
    $0 --version 2406 --assembly hg38     # Download specific version
    $0 --assembly hg19              # Download hg19 databases

Note: 
    - For phenotype-only analysis, Exomiser databases are NOT required
    - LIRICAL v2.1.0+ requires Exomiser 14.0.0+ compatible databases (2406+)
    - Manual download from GitHub may be required if automated download fails

Manual Download Instructions:
    1. Visit: https://github.com/exomiser/Exomiser/discussions/categories/data-release
    2. Download: ${EXOMISER_DATA_VERSION}_hg38.zip
    3. Extract to: $RESOURCES_DIR/data/

EOF
}

# Function to check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check for download utilities
    if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
        log_error "Neither wget nor curl found. Please install one of them."
        exit 1
    fi
    
    # Check for unzip
    if ! command -v unzip &> /dev/null; then
        log_error "unzip not found. Please install unzip utility."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Function to download Exomiser databases
download_exomiser_databases() {
    local version="$1"
    local assembly="$2"
    local data_dir="$3"
    
    log_info "Downloading Exomiser databases..."
    log_info "Version: $version"
    log_info "Assembly: $assembly"
    log_info "Target directory: $data_dir"
    
    mkdir -p "$data_dir"
    
    local filename="${version}_${assembly}.zip"
    local download_url="$EXOMISER_BASE_URL/v${version}/$filename"
    local target_file="$data_dir/$filename"
    
    log_info "Download URL: $download_url"
    log_warn "This download is ~4-6GB and may take significant time"
    
    # Try to download
    if command -v wget &> /dev/null; then
        log_info "Downloading with wget..."
        if wget -O "$target_file" "$download_url"; then
            log_success "Download completed: $target_file"
        else
            log_error "Download failed with wget"
            return 1
        fi
    elif command -v curl &> /dev/null; then
        log_info "Downloading with curl..."
        if curl -L -o "$target_file" "$download_url"; then
            log_success "Download completed: $target_file"
        else
            log_error "Download failed with curl"
            return 1
        fi
    fi
    
    # Extract the archive
    log_info "Extracting database files..."
    if unzip -q "$target_file" -d "$data_dir"; then
        log_success "Extraction completed"
        
        # List extracted files
        log_info "Extracted files:"
        find "$data_dir" -name "*${version}*" -type f | head -10
        
        # Clean up zip file
        rm "$target_file"
        log_info "Removed temporary archive: $target_file"
        
    else
        log_error "Extraction failed"
        return 1
    fi
}

# Function to provide manual download instructions
show_manual_instructions() {
    local version="$1"
    local assembly="$2"
    
    cat << EOF

${YELLOW}Automated download failed. Please download manually:${NC}

1. Visit: https://github.com/exomiser/Exomiser/discussions/categories/data-release
2. Find the ${version} data release discussion
3. Download: ${version}_${assembly}.zip
4. Extract to: $RESOURCES_DIR/data/
5. Verify files:
   - ${version}_${assembly}_variants.mv.db
   - ${version}_${assembly}_clinvar.mv.db

Required files for LIRICAL genomic analysis:
- ${version}_${assembly}_variants.mv.db  (variant annotations)
- ${version}_${assembly}_clinvar.mv.db   (ClinVar pathogenicity data)

EOF
}

# Main execution
main() {
    local version="$EXOMISER_DATA_VERSION"
    local assembly="hg38"
    local data_dir="$RESOURCES_DIR/data"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --version)
                version="$2"
                shift 2
                ;;
            --assembly)
                assembly="$2"
                shift 2
                ;;
            --data-dir)
                data_dir="$2"
                shift 2
                ;;
            --help|-h|help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Validate assembly
    if [[ "$assembly" != "hg19" && "$assembly" != "hg38" ]]; then
        log_error "Invalid assembly: $assembly (must be hg19 or hg38)"
        exit 1
    fi
    
    log_info "Exomiser Database Download Helper"
    log_info "Version: $version, Assembly: $assembly"
    echo
    
    check_prerequisites
    
    # Attempt download
    if download_exomiser_databases "$version" "$assembly" "$data_dir"; then
        log_success "Exomiser database setup completed successfully!"
        echo
        log_info "You can now run genomic analysis with VCF files using:"
        log_info "  --assembly $assembly"
        log_info "  --vcf your_variants.vcf"
    else
        log_warn "Automated download failed"
        show_manual_instructions "$version" "$assembly"
        exit 1
    fi
}

# Execute main function with all arguments
main "$@"