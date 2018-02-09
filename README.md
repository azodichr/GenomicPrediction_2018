# GenomicPrediction_2018
### Readme for Genomic Selection NN project ###

All scripts for this project on HPCC: /mnt/home/azodichr/GitHub/GenomicPrediction_2018/scripts/

## 0. File organization

Run scripts from a directory that has directories (named with the project ID) for each dataset. Datasets for this project are listed below. Each directory should contain a subdirectory 01_Data that contains the geno.csv and pheno.csv file formatted as described in Step #1. 

Project IDs:
rice_DP_Spindel
sorgh_DP_Fernan
soy_NAM_xavier
spruce_Dial_beaulieu
swgrs_DP_Lipka # Still working on genotype data

Project_ID/:
  00_RawData/
  01_Data/
	  pheno.csv
	  geno.csv



## 1. Preprocess data
Since all input data so far has been slightly different, this needs to be done manually
script: scripts/data_preprocessing.R

Create two files with matching indexes: geno.csv, pheno.csv
-Remove lines missing any phenotypes of interest
-Remove lines with missing genotype information
-Take the average of phenotypes across years and replicates
-Convert genotype data to [-1,0,1] format corresponding to [aa, Aa, AA]


## 2. Define Cross Validation folds

<pre><code> python make_CVs.py -id [ID] </code></pre>


## 3. Assess the predictive performance of the population structure
How well can you predict a trait value using just the population structure? These scripts run principle component analysis on the SNP data, then use the top N PCs to predict the trait values.

<pre><code> Rscript getPCs.R [ID]
Rscript predict_PC.R [ID] [N]  </code></pre>


## 4. GS using rrBLUP
Example qsub file for submitting to HPCC as an array job: /mnt/home/azodichr/03_GenomicSelection/qsub_files/qsub_rrBLUP.txt
*Be sure to change the ID to your project ID!

<pre><code> Rscript predict_rrBLUP.R [ID] [cv_num] [trait/all] [path/to/output/dir] </code></pre>


# 5. GS using Bayesian methods
Using the BGLR R package. Bayesian Methods available: BayesA, BayesB, B-LASSO, and B-Ridge Regression
Example qsub file for submitting to HPCC as an array job: /mnt/home/azodichr/03_GenomicSelection/qsub_files/qsub_BayA.txt 

<pre><code> Rscript predict_BayesA.R [ID] [cv_num] [optional_parameter] [trait/all] [path/to/output/dir]</code></pre>
BayesA: ID - CV_num - deg.freedom - trait - path_to_output
BayesB: ID - CV_num - deg.freedom - trait - path_to_output
BRR: ID - CV_num - trait - path_to_output
BL: ID - CV_num  - trait - path_to_output


