#!/bin/bash

module add apps/plink/2.00

UKB_GEN_DIR="" ## ADD THIS IN
SAMPLEFILE=${UKB_GEN_DIR}/data.chr1-22_plink.sample
OUTPUT="data/gen-data"

## Make snplist file
SNP1="rs34743896"
SNP2="rs35743227"
SNPLIST="data/snplist"
echo ${SNP1} > ${SNPLIST}
echo ${SNP2} >> ${SNPLIST}

plink \
  --bgen ${UKB_GEN_DIR}/data.chr02.bgen \
  --sample ${UKB_GEN_DIR}/data.chr1-22_plink.sample \
  --keep-autoconv \
  --extract ${SNPLIST} \
  --export A \
  --out ${OUTPUT}-chr2

## If the above PLINK command fails, then re-run it using the commented out command after figuring out why it failed
# plink \
#   --pfile data/gen-data-chr2 \
#   --extract ${SNPLIST} \
#   --export A \
#   --out ${OUTPUT}-chr2

plink \
  --bgen ${UKB_GEN_DIR}/data.chr21.bgen \
  --sample ${UKB_GEN_DIR}/data.chr1-22_plink.sample \
  --keep-autoconv \
  --extract ${SNPLIST} \
  --export A \
  --out ${OUTPUT}-chr21

## If the above PLINK command fails, then re-run it using the commented out command after figuring out why it failed
# plink \
#   --pfile data/gen-data-chr21 \
#   --extract ${SNPLIST} \
#   --export A \
#   --out ${OUTPUT}-chr21

rm *.pgen
rm *.psam
rm *.pvar