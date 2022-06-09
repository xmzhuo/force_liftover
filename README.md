# force_liftover
liftover vcf with brutal force </br>
It will liftover a malformat/problematic/iregular vcf by dealing with the siteonly vcf first. Then the original and target position and alleleic will be add to INFO as prior_to_<new_build>=chr1-1234-A-T; lift_to_<new_build>=chr1-2341-T-A. Then the remaining INFO and FORMAT will be added back to the vcf. </br>
However, please use cautiously as the annotation in the vcf won't be changed to reflect the new position or allelice information.

#Environment:
Ubuntu 18.04 or newer

#Dependency: 
picard Version:2.27.1 or newer </br>
bcftools version: 1.9 or newer


