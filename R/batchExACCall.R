#' Batch Call to the Broad Institue's ExAC project API to get Variant Annotations
#' @description This function make a batch call to the Broad Institue's ExAC project API
#' to retreive the annotation information of variants.
#' @author Ashish Jain
#' @param codeVector Character vector of codes consists of the variant
#' information in a format ("CHROMOSOME-POSITION-REFERENCE-VARIANT")
#' required for Broad Institue's ExAC project API.
#' @export
#' @return The output is a list object containing the
#' variant annotation information from the Broad Institute's ExAC
#' Project for each variant supplied.
#'
#' @examples
#' library(VCFAnnotator)
#' postVariantJson <- getVariantInfoFromExACAPI(c("14-21853913-T-C","14-21854139-A-G","22-46615746-A-G"))
#' print(postVariantJson[["14-21853913-T-C"]]$variant$allele_freq)
getVariantInfoFromExACAPI<-function(codeVector)
{
  #Intial Check for code vector
  codeVector <- ensurer::ensure_that(codeVector,!is.null(.),err_desc = "Please enter correct vector of Variant Codes.")
  #Making a POST Call request to the ExAC API
  postVariantResult <- POST("http://exac.hms.harvard.edu/rest/bulk/variant",body=toJSON(codeVector),encode = "json")
  #Extracting result from POST Call response
  postVariantJson <- content(postVariantResult)
  return(postVariantJson)
}
