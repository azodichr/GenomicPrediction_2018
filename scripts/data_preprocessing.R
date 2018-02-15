# GS Data Preprocessing

setwd('~/Desktop/Genomic_Selection/GS_Datasets/')

##### Gustavo's wheat dataset #####
# 599 lines with 1279 DArT markers
# 2 year average grain yields in four locations
# No missing data

dir.create('wheat_599_CIMMYT')
library(BGLR)
data(wheat)
row.names(wheat.Y) <- 1:nrow(wheat.Y)
names(wheat.Y) <- c('Yld_Env1', 'Yld_Env2', 'Yld_Env3', 'Yld_Env4')

write.table(wheat.Y, file='wheat_599_CIMMYT/01_Data/pheno.csv',  sep=",", quote = FALSE, row.names=TRUE, col.names=NA)
write.table(wheat.X, file='wheat_599_CIMMYT/01_Data/geno.csv', sep=",", quote = FALSE, row.names=TRUE, col.names=NA)





##### Susan McCouch's Rice dataset #####
# 328 after removing lines without both g & p data (332 lines originally) with 73,148 GBS markers
# 1 line with missing data (M1396 missing dry phenotypes) - removed -->> 327 lines
# Make 4 year averages in dry and wet environments

setwd("/Volumes/azodichr/03_GenomicSelection/rice_DP_Spindel/")
geno_file <- read.csv("00_RawData/MET_crfilt_.90_outliers_removed_for_RRBlup_line_corrected.csv", header= TRUE)

# Load in dry phenotypes by year and merge
p_12_Dr <- read.csv("00_RawData/RYT_plotdata_by_GHID_corrected_PUBLIC_ACCESS/corrected_RYT2012DS_plotdata_by_GHID.csv")
p_11_Dr <- read.csv("00_RawData/RYT_plotdata_by_GHID_corrected_PUBLIC_ACCESS/corrected_RYT2011DS_plotdata_by_GHID.csv")
p_10_Dr <- read.csv("00_RawData/RYT_plotdata_by_GHID_corrected_PUBLIC_ACCESS/corrected_RYT2010DS_plotdata_by_GHID.csv")
p_9_Dr <- read.csv("00_RawData/RYT_plotdata_by_GHID_corrected_PUBLIC_ACCESS/corrected_RYT2009DS_plotdata_by_GHID.csv")
p_12_Dr$MC <- NaN
p_12_Dr$Missing_Hill <- NaN
p_Dr <- rbind(p_9_Dr, p_10_Dr, p_11_Dr, p_12_Dr)

# Load in wet phenotypes by year and merge
p_12_Wet <- read.csv("00_RawData/RYT_plotdata_by_GHID_corrected_PUBLIC_ACCESS/corrected_RYT2012WS_plotdata_by_GHID.csv")
p_11_Wet <- read.csv("00_RawData/RYT_plotdata_by_GHID_corrected_PUBLIC_ACCESS/corrected_RYT2011WS_plotdata_by_GHID.csv")
p_10_Wet <- read.csv("00_RawData/RYT_plotdata_by_GHID_corrected_PUBLIC_ACCESS/corrected_RYT2010WS_plotdata_by_GHID.csv")
p_9_Wet <- read.csv("00_RawData/RYT_plotdata_by_GHID_corrected_PUBLIC_ACCESS/corrected_RYT2009WS_plotdata_by_GHID.csv")
p_12_Wet$MC <- NaN
p_12_Wet$Missing_Hill <- NaN
p_9_Wet$PLTHGT <- NaN
p_9_Wet$TILLER <- NaN
p_Wet <- rbind(p_9_Wet, p_10_Wet, p_11_Wet, p_12_Wet)

# Average over years and reps
p_Dr_ag <- aggregate(.~GHID, data=p_Dr, mean)
p_Wet_ag <- aggregate(.~GHID, data=p_Wet, mean)

drop_list <- c('YEAR', 'SEASON','REP','PLOTNO','Missing_Hill','MC','Plot_Yld','TILLER','MAT','LDG')
p_Dr_ag <- p_Dr_ag[, !colnames(p_Dr_ag) %in% drop_list]
p_Wet_ag <- p_Wet_ag[, !colnames(p_Wet_ag) %in% drop_list]

# Combine wet and dry years
p_combined <- merge(p_Dr_ag, p_Wet_ag, by = 'GHID', all=TRUE, suffixes = c('_dry', '_wet'))
phenos <- names(p_combined)

# Combine phenotype and genotype data so that in the final outputs the rows will match
rice_combined <- merge(p_combined, geno_file, by.x='GHID', by.y='Entry', all=FALSE)

# Remove lines with any NAs (only one line removed!)
rice_combined <- na.omit(rice_combined)
p_final <- rice_combined[, colnames(rice_combined) %in% phenos]
g_final <- rice_combined[, !colnames(rice_combined) %in% phenos]
g_final <- cbind(GHID = rice_combined$GHID, g_final)

# Write output tables 
write.table(g_final, file='01_Data/geno.csv', sep=",", quote = FALSE, row.names=FALSE)
write.table(p_final, file='01_Data/pheno.csv', sep=",", quote = FALSE, row.names=FALSE)

