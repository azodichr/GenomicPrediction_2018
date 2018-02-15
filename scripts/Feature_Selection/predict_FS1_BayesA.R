#####################################
# Make phenotype predictions using rrBLUP
#
# Arguments: [1] geno_file.csv
#            [2] pheno_file.csv
#            [3] CVs.csv
#            [4] Number of reps (i.e. 10 will do cv_1-cv_10)
#            [5] Trait
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

# Read in arguments 
geno_file = args[1]
pheno_file = args[2]
CVs_file = args[3]
reps = as.numeric(args[4])
trait = args[5]

## load the phenotypes and PCs
Y <- read.csv(pheno_file, row.names= 1, header=TRUE)
X <- read.csv(geno_file, row.names=1, header=TRUE)
cvs <- read.csv(CVs_file, row.names=1, header=TRUE)

y <- Y[trait]


# Center and scale X (makes it equivalent to the input for the linear model and methods that use that G matrix)
X=scale(X)

i = 1
for(i in 1:reps){
  print(paste('CV rep =',1))
  
  # load the folds
  CV.fold= paste('cv_', toString(i), sep='')
  test=cvs[,CV.fold]

  # Mask phenotype data for cv fold-5 
  yNA <- y
  yNA[which(test==5),] <- NA # Mask yields for test set

  # Run model
  ETA=list(list(X=X,model='BayesA')) 
  fm=BGLR(y=yNA[,trait],ETA=ETA,verbose=FALSE,df0 = df0, nIter=12000,burnIn=2000)
  print(fm)
  # Pull the estimated posterior means of marker effects
  coef <- fm$ETA[[1]]$b  
  print(coef)
  coef <- sort(abs(coef))
  unlink('*.dat')
  
  for (j in c(10, 50, 100, 250, 500, 1000)){
    top <- names(tail(coef, j)) # Get the names of the top X abs(marker effects)
    save_name <- paste('geno', trait, 'BayA', j, paste('list',i, sep=''), sep='_')
    write(top, save_name, sep=',', ncolumns=1)
  }
}

print(time.taken)
