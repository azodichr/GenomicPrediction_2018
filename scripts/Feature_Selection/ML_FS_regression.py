"""
PURPOSE:
Machine learning classifications implemented in sci-kit learn.

To access pandas, numpy, and sklearn packages on MSU HPCC first run:
$ export PATH=/mnt/home/azodichr/miniconda3/bin:$PATH

INPUTS:
	
	REQUIRED ALL:
	-df       Feature & class dataframe for ML. See "" for an example dataframe
	-alg      Available: RF, SVM (linear), SVMpoly, SVMrbf, GB, and Linear Regression (LR)
	
	OPTIONAL:
	-unknown  String in Y that indicates unknown values you want to predict. Leave as none if you don't have unknowns in your data Default = none
	-gs       Set to True if grid search over parameter space is desired. Default = False
	-normX		T/F to normalize the features (Default = F (except T for SVM))
	-normY	  T/F to normalize the predicted value (Default = F)
	-sep      Set sep for input data (Default = '\t')
	-cv       # of cross-validation folds. Default = 10
	-cv_reps  # of times CV predictions are run
	-cv_set  	File with cv folds defined
	-p        # of processors. Default = 1
	-tag      String for SAVE name and TAG column in RESULTS.txt output.
	-feat     Import file with subset of features to use. If invoked,-tag arg is recommended. Default: keep all features.
	-Y        String for column with what you are trying to predict. Default = Y
	-save     Adjust save name prefix. Default = [df]_[alg]_[tag (if used)], CAUTION: will overwrite!
	-short    Set to True to output only the median and std dev of prediction scores, default = full prediction scores
	-df_Y     File with class information. Use only if df contains the features but not the Y values 
								If more than one column in the class file, specify which column contains Y: -df_class class_file.csv,ColumnName
	
	PLOT OPTIONS:
	-plots    T/F - Do you want to output plots?

OUTPUT:
	-SAVE_imp           Importance scores for each feature
	-SAVE_GridSearch    Results from parameter sweep sorted by F1
	-RESULTS.txt     		Accumulates results from all ML runs done in a specific folder - use unique save names! XX = RF or SVC


MODIFIED: 
11/27/17: BY CBA TO RUN AFTER FEATURE SELECTION ON CV 1-4 (APPLY AND SCORE ONLY TO CV5)
"""

import sys, os
import pandas as pd
import numpy as np
from datetime import datetime
import time

import ML_FS_functions as ML

