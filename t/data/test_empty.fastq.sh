#! /bin/bash
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -t 00:02:00
#SBATCH -A lu2016-2-7
#SBATCH -p lu
#SBATCH -J test_empty.fastq
#SBATCH -o test_empty.fastq%j.out
#SBATCH -e test_empty.fastq%j.err
module load icc/2016.1.150-GCC-4.9.3-2.25 impi/5.1.2.150 SAMtools/1.3.1 HISAT2/2.0.4 BEDTools/2.25.0 ucsc-tools/R2016a 
hisat2  -x /projects/fs1/med-sal/git/SLURM_bioinformatics_scripts/t/data/hg38/hg38 -U /projects/fs1/med-sal/git/SLURM_bioinformatics_scripts/t/data/test_empty.fastq.gz --threads 2 --add-chrname > $SNIC_TMP/test_empty.fastq_hisat.sam
samtools view -Sb  $SNIC_TMP/test_empty.fastq_hisat.sam | samtools sort -@ 1 -o $SNIC_TMP/test_empty.fastq_hisat.sorted.bam -
if  [ -f $SNIC_TMP/test_empty.fastq_hisat.sorted.bam ]&&[ -s $SNIC_TMP/test_empty.fastq_hisat.sorted.bam ]; then
rm -f $SNIC_TMP/test_empty.fastq_hisat.sam
fi
mv $SNIC_TMP/test_empty.fastq_hisat.sorted.bam /projects/fs1/med-sal/git/SLURM_bioinformatics_scripts/t/data/HISAT2_OUT/test_empty.fastq_hisat.sorted.bam
module purge
module load GCC/4.9.3-2.25 OpenMPI/1.10.2 icc/2016.1.150-GCC-4.9.3-2.25 impi/5.1.2.150 BEDTools/2.25.0 Java/1.8.0_72 picard/2.8.2 ucsc-tools/R2016a 
bedtools genomecov -bg -split -ibam /projects/fs1/med-sal/git/SLURM_bioinformatics_scripts/t/data/HISAT2_OUT/test_empty.fastq_hisat.sorted.bam -g /projects/fs1/med-sal/git/SLURM_bioinformatics_scripts/t/data/fake_hg38.chrom.sizes.txt | sort -k1,1 -k2,2n > /projects/fs1/med-sal/git/SLURM_bioinformatics_scripts/t/data/HISAT2_OUT/test_empty.fastq_hisat.bedGraph
polish_bed_like_files.pl -bed_file /projects/fs1/med-sal/git/SLURM_bioinformatics_scripts/t/data/HISAT2_OUT/test_empty.fastq_hisat.bedGraph
bedGraphToBigWig /projects/fs1/med-sal/git/SLURM_bioinformatics_scripts/t/data/HISAT2_OUT/test_empty.fastq_hisat.bedGraph /projects/fs1/med-sal/git/SLURM_bioinformatics_scripts/t/data/fake_hg38.chrom.sizes.txt /projects/fs1/med-sal/git/SLURM_bioinformatics_scripts/t/data/HISAT2_OUT/test_empty.fastq_hisat.bw

