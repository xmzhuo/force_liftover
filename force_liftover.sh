
#picard Version:2.27.1 or newer
PICARD=/path/to/picard.jar
#bcftools version: 1.9 or newer
BCFTOOLS=/path/to/bcftools

input=$1
chain=$2
reference=$3
output=$4

force_liftover() {
    #force liftover when vcf is damaged, use cautious especially when ref and alt switch between genome build
    local input=$1
    local chain=$2
    local reference=$3
    local output=$4

    local build=$(basename $reference | sed 's/\..*$//')

    #making site only vcf
    local siteonly=${input%.vcf*}.siteonly.vcf
    java -jar $PICARD MakeSitesOnlyVcf -I $input -O $siteonly
    #liftover site only vcf
    java -jar $PICARD \
        LiftoverVcf \
        -I $siteonly \
        -O ${output%.vcf*}.siteonly.vcf \
        -C $chain \
        -REJECT ${output%.vcf*}.siteonly.rejected.vcf \
        -R $reference \
        --WARN_ON_MISSING_CONTIG true \
        --WRITE_ORIGINAL_POSITION true \
        --WRITE_ORIGINAL_ALLELES true \
        --ALLOW_MISSING_FIELDS_IN_HEADER true \
        --RECOVER_SWAPPED_REF_ALT true
    
    #enchance allele match to deal with multialleic sites ie: chr5-43436554 > A,AAAAAC-chr5-43436554
    $BCFTOOLS query -f '%OriginalAlleles\t%OriginalContig-%OriginalStart\t%REF-%ALT\t%CHROM\t%POS\t%ID\t%REF\t%ALT\n' ${output%.vcf*}.siteonly.vcf \
    | awk -F'\t' '{if($1 == ".") $1=$7","$8; print $1"-"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t"$8}' | sort -k1 - > ${output%.vcf*}.oripos.tsv
    
    $BCFTOOLS query -f '%REF,%ALT\n' $input > ${output%.vcf*}.vcfbody1.tsv
    $BCFTOOLS view -H $input | sed 's/\t/-/' > ${output%.vcf*}.vcfbody2.tsv
    paste -d'-' ${output%.vcf*}.vcfbody1.tsv ${output%.vcf*}.vcfbody2.tsv | sort -k1 - > ${output%.vcf*}.vcfbody.tsv

    join -1 1 -2 1 -t $'\t' ${output%.vcf*}.oripos.tsv ${output%.vcf*}.vcfbody.tsv | sed 's/\t\t/\t/' | sort | uniq > ${output%.vcf*}.join.tsv
    cat ${output%.vcf*}.join.tsv | cut -d $'\t' -f 1-2,8-10 --complement > ${output%.vcf*}.vcfbase.tsv
    #every field before format (CHROM to INFO)
    cat ${output%.vcf*}.vcfbase.tsv | cut -d $'\t' -f 1-8 > ${output%.vcf*}.vcf1.tsv
    #every field after format
    cat ${output%.vcf*}.vcfbase.tsv | cut -d $'\t' -f 9- > ${output%.vcf*}.vcf2.tsv
    #get the new build position and nt change, such as lift_to_b37=chr1-1234-A-T;prior_to_b37=chr1-1243 
    cat ${output%.vcf*}.join.tsv | cut -d $'\t' -f 1-4 | cut -d '-' -f 2- | awk -v var=$build '{print "lift_to_"var"="$3"-"$4"-"$2";prior_to_"var"="$1}'> ${output%.vcf*}.posinfo.tsv
    #get the original nt change, such as A-T
    cat ${output%.vcf*}.join.tsv | cut -d $'\t' -f 9-10 | awk '{print $1"-"$2}'> ${output%.vcf*}.pos.tsv
    #prepare the change in both old and new build, in case of force liftover mess up, b37=chr1-1234-A-T;OriginalPos=chr1-1243-A-T
    paste -d'-' ${output%.vcf*}.posinfo.tsv ${output%.vcf*}.pos.tsv > ${output%.vcf*}.infoadd.tsv
    #add the new info, append to the end
    paste -d';' ${output%.vcf*}.vcf1.tsv ${output%.vcf*}.infoadd.tsv > ${output%.vcf*}.vcfsite.tsv
    #add the format part back
    paste -d'\t' ${output%.vcf*}.vcfsite.tsv ${output%.vcf*}.vcf2.tsv > ${output%.vcf*}.vcfbody.tsv

    #rebuild the vcf file
    $BCFTOOLS view -h ${output%.vcf*}.siteonly.vcf > ${output%.vcf*}.vcfheader

    cat ${output%.vcf*}.vcfheader | grep -v '^#CHROM' > ${output%.vcf*}.vcf 
    echo "##INFO=<ID=lift_to_$build,Number=.,Type=String,Description="postion and nt change after liftover to $build">" >> ${output%.vcf*}.vcf
    echo "##INFO=<ID=prior_to_$build,Number=.,Type=String,Description="postion and nt change before liftover to $build">" >> ${output%.vcf*}.vcf
    $BCFTOOLS view -h $input | grep '^#CHROM' >> ${output%.vcf*}.vcf 

    cat ${output%.vcf*}.vcfbody.tsv >> ${output%.vcf*}.vcf

    $BCFTOOLS sort ${output%.vcf*}.vcf -Oz > ${output%.vcf*}.vcf.gz
    $BCFTOOLS index -t ${output%.vcf*}.vcf.gz

    rm $siteonly ${output%.vcf*}.*.tsv ${output%.vcf*}.vcfheader ${output%.vcf*}.vcf
    
}

force_liftover $input $chain $reference $output
