"""Take header file and runcc file and make the job files"""


import os, sys

head = sys.argv[1]
job = sys.argv[2]


with open(head) as h:
  header = h.readlines()

n = 0
with open(job) as j:
  for line in j:
    out_name = 'job' + str(n) + '.sh'
    out = open(out_name, 'w')
    
    for h in header:
      out.write(h)
    
    out.write(line)
    n += 1