# 6. Run ML using all the features
Utilizes the Shiu Lab machine learning pipeline (https://github.com/ShiuLab/ML-Pipeline) implementing ML with SciKit-Learn (http://scikit-learn.org/stable/)
Algorithms available for regression: RF (random forest), SVM (support vector machine), GB (gradient boosting), and LogReg (logistic regression)
See Shiu Lab ML-Pipeline repository for environment requirements. If working on MSU's HPCC, the environment is available at:
<code><pre>export PATH=/mnt/home/azodichr/miniconda3/bin:$PATH</code></pre>

Example run:
<code><pre>python python /mnt/home/azodichr/GitHub/ML-Pipeline/ML_regression.py -df geno.csv -df_Y pheno.csv,TRAIT -cv_set CVFs.csv  -sep , -alg [ALG] -gs T -plots F -p 5 -save SAVE_NAME -out PATH/TO/OUTPUT</code></pre>


# 7. Running ML after feature selection
L1: 
swgr:
Plant Height = 476
Standability = 328
Anthesis_Date = 140 (alpha = 0.0001)

python ~shius/codes/qsub_hpc.py -f submit -u azodichr -m 10 -w 230 -p 7 -c run_relief.txt -wd /mnt/home/azodichr/03_GenomicSelection/swgrs_DP_Lipka/08_ML/



# MLP 
python ~/GitHub/TF-GenomicSelection/make_jobs_tf.py job_header.txt test_params.txt
for i in job*.sh; do qsub $i; done


#### Getting results 

Get the average accuracies: ** modify line 14 to include the results you are interested in
$ python pull_results.py
Output: RESULTS.csv

Plots the results pulled above!
$ Rscript plot_results.R
Output: RESULTS.pdf





## Formalizing the Feature Selection
* Before we were breaking a ML rule by doing feature selection on the whole data set. Try a side experiment with FS using BayesA, LASSO, RF, and Relief (top 10, 100, 250, 500, 750, 1000, 1500, 2000). Using cv_1, do fs and build the models on groups 1-4, then test the fs model on group 5.


Feature selection:

BayesA:
Rscript FS_BayesA.R maize_DP_Crossa/
Rscript FS_BayesA.R swgrs_DP_Lipka/
Rscript FS_BayesA.R soy_NAM_xavier/


RandomForest:
See run files: 01_RF/run_FS_RF.txt
Example:
$ python ~/GitHub/ML-Pipeline/Feature_Selection.py -f RF -df ../geno.csv -df_class ../pheno_cv1_NAs.txt,height -n 1500 -type r -ignore '?' -sep ',' -list T -save soy_height_RF_1500


LASSO:
python ~/GitHub/ML-Pipeline/Feature_Selection.py -f LASSO -df ~/03_GenomicSelection/02_FeatureSelection/maize_DP_Crossa/geno.csv -df_class ~/03_GenomicSelection/02_FeatureSelection/maize_DP_Crossa/pheno_cv1_NAs.txt,GY -sep ',' -list T -type r -ignore '?' -p 0.01
python ~/GitHub/ML-Pipeline/Feature_Selection.py -f LASSO -df ~/03_GenomicSelection/02_FeatureSelection/swgrs_DP_Lipka/geno.csv -df_class ~/03_GenomicSelection/02_FeatureSelection/swgrs_DP_Lipka/pheno_cv1_NAs.csv,Plant_Height -sep ',' -list T -type r -ignore '?' -p 0.45
python ~/GitHub/ML-Pipeline/Feature_Selection.py -f LASSO -df ~/03_GenomicSelection/02_FeatureSelection/soy_NAM_xavier/geno.csv -df_class ~/03_GenomicSelection/02_FeatureSelection/soy_NAM_xavier/pheno_cv1_NAs.txt,height -sep ',' -list T -type r -ignore '?' -p 1.03


Relief:
python ~shius/codes/qsub_hpc.py -f submit -u azodichr -c run_FS_relief.txt -w 20 -m 50 -wd /mnt/home/azodichr/03_GenomicSelection/02_FeatureSelection/maize_DP_Crossa/03_relief/
python ~shius/codes/qsub_hpc.py -f submit -u azodichr -c run_FS_relief.txt -w 20 -m 50 -wd /mnt/home/azodichr/03_GenomicSelection/02_FeatureSelection/swgrs_DP_Lipka/03_relief/
python ~shius/codes/qsub_hpc.py -f submit -u azodichr -c run_FS_relief.txt -w 230 -m 80 -wd /mnt/home/azodichr/03_GenomicSelection/02_FeatureSelection/soy_NAM_xavier/03_relief/



Run models with selected features

## BayesA:
#maize_DP_Crossa
for i in */*fl_f*; do Rscript ../predict_BayesA.R maize_DP_Crossa $i fl_f; done
for i in 02_LASSO/maize_flf*; do Rscript ../predict_BayesA.R maize_DP_Crossa $i fl_f; done
for i in */*fl_m*; do Rscript ../predict_BayesA.R maize_DP_Crossa $i fl_m; done
for i in 02_LASSO/maize_flm*; do Rscript ../predict_BayesA.R maize_DP_Crossa $i fl_m; done
for i in */*GY*; do Rscript ../predict_BayesA.R maize_DP_Crossa $i GY; done
#swgrs_DP_Lipka
for i in */*Plan*; do Rscript ../predict_BayesA.R swgrs_DP_Lipka $i Plant_Height; done
for i in */*Anthes*; do Rscript ../predict_BayesA.R swgrs_DP_Lipka $i Anthesis_Date_8632; done
for i in */*Standability*; do Rscript ../predict_BayesA.R swgrs_DP_Lipka $i Standability; done
#soy_NAM_xavier
for i in */*height*; do Rscript ../predict_BayesA.R soy_NAM_xavier $i height; done
for i in */*R8*; do Rscript ../predict_BayesA.R soy_NAM_xavier $i R8; done
for i in */*yield*; do Rscript ../predict_BayesA.R soy_NAM_xavier $i yield; done


## rrBLUP:
export R_LIBS_USER=~/R/library
#maize_DP_Crossa
for i in */*fl_f*; do Rscript ../predict_rrBLUP.R maize_DP_Crossa $i fl_f; done
for i in 02_LASSO/maize_flf*; do Rscript ../predict_rrBLUP.R maize_DP_Crossa $i fl_f; done
for i in */*fl_m*; do Rscript ../predict_rrBLUP.R maize_DP_Crossa $i fl_m; done
for i in 02_LASSO/maize_flm*; do Rscript ../predict_rrBLUP.R maize_DP_Crossa $i fl_f; done
for i in */*GY*; do Rscript ../predict_rrBLUP.R maize_DP_Crossa $i GY; done
#swgrs_DP_Lipka
for i in */*Plant_Height*; do Rscript ../predict_rrBLUP.R swgrs_DP_Lipka $i Plant_Height; done
for i in 02_LASSO/swgrs_Pla*; do Rscript ../predict_rrBLUP.R swgrs_DP_Lipka $i Plant_Height; done
for i in */*Anthesis_Date_8632*; do Rscript ../predict_rrBLUP.R swgrs_DP_Lipka $i Anthesis_Date_8632; done
for i in 02_LASSO/swgrs_AnthesisDate_*; do Rscript ../predict_rrBLUP.R swgrs_DP_Lipka $i Anthesis_Date_8632; done
for i in */*Standability*; do Rscript ../predict_rrBLUP.R swgrs_DP_Lipka $i Standability; done
#soy_NAM_xavier
python ~shius/codes/qsub_hpc.py -f submit -u azodichr -c run_rrBLUP.txt -w 230 -m 10 -n 200 -wd /mnt/home/azodichr/03_GenomicSelection/02_FeatureSelection/soy_NAM_xavier/


## RF
#maize_DP_Crossa
for i in */*fl_f*; do python ../ML_regression.py -df geno.csv -df_Y pheno_cv1_NAs.txt,fl_f -gs T -n 5 -sep ',' -alg RF -UNKNOWN ? -answers pheno.csv -tag maize_DP_Crossa -feat $i; done
for i in */*fl_m*; do python ../ML_regression.py -df geno.csv -df_Y pheno_cv1_NAs.txt,fl_m -gs T -n 5 -sep ',' -alg RF -UNKNOWN ? -answers pheno.csv -tag maize_DP_Crossa -feat $i; done
for i in */*GY*; do python ../ML_regression.py -df geno.csv -df_Y pheno_cv1_NAs.txt,GY -gs T -n 5 -sep ',' -alg RF -UNKNOWN ? -answers pheno.csv -tag maize_DP_Crossa -feat $i; done
#swgrs_DP_Lipka
for i in */*Plant_Height*; do python ../ML_regression.py -df geno.csv -df_Y pheno_cv1_NAs.csv,Plant_Height -gs T -n 5 -sep ',' -alg RF -UNKNOWN ? -answers pheno.csv -tag swgrs_DP_Lipka -feat $i; done
for i in */*Anthesis_Date_8632*; do python ../ML_regression.py -df geno.csv -df_Y pheno_cv1_NAs.csv,Anthesis_Date_8632 -gs T -n 5 -sep ',' -alg RF -UNKNOWN ? -answers pheno.csv -tag swgrs_DP_Lipka -feat $i; done
for i in */*Standability*; do python ../ML_regression.py -df geno.csv -df_Y pheno_cv1_NAs.csv,Standability -gs T -n 5 -sep ',' -alg RF -UNKNOWN ? -answers pheno.csv -tag swgrs_DP_Lipka -feat $i; done
#soy_NAM_xavier
for i in */*height*; do echo python ../ML_regression.py -df geno.csv -df_Y pheno_cv1_NAs.txt,height -gs T -n 5 -sep ',' -alg RF -UNKNOWN ? -answers pheno.csv -tag soy_NAM_xavier -feat $i; done
for i in */*R8*; do echo python ../ML_regression.py -df geno.csv -df_Y pheno_cv1_NAs.txt,R8 -gs T -n 5 -sep ',' -alg RF -UNKNOWN ? -answers pheno.csv -tag soy_NAM_xavier -feat $i; done
for i in */*yield*; do echo python ../ML_regression.py -df geno.csv -df_Y pheno_cv1_NAs.txt,yield -gs T -n 5 -sep ',' -alg RF -UNKNOWN ? -answers pheno.csv -tag soy_NAM_xavier -feat $i; done


## MLP
#maize_DP_Crossa
for i in */*fl_f*; do echo python ../TF_MLP_GridSearch.py -x geno.csv -y pheno.csv -cv CVFs.csv -feat $i -label fl_f -tag maize_DP_Crossa; done
for i in */*fl_m*; do echo python ../TF_MLP_GridSearch.py -x geno.csv -y pheno.csv -cv CVFs.csv -feat $i -label fl_m -tag maize_DP_Crossa; done
for i in */*GY*; do echo python ../TF_MLP_GridSearch.py -x geno.csv -y pheno.csv -cv CVFs.csv -feat $i -label GY -tag maize_DP_Crossa; done
python ~/GitHub/TF-GenomicSelection/make_jobs_tf.py header_jobs.txt run_MLP.txt
for i in job*.sh; do qsub $i; done

#swgrs_DP_Lipka
for i in */*Plant_Height*; do echo python ../TF_MLP_GridSearch.py -x geno.csv -y pheno.csv -cv CVFs.csv -feat $i -label Plant_Height -tag swgrs_DP_Lipka; done
for i in */*Anthesis_Date_8632*; do echo python ../TF_MLP_GridSearch.py -x geno.csv -y pheno.csv -cv CVFs.csv -feat $i -label Anthesis_Date_8632 -tag swgrs_DP_Lipka; done
for i in */*Standability*; do echo python ../TF_MLP_GridSearch.py -x geno.csv -y pheno.csv -cv CVFs.csv -feat $i -label Standability -tag swgrs_DP_Lipka; done
python ~/GitHub/TF-GenomicSelection/make_jobs_tf.py header_jobs.txt run_MLP.txt
for i in job*.sh; do qsub $i; done

#soy_NAM_xavier
for i in */*height*; do echo python ../TF_MLP_GridSearch.py -x geno.csv -y pheno.csv -cv CVFs.csv -feat $i -label height -tag soy_NAM_xavier; done
for i in */*R8*; do echo python ../TF_MLP_GridSearch.py -x geno.csv -y pheno.csv -cv CVFs.csv -feat $i -label R8 -tag soy_NAM_xavier; done
for i in */*yield*; do echo python ../TF_MLP_GridSearch.py -x geno.csv -y pheno.csv -cv CVFs.csv -feat $i -label yield -tag soy_NAM_xavier; done
python ~/GitHub/TF-GenomicSelection/make_jobs_tf.py header_jobs.txt run_MLP.txt
for i in job*.sh; do qsub $i; done



#### Determine what % of the top X lines are predicted correctly by the different models:

python compare_predictions.py -d maize_DP_Crossa -p 0.2
python compare_predictions.py -d maize_DP_Crossa -p 0.1
python compare_predictions.py -d rice_DP_Spindel -p 0.2
python compare_predictions.py -d rice_DP_Spindel -p 0.1
python compare_predictions.py -d soy_NAM_xavier -p 0.2
python compare_predictions.py -d soy_NAM_xavier -p 0.1
python compare_predictions.py -d spruce_Dial_beaulieu -p 0.2
python compare_predictions.py -d spruce_Dial_beaulieu -p 0.1
python compare_predictions.py -d swgrs_DP_Lipka -p 0.2
python compare_predictions.py -d swgrs_DP_Lipka -p 0.1

cat maize_DP_Crossa/topOvlp_0.1.txt rice_DP_Spindel/topOvlp_0.1.txt soy_NAM_xavier/topOvlp_0.1.txt spruce_Dial_beaulieu/topOvlp_0.1.txt swgrs_DP_Lipka/topOvlp_0.1.txt > topOvlp_all_0.1.txt

cat maize_DP_Crossa/topOvlp_0.2.txt rice_DP_Spindel/topOvlp_0.2.txt soy_NAM_xavier/topOvlp_0.2.txt spruce_Dial_beaulieu/topOvlp_0.2.txt swgrs_DP_Lipka/topOvlp_0.2.txt > topOvlp_all_0.2.txt

### Appendix ###

# Installing R packages

Rscript -e "install.packages('rrBLUP', lib='~/R/library', contriburl=contrib.url('http://cran.r-project.org/'))"



