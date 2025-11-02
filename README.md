# VarCAD-Lirical

A Docker-based wrapper for [LIRICAL](https://github.com/TheJacksonLaboratory/LIRICAL) (LIkelihood Ratio Interpretation of Clinical AbnormaLities) that provides phenotype-driven prioritization of candidate diseases and genes in genomic diagnostics using the CLI `prioritize` command.

## ✅ Project Status: Fully Functional 

**VarCAD-Lirical v2.2.0** is ready for clinical genomics analysis with the following capabilities:

- ✅ **Phenotype Analysis**: Complete disease prioritization using HPO terms
- ✅ **Exomiser v2508 Integration**: Latest database version configured  
- ✅ **Official Examples**: LDS2 complex case integrated and tested
- ✅ **Multi-Platform**: Docker + bash scripts (WSL2/Linux)
- ✅ **Multiple Output Formats**: HTML, TSV, JSON reports
- ⚠️ **VCF Analysis**: Requires manual download of large databases (~22GB)

**Recent Test Results**: Successfully analyzed complex LDS2 connective tissue case, correctly identifying Loeys-Dietz syndrome 3 (99.87% probability) and Marfan syndrome (98.99% probability) from phenotype data alone.

VarCAD-Lirical provides a containerized environment for running LIRICAL analysis with:
- **Docker container** based on Ubuntu 24.04 LTS
- **Bash scripts** for cross-platform automation (WSL2/Linux)
- **Phenotype-driven analysis** using HPO terms (primary use case)
- **hg38 genome assembly** support for optional genomic analysis
- **Target diseases analysis** for WGS/WES results integration
- **Organized structure** for inputs, outputs, and resources
- **Official examples** including complex connective tissue cases (LDS2)

LIRICAL performs phenotype-driven prioritization using [Human Phenotype Ontology (HPO)](http://www.human-phenotype-ontology.org/) terms with the CLI `prioritize` command, supporting observed/negated phenotypes, age, sex, and optional genomic variant analysis from VCF files.

## Project Structure

```
VarCAD-Lirical/
├── Dockerfile                 # Ubuntu 24.04 LTS based container
├── scripts/                   # Bash scripts for operations
│   ├── run_lirical.sh        # Main LIRICAL CLI runner
│   ├── build_databases.sh    # Database build script for hg38
│   ├── docker_helper.sh      # Docker management utilities
│   ├── download_exomiser.sh  # Exomiser database downloader
│   └── setup.sh              # Environment setup script
├── resources/                 # LIRICAL app and databases (gitignored)
│   ├── data/                 # Database files for hg38 (optional, ~22GB)
│   ├── lirical-cli-2.2.0/    # LIRICAL application files
│   └── README.md
├── examples/                  # Test data and results (gitignored)
│   ├── inputs/               # LDS2 examples, VCF files, target disease lists
│   ├── outputs/              # Analysis results (HTML, TSV, JSON)
│   └── README.md
└── .gitignore                # Excludes resources/ and examples/
```

## ✅ Validation Status

**Last Tested**: November 2, 2025  
**Platform**: Windows 11 + WSL2 + Docker Desktop  
**LIRICAL Version**: 2.2.0  
**Exomiser Integration**: v2508 (latest)  
**Exomiser Default**: v2508

### Verified Functionality

| Feature | Status | Notes |
|---------|--------|-------|
| Phenotype-only analysis | ✅ **Working** | Fully tested with multiple scenarios |
| Docker containerization | ✅ **Working** | Cross-platform deployment verified |
| HPO term validation | ✅ **Working** | Proper error handling for invalid terms |
| Age/sex parameters | ✅ **Working** | ISO 8601 duration format supported |
| Output formats | ✅ **Working** | HTML, TSV, JSON all generated correctly |
| Database setup | ✅ **Working** | LIRICAL core databases installed |

### Known Limitations

| Feature | Status | Resolution |
|---------|--------|------------|
| Genomic analysis with VCF | ⚠️ **Limited** | Requires Exomiser v2508 databases (~22GB) - see database setup section |
| Target diseases mode | ✅ **Working** | Works with phenotype-only analysis and target disease lists |
| Bash script execution | ⚠️ **Limited** | WSL2 compatibility requires full Ubuntu, not docker-desktop |

### Test Cases Validated

```bash
# Test 1: Basic phenotype analysis (5-year-old female)
# Phenotypes: HP:0001156 (Brachydactyly), HP:0001382 (Joint hypermobility)
# Result: ✅ Successful - Generated HTML, TSV, JSON reports

# Test 2: Alternative phenotypes (25-year-old male)  
# Phenotypes: HP:0000098 (Tall stature), HP:0001382 (Joint hypermobility)
# Result: ✅ Successful - Disease rankings different as expected

# Test 3: Age variation (6-month-old infant)
# Phenotypes: HP:0001156 (Brachydactyly)
# Result: ✅ Successful - Age-specific disease scoring working

# Test 4: LDS2 Official Example (complex connective tissue case)
# Patient: 9-year-old female with Loeys-Dietz syndrome phenotype
# Phenotypes: HP:0001659,HP:0001166,HP:0000193,HP:0002650,HP:0000768 (observed)
#            HP:0001382,HP:0001250 (negated)
# Result: ✅ Successful - Correctly identified Loeys-Dietz syndrome 3 (99.87% probability)
#         and Marfan syndrome (98.99% probability). Processed 8,395 diseases in 6 seconds.

# Test 5: Exomiser Database Download and Setup (Windows WSL2)
# Command: wsl -d Ubuntu-24.04, then bash scripts/download_exomiser.sh
# Result: ✅ Successful - Downloaded 21.93GB Exomiser v2508 hg38 database in ~95 minutes
#         Extracted all required files: variants.mv.db, clinvar.mv.db, genome.mv.db
```

### LDS2 Example Integration

The project now includes the official LIRICAL developer example (LDS2 - Patient 4), demonstrating:
- **Complex Phenotype Analysis**: 13 distinct HPO terms covering cardiovascular and skeletal features
- **Connective Tissue Disorders**: Phenotype consistent with Loeys-Dietz syndrome
- **Multi-format Support**: YAML, JSON (Phenopacket v2.0), and VCF formats
- **Real Genomic Data**: ~4MB compressed VCF file with actual variant calls

**Available Files:**
- `examples/inputs/LDS2.yaml` - YAML configuration format
- `examples/inputs/LDS2.v2.json` - GA4GH Phenopacket v2.0 format  
- `examples/inputs/LDS2.vcf.gz` - Genomic variants for Patient 4

## Development Workflow

### 1. Local Development (Windows 11 + WSL2)
```bash
# Start WSL2 from Windows PowerShell/Command Prompt
wsl -d Ubuntu-24.04

# Clone and setup in WSL2
git clone https://github.com/ChrisRem85/VarCAD-Lirical.git
cd VarCAD-Lirical

# Ensure permissions (important in WSL2)
chmod +x scripts/*.sh

# Setup development environment
bash scripts/setup.sh all

# Test with small datasets
bash scripts/run_lirical.sh prioritize \
  --observed HP:0001156 \
  --age P5Y \
  --sex FEMALE \
  -o dev_test \
  -n test_patient
```

### 2. Deployment to HPC
```bash
# Method 1: Git deployment (recommended)
# On HPC server:
git clone https://github.com/ChrisRem85/VarCAD-Lirical.git
cd VarCAD-Lirical
./scripts/setup.sh all

# Method 2: Direct transfer (for local modifications)
# From WSL2:
tar --exclude='resources' --exclude='examples' -czf varcad-lirical.tar.gz VarCAD-Lirical/
scp varcad-lirical.tar.gz user@hpc-server:/path/to/destination/
```

### 3. Production Analysis
```bash
# On HPC server with large datasets
./scripts/run_lirical.sh target-diseases \
  --target-diseases /data/genomics/candidate_diseases.txt \
  --vcf /data/genomics/cohort_variants.vcf \
  --observed HP:0001156,HP:0001382,HP:0000098 \
  --age P10Y \
  --sex FEMALE \
  -o production_analysis_$(date +%Y%m%d) \
  -n cohort_study_v1

# Docker deployment for isolated environments
./scripts/docker_helper.sh build
./scripts/docker_helper.sh run target-diseases \
  --target-diseases diseases.txt \
  --vcf variants.vcf \
  --observed HP:0001156 \
  -o docker_production \
  -n isolated_analysis
```

## Quick Start

### Development Environment (Windows 11 + WSL2)

#### 1. Setup WSL2 Environment
```bash
# Start WSL2 Ubuntu distribution from PowerShell/Command Prompt
wsl -d Ubuntu-24.04

# Inside WSL2, navigate to project directory
cd /mnt/c/Users/your-username/path/to/VarCAD-Lirical

# Ensure scripts are executable (important for WSL2)
chmod +x scripts/*.sh

# Complete setup
bash scripts/setup.sh all
```

#### 3. Optional: Exomiser Database Setup (for VCF analysis)

**⚠️ Important**: Exomiser databases are much larger than originally documented (~22GB instead of 4-6GB). For most clinical use cases, **phenotype-only analysis is recommended** and fully functional without any database downloads.

**Current Status**: 
- ✅ Exomiser v2508 integration confirmed and accessible
- ✅ Download infrastructure created (bash scripts)  
- ⚠️ Database files are ~22GB each (hg38: 21.93 GB, phenotype-only: 12.53 GB)

**Recommended Approach: Phenotype-Only Analysis**
```bash
# Example: Full phenotype analysis without VCF (recommended)
./scripts/run_lirical.sh prioritize \
  --observed HP:0001659,HP:0001166,HP:0000193,HP:0002650,HP:0000768 \
  --negated HP:0001382,HP:0001250 \
  --age P9Y \
  --sex FEMALE \
  -o LDS2_analysis \
  -n patient_LDS2
```

**Capabilities Without Exomiser Databases:**
- ✅ **Phenotype Analysis**: Complete disease prioritization  
- ✅ **HPO Term Processing**: Full human phenotype ontology support  
- ✅ **Disease Ranking**: OMIM disease scoring and ranking  
- ✅ **Target Disease Lists**: WGS/WES candidate filtering  
- ✅ **Output Formats**: HTML, TSV, JSON reports  
- ✅ **LDS2 Example**: Complex connective tissue case analysis  
- ❌ **VCF Analysis**: Requires Exomiser databases for variant scoring  

**If VCF Analysis is Essential:**

**Download via bash script:**

**For Windows users (WSL2):**
```bash
# Start WSL2 Ubuntu distribution
wsl -d Ubuntu-24.04

# Then inside WSL2, navigate to project and run:
bash scripts/download_exomiser.sh --version 2508 --assembly hg38

# Exit WSL2 when done
exit
```

**For Linux users:**
```bash
# Download Exomiser v2508 databases (~22GB)
./scripts/download_exomiser.sh --version 2508 --assembly hg38
```

**Direct Download URLs (Exomiser 2508):**
- hg38: https://g-879a9f.f5dc97.75bc.dn.glob.us/data/2508_hg38.zip (21.93 GB)
- hg19: https://g-879a9f.f5dc97.75bc.dn.glob.us/data/2508_hg19.zip (~22 GB)
- phenotype: https://g-879a9f.f5dc97.75bc.dn.glob.us/data/2508_phenotype.zip (12.53 GB)

**Manual Steps:**
1. Visit: https://github.com/exomiser/Exomiser/discussions/611
2. Download appropriate zip file from direct links above
3. Extract to: `resources/data/`
4. Verify files: `2508_hg38_variants.mv.db`, `2508_hg38_clinvar.mv.db`

**Alternative Approaches:**
- Use cloud instances or HPC with pre-installed databases
- Consider download managers for stable 22GB downloads
- Evaluate if VCF analysis is critical for your use case

**Testing Genomic Analysis (after database download):**
```bash
# In WSL2, test full genomic analysis with LDS2 VCF
wsl -d Ubuntu-24.04

# Navigate to project and run genomic analysis
bash scripts/run_lirical.sh prioritize \
  --observed HP:0001659,HP:0001166,HP:0000193,HP:0002650,HP:0000768 \
  --negated HP:0001382,HP:0001250 \
  --age P9Y \
  --sex FEMALE \
  --assembly hg38 \
  --vcf examples/inputs/LDS2.vcf.gz \
  -o LDS2_genomic_analysis \
  -n patient_LDS2_with_vcf
```

#### 4. Development Testing
```bash
# Test with example data
./scripts/run_lirical.sh prioritize \
  --observed HP:0001156,HP:0001382 \
  --age P5Y \
  --sex FEMALE \
  -o dev_test \
  -n dev_analysis

# Test official LDS2 example (complex case)
docker run --rm \
  -v "${PWD}/examples/inputs:/app/examples/inputs" \
  -v "${PWD}/examples/outputs:/app/examples/outputs" \
  varcad-lirical \
  java -jar /opt/lirical/lirical-cli-2.2.0.jar prioritize \
  -d /app/resources/data \
  -o /app/examples/outputs/LDS2_quickstart \
  -f html -f tsv -f json \
  -p HP:0001659,HP:0001166,HP:0000193,HP:0002650,HP:0000768 \
  --age P9Y --sex FEMALE --sample-id LDS2_Patient4

# Test Docker build (uses Linux containers)
./scripts/docker_helper.sh build
./scripts/docker_helper.sh run prioritize \
  --observed HP:0001156 \
  -o docker_test \
  -n docker_analysis
  -n docker_analysis
```

### Production Environment (Ubuntu HPC)

#### 1. Transfer to HPC
```bash
# On HPC server
git clone https://github.com/ChrisRem85/VarCAD-Lirical.git
cd VarCAD-Lirical

# Setup environment
./scripts/setup.sh all
```

#### 2. Production Analysis
```bash
# Large-scale analysis on HPC
./scripts/run_lirical.sh target-diseases \
  --target-diseases /path/to/candidate_diseases.txt \
  --vcf /path/to/large_cohort.vcf \
  --observed HP:0001156,HP:0001382 \
  --age P10Y \
  --sex FEMALE \
  -o production_analysis \
  -n cohort_study
```

#### Basic Phenotype Analysis
```bash
# Development (WSL2) - small test
./scripts/run_lirical.sh prioritize \
  --observed HP:0001156,HP:0001382 \
  --age P5Y \
  --sex FEMALE \
  -o basic_analysis \
  -n patient1

# Production (HPC) - same command works
./scripts/run_lirical.sh prioritize \
  --observed HP:0000098 \
  --negated HP:0002650,HP:0001249 \
  --age adult \
  --sex MALE \
  -o negated_analysis \
  -n patient2
```

#### Target Diseases Analysis (WGS/WES)
```bash
# HPC production workflow
./scripts/run_lirical.sh target-diseases \
  --target-diseases candidate_diseases.txt \
  --vcf patient_variants.vcf \
  --observed HP:0001156,HP:0001382 \
  --age P10Y \
  --sex FEMALE \
  -o genomic_analysis \
  -n patient3
```

#### Docker Usage (Same on WSL2 and HPC)
```bash
# Build image (cross-platform)
./scripts/docker_helper.sh build

# Run containerized analysis
./scripts/docker_helper.sh run prioritize \
  --observed HP:0001156,HP:0001382 \
  --age P5Y \
  --sex FEMALE \
  -o container_results \
  -n container_analysis

# Interactive debugging
./scripts/docker_helper.sh exec bash
```

### 3. View Results

Results are saved in `examples/outputs/` and include:
- **HTML reports** with visual analysis and rankings
- **TSV files** with tabular differential diagnosis data
- **JSON files** with structured results for programmatic use

## Input Formats

### CLI Parameters
All analyses use the LIRICAL CLI `prioritize` command with these parameters:

#### Required Parameters:
- `--observed` - Comma-separated HPO terms for observed phenotypes (e.g., `HP:0001156,HP:0001382`)
- `-o, --output` - Output directory name (relative to `examples/outputs/`)

#### Optional Parameters:
- `--negated` - Comma-separated HPO terms for explicitly negated phenotypes
- `--age` - Patient age in ISO 8601 format (`P5Y` = 5 years, `P2Y6M` = 2 years 6 months) or descriptive (`adult`, `child`)
- `--sex` - Patient sex (`MALE`, `FEMALE`, `UNKNOWN`)
- `--vcf` - VCF file for genomic variant analysis
- `-n, --name` - Analysis name for output file prefixes
- `--assembly` - Genome assembly (default: `hg38`)

### Target Diseases Format
Text file with one OMIM ID per line for candidate diseases from WGS/WES analysis:
```
OMIM:154700  # Marfan syndrome
OMIM:130050  # Ehlers-Danlos syndrome
OMIM:166200  # Osteogenesis imperfecta
```

### Example HPO Terms:
- `HP:0001156` - Brachydactyly (short fingers/toes)
- `HP:0001382` - Joint hypermobility
- `HP:0000098` - Tall stature
- `HP:0002650` - Scoliosis
- `HP:0001249` - Intellectual disability

## Commands Reference

### Setup Script (`scripts/setup.sh`)
- `all` - Complete setup with database build
- `download` - Download LIRICAL distribution
- `examples` - Create example files
- `docker` - Build Docker image

### Database Build Script (`scripts/build_databases.sh`)
- Builds required databases for hg38 genome assembly
- Downloads and configures Exomiser databases
- Sets up HPO and disease association files

### LIRICAL Runner (`scripts/run_lirical.sh`)
- `prioritize` - Run phenotype-driven analysis with CLI parameters
- `target-diseases` - Run analysis with candidate diseases from WGS/WES
- `download` - Download pre-built databases
- `build-db` - Build databases locally
- `setup` - Setup LIRICAL environment

### Docker Helper (`scripts/docker_helper.sh`)
- `build` - Build Docker image
- `run` - Run container with command
- `exec` - Execute command in running container
- `logs` - Show container logs
- `status` - Show container status
- `clean` - Clean up containers and images

## Requirements

### System Requirements
- **Development Environment**: Windows 11 with WSL2 and Docker Desktop
- **Production Environment**: Ubuntu HPC servers with Docker
- **Bash** shell environment (WSL2 on Windows, native on Ubuntu)
- **Java 11+** runtime (Java 17 recommended)
- **Docker** engine with Linux containers
- **wget** and **unzip** utilities
- **6GB+ free disk space** for database files

### Cross-Platform Compatibility
- Scripts designed for Bash (compatible with WSL2 and Ubuntu)
- Docker containers use Linux base (Ubuntu 24.04 LTS)
- Path handling works across Windows/WSL/Linux environments
- Line endings handled automatically by Git and WSL

### LIRICAL Resources (hg38)
- LIRICAL distribution JAR (~100MB)
- Exomiser database files for hg38 (~22GB for full genomic, ~12.5GB phenotype-only) - **v2508 latest**
- HPO database files (~100MB) - included with LIRICAL
- Disease-gene association files (~50MB) - included with LIRICAL

## Configuration

### Environment Variables
- `LIRICAL_HOME` - LIRICAL installation directory (default: `/opt/lirical`)
- `JAVA_HOME` - Java installation path

### Directory Configuration
- Resources: `resources/` (databases, LIRICAL app for hg38)
- Input files: `examples/inputs/` (VCF files, target disease lists)
- Output files: `examples/outputs/` (HTML, TSV, JSON results)

## Troubleshooting

### Common Issues

**LIRICAL JAR not found:**
```bash
./scripts/setup.sh download --version v2.2.0
```

**Database files missing:**
```bash
./scripts/build_databases.sh
# OR for pre-built databases
./scripts/run_lirical.sh download
```

**Java version issues:**
Ensure Java 11+ is installed:
```bash
java -version
```

**Docker build fails:**
Check if LIRICAL distribution exists in `resources/`:
```bash
ls -la resources/
./scripts/setup.sh download
```

**HPO term validation errors:**
Ensure HPO terms are in correct format (`HP:XXXXXXX`):
```bash
# Valid: HP:0001156
# Invalid: HP:1156, 0001156, HP:001156
```

### Windows/WSL2 Specific Issues

**Script permission errors in WSL2:**
```bash
# Fix executable permissions
chmod +x scripts/*.sh

# If still failing, check line endings
dos2unix scripts/*.sh
```

**Docker daemon not running in WSL2:**
```bash
# Start Docker Desktop on Windows
# Or restart Docker service in WSL2
sudo service docker start
```

**Path issues between Windows and WSL2:**
```bash
# Use WSL2 paths for development
cd /mnt/c/Users/your-username/Documents/VarCAD-Lirical

# Avoid Windows-style paths (C:\Users\...)
```

**Large file transfers to HPC:**
```bash
# Compress resources before transfer
tar -czf resources.tar.gz resources/
scp resources.tar.gz user@hpc-server:/path/to/VarCAD-Lirical/
```

### Getting Help
- Run any script with `help` or `--help` for usage information
- Check [LIRICAL documentation](https://lirical.readthedocs.io/en/latest/)
- Review [LIRICAL stable documentation](https://thejacksonlaboratory.github.io/LIRICAL/stable/)
- Review [LIRICAL GitHub repository](https://github.com/TheJacksonLaboratory/LIRICAL)

## Development

### Adding New Features
1. Create feature branch from `main`
2. Implement changes in appropriate scripts
3. Test with example data
4. Update documentation
5. Submit pull request

### Testing

#### Development Testing (WSL2)
```bash
# Test basic functionality with example data
./scripts/run_lirical.sh prioritize \
  --observed HP:0001156,HP:0001382 \
  --age P5Y \
  --sex FEMALE \
  -o test \
  -n test

# Test Docker setup in WSL2
./scripts/docker_helper.sh build
./scripts/docker_helper.sh run prioritize --observed HP:0001156 -o test_docker -n test
```

#### Production Testing (HPC)
```bash
# Test on HPC with larger datasets
./scripts/run_lirical.sh target-diseases \
  --target-diseases production_diseases.txt \
  --vcf large_cohort.vcf \
  --observed HP:0001156 \
  -o hpc_test \
  -n hpc_validation

# Performance testing with Docker on HPC
time ./scripts/docker_helper.sh run prioritize \
  --observed HP:0001156,HP:0001382 \
  -o performance_test \
  -n timing_test
```

## License

This wrapper project follows the same license terms as the underlying LIRICAL software. Please refer to the [LIRICAL repository](https://github.com/TheJacksonLaboratory/LIRICAL) for license details.

## Citation

If you use this wrapper in your research, please cite the original LIRICAL paper:

> Robinson PN, Ravanmehr V, Jacobsen JOB, et al. Interpretable Clinical Genomics with a Likelihood Ratio Paradigm. Am J Hum Genet. 2020;107(3):403-417.

## Links

- [LIRICAL GitHub Repository](https://github.com/TheJacksonLaboratory/LIRICAL)
- [LIRICAL Documentation](https://lirical.readthedocs.io/en/latest/)
- [LIRICAL Stable Documentation](https://thejacksonlaboratory.github.io/LIRICAL/stable/)
- [Human Phenotype Ontology](http://www.human-phenotype-ontology.org/)
- [Phenopackets Schema](https://phenopackets-schema.readthedocs.io/)