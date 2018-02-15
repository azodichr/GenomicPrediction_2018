""" 

Pull results for genomic selection

"""

import os, sys
import pandas as pd
import numpy as np
import re

wkdir = os.path.abspath(sys.argv[0])[:-16]
print(wkdir)
use = ['02_PC', '03_rrBLUP', '04_BayesB','05_BayesA','06_BRR',"07_BL"]


index = []
accuracy = []
stdev = []
sterr = []
notes = []

for j in os.listdir(wkdir):
  if j.startswith("."):
    pass

  #elif re.search('[a-z].*_.*_.*', j):  ## Format of GS dataset directories
  elif re.search('rice_.*_.*', j):   
    print("Pulling scores for %s" % j)

    for i in os.listdir(wkdir + '/' + j):
      
      if i in use:

        for k in os.listdir(wkdir + '/' + j +'/' + i):
          if k.startswith('trait_'):
            wkdir2 = wkdir  + j +'/' + i + '/' + k + '/'
            method = i[3:]
            # Make 3 level index: ID, Trait, Method
            index.append((j,k[6:],method))
            
            yhat_all = pd.read_csv(wkdir2 + 'output/cv_1.csv', header=0, names = ['y', 'cv_1'])
            for m in os.listdir(wkdir2 + 'output/'):
              if m == 'cv_1.csv':
                pass
              elif m.startswith('cv_'):
                number = m.split('.')[0][3:]
                temp = pd.read_csv(wkdir2 + 'output/' + m, header=0, names = ['y', 'cv_' + number])
                yhat_all = pd.concat([yhat_all, temp['cv_' + number]], axis = 1)
              print(yhat_all)
              yhat_all['yhat_mean'] = (yhat_all.filter(like='cv_')).mean(axis=1)
              yhat_all['yhat_sd'] = (yhat_all.filter(like='cv_')).std(axis=1)
              yhat_all.to_csv(wkdir2 + 'output/yhat_all.csv', sep=',', index=False)
            quit()
      elif i == '08_ML':
        wkdir2 = wkdir  + j +'/' + i + '/' 
        for l in open(wkdir2 + 'RESULTS_reg.txt').readlines():
          if l.startswith('DateTime'):
            pass
          else:
            line = l.strip().split('\t')
            k = line[3]
            method = line[4]
            # Make 3 level index: ID, Trait, Method
            index.append((j,k,method))
            
            # Calculate acc and stdev from each run (100 cv mixes)
            accuracy = np.append(accuracy, line[18])
            stdev = np.append(stdev, line[19])
            sterr = np.append(sterr, line[20])
            notes = np.append(notes, 'na')

      elif i == '09_MLP':
          method = 'MLP'
          wkdir3 = wkdir  + j +'/' + i + '/'
          mlp = pd.read_table(wkdir3 + 'RESULTS.txt', sep='\t', header=0)
          mlp_mean = mlp.groupby(['Trait','Archit','ActFun','LearnRate','Beta']).agg({'Accuracy': ['mean','std']}).reset_index()
          mlp_mean.columns = list(map(''.join, mlp_mean.columns.values))
          mlp_mean = mlp_mean.sort_values('Accuracymean', ascending=False).drop_duplicates(['Trait'])
          for i, row in mlp_mean.iterrows():
            index.append((j,row['Trait'],method))
            accuracy = np.append(accuracy, row['Accuracymean'])
            stdev = np.append(stdev, row['Accuracystd'])
            sterr = np.append(sterr, 'na')
            notes = np.append(notes, row['ActFun'] + '_' + row['Archit'] + '_' + str(row['LearnRate']) + '_' + str(row['Beta']))


pd_index = pd.MultiIndex.from_tuples(index, names = ['ID','Trait','Method'])
data_array = np.column_stack((np.array(accuracy), np.array(stdev), np.array(sterr), np.array(notes)))

df_acc = pd.DataFrame(data_array, index = pd_index, columns = ('Ac_mean', 'Ac_sd', 'Ac_se', 'Notes'))
print(df_acc.head(20))

df_acc.to_csv('RESULTS.csv', sep=',')


