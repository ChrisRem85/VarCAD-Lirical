#!/bin/bash

# VarCAD-Lirical: Main LIRICAL Runner Script
# This script provides a convenient interface for running LIRICAL analysis using CLI prioritize command

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
LIRICAL_HOME="${LIRICAL_HOME:-/opt/lirical}"
LIRICAL_JAR="$LIRICAL_HOME/lib/lirical-cli.jar"

# Exomiser configuration - default to latest recommended version
EXOMISER_DATA_VERSION="${EXOMISER_DATA_VERSION:-2508}"

# Check if LIRICAL JAR exists in the expected location, if not, try the resources directory
if [[ ! -f "$LIRICAL_JAR" ]]; then
    # Try the resources directory structure
    LIRICAL_DIR=$(find "$APP_DIR/resources" -name "lirical-cli-*" -type d | head -n1)
    if [[ -n "$LIRICAL_DIR" ]]; then
        LIRICAL_JAR=$(find "$LIRICAL_DIR" -name "lirical-cli-*.jar" -type f | head -n1)
    fi
fi

RESOURCES_DIR="$APP_DIR/resources"
INPUTS_DIR="$APP_DIR/examples/inputs"
OUTPUTS_DIR="$APP_DIR/examples/outputs"

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

# Function to check if LIRICAL is properly installed
check_lirical_installation() {
    if [[ ! -f "$LIRICAL_JAR" ]]; then
        log_error "LIRICAL JAR not found at: $LIRICAL_JAR"
        log_error "Please ensure LIRICAL is properly installed in the resources directory"
        exit 1
    fi
    
    if ! java -version &>/dev/null; then
        log_error "Java not found. Please ensure Java 11+ is installed"
        exit 1
    fi
}

# Function to display usage information
show_usage() {
    cat << EOF
VarCAD-Lirical: LIRICAL Analysis Runner (hg38 genome assembly)

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    prioritize        Run LIRICAL prioritize analysis with HPO terms
    target-diseases   Run analysis with target diseases from WGS/WES results
    download          Download required database files
    build-db          Build LIRICAL databases for hg38
    setup             Setup LIRICAL resources and databases
    help              Show this help message

Prioritize Options:
    -o, --output          Output directory (relative to examples/outputs/)
    -n, --name            Analysis name (used for output file naming)
    --observed            Comma-separated HPO terms for observed phenotypes (e.g., HP:0001156,HP:0001382)
    --negated             Comma-separated HPO terms for negated phenotypes (optional)
    --age                 Patient age (e.g., P2Y6M for 2 years 6 months, or adult/child)
    --sex                 Patient sex (MALE/FEMALE/UNKNOWN)
    --data-dir            Path to LIRICAL data directory (default: resources/data)
    --vcf                 VCF file for genomic analysis (optional)
    --assembly            Genome assembly (default: hg38)

Target Diseases Options:
    --target-diseases     File with target disease list from WGS/WES analysis
    --vcf                 VCF file (required for target diseases analysis)
    (all other prioritize options also apply)
    
Examples:
    # Basic phenotype analysis
    $0 prioritize -o analysis1 -n patient1 --observed HP:0001156,HP:0001382 --age P5Y --sex FEMALE
    
    # Analysis with negated phenotypes
    $0 prioritize -o analysis2 -n patient2 --observed HP:0000098 --negated HP:0001382,HP:0002650 --age adult --sex MALE
    
    # Target diseases analysis with WGS results
    $0 target-diseases -o wgs_analysis -n patient3 --target-diseases candidate_diseases.txt --vcf variants.vcf --observed HP:0001156 --age P10Y --sex FEMALE
    
    # Setup commands
    $0 download
    $0 build-db
    $0 setup

For more information about LIRICAL, visit:
https://github.com/TheJacksonLaboratory/LIRICAL
https://thejacksonlaboratory.github.io/LIRICAL/stable/
EOF
}

# Function to validate HPO terms format
validate_hpo_terms() {
    local hpo_terms="$1"
    local term_type="$2"
    
    if [[ -z "$hpo_terms" ]]; then
        return 0
    fi
    
    # Split by comma and validate each term
    IFS=',' read -ra TERMS <<< "$hpo_terms"
    for term in "${TERMS[@]}"; do
        if [[ ! "$term" =~ ^HP:[0-9]{7}$ ]]; then
            log_error "Invalid HPO term format in $term_type: $term"
            log_error "HPO terms must be in format HP:XXXXXXX (e.g., HP:0001156)"
            exit 1
        fi
    done
}

