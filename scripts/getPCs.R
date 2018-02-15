#####################################
# Uses a genotype file and outputs PCs and PC plots
#
# Arguments: [1] id (i.e. wheat_599_CIMMYT)
#
# Plots include: - Percent of variance explained by the PCs
#                - Plots of PCs: PC vs PC (PC 1-5) 
#                - Plot the G matrix diagonals (related to population structure)
#
# Written by: Christina Azodi
# Original: 4.24.17
# Modified: 
#####################################

# Removes all existing variables from the workspace
rm(list=ls())

# Compute PCs for descriptive stats and for later use in modeling 
args = commandArgs(TRUE)

#### Testing parameters
#id <- 'wheat_599_CIMMYT'
#setwd(paste("~/Desktop/Genomic_Selection/GS_Datasets", id, sep='/'))
#X <- read.csv("01_Data/geno.csv", row.names=1)

####

# Input data
id <- args[1]
id
setwd(paste("/mnt/home/azodichr/03_GenomicSelection", id, sep='/'))

X <- read.csv('01_Data/geno.csv', row.names=1)
Y <- read.csv('01_Data/pheno.csv', row.names=1)

# Create output folder if not already present
dir.create('02_PC')
dir.create('02_PC/00_getPC')
setwd('02_PC/00_getPC')

#source('../parameters/parameters.r')

#### Calculate the G matrix
X=scale(X) # Centers (subtract the column means) and Scales (dividing the centered columns by their stdev)
G=tcrossprod(X) # Take the cross product X transpose
G=G/mean(diag(G))


#### Calculate eigenvalues
EVD=eigen(G)
rownames(EVD$vectors)=rownames(G)
save(EVD,file='EVD.RData')


#### Plot proportion of variance explained ####
pdf('VarExplained.pdf')
var_exp <- (EVD$values)/nrow(X)
cum_exp <- list(var_exp[1])

for(i in 2:length(var_exp)){
  cum_exp[[i]] <- as.numeric(cum_exp[i-1]) + as.numeric(var_exp[i])
}

plot(1:nrow(X), cum_exp, xlab='# PCs', ylab='% Variance Explained', main = id)
abline(h= c(0.5, 0.9), col='blue')

dev.off()
 
#### Plot the G matrix diagonals ####
pdf('diag.pdf')
hist(diag(G), xlab = 'Diagonal Element (G-Matrix)', main = id, breaks=20)
dev.off()


#### Plots the PCs ####
pdf('PCs.pdf')

par(mfrow=c(3,4))
for(i in 1:4){
  for(j in (i+1):5){
    plot(x=EVD$vectors[,i],y=EVD$vectors[,j],
         main=paste0('PC-',i,' Vs. PC-',j),
         xlab=paste0('PC-',i),
         ylab=paste0('PC-',j),
         cex=.1 #,col=as.integer(factor(SUBJECTS$line))
    )
    #print(c(i,j))
  }
}
dev.off()

#### Export % X variance and Yi variance explained by the top 5 PCs ####

XY_var_exp <- cbind('X', sum(var_exp[0:5]))

for(i in 1:length(Y)){
  y=Y[, names(Y)[i]]
  fm = lm(y~EVD$vectors[,1:5])
  XY_var_exp <- rbind(XY_var_exp, cbind(names(Y)[i], summary(fm)$adj.r.squared))
}
  
write.table(XY_var_exp, 'VarExplained.csv', sep=',', row.names=FALSE, col.names=FALSE)

quit(save='no')
