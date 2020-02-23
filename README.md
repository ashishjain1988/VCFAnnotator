# VCFAnnotator-Tempus
This is an R package for the automatic annotation generation of the variants supplied in the VCF file into a text file.

**Requirement**

You need R version 3.6.1 or above to run this application. Other dependencies are:

* `tidyverse (>= 1.1.0)`
* `ensurer (>= 1.1.0)`
* `httr (>= 1.4.1)`
* `jsonlite (>=1.6.0)`

**How to install the R package**

* Install Dependencies
* `install.packages(c("tidyverse","ensurer","httr","jsonlite"))`

**From Github**

* Now install the `devtools` package
* `install.packages("devtools")`
* `library("devtools")`
* Run command `install_github("ashishjain1988/VCFAnnotator-Tempus")`

**From tar file**

* Run command `install.packages("<Absolute Path>/VCFAnnotatorTempus_1.0.0.tar.gz", repos = NULL)`

**Running the VCF Annotator**

VCF Annotator is an R package used for the automatic annotation generation of the variants supplied in the VCF file. This package parses information of variants supplied in a VCF file. This package also add the annotations from the Broad Institue's ExAC project by making a POST call to its [batch API](http://exac.hms.harvard.edu/rest/bulk/variant). The output in the text file have the annotations including 

* Type of variation (most deleterious)
* Depth of sequence coverage
* Number of reads supporting variants
* Percentage of reads supporting the variant versus those supporting reference reads
* Allele frequency from ExAC project
* Consequence of the variant from ExAC project

In our code, we rank the type of variations according to the magnitude of its deleterious possibilty (Insertion,Deletion > Complex > Multi Nucleotide Polymorphism > Single Nucleotide Polymorphism). In order to annotate the variants supplied in the VCF file `annotateVariant` function of this package is used. This function requires the path of the VCF file and then automatically annotates the variants and supply them in a data.frame object which can be written into a text file. A simple example is shown below by using an R terrminal.

```R
library(VCFAnnotatorTempus)

VCFfilePath <- system.file('extdata', 'Challenge_data.vcf', package = 'VCFAnnotatorTempus')
t <- annotateVariant(file = VCFfilePath)
write.table(t,"Challenge_data_annotated_variants.txt",sep="\t",quote = F,row.names = F)
```
In addition to that, there is another function `getVariantInfoFromExACAPI` which make a batch call to the Broad Institue's ExAC project API to retreive the annotation information of variants. More information about this function can be found by typing `?getVariantInfoFromExACAPI` in R terminal. This function is called by the `annotateVariant` function internally to add annotations from ExAC project.
