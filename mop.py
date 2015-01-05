#!/usr/bin/env python
import subprocess as sp
import sys
import time

# runs a command for you and if the process is using over a certain
# memory threshold; fucking mop it out of the way
# usage: 
# ./mop.py max_bytes mycmd 

# example: ./mop.py 10000 ls .


PAGE_SIZE = 4000
def getRESMem(pid):
  return PAGE_SIZE * int(open("/proc/" + str(pid) + "/statm").read().split()[2])

max_mem = int(sys.argv[1])
cmd = sys.argv[2:]

print "running " + str(cmd)

p = sp.Popen(cmd)

while True:
  if not p.poll() is None:
    print "process terminated by itself"
    break
  mem = getRESMem(p.pid)
  if mem > max_mem:
    print "process reached memory " + str(mem) + " so i'm moppin it"
    p.kill()
    break
  time.sleep(0.1)
