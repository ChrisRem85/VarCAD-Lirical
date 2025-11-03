# Usage Examples

Comprehensive examples for running LIRICAL analysis with VarCAD-Lirical.

## Basic Phenotype Analysis

### Simple Disease Prioritization
```bash
# Basic analysis with observed phenotypes
./scripts/run_lirical.sh prioritize \
  --observed HP:0001156,HP:0001382 \
  --age P5Y \
  --sex FEMALE \
  -o basic_example \
  -n patient_001
```

### Analysis with Negated Phenotypes
```bash
# Include both observed and negated phenotypes
./scripts/run_lirical.sh prioritize \
  --observed HP:0001156,HP:0001382,HP:0002615 \
  --negated HP:0000252,HP:0001250 \
  --age P10Y \
  --sex MALE \
  -o negated_example \
  -n patient_002
```

### Age-Specific Analysis
```bash
# Pediatric analysis (5 years old)
./scripts/run_lirical.sh prioritize \
  --observed HP:0001156,HP:0001382 \
  --age P5Y \
  --sex FEMALE \
  -o pediatric_analysis \
  -n child_patient

# Adult analysis
./scripts/run_lirical.sh prioritize \
  --observed HP:0001156,HP:0001382 \
  --age P30Y \
  --sex MALE \
  -o adult_analysis \
  -n adult_patient
```

## Complex Clinical Cases

### LDS2 Connective Tissue Disorder (Official Example)
```bash
# Complex multi-system phenotype analysis
./scripts/run_lirical.sh prioritize \
  --observed HP:0001156,HP:0001382,HP:0002615,HP:0000767,HP:0001519,HP:0002647,HP:0003423,HP:0002705,HP:0004970,HP:0002023,HP:0100775,HP:0000028,HP:0000303 \
  --age P5Y \
  --sex FEMALE \
  -o LDS2_complex \
  -n LDS2_patient

# Expected results:
# - Loeys-Dietz syndrome 3: 99.87% probability
# - Marfan syndrome: 98.99% probability
# - Multiple other connective tissue disorders ranked
```

### Cardiovascular Disorders
```bash
# Hypertrophic cardiomyopathy case
./scripts/run_lirical.sh prioritize \
  --observed HP:0001639,HP:0001644,HP:0005162,HP:0001635 \
  --age P45Y \
  --sex MALE \
  -o cardiomyopathy \
  -n cardio_patient
```

### Metabolic Disorders
```bash
# Glycogen storage disease case
./scripts/run_lirical.sh prioritize \
  --observed HP:0001943,HP:0002240,HP:0000819,HP:0001250 \
  --age P2Y \
  --sex FEMALE \
  -o metabolic_disorder \
  -n metabolic_patient
```

## Genomic Analysis with VCF Files

### Basic VCF Integration
```bash
# Phenotype + genomic variant analysis
./scripts/run_lirical.sh prioritize \
  --observed HP:0001156,HP:0001382 \
  --vcf patient_variants.vcf \
  --age P5Y \
  --sex FEMALE \
  -o genomic_analysis \
  -n genomic_patient

# Note: Requires Exomiser databases (~22GB)
# VCF file should be in examples/inputs/
```

### Target Diseases Analysis
```bash
# Focus analysis on specific diseases from WGS/WES
./scripts/run_lirical.sh target-diseases \
  --target-diseases candidate_diseases.txt \
  --vcf variants.vcf \
  --observed HP:0001156,HP:0001382 \
  --age P5Y \
  --sex FEMALE \
  -o target_analysis \
  -n targeted_patient

# candidate_diseases.txt contains OMIM IDs:
# 609192
# 154700
# 132900
```

## Docker-Based Analysis

### Containerized Execution
```bash
# Build Docker image first
./scripts/setup_lirical.sh docker-build

# Run analysis in container
./scripts/run_lirical.sh --docker prioritize \
  --observed HP:0001156,HP:0001382 \
  --age P5Y \
  --sex FEMALE \
  -o docker_analysis \
  -n docker_patient

# All files automatically mounted between host and container
```

