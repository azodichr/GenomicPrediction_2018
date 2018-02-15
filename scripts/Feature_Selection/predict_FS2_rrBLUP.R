#####################################
# Make phenotype predictions using rrBLUP modified for feature selection (1-4: train, 5: test)
#
# Arguments: [1] id (i.e. wheat_599_CIMMYT)
#            [2] JobNum (use PSB JobArray)
#            [3] 
#
#
# Written by: Christina Azodi
# Original: 4.26.17
# Modified: CA 11/27/17
#####################################
library(rrBLUP)

# Removes all existing variables from the workspace
rm(list=ls())
args = commandArgs(trailingOnly=TRUE)

# Read in arguments with 5 as the default PCs to include
if (length(args)==0) {
  stop("Need at least one argument (ID)", call.=FALSE)
} else if (length(args)==2) {
  # default output file
  args[3] <- 5
}
#id <- 'rice_DP_Spindel'
#jobNum <- 2
#pc.num <- 5
id = args[1]
keep = args[2]
trait = args[3]

## load the phenotypes and PCs
setwd(paste("/mnt/home/azodichr/03_GenomicSelection/02_FeatureSelection/", id, sep=''))
#setwd(paste('~/Desktop/Genomic_Selection/GS_Datasets/', id, sep=''))

keep_list <- readLines(keep)
Y <- read.csv('pheno.csv', row.names=1)
X <- read.csv('geno.csv', row.names=1)
X <- X[names(X) %in% keep_list]
cvs <- read.csv('CVFs.csv', row.names=1)

# Make the relationship matrix from the markers
M=tcrossprod(scale(X))  # centered and scaled XX'
M=M/mean(diag(M))
rownames(M) <- 1:nrow(X)

# For trait in Y dataframe
print(paste('trait =',trait))
y=Y[, trait]
CV.fold= 'cv_1'
ETA=list(list(X=X,model='BayesA')) 
  
# load the folds
tst=cvs[,CV.fold]
yhat <- data.frame(cbind(y, yhat = 0))
yhat$yhat <- as.numeric(yhat$yhat)
row.names(yhat) <- row.names(Y)

test <- which(tst==5)
yNA <- y
yNA[test] <- NA # Mask yields for validation set
df <- data.frame(y=yNA,gid=1:nrow(X)) # Set up dataframe with traits and genotype labels (same order as in A1) 

rrblup <- kin.blup(df,K=M,geno="gid",pheno='y') #optional parameters: fixed effects, gaussian kernel, covariates
yhat$yhat[test] <- rrblup$g[test]

unlink('*.dat')
accuracy <- cor(yhat$y[test], yhat$yhat[test])

to_save = paste(id, trait, keep, length(keep_list), 'rrBLUP', accuracy, sep=',')
write.table(to_save, 'results.csv', append=TRUE, sep=',', row.names=FALSE, col.names=FALSE, quote=FALSE)  



