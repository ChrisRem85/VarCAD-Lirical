# Development Guide

Guide for developers contributing to VarCAD-Lirical.

## Development Environment Setup

### Prerequisites
- **Git** for version control
- **WSL2 Ubuntu** (Windows) or **native Ubuntu** (Linux)
- **Docker Desktop** (Windows) or **Docker Engine** (Linux)
- **Java 17** development kit
- **Bash** shell environment
- **Text editor/IDE** (VS Code recommended)

### Initial Setup
```bash
# Fork and clone repository
git clone https://github.com/YOUR_USERNAME/VarCAD-Lirical.git
cd VarCAD-Lirical

# Set upstream remote
git remote add upstream https://github.com/ChrisRem85/VarCAD-Lirical.git

# Create development branch
git checkout -b feature/your-feature-name

# Setup development environment
./scripts/setup_lirical.sh all
```

## Project Architecture

### Directory Structure
```
VarCAD-Lirical/
├── .github/
│   └── copilot-instructions.md    # AI assistant instructions
├── docs/                          # Documentation files
│   ├── installation.md
│   ├── usage-examples.md
│   ├── commands.md
│   ├── docker.md
│   ├── input-output.md
│   ├── troubleshooting.md
│   └── development.md (this file)
├── scripts/                       # Bash automation scripts
│   ├── run_lirical.sh            # Main analysis runner
│   ├── setup_lirical.sh          # Environment setup
│   ├── test_lirical.sh           # Test suite
│   └── build_databases.sh        # Database builder
├── Dockerfile                     # Container definition
├── .dockerignore                  # Docker build context exclusions
├── .gitignore                     # Git exclusions
└── README.md                      # Main project documentation
```

### Core Components

#### Script Architecture
- **Consistent Error Handling**: `set -euo pipefail` in all scripts
- **Colored Logging**: Standardized log functions across scripts
- **Modular Design**: Functions for reusable code blocks
- **Help Systems**: Comprehensive usage documentation in each script

#### Docker Integration
- **Base Image**: Ubuntu 24.04 LTS for consistency
- **Volume Mounts**: Clean separation of host/container data
- **Build Process**: Multi-stage builds for optimization
- **Runtime Flexibility**: Support for both direct and containerized execution

## Coding Standards

### Bash Script Guidelines

#### Script Header Template
```bash
#!/bin/bash

# Script Name: descriptive_name.sh
# Purpose: Brief description of script functionality
# Author: Your Name
# Version: x.y.z

set -euo pipefail

# Script directory detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
```

#### Logging Functions
```bash
# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Standard logging functions
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
```

#### Function Structure
```bash
# Function documentation
# Purpose: Brief description
# Parameters: $1 - description, $2 - description
# Returns: 0 on success, 1 on failure
function_name() {
    local param1="$1"
    local param2="$2"
    
    # Input validation
    if [[ -z "$param1" ]]; then
        log_error "Parameter 1 is required"
        return 1
    fi
    
    # Function logic
    log_info "Processing $param1"
    
    # Success indication
    log_success "Function completed successfully"
    return 0
}
```

#### Error Handling
```bash
# Function-level error handling
process_data() {
    local input_file="$1"
    
    if [[ ! -f "$input_file" ]]; then
        log_error "Input file not found: $input_file"
        return 1
    fi
    
    # Process with error checking
    if ! some_command "$input_file"; then
        log_error "Failed to process $input_file"
        return 1
    fi
    
    return 0
}

# Script-level error handling
main() {
    if ! process_data "$input"; then
        log_error "Data processing failed"
        exit 1
    fi
}
```

### Docker Best Practices

#### Dockerfile Structure
```dockerfile
# Use specific version tags
FROM ubuntu:24.04

# Set metadata
LABEL maintainer="your.email@example.com"
LABEL description="VarCAD-Lirical container"
LABEL version="2.2.0"

# Install packages in single layer
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy files with appropriate ownership
COPY --chown=app:app . /app/

# Use non-root user for security
RUN useradd -m app
USER app
```

## Testing Framework

### Test Suite Structure
The test suite in `test_lirical.sh` follows this pattern:

