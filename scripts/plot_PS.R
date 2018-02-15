### Comparison of model performace across the Grid Search
ids <- c('rice_DP_Spindel','sorgh_DP_Fernan','soy_NAM_xavier','spruce_Dial_beaulieu','swgrs_DP_Lipka')
setwd('/Volumes/azodichr/03_GenomicSelection/')

cls <- c(ID="character", MSE="numeric",Model="character",Trait="character",params="character")
data <- read.csv('parameter_search_results.csv', colClasses=cls, stringsAsFactors=FALSE)
data$MSE <- abs(data$MSE)

# Aggregate by parameter/model
data_ag <- aggregate(MSE ~ ID + Model + Trait + params, data, mean)

# Remove weird strings in parameter lines
data_ag <- separate(data_ag, params, c("Feat1", "Feat2", 'Feat3', 'Feat4'), ",", fill='right')
data_ag <- as.data.frame(lapply(data_ag, gsub, pattern = "\\'[A-z]+\\'\\:", replacement = ""))
data_ag <- as.data.frame(lapply(data_ag, gsub, pattern = "\\{", replacement = ""))
data_ag <- as.data.frame(lapply(data_ag, gsub, pattern = "}", replacement = ""))
data_ag <- as.data.frame(lapply(data_ag, gsub, pattern = " ", replacement = ""))

library(ggplot2)
ggplot(data_ag, aes(Feat1, Feat2)) + geom_tile(aes(fill=as.numeric(MSE)), colour='white') +
  
  #scale_fill_gradient(limits=c(0,0.5), low='white',high='firebrick')+
  theme_minimal(10) 
