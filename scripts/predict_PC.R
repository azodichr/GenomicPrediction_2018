#####################################
# Make phenotype predictions using PCs
#
# Arguments: [1] id (i.e. wheat_599_CIMMYT)
#            [2] JobNum (use PSB JobArray)
#            [3] Number of PCs to use (default = 5)
#            [4] Output directory
#
#
# Written by: Christina Azodi
# Original: 4.24.17
# Modified: 
#####################################

# Removes all existing variables from the workspace
rm(list=ls())
args = commandArgs(trailingOnly=TRUE)

# Read in arguments with 5 as the default PCs to include
if (length(args)==0) {
  stop("Need at least one argument (ID)", call.=FALSE)
} else if (length(args)==2) {
  # default output file
  args[3] <- 5
  args[4] <- "/mnt/home/azodichr/03_GenomicSelection/"
}

id = args[1]
jobNum = as.numeric(args[2])
pc.num = args[3]
save_dir = args[4]

## load the phenotypes and PCs
setwd(paste("/mnt/home/azodichr/03_GenomicSelection/", id, sep=''))
Y <- read.csv('01_Data/pheno.csv', row.names=1)
load('/02_PC/00_getPC/EVD.RData')
cvs <- read.csv('01_Data/CVFs.csv', row.names=1)

# Make output directory
setwd(save_dir)
dir.create(id)
setwd(id)
dir.create(paste('02_PC_', pc.num, sep=''))
setwd(paste('02_PC_', pc.num, sep=''))

PC <- EVD$vectors[,1:pc.num]

for (j in 1:101){
  jobNum <- j
  for(i in 1:length(Y)){
    names(Y)[i]
    dir.create(paste('trait_',names(Y)[i], sep=''))
    setwd(paste('trait_',names(Y)[i], sep=''))
    dir.create('output')
    y=Y[, names(Y)[i]]
    CV.fold= paste('cv_', toString(jobNum-1), sep='')
    
    if(CV.fold =='cv_0'){
      # fit model to the entire data set and save model
      fm <-lm(y~PC)
      write.csv(cbind(y, PC5_pred = fm$fitted.values), file='full_pred.csv', sep=',')
      save(fm,file='full_model.RData')
    }
  
    else{
      # load the folds
      tst=cvs[,CV.fold]
      yhat <- data.frame(cbind(y, yhat = 0))
      yhat$yhat <- as.numeric(yhat$yhat)
      row.names(yhat) <- row.names(Y)
      
      for(i in 1:5){
        # Make training (TRN) and testing (TST) dfs
        yTRN=y[tst!=i]
        yTST=y[tst==i]
        XTRN=PC[tst!=i,]
        XTST=PC[tst==i,]
        
        train_set <- data.frame(cbind(yTRN, XTRN))
        test_set <- data.frame(cbind(yTST, XTST))
        
        # Build model and use it to predict the test set
        fm2 <- lm(yTRN ~ ., data=train_set)
        pred <- predict(fm2, newdata=(test_set), interval="confidence")
        
        results <- data.frame(pred[,'fit'])
        yhat[row.names(results),]$yhat <- results$pred....fit..
        
        #save(fm2,file=paste(CV.fold,'.',i,'.RData', sep=''))
      }
      
      write.table(yhat, paste('output/', CV.fold,'.csv', sep=''), sep=',', row.names=FALSE, col.names=TRUE)
      accuracy <- cor(yhat$y, yhat$yhat)
      df_out <- data.frame(CV.fold, accuracy)
      write.table(df_out, 'accuracy.csv', append=TRUE, sep=',', row.names=FALSE, col.names=FALSE)  
    }
    setwd('../')
  }
}

print('Complete')