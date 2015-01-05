#!/usr/bin/env python
import subprocess as sp
import sys
import time
import signal, psutil
import os
from sets import Set

def get_child_processes(parent_pid):
    try:
      p = psutil.Process(parent_pid)
    except psutil.error.NoSuchProcess:
      return
    child_pids = p.get_children(recursive=True)
    return [child.pid for child in child_pids]

# runs a command for you and if the process is using over a certain
# memory threshold; fucking mop it out of the way
# usage: 
# ./mop.py max_bytes mycmd 

# example: ./mop.py 10000 ls .


PAGE_SIZE = 4000
def getRESMem(pid):
  return PAGE_SIZE * int(open("/proc/" + str(pid) + "/statm").read().split()[1])

max_mem = int(sys.argv[1])
cmd = sys.argv[2:]

print "running " + str(cmd)

p = sp.Popen(cmd)

print "process pid is " + str(p.pid)

allChildren = Set()

while True:
  if not p.poll() is None:
    print "process terminated by itself"
    break
  children = get_child_processes(p.pid)
  chSet = Set(children)
  newChildren = chSet.difference(allChildren)
  if len(newChildren) > 0:
    print "!!! new children spawned " + str(newChildren)
  allChildren = allChildren.union(children)

  # compute total memory for it and it's children
  mem = sum([getRESMem(pid) for pid in [p.pid] + children ])
  # print "total memory of " + str(children) + " is " + str(mem)
  if mem > max_mem:
    print "process reached memory " + str(mem) + " so i'm moppin it along with children"
    print children
    p.kill()
    for pid in children:
      print "killing child with pid " + str(pid)
      os.kill(pid, signal.SIGKILL) # tell it to fuck off no excuse
    break
  time.sleep(0.1) # wait for a bit
