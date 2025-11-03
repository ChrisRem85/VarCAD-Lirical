# Commands Reference

Complete reference for all VarCAD-Lirical scripts and their options.

## run_lirical.sh

Main analysis script for executing LIRICAL commands.

### Syntax
```bash
./scripts/run_lirical.sh [--docker] [COMMAND] [OPTIONS]
```

### Global Options
- `--docker` - Run analysis in Docker container

### Commands

#### prioritize
Phenotype-driven disease prioritization analysis.

```bash
./scripts/run_lirical.sh prioritize [OPTIONS]
```

**Options:**
- `-o, --output DIR` - Output directory (relative to examples/outputs/)
- `-n, --name NAME` - Analysis name for file naming
- `--observed TERMS` - Comma-separated HPO terms for observed phenotypes
- `--negated TERMS` - Comma-separated HPO terms for negated phenotypes (optional)
- `--age AGE` - Patient age (P5Y format or adult/child)
- `--sex SEX` - Patient sex (MALE/FEMALE/UNKNOWN)
- `--data-dir PATH` - LIRICAL data directory (default: resources/data)
- `--vcf FILE` - VCF file for genomic analysis (optional)
- `--assembly ASSEMBLY` - Genome assembly (default: hg38)

**Examples:**
```bash
# Basic phenotype analysis
./scripts/run_lirical.sh prioritize \
  --observed HP:0001156,HP:0001382 \
  --age P5Y \
  --sex FEMALE \
  -o basic_analysis \
  -n patient1

# With VCF genomic data
./scripts/run_lirical.sh prioritize \
  --observed HP:0001156,HP:0001382 \
  --vcf patient.vcf \
  --age P5Y \
  --sex FEMALE \
  -o genomic_analysis \
  -n patient2
```

#### target-diseases
Analysis focused on specific target diseases from WGS/WES results.

```bash
./scripts/run_lirical.sh target-diseases [OPTIONS]
```

**Options:**
- `--target-diseases FILE` - Text file with OMIM disease IDs (one per line)
- `--vcf FILE` - VCF file with genomic variants
- `--observed TERMS` - Comma-separated HPO terms for observed phenotypes
- `--negated TERMS` - Comma-separated HPO terms for negated phenotypes (optional)
- `--age AGE` - Patient age
- `--sex SEX` - Patient sex
- `-o, --output DIR` - Output directory
- `-n, --name NAME` - Analysis name

**Example:**
```bash
./scripts/run_lirical.sh target-diseases \
  --target-diseases diseases.txt \
  --vcf variants.vcf \
  --observed HP:0001156,HP:0001382 \
  -o target_analysis \
  -n patient3
```

#### download
Download required LIRICAL database files.

```bash
./scripts/run_lirical.sh download
```

#### build-db
Build LIRICAL databases for hg38 assembly.

```bash
./scripts/run_lirical.sh build-db
```

#### setup
Complete environment setup.

```bash
./scripts/run_lirical.sh setup
```

#### help
Display usage information.

```bash
./scripts/run_lirical.sh help
```

## setup_lirical.sh

Environment setup and Docker management script.

### Syntax
```bash
./scripts/setup_lirical.sh [COMMAND] [OPTIONS]
```

### Commands

#### all
Complete end-to-end setup.

```bash
./scripts/setup_lirical.sh all
```
Performs: download → build-db → examples setup → validation

#### download
Download LIRICAL distribution and extract.

```bash
./scripts/setup_lirical.sh download
```

#### build-db
Build LIRICAL databases for hg38.

```bash
./scripts/setup_lirical.sh build-db
```

#### examples
Setup examples directory structure and test files.

```bash
./scripts/setup_lirical.sh examples
```

#### docker-build
Build Docker image for containerized execution.

```bash
./scripts/setup_lirical.sh docker-build
```

#### docker-status
Show Docker container and image status.

```bash
./scripts/setup_lirical.sh docker-status
```

#### docker-logs
Display Docker container logs.

```bash
./scripts/setup_lirical.sh docker-logs
```

#### docker-clean
Clean up Docker containers and images.

```bash
./scripts/setup_lirical.sh docker-clean
```

#### help
Display usage information.

```bash
./scripts/setup_lirical.sh help
```

## test_lirical.sh

Comprehensive testing script for validation.

### Syntax
```bash
./scripts/test_lirical.sh
```

### Test Suite
- **Test 1**: Basic phenotype analysis
- **Test 2**: Negated phenotypes analysis  
- **Test 3**: Target diseases analysis
- **Test 4**: Age and sex parameter validation
- **Test 5**: Complex multi-system analysis (LDS2)
- **Test 6**: VCF genomic analysis (if VCF available)
- **Test 7**: Docker-based phenotype analysis (if Docker available)
- **Test 8**: Docker container management functions
- **Test 9**: Docker environment validation

