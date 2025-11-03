# Input/Output Formats

Detailed specification of all input and output file formats used by VarCAD-Lirical.

## Input Formats

### HPO Terms (Command Line)

#### Format Specification
- **Syntax**: `HP:XXXXXXX` where X is a digit
- **Multiple Terms**: Comma-separated, no spaces
- **Case**: Case-sensitive, must be uppercase HP
- **Validation**: Terms validated against HPO database

#### Examples
```bash
# Single term
--observed HP:0001156

# Multiple terms
--observed HP:0001156,HP:0001382,HP:0002615

# With negated terms
--observed HP:0001156,HP:0001382 --negated HP:0000252,HP:0001250
```

#### Common HPO Terms
| HPO ID | Description | Category |
|--------|-------------|----------|
| HP:0001156 | Brachydactyly | Limb/digit abnormalities |
| HP:0001382 | Joint hypermobility | Musculoskeletal |
| HP:0002615 | Hypotension | Cardiovascular |
| HP:0000767 | Pectus excavatum | Thoracic abnormalities |
| HP:0001519 | Disproportionate tall stature | Growth abnormalities |
| HP:0000252 | Microcephaly | Head/neck abnormalities |
| HP:0001250 | Seizures | Neurological |

### VCF Files

#### File Location
- **Directory**: `examples/inputs/`
- **Naming**: Any valid filename ending in `.vcf` or `.vcf.gz`
- **Access**: Automatically detected and mounted in Docker

#### Format Requirements
- **Standard**: VCF 4.0+ specification
- **Assembly**: Must match `--assembly` parameter (default: hg38)
- **Coordinates**: 1-based genomic coordinates
- **Compression**: Supports gzip compression (.vcf.gz)

#### Example VCF Header
```vcf
##fileformat=VCFv4.2
##reference=GRCh38
##contig=<ID=chr1,length=248956422>
##INFO=<ID=AF,Number=A,Type=Float,Description="Allele Frequency">
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	SAMPLE
```

#### Supported Variant Types
- SNVs (Single Nucleotide Variants)
- Indels (Insertions/Deletions)
- Complex variants
- Structural variants (basic support)

### Target Disease Lists

#### File Format
- **Format**: Plain text file
- **Content**: One OMIM disease ID per line
- **Location**: `examples/inputs/`
- **Encoding**: UTF-8

#### Example File (`candidate_diseases.txt`)
```
609192
154700
132900
175050
608328
```

#### Disease ID Sources
- **OMIM**: Online Mendelian Inheritance in Man IDs
- **Format**: 6-digit numeric IDs
- **Validation**: IDs validated against LIRICAL disease database

### Age Specifications

#### ISO 8601 Duration Format
- **Syntax**: `P[n]Y[n]M[n]D` 
- **Examples**:
  - `P5Y` - 5 years old
  - `P2Y6M` - 2 years 6 months old
  - `P6M` - 6 months old
  - `P30Y` - 30 years old

#### Simple Terms
- `adult` - General adult (>18 years)
- `child` - General child (<18 years)
- `infant` - Infant (<1 year)

### Sex Values
- `MALE` - Male patient
- `FEMALE` - Female patient  
- `UNKNOWN` - Sex not specified or unknown

## Output Formats

### Directory Structure
```
examples/outputs/[analysis_name]/
├── lirical.html          # Primary visual report
├── lirical.tsv           # Tabular data
├── lirical.json          # Structured JSON data
└── [additional_files]    # Analysis-specific files
```

### HTML Report (`lirical.html`)

#### Content Sections
1. **Analysis Summary**: Patient info, analysis parameters
2. **Disease Rankings**: Top candidate diseases with probabilities
3. **Gene Analysis**: Associated genes and variants (if VCF provided)
4. **Phenotype Matching**: HPO term matching details
5. **Evidence Summary**: Supporting evidence for each diagnosis

#### Interactive Features
- **Sortable Tables**: Click column headers to sort
- **Expandable Sections**: Click to show/hide details
- **Hyperlinks**: Links to external databases (OMIM, HPO)
- **Graphs**: Probability distributions and evidence plots

#### Browser Compatibility
- Chrome/Chromium 90+
- Firefox 88+
- Safari 14+
- Edge 90+

### TSV Report (`lirical.tsv`)

#### Column Structure
| Column | Description | Example |
|--------|-------------|---------|
| rank | Disease ranking | 1, 2, 3... |
| diseaseId | OMIM disease ID | 609192 |
| diseaseName | Disease name | Loeys-Dietz syndrome 3 |
| probability | Disease probability | 0.9987 |
| compositeLR | Composite likelihood ratio | 458.23 |
| entrez_gene_id | Associated gene ID | 7046 |
| gene_symbol | Gene symbol | TGFBR1 |

#### Usage Examples
```bash
# View top 10 diseases
head -11 examples/outputs/analysis/lirical.tsv

# Extract diseases >50% probability
awk -F'\t' '$4 > 0.5' examples/outputs/analysis/lirical.tsv

# Sort by probability
sort -k4 -nr examples/outputs/analysis/lirical.tsv
```

### JSON Report (`lirical.json`)

