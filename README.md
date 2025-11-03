# VarCAD-Lirical

A Docker-based wrapper for [LIRICAL](https://github.com/TheJacksonLaboratory/LIRICAL) (LIkelihood Ratio Interpretation of Clinical AbnormaLities) that provides phenotype-driven prioritization of candidate diseases and genes in genomic diagnostics.

## ✅ Project Status: Fully Functional 

**VarCAD-Lirical v2.2.0** is ready for clinical genomics analysis with:

- ✅ **Phenotype Analysis**: Complete disease prioritization using HPO terms
- ✅ **VCF Genomic Analysis**: Automatic Exomiser database detection and configuration
- ✅ **Docker Integration**: Containerized execution with `--docker` flag
- ✅ **Multi-Platform**: Docker + bash scripts (WSL2/Linux)
- ✅ **Multiple Output Formats**: HTML, TSV, JSON reports
- ⚠️ **Database Downloads**: VCF analysis requires large databases (~22GB)

## Quick Start

### 1. Setup Environment
```bash
# Clone repository
git clone https://github.com/ChrisRem85/VarCAD-Lirical.git
cd VarCAD-Lirical

# Setup LIRICAL with hg38 databases
./scripts/setup_lirical.sh all
```

### 2. Test Installation
```bash
# Run comprehensive test suite
./scripts/test_lirical.sh
```

### 3. Run Analysis
```bash
# Basic phenotype analysis
./scripts/run_lirical.sh prioritize \
  --observed HP:0001156,HP:0001382 \
  --age P5Y \
  --sex FEMALE \
  -o basic_analysis \
  -n patient1

# Docker containerized analysis
./scripts/run_lirical.sh --docker prioritize \
  --observed HP:0001156,HP:0001382 \
  -o docker_analysis \
  -n patient1

# View results
open examples/outputs/basic_analysis/lirical.html
```

## Project Structure

```
VarCAD-Lirical/
├── Dockerfile                 # Ubuntu 24.04 LTS based container
├── scripts/                   # Bash scripts for operations
│   ├── run_lirical.sh        # Main LIRICAL CLI runner (supports --docker flag)
│   ├── build_databases.sh    # Database build script for hg38
│   ├── setup_lirical.sh      # Environment setup and Docker management
│   └── test_lirical.sh       # Comprehensive test suite with Docker tests
├── resources/                 # LIRICAL app and databases (gitignored)
├── examples/                  # Test data and results (gitignored)
└── docs/                      # Detailed documentation
```

## Documentation

- **[Installation Guide](docs/installation.md)** - Complete setup instructions
- **[Usage Examples](docs/usage-examples.md)** - Comprehensive analysis examples
- **[Input/Output Formats](docs/input-output.md)** - File formats and requirements
- **[Commands Reference](docs/commands.md)** - All script commands and options
- **[Docker Guide](docs/docker.md)** - Containerization and deployment
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions
- **[Development](docs/development.md)** - Development workflow and contribution guide

## Core Features

### Analysis Types
- **Phenotype Analysis**: Disease prioritization using HPO terms
- **Genomic Analysis**: VCF file integration with phenotype data
- **Target Diseases**: Focus analysis on specific disease sets

### Execution Modes
- **Direct**: Native bash execution on host system
- **Docker**: Containerized execution with `--docker` flag

### Output Formats
- **HTML**: Interactive visual reports
- **TSV**: Tabular data for analysis
- **JSON**: Structured data for integration

## Requirements

- **System**: Windows 11 (WSL2) or Ubuntu Linux
- **Runtime**: Java 11+ (Java 17 recommended)
- **Optional**: Docker for containerized execution
- **Storage**: 6GB+ for database files

## Commands Overview

```bash
# Environment setup
./scripts/setup_lirical.sh all                    # Complete setup
./scripts/setup_lirical.sh docker-build           # Build Docker image

# Analysis execution
./scripts/run_lirical.sh prioritize [OPTIONS]     # Phenotype analysis
./scripts/run_lirical.sh --docker [COMMAND]       # Docker execution
./scripts/run_lirical.sh target-diseases [OPTIONS] # Target diseases analysis

# Testing and validation
./scripts/test_lirical.sh                         # Run test suite

# Docker management
./scripts/setup_lirical.sh docker-status          # Container status
./scripts/setup_lirical.sh docker-logs            # View logs
./scripts/setup_lirical.sh docker-clean           # Cleanup
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Citation

When using VarCAD-Lirical in your research, please cite:

**LIRICAL:**
> Robinson PN, et al. Efficient phenotype-driven analysis of rare disease patients using LIRICAL. *medRxiv*. 2019. doi: [10.1101/2019.12.19.19015297](https://doi.org/10.1101/2019.12.19.19015297)

**VarCAD-Lirical:**
> ChrisRem85. VarCAD-Lirical: Docker-based wrapper for LIRICAL phenotype analysis. GitHub: https://github.com/ChrisRem85/VarCAD-Lirical

## Links

- **LIRICAL Documentation**: https://thejacksonlaboratory.github.io/LIRICAL/stable/
- **LIRICAL GitHub**: https://github.com/TheJacksonLaboratory/LIRICAL
- **HPO Terms**: http://www.human-phenotype-ontology.org/
- **Docker Hub**: https://hub.docker.com/