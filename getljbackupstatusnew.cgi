#!/usr/bin/python3

import cgi, sys, hashlib, tempfile, urllib.request, urllib.parse, urllib.error, shutil, os

def deleteSession(sessionPath):
    try:
        os.remove(sessionPath + ".lock")
    except:
        pass
    try:
        os.remove(sessionPath + ".new")
    except:
        pass
    try:
        os.remove(sessionPath)
    except:
        pass

def getFileNameFromSessionId(session_id):
    tempDirectory = tempfile.gettempdir()
    prefix = 'ljbackupsess'
    suffix = ''
    m = hashlib.md5()
    m.update(session_id)
    md5 = m.hexdigest()[:16]
    return tempDirectory + "/" + prefix + md5 + suffix

form = cgi.FieldStorage()
session_id = form.getfirst('session_id')
#open('/tmp/ljnew-a', 'w').close()
path = getFileNameFromSessionId(session_id)
#open('/tmp/ljnew-b', 'w').close()
data = {}
try:
    #open('/tmp/ljnew-c', 'w').close()
    with open(path, 'r') as f:
        #open('/tmp/ljnew-d', 'w').close()
        for line in f:
            l = line.strip()
            equalsIndex = l.find('=')
            key = urllib.parse.unquote_plus(l[:equalsIndex])
            valueString = urllib.parse.unquote_plus(l[equalsIndex+1:])
            if valueString == 'BT':
                value = True
            elif valueString == 'BF':
                value = False
            else:
                value = valueString[1:]
            data[key] = value
except:
    print("Content-type: text/plain\n")
    print("11Error getting session - please try again.  If this continues to happen, contact Greg (reachable from www.gregstoll.com)");
    sys.exit(0)

doneCode = "1" if data['done'] else "0"
errorCode = "1" if data['error'] else "0"
status = data['status'] if data['status'] else "Unknown"
# Clean up if there was an error and remove the session and directory
if (data['error']):
    dirName = data['dirName']
    if (dirName != ''):
        shutil.rmtree(dirName)
    deleteSession(path)

print("Content-type: text/plain\n")
print(doneCode + errorCode + status)