### Output
- Validates all core functionality
- Tests Docker integration if available
- Provides detailed success/failure reporting
- Creates test results in examples/outputs/

## build_databases.sh

Database build script for hg38 assembly.

### Syntax
```bash
./scripts/build_databases.sh [OPTIONS]
```

### Options
- `--exomiser` - Also download Exomiser databases (~22GB)
- `--data-version VERSION` - Specify Exomiser data version (default: 2508)

### Examples
```bash
# Build basic LIRICAL databases
./scripts/build_databases.sh

# Include Exomiser databases for VCF analysis
./scripts/build_databases.sh --exomiser
```

## Common Parameter Formats

### HPO Terms
- Format: `HP:XXXXXXX` (e.g., `HP:0001156`)
- Multiple terms: Comma-separated (no spaces)
- Example: `HP:0001156,HP:0001382,HP:0002615`

### Age Specification
- **ISO 8601 Duration**: `P5Y` (5 years), `P2Y6M` (2 years 6 months)
- **Simple Terms**: `adult`, `child`
- **Examples**: `P6M`, `P5Y`, `P30Y`, `adult`

### Sex Values
- `MALE`
- `FEMALE` 
- `UNKNOWN`

### Output Directory
- Relative to `examples/outputs/`
- Example: `-o analysis1` creates `examples/outputs/analysis1/`

### Analysis Names
- Used for output file naming
- Example: `-n patient1` creates files like `patient1_lirical.html`

## Docker Integration

### Container Execution
Add `--docker` flag before any command:

```bash
# Direct execution
./scripts/run_lirical.sh prioritize --observed HP:0001156 -o test -n test

# Docker execution
./scripts/run_lirical.sh --docker prioritize --observed HP:0001156 -o test -n test
```

### Volume Mounts
Docker automatically mounts:
- `examples/inputs/` → `/app/examples/inputs/` (read-only)
- `examples/outputs/` → `/app/examples/outputs/` (read-write)

### Image Management
```bash
# Build image
./scripts/setup_lirical.sh docker-build

# Check status
./scripts/setup_lirical.sh docker-status

# View logs
./scripts/setup_lirical.sh docker-logs

# Cleanup
./scripts/setup_lirical.sh docker-clean
```

## Exit Codes

### Success
- `0` - Command completed successfully

### Errors
- `1` - General error (invalid arguments, missing files)
- `2` - Missing dependencies (Java, Docker when required)
- `3` - Analysis execution failure
- `4` - Database/resource errors

## Environment Variables

Scripts respect these environment variables:

- `JAVA_HOME` - Java installation directory
- `LIRICAL_DATA_DIR` - Custom data directory location
- `DOCKER_BUILDKIT` - Enable Docker BuildKit (recommended: 1)

## File Locations

### Input Files
- HPO terms: Command line parameters
- VCF files: `examples/inputs/`
- Target diseases: `examples/inputs/` (text files with OMIM IDs)

### Output Files
- Analysis results: `examples/outputs/[analysis_name]/`
- Logs: Console output and Docker logs
- Test results: `examples/outputs/[test_name]/`

### Resources
- LIRICAL JAR: `resources/lirical-cli-*/`
- Databases: `resources/data/`
- Exomiser data: `resources/exomiser_db/` (if installed)

## Performance Options

### Memory Settings
For large VCF files, increase Java memory:
```bash
export JAVA_OPTS="-Xmx8g"
./scripts/run_lirical.sh prioritize --vcf large_file.vcf ...
```

### Parallel Processing
Scripts support parallel execution for batch processing:
```bash
# Process multiple patients in parallel
for patient in patient_001 patient_002 patient_003; do
  ./scripts/run_lirical.sh prioritize \
    --observed HP:0001156,HP:0001382 \
    -o batch_${patient} \
    -n ${patient} &
done
wait
```

## Debugging

### Verbose Output
Add debugging to scripts:
```bash
# Enable bash debugging
bash -x ./scripts/run_lirical.sh prioritize ...

# Docker verbose mode
./scripts/setup_lirical.sh docker-build --verbose
```

### Log Analysis
```bash
# Check Docker logs
./scripts/setup_lirical.sh docker-logs

# Check Java version
java -version

# Verify databases
ls -la resources/data/
```

## Next Steps

- **Examples**: See [usage-examples.md](usage-examples.md) for practical examples
- **Input/Output**: See [input-output.md](input-output.md) for file format details
- **Docker**: See [docker.md](docker.md) for containerization details
- **Troubleshooting**: See [troubleshooting.md](troubleshooting.md) for common issues