### Production Docker Workflow
```bash
# Complete Docker-based workflow
./scripts/setup_lirical.sh docker-build
./scripts/run_lirical.sh --docker target-diseases \
  --target-diseases production_diseases.txt \
  --vcf large_cohort.vcf \
  --observed HP:0001156,HP:0001382 \
  -o production_analysis \
  -n production_batch
```

## HPO Terms Reference

### Common Phenotypes

#### Growth and Development
- `HP:0001156` - Brachydactyly (short fingers/toes)
- `HP:0000098` - Tall stature
- `HP:0004322` - Short stature
- `HP:0001252` - Muscular hypotonia

#### Musculoskeletal
- `HP:0001382` - Joint hypermobility
- `HP:0002808` - Kyphosis
- `HP:0002650` - Scoliosis
- `HP:0000767` - Pectus excavatum

#### Cardiovascular
- `HP:0001639` - Hypertrophic cardiomyopathy
- `HP:0001644` - Dilated cardiomyopathy
- `HP:0002615` - Hypotension
- `HP:0000822` - Hypertension

#### Neurological
- `HP:0001250` - Seizures
- `HP:0000252` - Microcephaly
- `HP:0000256` - Macrocephaly
- `HP:0002194` - Delayed gross motor development

#### Facial Features
- `HP:0000303` - Facial asymmetry
- `HP:0000275` - Narrow face
- `HP:0000455` - Broad nose
- `HP:0000028` - Cryptorchidism

### Age Specifications
- `P5Y` - 5 years old
- `P2Y6M` - 2 years 6 months
- `P6M` - 6 months
- `P30Y` - 30 years old
- `adult` - General adult
- `child` - General child

## Analysis Organization

### Output Directory Structure
```bash
examples/outputs/
├── phenotype_analysis/          # Phenotype-only results
│   ├── basic_example/
│   ├── negated_example/
│   └── LDS2_complex/
├── genomic_analysis/            # VCF + phenotype results
│   ├── genomic_analysis/
│   └── target_analysis/
└── docker_analysis/             # Docker-based results
    └── docker_analysis/
```

### Batch Processing
```bash
# Process multiple patients
for patient in patient_001 patient_002 patient_003; do
  ./scripts/run_lirical.sh prioritize \
    --observed HP:0001156,HP:0001382 \
    --age P5Y \
    --sex FEMALE \
    -o batch_analysis \
    -n ${patient}
done
```

## Result Interpretation

### High-Confidence Results (>95%)
- Strong evidence for specific disease
- Review detailed HTML report
- Consider clinical correlation

### Moderate Confidence (50-95%)
- Multiple candidate diseases
- Additional phenotyping may help
- Consider genomic analysis

### Low Confidence (<50%)
- Broad differential diagnosis
- May need additional phenotypes
- Consider atypical presentations

## Performance Considerations

### Analysis Speed
- Phenotype-only: ~30 seconds per analysis
- With VCF: 2-5 minutes depending on variant count
- Target diseases: Faster than full analysis

### Resource Usage
- RAM: 2-4GB during analysis
- CPU: Benefits from multiple cores
- Storage: Results are 1-10MB per analysis

## Common Patterns

### Connective Tissue Disorders
```bash
# Typical phenotypes
--observed HP:0001156,HP:0001382,HP:0002615,HP:0000767
```

### Metabolic Disorders
```bash
# Growth and development focus
--observed HP:0001943,HP:0002240,HP:0000819,HP:0001252
```

### Cardiovascular Syndromes
```bash
# Heart and vessel abnormalities
--observed HP:0001639,HP:0001644,HP:0005162,HP:0001635
```

## Next Steps

After running analysis:

1. **Review HTML Report**: Primary visual analysis
2. **Check TSV Data**: For programmatic analysis
3. **Validate Results**: Clinical correlation
4. **Consider Additional Analysis**: VCF integration if needed
5. **Export Results**: For clinical reporting

See [input-output.md](input-output.md) for detailed file format information.