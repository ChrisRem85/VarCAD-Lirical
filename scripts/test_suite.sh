#!/bin/bash

# VarCAD-Lirical Test Suite
# Comprehensive testing of LIRICAL wrapper functionality

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== VarCAD-Lirical Test Suite ===${NC}"
echo

# Test 1: Basic phenotype analysis
echo -e "${BLUE}Test 1: Basic phenotype analysis${NC}"
echo "Running Docker-based LIRICAL analysis with phenotypes: HP:0001156 (Brachydactyly), HP:0001382 (Joint hypermobility)"

docker run --rm \
    -v "$APP_DIR/examples/inputs:/app/examples/inputs" \
    -v "$APP_DIR/examples/outputs:/app/examples/outputs" \
    varcad-lirical \
    java -jar /opt/lirical/lirical-cli-2.2.0.jar prioritize \
    -d /app/resources/data \
    -o /app/examples/outputs/test_suite_basic \
    -f html -f tsv -f json \
    -p HP:0001156,HP:0001382 \
    --age P5Y \
    --sex FEMALE \
    --sample-id test_suite_basic

if [[ -f "$APP_DIR/examples/outputs/test_suite_basic/lirical.html" ]]; then
    echo -e "${GREEN}✓ Test 1 PASSED: Basic phenotype analysis completed${NC}"
    echo "  - HTML report: examples/outputs/test_suite_basic/lirical.html"
    echo "  - TSV data: examples/outputs/test_suite_basic/lirical.tsv"
    echo "  - JSON data: examples/outputs/test_suite_basic/lirical.json"
else
    echo -e "${RED}✗ Test 1 FAILED: Output files not found${NC}"
    exit 1
fi

echo

# Test 2: Different phenotypes
echo -e "${BLUE}Test 2: Analysis with different phenotypes${NC}"
echo "Running analysis with: HP:0000098 (Tall stature), HP:0001382 (Joint hypermobility)"

docker run --rm \
    -v "$APP_DIR/examples/inputs:/app/examples/inputs" \
    -v "$APP_DIR/examples/outputs:/app/examples/outputs" \
    varcad-lirical \
    java -jar /opt/lirical/lirical-cli-2.2.0.jar prioritize \
    -d /app/resources/data \
    -o /app/examples/outputs/test_suite_tall \
    -f html -f tsv -f json \
    -p HP:0000098,HP:0001382 \
    --age P25Y \
    --sex MALE \
    --sample-id test_suite_tall

if [[ -f "$APP_DIR/examples/outputs/test_suite_tall/lirical.html" ]]; then
    echo -e "${GREEN}✓ Test 2 PASSED: Alternative phenotype analysis completed${NC}"
else
    echo -e "${RED}✗ Test 2 FAILED: Output files not found${NC}"
    exit 1
fi

echo

# Test 3: Age variations
echo -e "${BLUE}Test 3: Pediatric vs adult analysis${NC}"
echo "Running pediatric analysis (6 months) with HP:0001156"

docker run --rm \
    -v "$APP_DIR/examples/inputs:/app/examples/inputs" \
    -v "$APP_DIR/examples/outputs:/app/examples/outputs" \
    varcad-lirical \
    java -jar /opt/lirical/lirical-cli-2.2.0.jar prioritize \
    -d /app/resources/data \
    -o /app/examples/outputs/test_suite_infant \
    -f html -f tsv -f json \
    -p HP:0001156 \
    --age P6M \
    --sex FEMALE \
    --sample-id test_suite_infant

if [[ -f "$APP_DIR/examples/outputs/test_suite_infant/lirical.html" ]]; then
    echo -e "${GREEN}✓ Test 3 PASSED: Pediatric analysis completed${NC}"
else
    echo -e "${RED}✗ Test 3 FAILED: Output files not found${NC}"
    exit 1
fi

echo

# Test 4: Official LDS2 example
echo -e "${BLUE}Test 4: LDS2 Official Example (complex case)${NC}"
echo "Running official LIRICAL developer example with connective tissue disorder phenotype"

docker run --rm \
    -v "$APP_DIR/examples/inputs:/app/examples/inputs" \
    -v "$APP_DIR/examples/outputs:/app/examples/outputs" \
    varcad-lirical \
    java -jar /opt/lirical/lirical-cli-2.2.0.jar prioritize \
    -d /app/resources/data \
    -o /app/examples/outputs/test_suite_LDS2 \
    -f html -f tsv -f json \
    -p HP:0001659,HP:0001166,HP:0001631,HP:0000193,HP:0012385,HP:0011645,HP:0000272,HP:0000347,HP:0001655,HP:0000768,HP:0004927,HP:0002650,HP:0001704 \
    --age P9Y \
    --sex FEMALE \
    --sample-id test_suite_LDS2

if [[ -f "$APP_DIR/examples/outputs/test_suite_LDS2/lirical.html" ]]; then
    echo -e "${GREEN}✓ Test 4 PASSED: LDS2 complex analysis completed${NC}"
else
    echo -e "${RED}✗ Test 4 FAILED: Output files not found${NC}"
    exit 1
fi

echo

# Summary
echo -e "${GREEN}=== Test Suite Summary ===${NC}"
echo -e "${GREEN}All tests passed successfully!${NC}"
echo
echo "Generated test outputs:"
echo "1. examples/outputs/test_suite_basic/ - Basic phenotype analysis (5 year old female)"
echo "2. examples/outputs/test_suite_tall/ - Tall stature analysis (25 year old male)"
echo "3. examples/outputs/test_suite_infant/ - Infant analysis (6 month old female)"
echo "4. examples/outputs/test_suite_LDS2/ - Complex connective tissue disorder (LDS2 official example)"
echo
echo "You can view the HTML reports in a web browser to see the clinical analysis results."
echo
echo "LDS2 Example demonstrates:"
echo "• Complex multi-system phenotype analysis (13 HPO terms)"
echo "• Connective tissue disorder differential diagnosis"
echo "• Official LIRICAL developer test case validation"
echo
echo -e "${YELLOW}Note: Genomic analysis requires Exomiser v2508 variant databases${NC}"
echo -e "${YELLOW}Current setup supports phenotype-only analysis${NC}"