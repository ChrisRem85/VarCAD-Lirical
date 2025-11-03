<!-- .github/copilot-instructions.md -->
# Copilot / AI Agent Instructions — VarCAD-Lirical

**Project Type**: Docker-based LIRICAL wrapper with bash scripts for clinical genomics analysis  
**Languages**: Bash scripting, Dockerfile, Java (for LIRICAL)  
**Owner**: ChrisRem85  
**Development**: Windows 11 + WSL2 + Docker Desktop  
**Production**: Ubuntu HPC servers with Docker

## Project Architecture

VarCAD-Lirical is a containerized wrapper for [LIRICAL](https://github.com/TheJacksonLaboratory/LIRICAL) providing:
- Ubuntu 24.04 LTS based Docker container (`Dockerfile`)
- Bash scripts for LIRICAL operations (`scripts/`)
- Organized structure for resources and examples with gitignore exclusions

### Key Components
- `Dockerfile` - Ubuntu 24.04 + Java 17 + LIRICAL setup
- `scripts/run_lirical.sh` - Main analysis runner with `--docker` flag support
- `scripts/build_databases.sh` - Database build script for hg38
- `scripts/setup_lirical.sh` - Environment setup and Docker management
- `scripts/test_lirical.sh` - Comprehensive test suite with Docker tests
- `resources/` - LIRICAL JAR and databases (gitignored, ~4-6GB for hg38)
- `examples/inputs/` - Test data (VCF files, target disease lists, gitignored)
- `examples/outputs/` - Analysis results (HTML/TSV/JSON, gitignored)

## Development Patterns

### Script Structure (follow existing patterns)
- Use `set -euo pipefail` for strict error handling
- Implement colored logging functions: `log_info()`, `log_warn()`, `log_error()`, `log_success()`
- Include comprehensive `show_usage()` function with examples
- Support `--help`, `-h`, and `help` commands
- Use consistent variable naming: `SCRIPT_DIR`, `APP_DIR`, `RESOURCES_DIR`

### File Organization
- Scripts go in `scripts/` with `.sh` extension and executable permissions
- All user data stays in `examples/` (gitignored)
- All LIRICAL resources stay in `resources/` (gitignored)
- Documentation updates go in `README.md` with proper examples

### Docker Workflow
1. Resources must be populated before building: `./scripts/setup_lirical.sh download`
2. Build image: `./scripts/setup_lirical.sh docker-build`
3. Run analysis: `./scripts/run_lirical.sh --docker [LIRICAL_COMMAND]`
4. Container management: `./scripts/setup_lirical.sh docker-status|docker-logs|docker-clean`

### Cross-Platform Development
- **Development**: Windows 11 with WSL2 and Docker Desktop
- **Production**: Ubuntu HPC servers with native Docker
- Scripts use Bash (compatible with both WSL2 and Ubuntu)
- Docker containers always use Linux (Ubuntu 24.04 LTS)
- Ensure executable permissions: `chmod +x scripts/*.sh` in WSL2

## Common Tasks

### Adding New Script Features
- Follow pattern in `scripts/run_lirical.sh` for argument parsing
- Add new commands to main case statement
- Include comprehensive error checking and user-friendly messages
- Test both direct execution and Docker container usage

### Modifying Docker Setup
- Base image is Ubuntu 24.04 LTS (don't change)
- Java 17 OpenJDK is required for LIRICAL
- Volume mounts: `examples/inputs:/app/examples/inputs`, `examples/outputs:/app/examples/outputs`
- Working directory: `/app`

### Database and Resource Management
- LIRICAL requires ~4-6GB of database files for hg38 assembly
- Use `./scripts/build_databases.sh` to build databases locally
- Use `./scripts/run_lirical.sh download` for pre-built databases
- Resources directory structure: `resources/data/` for databases, `resources/lirical-cli-X.X.X-distribution.zip`
- Exomiser data release 2508 is the current default for genomic analysis
- Never commit resources to git (large files, gitignored)

## LIRICAL Integration Points

### Input Formats
- **CLI Parameters**: `--observed`, `--negated`, `--age`, `--sex` for phenotype specification
- **HPO Terms**: Must be in format `HP:XXXXXXX` (e.g., `HP:0001156`)
- **Target Diseases**: Text files with OMIM IDs (one per line) for WGS/WES analysis
- **VCF Files**: Optional genomic variant files for enhanced analysis (hg38 assembly)

### Output Formats
- **HTML**: Visual reports with disease rankings and detailed breakdowns
- **TSV**: Tabular data for programmatic analysis
- **JSON**: Structured results for downstream processing

### Critical Commands
```bash
# Setup everything for hg38
./scripts/setup_lirical.sh all

# Basic phenotype analysis
./scripts/run_lirical.sh prioritize --observed HP:0001156,HP:0001382 --age P5Y --sex FEMALE -o analysis1 -n patient1

# Target diseases analysis (WGS/WES)
./scripts/run_lirical.sh target-diseases --target-diseases diseases.txt --vcf variants.vcf --observed HP:0001156 -o genomic_analysis -n patient2

# Docker equivalent
./scripts/run_lirical.sh --docker prioritize --observed HP:0001156 -o test -n test
```

## Testing and Validation

### Before Committing Changes
1. Test script execution: `./scripts/setup_lirical.sh examples && ./scripts/run_lirical.sh help`
2. Verify Docker build: `./scripts/docker_helper.sh build`
3. Run example analysis: `./scripts/run_lirical.sh prioritize --observed HP:0001156 -o test -n test`
4. Check all scripts have executable permissions

### Example Data
- `examples/inputs/example_target_diseases.txt` - Sample target diseases for WGS/WES analysis
- `examples/inputs/example_commands.sh` - Executable script with CLI examples
- Both contain same phenotypes: Brachydactyly, Joint hypermobility, Tall stature

## External Dependencies

- **LIRICAL releases**: https://github.com/TheJacksonLaboratory/LIRICAL/releases
- **Documentation**: https://lirical.readthedocs.io/en/latest/
- **Stable documentation**: https://thejacksonlaboratory.github.io/LIRICAL/stable/
- **HPO terms**: http://www.human-phenotype-ontology.org/
- **Phenopackets**: https://phenopackets-schema.readthedocs.io/

## Safety and Maintenance

- Never modify `resources/` or `examples/` content in git (gitignored for good reason)
- Always test scripts on both host system and Docker container
- Maintain backward compatibility in script interfaces
- Document any new HPO terms or analysis parameters in examples
- Keep Docker image size reasonable (currently ~1GB without resources)

When modifying this project, prioritize user experience in script interfaces and maintain the clean separation between application logic (scripts), runtime environment (Docker), and user data (gitignored directories).

— End of instructions —