# Function to run LIRICAL prioritize analysis
run_prioritize_analysis() {
    local output_dir="$1"
    local analysis_name="$2"
    local observed_phenotypes="$3"
    local negated_phenotypes="${4:-}"
    local age="${5:-}"
    local sex="${6:-}"
    local vcf_file="${7:-}"
    local data_dir="${8:-$RESOURCES_DIR/data}"
    local assembly="${9:-hg38}"
    
    local output_path="$OUTPUTS_DIR/$output_dir"
    
    # Validate HPO terms
    validate_hpo_terms "$observed_phenotypes" "observed phenotypes"
    validate_hpo_terms "$negated_phenotypes" "negated phenotypes"
    
    # Validate required parameters
    if [[ -z "$observed_phenotypes" ]]; then
        log_error "At least one observed phenotype is required"
        exit 1
    fi
    
    # Create output directory
    mkdir -p "$output_path"
    
    # Build LIRICAL command
    local cmd=(java -jar "$LIRICAL_JAR")
    cmd+=(prioritize)
    cmd+=(-d "$data_dir")
    cmd+=(-o "$output_path")
    cmd+=(-f html)
    cmd+=(-f tsv)
    cmd+=(-f json)
    
    # Add observed phenotypes
    if [[ -n "$observed_phenotypes" ]]; then
        cmd+=(-p "$observed_phenotypes")
    fi
    
    # Add negated phenotypes if provided
    if [[ -n "$negated_phenotypes" ]]; then
        cmd+=(-n "$negated_phenotypes")
    fi
    
    # Add age if provided
    if [[ -n "$age" ]]; then
        cmd+=(--age "$age")
    fi
    
    # Add sex if provided
    if [[ -n "$sex" ]]; then
        cmd+=(--sex "$sex")
    fi
    
    # Add VCF file if provided
    if [[ -n "$vcf_file" ]]; then
        local vcf_path="$INPUTS_DIR/$vcf_file"
        if [[ -f "$vcf_path" ]]; then
            cmd+=(--vcf "$vcf_path")
        else
            log_warn "VCF file not found: $vcf_path. Continuing without genomic analysis."
        fi
    fi
    
    # Add analysis name prefix
    if [[ -n "$analysis_name" ]]; then
        cmd+=(--sample-id "$analysis_name")
    fi
    
    log_info "Running LIRICAL prioritize analysis..."
    log_info "Observed phenotypes: $observed_phenotypes"
    if [[ -n "$negated_phenotypes" ]]; then
        log_info "Negated phenotypes: $negated_phenotypes"
    fi
    if [[ -n "$age" ]]; then
        log_info "Age: $age"
    fi
    if [[ -n "$sex" ]]; then
        log_info "Sex: $sex"
    fi
    log_info "Assembly: $assembly"
    log_info "Output: $output_path"
    log_info "Command: ${cmd[*]}"
    
    # Execute LIRICAL
    if "${cmd[@]}"; then
        log_success "Analysis completed successfully!"
        log_info "Results saved to: $output_path"
    else
        log_error "Analysis failed!"
        exit 1
    fi
}