def main():
	
	# Default code parameters
	n, FEAT, apply, n_jobs, Y_col, plots, cv_num, TAG, SAVE, short_scores = 100, 'all','F', 1, 'Y', 'False', 10, '', '', ''
	y_name, SEP, THRSHD_test, DF_Y, df_unknowns,UNKNOWN, normX, normY, cv_reps, cv_sets, fs_cv = 'Y', '\t','F1', 'ignore', 'none','unk', 'F', 'F', 10, 'none', 'pass'

	# Default parameters for Grid search
	GS, gs_score = 'F', 'neg_mean_squared_error'
	
	# Default Random Forest and GB parameters
	n_estimators, max_depth, max_features, learning_rate = 500, 10, "sqrt", 1.0
	
	# Default Linear SVC parameters
	kernel, C, degree, gamma, loss, max_iter = 'linear', 1, 2, 1, 'hinge', "500"
	
	# Default Logistic Regression paramemter
	penalty, C, intercept_scaling = 'l2', 1.0, 1.0
	
	for i in range (1,len(sys.argv),2):
		if sys.argv[i] == "-df":
			DF = sys.argv[i+1]
		elif sys.argv[i] == "-df_Y":
			DF_Y = sys.argv[i+1]
		elif sys.argv[i] == "-y_name":
			y_name = sys.argv[i+1]
		elif sys.argv[i] == "-sep":
			SEP = sys.argv[i+1]
		elif sys.argv[i] == '-save':
			SAVE = sys.argv[i+1]
		elif sys.argv[i] == '-feat':
			FEAT = sys.argv[i+1]
		elif sys.argv[i] == "-gs":
			GS = sys.argv[i+1]
		elif sys.argv[i] == '-normX':
			normX = sys.argv[i+1].lower()
		elif sys.argv[i] == "-normY":
			normY = sys.argv[i+1].lower()
		elif sys.argv[i] == "-gs_score":
			gs_score = sys.argv[i+1]
		elif sys.argv[i] == "-Y":
			Y = sys.argv[i+1]
		elif sys.argv[i] == "-UNKNOWN":
			UNKNOWN = sys.argv[i+1]
		elif sys.argv[i] == "-n":
			n = int(sys.argv[i+1])
		elif sys.argv[i] == "-b":
			n = int(sys.argv[i+1])
		elif sys.argv[i] == "-alg":
			ALG = sys.argv[i+1]
		elif sys.argv[i] == "-cv":
			cv_num = int(sys.argv[i+1])
		elif sys.argv[i] == "-cv_reps":
			cv_reps = int(sys.argv[i+1])
		elif sys.argv[i] == "-cv_set":
			cv_sets = pd.read_csv(sys.argv[i+1], index_col = 0)
			cv_reps = len(cv_sets.columns)
			cv_num = len(cv_sets.iloc[:,0].unique())
			print(cv_num)
		elif sys.argv[i] == "-plots":
			plots = sys.argv[i+1]
		elif sys.argv[i] == "-tag":
			TAG = sys.argv[i+1]
		elif sys.argv[i] == "-answers":
			ANSWERS = sys.argv[i+1]
		elif sys.argv[i] == "-threshold_test":
			THRSHD_test = sys.argv[i+1]
		elif sys.argv[i] == "-n_jobs" or sys.argv[i] == "-p":
			n_jobs = int(sys.argv[i+1])
		elif sys.argv[i] == "-FS_cv":
			fs_cv = sys.argv[i+1]
		elif sys.argv[i] == "-short":
			scores_len = sys.argv[i+1]
			if scores_len.lower() == "true" or scores_len.lower() == "t":
				short_scores = True

	if len(sys.argv) <= 1:
		print(__doc__)
		exit()
	
	####### Load Dataframe & Pre-process #######
	
	df = pd.read_csv(DF, sep=SEP, index_col = 0)
	# If feature info and class info are in separate files
	if DF_Y != 'ignore':
		df_Y_file, df_Y_col = DF_Y.strip().split(',')
		df_Y = pd.read_csv(df_Y_file, sep=SEP, index_col = 0)
		df[y_name] = df_Y[df_Y_col]
		y_name = df_Y_col

	# Specify Y column - default = Class
	y_name2 = y_name[:] 
	if y_name != 'Y':
		df = df.rename(columns = {y_name:'Y'})
		y_name = y_name
	
	print(df.head())
	# Filter out features not in feat file given - default: keep all
	if FEAT != 'all':
		with open(FEAT) as f:
			features = f.read().strip().splitlines()
			features = ['Y'] + features
		df = df.loc[:,features]
	
	# Remove instances with NaN or NA values
	#df = df.replace("?",np.nan)
	#df = df.dropna(axis=0)
	
	# Set up dataframe of unknown instances that the final models will be applied to and drop unknowns from df for model building
	if UNKNOWN in df['Y'].unique():
		df_unknowns = df[(df['Y']==UNKNOWN)]
		predictions = pd.DataFrame(data=df['Y'], index=df.index, columns=['Y'])
		
		answer_df = pd.read_csv(ANSWERS, sep=SEP, index_col = 0)
		answer_df = answer_df.rename(columns = {y_name:'Y'})
		answers = answer_df[(df['Y']==UNKNOWN)]
		
		df = df.drop(df_unknowns.index.values)
		print("Model built using %i instances and applied to %i unknown instances (see _scores file for results)" % (len(df.index), len(df_unknowns.index)))
	else:
		predictions = pd.DataFrame(data=df['Y'], index=df.index, columns=['Y'])
		print("Model built using %i instances" % len(df.index))

	if fs_cv != "pass":
		fs_cv_file, fs_cv_num = fs_cv.strip().split(',')
		fs_cv_df = pd.read_csv(fs_cv_file, sep=SEP, index_col = 0)
		print(fs_cv_df.head())
		exit()
		
		
	if SAVE == "":
		if TAG == "":
			SAVE = DF + "_" + ALG
		else:
			SAVE = DF + "_" + ALG + "_" + TAG
	
	# Normalize feature data (normX)
	if ALG == "SVM" or normX == 't' or normX == 'true':
		from sklearn import preprocessing
		y = df['Y']
		X = df.drop(['Y'], axis=1)
		min_max_scaler = preprocessing.MinMaxScaler()
		X_scaled = min_max_scaler.fit_transform(X)
		df = pd.DataFrame(X_scaled, columns = X.columns, index = X.index)
		df.insert(loc=0, column = 'Y', value = y)

	# Normalize y variable (normY)
	if normY == 't' or normY == 'true':
		print('normY not implemented yet!!!')
	
	
	print("Snapshot of data being used:")
	print(df.head())

	n_features = len(list(df)) - 1
	
	####### Run parameter sweep using a grid search #######
	
	if GS.lower() == 'true' or GS.lower() == 't':
		start_time = time.time()
		print("\n\n===>  Grid search started  <===") 
		
		params2use = ML.fun.RegGridSearch(df, SAVE, ALG, gs_score, cv_num, n_jobs)
		
		print("Parameters selected:")
		for key,val in params2use.items():
			print("%s: %s" % (key, val))
			exec(key + '=val')   # Assigns parameters in the params2use dictionary into variables

	else:
		params2use = "Default parameters used"
	 
	####### Run ML models #######
	start_time = time.time()
	print("\n\n===>  ML Pipeline started  <===")
	
	results = []
	imp = pd.DataFrame(index = list(df.drop(['Y'], axis=1)))


	# Prime classifier object based on chosen algorithm
	if ALG == "RF":
		reg = ML.fun.DefineReg_RandomForest(n_estimators,max_depth,max_features,n_jobs,1)
	elif ALG == "SVM" or ALG == 'SVMrbf' or ALG == 'SVMpoly':
		reg = ML.fun.DefineReg_SVM(kernel,C,degree,gamma,1)
	elif ALG == "GB":
		reg = ML.fun.DefineReg_GB(learning_rate,max_features,max_depth,n_jobs,1)
	elif ALG == "LR":
		reg = ML.fun.DefineReg_LinReg()
	
	# Run ML algorithm on balanced datasets.
	cor = ML.fun.Run_Regression_Model(df, reg, cv_num, ALG, df_unknowns, cv_sets, 1, answers)

		
	# Save to summary RESULTS file with all models run from the same directory


	out2 = open('results.csv', 'a')
	out2.write('%s,%s,%s,%i,%s,%0.5f\n' % (TAG, y_name2, FEAT, len(features)-1, ALG, cor))




if __name__ == '__main__':
	main()
