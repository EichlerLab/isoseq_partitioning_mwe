# Partitioning reads by mapping location
This is a simple pipeline demonstrating the method in Dougherty et al. 2018 for partitioning FLNC reads by mapping location with regard for segmental duplications.

## Quick start
Use the `environment.yml` file to install the conda environment. (For eichlerlab users, run `source /net/eichler/vol2/eee_shared/modules/anaconda/4.4.0/envs/isoseq/bin/activate isoseq`)
Then run:
```bash
snakemake define_partitions
snakemake
```

## Input preparation
FLNCs should be mapped to a reference with GMAP. The segdups file is generated from the genomicSuperDup file (available from UCSC genome browser) using this command:
```bash
zcat genomicSuperDup.tab.gz | awk 'OFS="\t"{print $1,$2,$3,$7":"$8"-"$9}' > hg38_segdups.bed 
```