# Function to run target diseases analysis
run_target_diseases_analysis() {
    local output_dir="$1"
    local analysis_name="$2"
    local target_diseases_file="$3"
    local vcf_file="$4"
    local observed_phenotypes="${5:-}"
    local negated_phenotypes="${6:-}"
    local age="${7:-}"
    local sex="${8:-}"
    local data_dir="${9:-$RESOURCES_DIR/data}"
    local assembly="${10:-hg38}"
    
    local output_path="$OUTPUTS_DIR/$output_dir"
    local target_diseases_path="$INPUTS_DIR/$target_diseases_file"
    local vcf_path="$INPUTS_DIR/$vcf_file"
    
    # Validate required files
    if [[ ! -f "$target_diseases_path" ]]; then
        log_error "Target diseases file not found: $target_diseases_path"
        exit 1
    fi
    
    if [[ ! -f "$vcf_path" ]]; then
        log_error "VCF file not found: $vcf_path"
        log_error "VCF file is required for target diseases analysis"
        exit 1
    fi
    
    # Validate HPO terms
    validate_hpo_terms "$observed_phenotypes" "observed phenotypes"
    validate_hpo_terms "$negated_phenotypes" "negated phenotypes"
    
    # Create output directory
    mkdir -p "$output_path"
    
    # Build LIRICAL command
    local cmd=(java -jar "$LIRICAL_JAR")
    cmd+=(prioritize)
    cmd+=(--exomiser-data-directory "$data_dir")
    cmd+=(--output-directory "$output_path")
    cmd+=(--assembly "$assembly")
    cmd+=(--vcf "$vcf_path")
    cmd+=(--target-diseases "$target_diseases_path")
    
    # Add observed phenotypes if provided
    if [[ -n "$observed_phenotypes" ]]; then
        IFS=',' read -ra OBS_TERMS <<< "$observed_phenotypes"
        for term in "${OBS_TERMS[@]}"; do
            cmd+=(--observed-phenotypes "$term")
        done
    fi
    
    # Add negated phenotypes if provided
    if [[ -n "$negated_phenotypes" ]]; then
        IFS=',' read -ra NEG_TERMS <<< "$negated_phenotypes"
        for term in "${NEG_TERMS[@]}"; do
            cmd+=(--negated-phenotypes "$term")
        done
    fi
    
    # Add age if provided
    if [[ -n "$age" ]]; then
        cmd+=(--age "$age")
    fi
    
    # Add sex if provided
    if [[ -n "$sex" ]]; then
        cmd+=(--sex "$sex")
    fi
    
    # Add analysis name prefix
    if [[ -n "$analysis_name" ]]; then
        cmd+=(--sample-id "$analysis_name")
    fi
    
    log_info "Running LIRICAL target diseases analysis..."
    log_info "Target diseases file: $target_diseases_path"
    log_info "VCF file: $vcf_path"
    if [[ -n "$observed_phenotypes" ]]; then
        log_info "Observed phenotypes: $observed_phenotypes"
    fi
    if [[ -n "$negated_phenotypes" ]]; then
        log_info "Negated phenotypes: $negated_phenotypes"
    fi
    if [[ -n "$age" ]]; then
        log_info "Age: $age"
    fi
    if [[ -n "$sex" ]]; then
        log_info "Sex: $sex"
    fi
    log_info "Assembly: $assembly"
    log_info "Output: $output_path"
    log_info "Command: ${cmd[*]}"
    
    # Execute LIRICAL
    if "${cmd[@]}"; then
        log_success "Target diseases analysis completed successfully!"
        log_info "Results saved to: $output_path"
    else
        log_error "Target diseases analysis failed!"
        exit 1
    fi
}

# Function to download LIRICAL databases
download_databases() {
    local data_dir="${1:-$RESOURCES_DIR/data}"
    
    mkdir -p "$data_dir"
    
    log_info "Downloading LIRICAL database files for hg38..."
    log_info "Data directory: $data_dir"
    
    local cmd=(java -jar "$LIRICAL_JAR")
    cmd+=(download)
    cmd+=(-d "$data_dir")
    cmd+=(--assembly hg38)
    
    log_info "Command: ${cmd[*]}"
    
    if "${cmd[@]}"; then
        log_success "Database download completed successfully!"
    else
        log_error "Database download failed!"
        exit 1
    fi
}

# Function to build LIRICAL databases
build_databases() {
    local data_dir="${1:-$RESOURCES_DIR/data}"
    
    log_info "Building LIRICAL databases for hg38..."
    log_info "This may take a significant amount of time and resources"
    
    # Call the dedicated build script
    local build_script="$SCRIPT_DIR/build_databases.sh"
    if [[ -f "$build_script" ]]; then
        "$build_script" "$data_dir"
    else
        log_error "Build databases script not found: $build_script"
        log_info "Using basic download instead..."
        download_databases "$data_dir"
    fi
}

