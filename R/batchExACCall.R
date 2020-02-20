#' Batch Call to the Broad Institue's ExAC project API to get Variant Annotations
#' @description This function carries out a batch call to the
#' @author Ashish Jain
#' @param codeVector Character vector of codes consists of the variant
#' information in a format ("CHROMOSOME-POSITION-REFERENCE-VARIANT")
#' required for Broad Institue's ExAC project API.
#' @export
#' @return The output is a list object containing the
#' variant annotation information from the Broad Institute's ExAC
#' Project for each variant supplied.
getVariantInfoFromExACAPI<-function(codeVector)
{
  postVariantResult <- POST("http://exac.hms.harvard.edu/rest/bulk/variant",body=toJSON(codeVector),encode = "json")
  postVariantJson <- content(postVariantResult)
  return(postVariantJson)
}