1. **Setup Phase**: Prepare test environment
2. **Execution Phase**: Run analysis with test data
3. **Validation Phase**: Verify expected outputs exist
4. **Cleanup Phase**: Clean up test artifacts (optional)

### Adding New Tests

#### Test Template
```bash
# Test N: Description of test
log_info "Test N: Descriptive test name"
echo "Brief description of what this test validates"

# Setup test parameters
test_output="test_directory"
test_name="test_identifier"

# Execute test
"$SCRIPT_DIR/run_lirical.sh" prioritize \
    --observed HP:0001156,HP:0001382 \
    --age P5Y \
    --sex FEMALE \
    -o "$test_output" \
    -n "$test_name"

# Validate results
if [[ -f "$APP_DIR/examples/outputs/$test_output/lirical.html" ]]; then
    log_success "Test N PASSED: Description of validation"
    echo "  - Expected output file created"
    echo "  - Additional validation details"
else
    log_error "Test N FAILED: Expected output not found"
    exit 1
fi

echo
```

#### Docker Test Template
```bash
# Test N: Docker-specific test
if command -v docker &> /dev/null && docker ps &> /dev/null; then
    log_info "Test N: Docker test description"
    
    # Execute Docker test
    "$SCRIPT_DIR/run_lirical.sh" --docker prioritize \
        --observed HP:0001156 \
        -o docker_test \
        -n docker_test
    
    # Validate Docker results
    if [[ -f "$APP_DIR/examples/outputs/docker_test/lirical.html" ]]; then
        log_success "Test N PASSED: Docker test completed"
    else
        log_error "Test N FAILED: Docker test output missing"
    fi
else
    log_warn "Docker not available - skipping Test N"
fi
```

### Continuous Integration

#### Pre-commit Checks
```bash
# Create pre-commit hook (.git/hooks/pre-commit)
#!/bin/bash

echo "Running pre-commit checks..."

# Check script syntax
for script in scripts/*.sh; do
    if ! bash -n "$script"; then
        echo "Syntax error in $script"
        exit 1
    fi
done

# Run test suite
if ! ./scripts/test_lirical.sh; then
    echo "Test suite failed"
    exit 1
fi

echo "Pre-commit checks passed"
```

## Contributing Workflow

### Development Process

#### 1. Issue Creation
- **Bug Reports**: Include system details, error messages, reproduction steps
- **Feature Requests**: Describe use case, expected behavior, acceptance criteria
- **Documentation**: Specify what needs clarification or addition

#### 2. Branch Strategy
```bash
# Feature development
git checkout -b feature/short-description

# Bug fixes
git checkout -b bugfix/issue-number-description

# Documentation updates
git checkout -b docs/section-being-updated
```

#### 3. Development Workflow
```bash
# Regular commits with descriptive messages
git add .
git commit -m "Add Docker integration for run_lirical.sh

- Implement --docker flag parsing
- Add Docker utility functions
- Update help documentation
- Add error handling for Docker unavailability"

# Sync with upstream regularly
git fetch upstream
git rebase upstream/main
```

#### 4. Testing Before Submission
```bash
# Run full test suite
./scripts/test_lirical.sh

# Test specific functionality
./scripts/run_lirical.sh prioritize --observed HP:0001156 -o dev_test -n dev_test

# Test Docker integration (if applicable)
./scripts/setup_lirical.sh docker-build
./scripts/run_lirical.sh --docker prioritize --observed HP:0001156 -o docker_dev_test -n docker_dev_test

# Validate on clean environment
docker run --rm -v "$(pwd):/workspace" ubuntu:24.04 bash -c "
  cd /workspace && 
  ./scripts/setup_lirical.sh all && 
  ./scripts/test_lirical.sh
"
```

### Pull Request Guidelines

#### PR Template
```markdown
## Description
Brief description of changes made.

## Type of Change
- [ ] Bug fix (non-breaking change fixing an issue)
- [ ] New feature (non-breaking change adding functionality) 
- [ ] Breaking change (change affecting existing functionality)
- [ ] Documentation update

## Testing
- [ ] Test suite passes (`./scripts/test_lirical.sh`)
- [ ] Manual testing completed
- [ ] Docker functionality tested (if applicable)
- [ ] Cross-platform testing (WSL2/Linux)

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated (if needed)
- [ ] No new warnings or errors introduced
```

