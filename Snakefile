import os

SNAKEMAKE_DIR = os.path.dirname(workflow.snakefile)

shell.executable("/bin/bash")

if config == {}:
    configfile: "%s/config.yaml" % SNAKEMAKE_DIR

if not os.path.exists("log"):
    os.makedirs("log")

def get_parts():
    if not os.path.exists("partitioned/partitions.bed"):
        print("run snakemake define_partitions to create partitions.bed")
        sys.exit(1)
    parts = ["unmapped"]
    with open("partitioned/partitions.bed") as infile:
        for line in infile:
            chr, start, end, part = line.rstrip().split()[0:4]
            if part not in parts:
                parts.append(part)
    return parts

if os.path.exists("partitioned/partitions.bed"):
    PARTS = get_parts()
else:
    PARTS = []

localrules: all

rule all:
    input: expand("partitioned/isoseq.flnc.{part}.fastq", part=PARTS)

rule clean_fastq:
    input: "partitioned/isoseq.flnc.{part}.fastq"
    output: "partitioned/isoseq.flnc.{part}.cleaned.fastq"
    shell:
        "python scripts/clean_fastq.py {input} {output}"

rule partition:
    input: flnc=config["mapped_flnc"], partition_regions="partitioned/partitions.bed"
    output: "partitioned/isoseq.flnc.{part,\d+}.fastq", "partitioned/isoseq.regions.{part,\d+}.bed"
    run:
        outfile = open(output[1], "w")
        with open(input.partition_regions, "r") as reader:
            for line in reader:
                chr, start, end, name, reads = line.rstrip().split()
                if name == wildcards.part:
                    print(chr, start, end, sep="\t", file=outfile)
        outfile.close()
        shell("samtools view -b -q40 {input.flnc} -L {output[1]} | samtools fastq - > {output[0]}")

rule get_unmapped:
    input: flnc=config["mapped_flnc"]
    output: "partitioned/isoseq.flnc.unmapped.fastq"
    shell:
        "python scripts/get_unmapped.py {input} {output}"

rule define_partitions:
    input: flnc=config["mapped_flnc"], segdups=config["segdups"] 
    output: "partitioned/partitions.bed"
    shell:
        """samtools view -b {input.flnc} -q 40 | bedtools bamtobed > partitioned/flnc.sorted.bed
        bedtools merge -i partitioned/flnc.sorted.bed -c 4 -o count > partitioned/flnc.merged.bed
        python scripts/partition_reads_by_segdups.py {input.segdups} partitioned/flnc.merged.bed {output} --count_threshold 500"""
