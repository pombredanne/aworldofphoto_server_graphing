#!/usr/bin/env python
import sys
import time
import os
import platform
import subprocess
import socket


host, port = sys.argv[1:]
port = int(port)

delay = 2 

def get_loadavg():    
    # For more details, "man proc" and "man uptime"      
        if platform.system() == "Linux":
            return open('/proc/loadavg').read().strip().split()[:3]    
        else:
            command = "uptime"
            process = subprocess.Popen(command, stdout=subprocess.PIPE, shell=True)                      
            os.waitpid(process.pid, 0)
            output = process.stdout.read().replace(',', ' ').strip().split()          
            length = len(output)
            return output[length - 3:length]


sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
try:
    sock.connect((host,port))
except:
    print "Couldn't connect to %(server)s on port %(port)d" % {'server': host, 'port': port}
    sys.exit(1)

while True:
    now = int(time.time())
    loadavg = get_loadavg()
    print 'Sending load: %s' % loadavg[0]
    sock.send('uptime_1min:%s|kv' % loadavg[0])
    time.sleep(delay)
