"""

"""

import sys, os
import pandas as pd
import numpy as np
import math
import random

for i in range (1,len(sys.argv),2):
  if sys.argv[i] == "-id":
    ID = sys.argv[i+1]


file_name = ID + "/01_Data/pheno.csv"

df = pd.read_csv(file_name, sep=',', header =0, index_col = 0)

cvs = pd.DataFrame(index = df.index)

n_lines = len(df)
n_reps = int((n_lines/5) + 1) #math.ceil
print(n_lines)

for i in range(1,101):
  name = 'cv_' + str(i)
  mix = np.repeat(range(1,6), n_reps)
  np.random.shuffle(mix)

  cvs[name] = mix[0:n_lines]

cvs.to_csv(ID + '/01_Data/CVFs.csv', sep=',')
print(cvs.head())
