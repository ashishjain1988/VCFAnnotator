#' Annotate the variants supplied in a VCF file
#' @description Annotate the variants supplied in a VCF file
#' @author Ashish Jain
#' @param file The path of the file containing the variant
#' information in the VCF format
#' @export
#' @return The output is a dataframe object containing the
#' annotation of the variants parsed from the VCF file and
#' downloaded from the Broad Institute's ExAC Project. The
#' annotation includes the chromosome,

annotateVariant<-function(file){

  file <- ensurer::ensure_that(file,file.exists(file),
                                err_desc = "Please enter correct path of VCF file.")
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

    #Type of variantion (INFO["TYPE"]). Selecting the first as the most deleterious possibilty.
    typeOfVariation <- unlist(strsplit(infoTable[infoTable$Key == "TYPE",2],","))[1]

    #Depth of Sequence coverage at the site if variation (INFO["DP"]).
    seqDepth <- infoTable[infoTable$Key == "DP",2]

    #Number of reads supporting the variant (INFO["AC"]).
    alleleCount <- infoTable[infoTable$Key == "AC",2]

    #Percentage of reads supporting the variant versus those supporting reference reads(INFO["AF"]*100).
    #allelePercent <- as.numeric(infoTable[infoTable$Key == "AF",2])*100
    allelePercent <- as.numeric(unlist(strsplit(infoTable[infoTable$Key == "AF",2],","))[1])*100

    return(c(chromosome,position,typeOfVariation,seqDepth,alleleCount,allelePercent,code))
  })))

  colnames(annotationObject) <- c("Chromosome","Position","Type-of-Variant","Depth","Alternate-Allele","Percentage-Reads","Code")

  postVariantJson <- getVariantInfoFromExACAPI(as.character(annotationObject$Code))

  out<-data.frame(t(apply(annotationObject,1,function(rowObject){
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

  colnames(out) <- c("Code","Allele-Frequency","Consequence")
  finalAnnotation<-cbind(subset(annotationObject,select=-Code),subset(out,select= -Code))
  return(finalAnnotation)
}

#Function too create a code required for Broad Institue's ExAC project API
#Code is in format "CHROMOSOME-POSITION-REFERENCE-VARIANT"
createExACAPIVarCode<-function(chromosome,position,reference,variant)
{
  return(paste0(chromosome,"-",position,"-",reference,"-",variant))
}

