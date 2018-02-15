"""Take qsub files from a directory and switch all the project IDs"""


import os, sys

for i in range (1,len(sys.argv),2):
  if sys.argv[i] == "-i":
    i = sys.argv[i+1]

ids = ['maize_DP_Crossa', 'rice_DP_Spindel', 'sorgh_DP_Fernan', 'soy_NAM_xavier', 'spruce_Dial_beaulieu', 'swgrs_DP_Lipka']
ids.remove(i)

for file in os.listdir(i):
    if file.startswith("qsub"):
      print("Working on %s" % file)
      with open(i + '/' + file, 'r') as job:
        content = job.readlines()
        
        for ID in ids:
          if not os.path.exists(ID):
            os.makedirs(ID)

          content_temp = content
          content_changed = [x.replace(i, ID) for x in content_temp]
          
          out = open(ID + '/' + file, 'w')
          for line in content_changed:
            out.write(line)