#### Review Process
1. **Automated Checks**: CI pipeline validates basic functionality
2. **Code Review**: Maintainer reviews code quality and design
3. **Testing**: Comprehensive testing in review environment
4. **Documentation**: Verify documentation updates are complete
5. **Merge**: Squash and merge after approval

## Release Process

### Version Management
- **Major.Minor.Patch** semantic versioning
- **Major**: Breaking changes or significant new features
- **Minor**: New features maintaining backward compatibility
- **Patch**: Bug fixes and small improvements

### Release Checklist
```bash
# 1. Update version numbers
# - README.md project status
# - Dockerfile labels
# - Script headers (if applicable)

# 2. Update documentation
# - CHANGELOG.md with release notes
# - Documentation for new features
# - Updated examples if needed

# 3. Test release candidate
./scripts/test_lirical.sh
./scripts/setup_lirical.sh docker-build
# Test on clean environment

# 4. Create release
git tag -a v2.2.1 -m "Release version 2.2.1"
git push upstream v2.2.1

# 5. Update GitHub release notes
# - Summarize changes
# - Include breaking changes
# - Provide upgrade instructions
```

## Debugging and Troubleshooting

### Development Debugging
```bash
# Enable bash debugging
bash -x ./scripts/run_lirical.sh prioritize ...

# Java debugging
export JAVA_OPTS="-verbose:gc -XX:+PrintGCDetails"

# Docker debugging
docker build --progress=plain --no-cache .
```

### Common Development Issues

#### Script Permission Problems
```bash
# Fix after editing scripts
chmod +x scripts/*.sh

# Verify permissions
ls -la scripts/
```

#### Line Ending Issues (Windows)
```bash
# Convert to Unix line endings
dos2unix scripts/*.sh

# Configure Git properly
git config core.autocrlf input
```

#### Docker Build Context Issues
```bash
# Check .dockerignore is comprehensive
echo "examples/" >> .dockerignore
echo "resources/" >> .dockerignore
echo ".git/" >> .dockerignore
```

## Documentation Standards

### Documentation Structure
- **Main README**: High-level overview and quick start
- **Detailed Guides**: Comprehensive documentation in `docs/`
- **Inline Comments**: Code explanation where needed
- **Help Functions**: Built-in help in all scripts

### Writing Guidelines
- **Clear Structure**: Logical organization with headers
- **Code Examples**: Working examples for all features
- **Cross-References**: Links between related documentation
- **Maintenance**: Keep documentation current with code changes

## Performance Considerations

### Optimization Areas
- **Script Execution**: Minimize subprocess calls
- **Docker Images**: Multi-stage builds, layer caching
- **Database Access**: Efficient data directory organization
- **Memory Usage**: Java heap size optimization

### Benchmarking
```bash
# Time analysis execution
time ./scripts/run_lirical.sh prioritize --observed HP:0001156 -o benchmark -n benchmark

# Monitor resource usage
htop  # or
docker stats  # for containerized execution
```

## Security Considerations

### Input Validation
- **HPO Terms**: Validate format and existence
- **File Paths**: Prevent path traversal attacks
- **User Input**: Sanitize all user-provided data

### Docker Security
- **Non-root Execution**: Run containers as non-root user
- **Minimal Privileges**: Only necessary permissions
- **Network Isolation**: Disable networking when not needed

## Future Development

### Planned Enhancements
- **Performance Optimization**: Faster database access
- **Additional Output Formats**: XML, PDF reports
- **API Integration**: REST API for remote access
- **Cloud Deployment**: Kubernetes, AWS Batch support

### Architecture Evolution
- **Modular Design**: Plugin architecture for extensions
- **Configuration Management**: External configuration files
- **Logging Framework**: Structured logging with levels
- **Monitoring**: Health checks and metrics collection

This development guide provides the foundation for contributing to VarCAD-Lirical. Follow these guidelines to ensure consistent, high-quality contributions that maintain the project's standards and compatibility.