# Function to setup LIRICAL resources
setup_lirical() {
    log_info "Setting up LIRICAL resources..."
    
    # Check if LIRICAL distribution exists
    local lirical_zip=$(find "$RESOURCES_DIR" -name "lirical-cli-*-distribution.zip" -type f | head -n1)
    
    if [[ -z "$lirical_zip" ]]; then
        log_error "LIRICAL distribution ZIP not found in resources/"
        log_error "Please download the latest LIRICAL distribution from:"
        log_error "https://github.com/TheJacksonLaboratory/LIRICAL/releases"
        exit 1
    fi
    
    log_info "Found LIRICAL distribution: $(basename "$lirical_zip")"
    
    # Extract LIRICAL if needed
    if [[ ! -f "$LIRICAL_JAR" ]]; then
        log_info "Extracting LIRICAL distribution..."
        cd "$RESOURCES_DIR"
        unzip -q "$lirical_zip"
        
        # Move files to LIRICAL_HOME
        local extract_dir=$(find . -name "lirical-cli-*" -type d | head -n1)
        if [[ -n "$extract_dir" ]]; then
            mkdir -p "$LIRICAL_HOME"
            cp -r "$extract_dir"/* "$LIRICAL_HOME/"
            chmod +x "$LIRICAL_HOME/bin/"*.sh
            rm -rf "$extract_dir"
        fi
        
        cd "$APP_DIR"
    fi
    
    # Download/build databases
    if [[ ! -d "$RESOURCES_DIR/data" ]] || [[ -z "$(ls -A "$RESOURCES_DIR/data" 2>/dev/null)" ]]; then
        log_info "Setting up hg38 database files..."
        build_databases
    else
        log_info "Database files already exist, skipping build"
    fi
    
    log_success "LIRICAL setup completed successfully!"
}

# Main function
main() {
    # Check if no arguments provided
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 0
    fi
    
    # Parse command
    local command="$1"
    shift
    
    case "$command" in
        "prioritize")
            check_lirical_installation
            
            local output_dir=""
            local analysis_name=""
            local observed_phenotypes=""
            local negated_phenotypes=""
            local age=""
            local sex=""
            local vcf_file=""
            local data_dir="$RESOURCES_DIR/data"
            local assembly="hg38"
            
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    -o|--output)
                        output_dir="$2"
                        shift 2
                        ;;
                    -n|--name)
                        analysis_name="$2"
                        shift 2
                        ;;
                    --observed)
                        observed_phenotypes="$2"
                        shift 2
                        ;;
                    --negated)
                        negated_phenotypes="$2"
                        shift 2
                        ;;
                    --age)
                        age="$2"
                        shift 2
                        ;;
                    --sex)
                        sex="$2"
                        shift 2
                        ;;
                    --vcf)
                        vcf_file="$2"
                        shift 2
                        ;;
                    --data-dir)
                        data_dir="$2"
                        shift 2
                        ;;
                    --assembly)
                        assembly="$2"
                        shift 2
                        ;;
                    *)
                        log_error "Unknown option: $1"
                        show_usage
                        exit 1
                        ;;
                esac
            done
            
            if [[ -z "$output_dir" || -z "$observed_phenotypes" ]]; then
                log_error "Output directory and observed phenotypes are required"
                show_usage
                exit 1
            fi
            
            run_prioritize_analysis "$output_dir" "$analysis_name" "$observed_phenotypes" "$negated_phenotypes" "$age" "$sex" "$vcf_file" "$data_dir" "$assembly"
            ;;
            
        "target-diseases")
            check_lirical_installation
            
            local output_dir=""
            local analysis_name=""
            local target_diseases_file=""
            local vcf_file=""
            local observed_phenotypes=""
            local negated_phenotypes=""
            local age=""
            local sex=""
            local data_dir="$RESOURCES_DIR/data"
            local assembly="hg38"
            
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    -o|--output)
                        output_dir="$2"
                        shift 2
                        ;;
                    -n|--name)
                        analysis_name="$2"
                        shift 2
                        ;;
                    --target-diseases)
                        target_diseases_file="$2"
                        shift 2
                        ;;
                    --vcf)
                        vcf_file="$2"
                        shift 2
                        ;;
                    --observed)
                        observed_phenotypes="$2"
                        shift 2
                        ;;
                    --negated)
                        negated_phenotypes="$2"
                        shift 2
                        ;;
                    --age)
                        age="$2"
                        shift 2
                        ;;
                    --sex)
                        sex="$2"
                        shift 2
                        ;;
                    --data-dir)
                        data_dir="$2"
                        shift 2
                        ;;
                    --assembly)
                        assembly="$2"
                        shift 2
                        ;;
                    *)
                        log_error "Unknown option: $1"
                        show_usage
                        exit 1
                        ;;
                esac
            done
            
            if [[ -z "$output_dir" || -z "$target_diseases_file" || -z "$vcf_file" ]]; then
                log_error "Output directory, target diseases file, and VCF file are required"
                show_usage
                exit 1
            fi
            
            run_target_diseases_analysis "$output_dir" "$analysis_name" "$target_diseases_file" "$vcf_file" "$observed_phenotypes" "$negated_phenotypes" "$age" "$sex" "$data_dir" "$assembly"
            ;;
            
        "download")
            check_lirical_installation
            download_databases
            ;;
            
        "build-db")
            check_lirical_installation
            build_databases
            ;;
            
        "setup")
            setup_lirical
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

# Run main function with all arguments
main "$@"



# Function to download LIRICAL databases
download_databases() {
    local data_dir="${1:-$RESOURCES_DIR/data}"
    
    mkdir -p "$data_dir"
    
    log_info "Downloading LIRICAL database files..."
    log_info "Data directory: $data_dir"
    
    local cmd=(java -jar "$LIRICAL_JAR")
    cmd+=(download)
    cmd+=(-d "$data_dir")
    
    log_info "Command: ${cmd[*]}"
    
    if "${cmd[@]}"; then
        log_success "Database download completed successfully!"
    else
        log_error "Database download failed!"
        exit 1
    fi
}

# Function to setup LIRICAL resources
setup_lirical() {
    log_info "Setting up LIRICAL resources..."
    
    # Check if LIRICAL distribution exists
    local lirical_zip=$(find "$RESOURCES_DIR" -name "lirical-cli-*-distribution.zip" -type f | head -n1)
    
    if [[ -z "$lirical_zip" ]]; then
        log_error "LIRICAL distribution ZIP not found in resources/"
        log_error "Please download the latest LIRICAL distribution from:"
        log_error "https://github.com/TheJacksonLaboratory/LIRICAL/releases"
        exit 1
    fi
    
    log_info "Found LIRICAL distribution: $(basename "$lirical_zip")"
    
    # Extract LIRICAL if needed
    if [[ ! -f "$LIRICAL_JAR" ]]; then
        log_info "Extracting LIRICAL distribution..."
        cd "$RESOURCES_DIR"
        unzip -q "$lirical_zip"
        
        # Move files to LIRICAL_HOME
        local extract_dir=$(find . -name "lirical-cli-*" -type d | head -n1)
        if [[ -n "$extract_dir" ]]; then
            mkdir -p "$LIRICAL_HOME"
            cp -r "$extract_dir"/* "$LIRICAL_HOME/"
            chmod +x "$LIRICAL_HOME/bin/"*.sh
            rm -rf "$extract_dir"
        fi
        
        cd "$APP_DIR"
    fi
    
    # Download databases
    if [[ ! -d "$RESOURCES_DIR/data" ]] || [[ -z "$(ls -A "$RESOURCES_DIR/data" 2>/dev/null)" ]]; then
        log_info "Downloading required database files..."
        download_databases
    else
        log_info "Database files already exist, skipping download"
    fi
    
    log_success "LIRICAL setup completed successfully!"
}

# Main function
main() {
    # Check if no arguments provided
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 0
    fi
    
    # Parse command
    local command="$1"
    shift
    
    case "$command" in
        "phenopacket")
            check_lirical_installation
            
            local input_file=""
            local output_dir=""
            local analysis_name=""
            local vcf_file=""
            local data_dir="$RESOURCES_DIR/data"
            
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    -i|--input)
                        input_file="$2"
                        shift 2
                        ;;
                    -o|--output)
                        output_dir="$2"
                        shift 2
                        ;;
                    -n|--name)
                        analysis_name="$2"
                        shift 2
                        ;;
                    --vcf)
                        vcf_file="$2"
                        shift 2
                        ;;
                    --data-dir)
                        data_dir="$2"
                        shift 2
                        ;;
                    *)
                        log_error "Unknown option: $1"
                        show_usage
                        exit 1
                        ;;
                esac
            done
            
            if [[ -z "$input_file" || -z "$output_dir" ]]; then
                log_error "Input file and output directory are required"
                show_usage
                exit 1
            fi
            
            run_phenopacket_analysis "$input_file" "$output_dir" "$analysis_name" "$vcf_file" "$data_dir"
            ;;
            
        "yaml")
            check_lirical_installation
            
            local input_file=""
            local output_dir=""
            local analysis_name=""
            local data_dir="$RESOURCES_DIR/data"
            
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    -i|--input)
                        input_file="$2"
                        shift 2
                        ;;
                    -o|--output)
                        output_dir="$2"
                        shift 2
                        ;;
                    -n|--name)
                        analysis_name="$2"
                        shift 2
                        ;;
                    --data-dir)
                        data_dir="$2"
                        shift 2
                        ;;
                    *)
                        log_error "Unknown option: $1"
                        show_usage
                        exit 1
                        ;;
                esac
            done
            
            if [[ -z "$input_file" || -z "$output_dir" ]]; then
                log_error "Input file and output directory are required"
                show_usage
                exit 1
            fi
            
            run_yaml_analysis "$input_file" "$output_dir" "$analysis_name" "$data_dir"
            ;;
            
        "download")
            check_lirical_installation
            download_databases
            ;;
            
        "setup")
            setup_lirical
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

# Run main function with all arguments
main "$@"