rice <- read.csv('/Volumes/azodichr/03_GenomicSelection/rice_DP_Spindel/01_Data/geno.csv',header=T, sep=',')
markers <- names(rice)
m <- as.list(strsplit(markers, '_'),head, n=1)

m <- as.list(strsplit(markers, '_'))

##### Beaulieu's spruce dataset #####
# 1722 lines with 6933 markers

setwd('/Volumes/azodichr/03_GenomicSelection/spruce_Dial_beaulieu/00_RawData/')
g <- read.table('E952_snps_imp_6932.csv', sep=',', header=T)
p_dbh <- read.table('E952_pheno-dbh12.txt', sep=' ', header=F)
names(p_dbh) <- c('ID','a','b','c','d','DBH')
p_h <- read.table('E952_pheno-ht12.txt', sep=' ', header=F)
names(p_h) <- c('ID','a','b','c','d','HT')
p_den <- read.table('E952_pheno-aden.txt', sep=' ', header=F)
names(p_den) <- c('ID','a','b','c','d','DE')
p <- merge(p_dbh[c('ID','DBH')], p_h[c('ID','HT')], by='ID')
p <- merge(p, p_den[c('ID','DE')])

# convert [0,1,2] (i.e. [aa, Aa, AA]) to [-1, 0, 1]
dict <- list('0' = '-1', '1' = '0', '2' = '1')
g2 = g
for (i in 1:3){g2 <- replace(g2, g2 == names(dict[i]), dict[i])}

all <- merge(p, g2, by='ID')
p_final <- all[, colnames(all) %in% c('ID','DBH','HT','DE')]
g_final <- all[, !colnames(all) %in% c('DBH','HT','DE')]
g_final <- apply(g_final,2,as.character)

write.table(g_final, file='../01_Data/geno.csv', sep=",", quote = FALSE, row.names=FALSE)
write.table(p_final, file='../01_Data/pheno.csv', sep=",", quote = FALSE, row.names=FALSE)



#### Soy NAM ###
# From: install.packages('SoyNAM')
# Use phenotpes from Illinois - most data available (average over the 3 years)
library(NAM)
setwd('/Volumes/azodichr/03_GenomicSelection/soy_NAM_xavier/')
data(met,package='NAM')

# convert [0,1,2] [aa, Aa, AA] to [-1, 0, 1]
dict <- list('0' = '-1', '1' = '0', '2' = '1')
Gen2 = Gen
for (i in 1:3){Gen2 <- replace(Gen2, Gen2 == names(dict[i]), dict[i])}

pheno <- read.csv('01_Data/pheno.csv',header=T)
names(pheno) <- c('ID', 'HT', 'R8', 'YLD')
soy_combined <- merge(pheno, Gen2, by.x='ID', by.y=0, all=FALSE)

p_final <- soy_combined[, colnames(soy_combined) %in% c('ID', 'HT', 'R8', 'YLD')]
g_final <- soy_combined[, !colnames(soy_combined) %in% c('HT', 'R8', 'YLD')]
g_final <- apply(g_final,2,as.character)

write.table(g_final, file='01_Data/geno.csv', sep=",", quote = FALSE, row.names=FALSE)
write.table(p_final, file='01_Data/pheno.csv', sep=",", quote = FALSE, row.names=FALSE)



### Maize from Crossa
setwd('/Volumes/azodichr/03_GenomicSelection/maize_DP_Crossa/00_RawData/')
flow <- c('flowering/dataCorn_WW_flf.RData', 'flowering/dataCorn_WW_flm.RData', 'grain_yield/dataCorn_WW.RData')
load(flow[1])
flf <- y
geno <- X
load(flow[2])
flm <- y
load(flow[3])
mgy <- y
geno2 <- X

markers_remove <- setdiff(names(as.data.frame(geno)), names(as.data.frame(geno2)))
#install.packages('compare')
library(compare)
comp <- compare(as.data.frame(geno), as.data.frame(geno2)[-markers_remove])

pheno <- data.frame(fl_f=flf, fl_m=flm, GY=mgy)
write.csv(pheno, file='../01_Data/pheno.csv', row.names=TRUE, col.names=TRUE, sep=',', quote=FALSE)
write.csv(geno, file='../01_Data/geno.csv', row.names=TRUE, col.names=TRUE, sep=',', quote=FALSE)




#### Sorghum from Fernando et al.
# https://github.com/samuelbfernandes/Trait-assisted-GS

setwd('/Volumes/azodichr/03_GenomicSelection/sorgh_DP_Fernan/')
geno <- read.csv('00_RawData/snps.csv', sep = ',', header=TRUE)
pheno <- read.csv('00_RawData/pheno.csv', sep = ',', header = TRUE)
pheno_ag <- aggregate(.~GENO, data=pheno, mean) # Take the mean value from the plots
pheno_ag <- pheno_ag[c('GENO','Y','M','h4')]
names(pheno_ag) <- c('ID', 'YLD', 'MO', 'HT')

