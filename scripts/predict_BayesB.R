#####################################
# Make phenotype predictions using BayesB
#
# Arguments: [1] id (i.e. wheat_599_CIMMYT)
#            [2] JobNum (use PSB JobArray)
#            [3] Degrees of Freedom (default = 5)
#            [4] Traits to apply to (default = all)
#            [5] Output directory
#
#
# Written by: Christina Azodi
# Original: 4.26.17
# Modified: 
#####################################
library(BGLR)

# Removes all existing variables from the workspace
rm(list=ls())
args = commandArgs(trailingOnly=TRUE)

start.time <- Sys.time()

# Read in arguments with 5 as the default PCs to include
if (length(args)==0) {
  stop("Need at least one argument (ID)", call.=FALSE)
} else if (length(args)==2) {
  # default output file
  args[3] <- 5
  args[4] <- 'all'
  args[5] <- "/mnt/home/azodichr/03_GenomicSelection/"
}
#id <- 'wheat_599_CIMMYT'
#jobNum <- 2
#pc.num <- 5
id = args[1]
jobNum = as.numeric(args[2])
df0 = as.numeric(args[3])
trait = args[4]
save_dir = args[5]

## load the phenotypes and PCs
setwd(paste("/mnt/home/azodichr/03_GenomicSelection/", id, sep=''))
Y <- read.csv('01_Data/pheno.csv', row.names=1)
X <- read.csv('01_Data/geno.csv', row.names=1)
cvs <- read.csv('01_Data/CVFs.csv', row.names=1)

if (trait == 'all') {
  print('Modeling all traits')
} else {
  Y <- Y[trait]
}

# Make output directory
setwd(save_dir)
dir.create(id)
setwd(id)
dir.create(paste('05_BayesB_df0_', df0, sep=''))
setwd(paste('05_BayesB_df0_', df0, sep=''))


# Center and scale X (makes it equivalent to the input for the linear model and methods that use that G matrix)
X=scale(X)

for(i in 1:length(Y)){
  print(paste('trait =',names(Y)[i]))
  dir.create(paste('trait_',names(Y)[i], sep=''))
  setwd(paste('trait_',names(Y)[i], sep=''))
  dir.create('output')
  y=Y[, names(Y)[i]]
  CV.fold= paste('cv_', toString(jobNum-1), sep='')
  ETA=list(list(X=X,model='BayesB')) 
  
  if(CV.fold =='cv_0'){
    # fit model to the entire data set and save model
    fm=BGLR(y=y,ETA=ETA,verbose=FALSE,nIter=12000,burnIn=2000)
    save(fm,file='full_model.RData')
  }
  
  else{
    # load the folds
    tst=cvs[,CV.fold]
    yhat <- data.frame(cbind(y, yhat = 0))
    yhat$yhat <- as.numeric(yhat$yhat)
    row.names(yhat) <- row.names(Y)

    for(j in 1:5){
      print(paste('fold =',j))
      test <- which(tst==j)
      yNA <- y
      yNA[test] <- NA # Mask yields for validation set
      fm=BGLR(y=yNA,ETA=ETA,verbose=FALSE,nIter=12000,burnIn=2000)
      yhat$yhat[test] <- fm$yHat[test]

    }
    unlink('*.dat')
    write.table(yhat, paste('output/', CV.fold,'.csv', sep=''), sep=',', row.names=FALSE, col.names=TRUE)
    accuracy <- cor(yhat$y, yhat$yhat)
    end.time <- Sys.time()
    time.taken <- difftime(end.time, start.time, units='sec')
    df_out <- data.frame(CV.fold, accuracy, time.taken)
    write.table(df_out, 'accuracy.csv', append=TRUE, sep=',', row.names=FALSE, col.names=FALSE)  
  }
  setwd('../')
}
print('Complete')
