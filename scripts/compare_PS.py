"""
Grid search analysis
"""
import os, sys
import pandas as pd
import numpy as np
import re

ids = ['rice_DP_Spindel','sorgh_DP_Fernan','soy_NAM_xavier', 'spruce_Dial_beaulieu', 'swgrs_DP_Lipka']

no_gs = ['03_rrBLUP','06_BRR','07_BL']

bay_gs = ['05_BayesA','04_BayesB']

ml_gs = ['08_ML2']



wkdir = '/mnt/home/azodichr/03_GenomicSelection'
mses = pd.DataFrame() #index=None, columns = cols) # ID, trait, model, params, MSE


for id in os.listdir(wkdir):
  if id in ids:  
    print("Pulling scores for %s" % id)

    for model_dir in os.listdir(wkdir + '/' + id):
      
      if model_dir in no_gs:
        temp = pd.read_csv(wkdir + '/' + id + '/' + model_dir + '/trait_PLTHGT_dry/output/yhat_all.csv')
        mse = np.mean((temp['y'] - temp['yhat_mean'])**2)
        model_name = model_dir.strip().split('_')[1]
        mses = mses.append({'ID':id, 'Trait':'HT', 'Model':model_name, 'params':None, 'MSE': mse}, ignore_index=True)# , columns=cols))
        print(mses)
      elif any(model_dir in s for s in bay_gs):
        #x, model_name, y, param = model_dir.strip().split('_')
        x, model_name = model_dir.strip().split('_')
        param = None
        temp = pd.read_csv(wkdir + '/' + id + '/' + model_dir + '/trait_PLTHGT_dry/output/yhat_all.csv')
        mse = np.mean((temp['y'] - temp['yhat_mean'])**2)
        mses = mses.append({'ID':id, 'Trait':'HT', 'Model':model_name, 'params':None, 'MSE': mse}, ignore_index=True)# , columns=cols))
        print(mses)
      elif model_dir in ml_gs:
        for ml_file in os.listdir(wkdir + '/' + id + '/' + model_dir):
          if 'GridSearchFULL' in ml_file and 'HT' in ml_file:
            species, trait, model_name, x = ml_file.strip().split('_')
            temp = pd.read_csv(wkdir + '/' + id + '/' + model_dir + '/' + ml_file, index_col=0)
            temp.columns = temp.columns.str.replace('mean_test_score','MSE')
            temp['ID'] = id
            temp['Trait'] = trait
            temp['Model'] = model_name
            mses = mses.append(temp)

print(mses.head())

mses.to_csv('parameter_search_results.csv', index=False)
