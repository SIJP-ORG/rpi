#!/usr/bin/python
#
# barcode.py [ISBN] 
#    --> Just use ISBN (no image recognition).
# barcode.py uvc
#    --> Image recognition from USB UVC camera.
# barcode.py rpi
#    --> Image recognition from official camera module.
# barcode.py
#    --> Same as "rpi".
#
# Prerequisits:
#     apt-get install zbar-tools

import shelve
import sys
import subprocess
import re
import requests
from xml.etree import ElementTree

def process_isbn(isbn):
   url = "http://iss.ndl.go.jp/api/opensearch?isbn=%s" % isbn
   response = requests.get(url)

   # Response from NDL OpenSearch API is somewhat complex XML unfortunately.
   # We have to parse it now.
   root = ElementTree.fromstring(response.content)
   title = root.findall('.//dc:title', namespaces)[0].text
   author =  root.findall('.//dc:creator', namespaces)[0].text
   pubDate =  root.findall('.//pubDate', namespaces)[0].text
   publisher = root.findall('.//dc:publisher', namespaces)[0].text
   # dcndl.titleTranscription may not exist.
   try:
      transcript = root.findall('.//dcndl:titleTranscription', namespaces)[0].text
   except:
      transcript = ""

   # construct a KVS element and store it in the persistent storage.
   entry = {
      'title':title,
      'author':author,
      'pubDate':pubDate,
      'publisher':publisher,
      'transcript':transcript,
      }

   kvs[isbn] = entry

   # verbose output
   print entry['title']
   print entry['author']
   print entry['pubDate']
   print entry['publisher']
   print entry['transcript']


###
### Main
###
   
if __name__ == '__main__':
   kvs = shelve.open("shelve.db");

   # ElementTree requires namespace definition to work with XML with namespaces correctly
   # It is hardcoded at this point, but this should be constructed from response.
   namespaces = {
      'dc': 'http://purl.org/dc/elements/1.1/',
      'dcndl': 'http://ndl.go.jp/dcndl/terms/',
   }

   for prefix, uri in namespaces.iteritems():
      ElementTree.register_namespace(prefix, uri)

   # Determine major/sub mode from arguments.
   # (major, sub) = (camera, rpi) | (camera, uvc) | (isbn, null)
   if len(sys.argv) < 2:
      mode = 'camera'
      submode = 'rpi'
   else:
      if sys.argv[1] == 'uvc':
         mode = 'camera'
         submode = 'uvc'
      elif sys.argv[1] == 'rpi':
         mode = 'camera'
         submode = 'rpi'
      else:
         mode = 'isbn'
         
   if mode == 'camera':
      print "camera mode"

      # Open a pipe with zbarcam and wait for ISBN code.
      # For 'rpi' mode, turn on overlay for preview beforehand, and turn it off when done.
      # For 'uvc' mode, just invoke zbarcam and kill it when done.
      if submode == 'rpi':
         subprocess.call("v4l2-ctl --overlay=1".strip().split(" "));
         cmd = "zbarcam -v --nodisplay --prescale=640x480"
      else:
         cmd = "zbarcam"

      subproc = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

      pat = re.compile('^EAN-13:(9\d{12})')

      while True:
         line = subproc.stdout.readline()
         if not line:
            break
         print line.rstrip()
         m = pat.match(line)
         if m is not None:
            isbn = m.group(1)
            print ">> isbn=", isbn
            process_isbn(isbn)
            break;

# Looks like zbarcam does not die with these.
#      subproc.terminate()
#      subproc.kill()
      subprocess.call("killall zbarcam".strip().split(" "));
      if submode == 'rpi':
         subprocess.call("v4l2-ctl --overlay=0".strip().split(" "));
            
   else:
      print "scanner mode"
      isbn = sys.argv[1]
      process_isbn(isbn)
   
   kvs.sync();
   kvs.close();
