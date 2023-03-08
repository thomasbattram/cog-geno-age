## README

Association between genotype/genotype:age interaction (genotype at rs34743896 and rs35743227) and cognition - as measured by the UKB variable "Duration to complete numeric path" (https://biobank.ndph.ox.ac.uk/showcase/field.cgi?id=20156variable).

Time when outcome was collected: https://biobank.ndph.ox.ac.uk/showcase/field.cgi?id=20136

## Workflow

1. Copy "data.51913.csv" (UKB phenotype data) and "linker.81499.csv" (UKB-ID to IEU-ID linker file) from the RDSF space for the UKB project "81499" to local working directory
2. Run [`extract-genetic-data.sh`](scripts/extract-genetic-data.sh) to extract UKB genetic data for the SNPs of interest
3. Run [`run-interaction-models.R`](scripts/run-interaction-models.R) to run the associations.
4. Remove the "data.51913.csv" and "linker.81499.csv" from local directory
