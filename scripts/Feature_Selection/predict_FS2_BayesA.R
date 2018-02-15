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
library(BGLR)

# Removes all existing variables from the workspace
rm(list=ls())
args = commandArgs(trailingOnly=TRUE)

# Read in arguments with 5 as the default PCs to include

#id <- 'wheat_599_CIMMYT'
#jobNum <- 2
#pc.num <- 5
id = args[1]
#id = 'maize_DP_Crossa'
keep = args[2]
trait = args[3]
df0 = 5

## load the phenotypes and PCs
setwd(paste("/mnt/home/azodichr/03_GenomicSelection/02_FeatureSelection/", id, sep=''))
#setwd(paste('/Volumes/azodichr/03_GenomicSelection/02_FeatureSelection/', id, sep=''))

keep_list <- readLines(keep)
Y <- read.csv('pheno.csv', row.names=1)
X <- read.csv('geno.csv', row.names=1)
X <- X[names(X) %in% keep_list]
cvs <- read.csv('CVFs.csv', row.names=1)


# Center and scale X (makes it equivalent to the input for the linear model and methods that use that G matrix)
X=scale(X)

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
fm=BGLR(y=yNA,ETA=ETA,verbose=FALSE,df0 = df0, nIter=12000,burnIn=2000)
yhat$yhat[test] <- fm$yHat[test]

unlink('*.dat')
accuracy <- cor(yhat$y[test], yhat$yhat[test])

to_save = paste(id, trait, keep, length(keep_list), 'BayesA', accuracy, sep=',')
write.table(to_save, 'results.csv', append=TRUE, sep=',', row.names=FALSE, col.names=FALSE, quote=FALSE)  


