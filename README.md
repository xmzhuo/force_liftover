# force_liftover
## liftover vcf with brutal force </br>
It will liftover a malformat/problematic/iregular vcf by dealing with the siteonly vcf first. </br>
Then the original and target position and alleleic will be add to INFO as prior_to_<new_build>=chr1-1234-A-T; lift_to_<new_build>=chr1-2341-T-A. </br> 
In the finaly step, the remaining INFO and FORMAT will be added back to the vcf. </br>
However, please use cautiously as the annotation in the vcf won't be changed to reflect the new position or allelice information.

# Environment: 
Ubuntu 18.04 or newer

# Dependency: 
picard Version:2.27.1 or newer </br>
bcftools version: 1.9 or newer

# Example Input:
```
bash force_liftover.sh example.hg38.vcf.gz hg38ToHg19.over.chain.gz hg19.fasta example.hg19.vcf.gz
```

# Example Output:
```
##INFO=<ID=lift_to_hg19,Number=.,Type=String,Description=postion and nt change after liftover to hg19>
##INFO=<ID=prior_to_hg19,Number=.,Type=String,Description=postion and nt change before liftover to hg19>
##bcftools_viewVersion=1.4.1+htslib-1.4.1
##bcftools_viewCommand=view example.hg19.vcf.gz; Date=Thu Jun  9 16:09:08 2022
#CHROM  POS     ID      REF     ALT     QUAL    FILTER  INFO    FORMAT  HCC-1143BL-NovaSeq      HCC-1143-NovaSeq
chr1       847617  .       G       A       .       PASS    HighConfidence;TYPE=SNV;called_by=strelka2,mutect2,lancet;num_callers=3;CSQ=ENSG00000230699|lincRNA||non_coding_transcript_exon_variant||||||||ENST00000448179.1:n.332G>A||MODIFIER|SAMD11|||||AL645608.3|Clone_based_ensembl_gene;CancerGeneCensus=||||||||||;lift_to_hg19=chr1-847617-G-A;prior_to_hg19=chr1-912237-G-A AD:DP:AF        184,0:184:0     274,101:375:0.2693
chr1       882050  .       C       G       .       PASS    HighConfidence;TYPE=SNV;called_by=strelka2,mutect2,lancet;num_callers=3;CSQ=ENSG00000188976|protein_coding||intron_variant||||||||ENST00000327044.6:c.1660-125G>C||MODIFIER|NOC2L|||||NOC2L|HGNC;CancerGeneCensus=||||||||||;lift_to_hg19=chr1-882050-C-G;prior_to_hg19=chr1-946670-C-G   AD:DP:AF        192,0:192:0     280,102:382:0.267
```
