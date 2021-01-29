#' Annotate the variants supplied in a VCF file
#' @description This function annotates the variants by parsing
#' VCF file supplied as input and call the Broad Institue's ExAC
#' project API to get additional variant annotations.
#' @author Ashish Jain
#' @param file The path of the file containing the variant
#' information in the VCF format
#' @export
#' @return The output is a dataframe object containing the
#' annotation of the variants parsed from the VCF file and
#' downloaded from the Broad Institute's ExAC Project. The
#' annotation includes the chromosome, Postion, Variant Type,
#' Depth of the reads, Alternate Allele Count, Percentage of
#' Allele to Gentotype, Allele Frequency, Consequence.
#'
#' @examples
#' library(VCFAnnotator)
#' VCFfilePath <- system.file('extdata', 'Challenge_data_test.vcf', package = 'VCFAnnotator')
#' t <- annotateVariant(file = VCFfilePath)
#' head(t)

annotateVariant<-function(file){

  #Intial Check for the file path
  file <- ensurer::ensure_that(file,file.exists(.),
                                err_desc = "Please enter correct path of VCF file.")
  # file <- ensurer::ensure_that(file,str_ends(.,".vcf") || str_ends(.,".VCF"),
  #                              err_desc = "Please enter path of a VCF file.")
  ##Reading and loading the variant informatioon from the VCF file to data frame
  data<-read.table(file,sep = "\t")
  ##Iterating over the variant data to extract annotations
  annotationObject<-data.frame(t(apply(data,1,function(x){
    #Creating the code required for Broad Institue's ExAC project API
    chromosome <- x[1]
    position <- trimws(x[2])
    reference <- x[4]
    variant <- x[5]
    #Code is in format "CHROMOSOME-POSITION-REFERENCE-VARIANT"
    code <- createExACAPIVarCode(chromosome,position,reference,variant)

    ##Parsing the data in the INFO tab as key value pair into a data frame
    infoTable <- data.frame(strsplit(as.character(x[8]),";")) %>% separate(col = 1, into = c("Key", "Value"), sep = "=")

    #Type of variantion (INFO["TYPE"]). Selecting the deleterious possibilty based on the order defined below.
    #Rank High to Low: ins, del, complex, mnp, snp
    variantDelRankMap <- list(`snp`=0, `mnp`=1,`ins`=3,`del`=3,`complex`=2)
    variantList <- unlist(strsplit(infoTable[infoTable$Key == "TYPE",2],","))
    variantPosition <- which.max(unlist(lapply(seq(along = variantList), function(i) {return(variantDelRankMap[[variantList[i]]])})))
    variantNameMap <- list(`snp`="Single Nucleotide Polymorphism", `mnp`="Multi Nucleotide Polymorphism",`ins`="Insertion",`del`="Deletion",`complex`="Complex")
    typeOfVariation <- variantNameMap[[variantList[variantPosition]]]

    #Depth of Sequence coverage at the site if variation (INFO["DP"]).
    seqDepth <- infoTable[infoTable$Key == "DP",2]

    #Number of reads supporting the variant (INFO["AC"]).
    alleleCount <- unlist(strsplit(infoTable[infoTable$Key == "AC",2],","))[variantPosition]

    #Percentage of reads supporting the variant versus those supporting reference reads(INFO["AF"]*100).
    allelePercent <- as.numeric(unlist(strsplit(infoTable[infoTable$Key == "AF",2],","))[variantPosition])*100

    return(c(chromosome,position,typeOfVariation,seqDepth,alleleCount,allelePercent,code))
  })))

  colnames(annotationObject) <- c("Chromosome","Position","Type-of-Variant","Depth","Alternate-Allele","Percentage-Reads","Code")

  #Batch ExAC project API Call
  postVariantJson <- getVariantInfoFromExACAPI(as.character(annotationObject$Code))

  #Extracting allele Frequency and Consequence information of the variants
  ExACInfo<-data.frame(t(apply(annotationObject,1,function(rowObject){
    exACCode <- rowObject["Code"]
    variantInfo <- postVariantJson[[exACCode]]
    if(!is.null(variantInfo$variant$allele_freq)){
      value <- c(exACCode,variantInfo$variant$allele_freq)
    }else
    {
      value <- c(exACCode,"NA")
    }
    if(!is.null(variantInfo$consequence))
    {
      value <- c(value, paste(names(variantInfo$consequence),collapse = ","))
    }else
    {
      value <- c(value, "NA")
    }

    return(value)
  })))

  colnames(ExACInfo) <- c("Code","Allele-Frequency","Consequence")
  finalAnnotation<-cbind(subset(annotationObject,select=-Code),subset(ExACInfo,select= -Code))
  return(finalAnnotation)
}

#Function too create a code required for Broad Institue's ExAC project API
#Code is in format "CHROMOSOME-POSITION-REFERENCE-VARIANT"
createExACAPIVarCode<-function(chromosome,position,reference,variant)
{
  return(paste0(chromosome,"-",position,"-",reference,"-",variant))
}