#### Structure Overview
```json
{
  "analysis": {
    "analysisId": "patient_001",
    "analysisDate": "2024-11-03T10:30:00Z",
    "liricalVersion": "2.2.0",
    "assembly": "hg38"
  },
  "patient": {
    "age": "P5Y",
    "sex": "FEMALE",
    "observedPhenotypes": ["HP:0001156", "HP:0001382"],
    "negatedPhenotypes": []
  },
  "results": {
    "diseases": [
      {
        "rank": 1,
        "diseaseId": "609192",
        "diseaseName": "Loeys-Dietz syndrome 3",
        "probability": 0.9987,
        "compositeLR": 458.23
      }
    ]
  }
}
```

#### Key Sections

##### Analysis Metadata
```json
"analysis": {
  "analysisId": "unique_identifier",
  "analysisDate": "ISO_8601_timestamp", 
  "liricalVersion": "version_string",
  "assembly": "genome_assembly",
  "analysisType": "prioritize|target-diseases"
}
```

##### Patient Information
```json
"patient": {
  "age": "age_specification",
  "sex": "MALE|FEMALE|UNKNOWN",
  "observedPhenotypes": ["HP:term1", "HP:term2"],
  "negatedPhenotypes": ["HP:term3", "HP:term4"],
  "vcfFile": "optional_vcf_filename"
}
```

##### Disease Results
```json
"diseases": [
  {
    "rank": 1,
    "diseaseId": "OMIM_ID",
    "diseaseName": "disease_name",
    "probability": 0.95,
    "compositeLR": 123.45,
    "genes": [
      {
        "geneId": "entrez_id",
        "geneSymbol": "GENE_NAME",
        "variants": ["variant_info"]
      }
    ]
  }
]
```

#### Programmatic Access
```python
import json

# Load results
with open('examples/outputs/analysis/lirical.json', 'r') as f:
    results = json.load(f)

# Extract top disease
top_disease = results['results']['diseases'][0]
print(f"Top diagnosis: {top_disease['diseaseName']} ({top_disease['probability']:.2%})")

# Filter high-confidence results
high_conf = [d for d in results['results']['diseases'] if d['probability'] > 0.8]
```

```r
# R example
library(jsonlite)

# Load results
results <- fromJSON('examples/outputs/analysis/lirical.json')

# Create dataframe of diseases
diseases_df <- results$results$diseases

# Plot probability distribution
hist(diseases_df$probability, main="Disease Probability Distribution")
```

## Analysis Parameters File

Some analyses generate a parameters file documenting exact settings used.

### Format
```json
{
  "input_parameters": {
    "observed_phenotypes": ["HP:0001156", "HP:0001382"],
    "negated_phenotypes": [],
    "age": "P5Y",
    "sex": "FEMALE",
    "vcf_file": "patient.vcf",
    "assembly": "hg38",
    "data_directory": "/app/resources/data"
  },
  "analysis_settings": {
    "output_formats": ["html", "tsv", "json"],
    "analysis_type": "prioritize",
    "timestamp": "2024-11-03T10:30:00Z"
  }
}
```

## File Size Expectations

### Typical Output Sizes
- **HTML Report**: 500KB - 2MB (depending on number of diseases)
- **TSV File**: 50KB - 500KB (depends on disease database size)
- **JSON File**: 100KB - 1MB (structured data)
- **Total per Analysis**: 1MB - 5MB typically

### Large Analysis Considerations
- **VCF with many variants**: Output files may be larger
- **Comprehensive disease analysis**: More diseases = larger files
- **Complex phenotypes**: More detailed evidence = larger reports

## Data Integration

### Importing to Databases
```sql
-- PostgreSQL example
CREATE TABLE lirical_results (
    analysis_id VARCHAR(100),
    rank INTEGER,
    disease_id VARCHAR(20),
    disease_name TEXT,
    probability DECIMAL(5,4),
    composite_lr DECIMAL(10,2)
);

COPY lirical_results 
FROM '/path/to/lirical.tsv' 
DELIMITER E'\t' 
CSV HEADER;
```

### Excel/Spreadsheet Import
1. Open Excel/LibreOffice Calc
2. Import `lirical.tsv` file
3. Specify tab delimiter
4. Set appropriate column types

### Bioinformatics Pipeline Integration
```bash
# Extract high-confidence diseases
awk -F'\t' 'NR>1 && $4>0.8 {print $2,$3,$4}' lirical.tsv > high_confidence.txt

# Merge with other analysis results
join -t$'\t' -1 2 -2 1 lirical.tsv other_results.tsv > merged_results.tsv
```

## Quality Control

### Validation Checks
- **HPO terms**: Verified against current HPO release
- **VCF format**: Standard VCF validation
- **Output completeness**: All expected files generated
- **Data consistency**: Cross-file data consistency checks

### Common Issues
- **Invalid HPO terms**: Check for typos in HP IDs
- **VCF assembly mismatch**: Ensure VCF matches specified assembly
- **Missing output files**: Check for analysis errors in logs
- **Encoding issues**: Ensure UTF-8 encoding for all text files

## Next Steps

- **Usage Examples**: See [usage-examples.md](usage-examples.md) for practical file examples
- **Commands**: See [commands.md](commands.md) for file specification options
- **Troubleshooting**: See [troubleshooting.md](troubleshooting.md) for file-related issues