sorg_combined <- merge(pheno_ag, geno, by.x='ID', by.y="X", all=FALSE) # 451 lines with both P & G data

p_final <- sorg_combined[, colnames(sorg_combined) %in% c('ID','YLD','MO','HT')]
g_final <- sorg_combined[, !colnames(sorg_combined) %in% c('YLD','MO','HT')]

write.table(g_final, file='01_Data/geno.csv', sep=",", quote = FALSE, row.names=FALSE)
write.table(p_final, file='01_Data/pheno.csv', sep=",", quote = FALSE, row.names=FALSE)


#### Switchgrass from Lipka et al 2014 and Evans et al 2017 
# Phenotypes: http://publish.illinois.edu/switchgrass-panel/files/2014/09/BLUPs_7_Morph_Traits_Assoc_for_GWAS_sorted_Anchored.txt
# Genotypes: https://datadryad.org//resource/doi:10.5061/dryad.mp6cp
library(data.table)
setwd('/Volumes/azodichr/03_GenomicSelection/swgrs_DP_Lipka/')
#geno <- read.csv('00_RawData/snipe_slap_sapper_filtered_biallelic_snps_final_reheader.txt', sep = '\t', header=TRUE)


key <- read.table('00_RawData/IDconversion_Lipka_Evans.csv', sep=',', header=TRUE, na.strings='')
keep <- unique(key$Genotype_Evans) 
keep <- as.vector(keep[!is.na(keep)])
keep <- c(c('Chromosome', 'Position', 'Reference', 'Alleles'), keep)
geno <- fread('00_RawData/test_geno.txt', sep='\t')
#geno <- fread('00_RawData/snipe_slap_sapper_filtered_biallelic_snps_final_reheader.txt', sep = '\t', header=TRUE)

geno2 <- geno[,keep, with = FALSE]

# Remove (##) 
geno2[,5:ncol(geno2)] <- data.frame(lapply(geno2[,5:ncol(geno2)], function(x) {gsub("[0-9]", "", x)}))
geno2[,5:ncol(geno2)] <- data.frame(lapply(geno2[,5:ncol(geno2)], function(x) {gsub("()", "", x, fixed=TRUE)}))

# If het (i.e. A/G), replace with NA
geno2[,5:ncol(geno2)] <- data.frame(lapply(geno2[,5:ncol(geno2)], function(x) {gsub("[A-Z]/[A-Z]", NA, x)}))

# Replace Reference call with 1 and non-reference call with -1
geno2[,5:ncol(geno2)] <- as.data.frame(lapply(geno2[,5:ncol(geno2)], function(x) ifelse(x == geno2$Reference, 1, -1)))

# Replace hets (NAs) with 0
geno2[is.na(geno2)] <- 0

# Make SNP names column
geno3 <- geno2
geno3$SNPname <- paste(geno3$Chromosome, geno3$Position, geno3$Reference, sep='_')
col_names <- geno3$SNPname
geno3$Chromosome <- NULL
geno3$Position <- NULL
geno3$Reference <- NULL
geno3$Alleles <- NULL
geno3$SNPname <- NULL

# Transpose and set SNP names
geno3 <- as.data.frame(t(geno3))
colnames(geno3) <- col_names

# Remove SNPs that have less than 5% minor allele frequency
geno4 <- geno3[,colMeans(geno3) < 0.95 & colMeans(geno3) > -0.95]

# Load in phenotype data
pheno <- read.csv('BLUPs_7_Morph_Traits_Assoc_for_GWAS_sorted_Anchored.txt', sep='\t',header=TRUE)
pheno <- pheno[c('MAP_ID','Standability','Plant_Height','Anthesis_Date_8632')]
names(pheno) <- c('ID', 'ST', 'HT', 'AN')
pheno2 <- merge(pheno, key, by.x='ID', by.y='Phenotype_Lipka', all=FALSE)

swgr_combined <- merge(pheno2, dataset, by.x='Genotype_Evans', by.y="X", all=FALSE) 
swgr_combined$ID <- swgr_combined$Genotype_Evans
swgr_combined$Genotype_Evans <- NULL

p_final <- swgr_combined[, colnames(swgr_combined) %in% c('ID','ST', 'HT', 'AN')]
g_final <- swgr_combined[, !colnames(swgr_combined) %in% c('YLD', 'ST', 'HT', 'AN')]

write.table(g_final, file='../01_Data/geno.csv', sep=",", quote = FALSE, row.names=FALSE)
write.table(p_final, file='../01_Data/pheno.csv', sep=",", quote = FALSE, row.names=FALSE)



#### Maize data from Hirsch et al 2014 and Evans et al 2017 
# Phenotypes: http://publish.illinois.edu/switchgrass-panel/files/2014/09/BLUPs_7_Morph_Traits_Assoc_for_GWAS_sorted_Anchored.txt
# Genotypes: http://datadryad.org/resource/doi:10.5061/dryad.r73c5
## File to convert v2 SNPs into v4 from R. Buell: zm_v4_503_snp_w_v2_pos.sort.header.txt
library(data.table)


