#!/usr/bin/python
import shelve
import sys
import subprocess
import re
import requests
from xml.etree import ElementTree

def process_isbn(isbn):
   url = "http://iss.ndl.go.jp/api/opensearch?isbn=%s" % isbn
   response = requests.get(url)
   root = ElementTree.fromstring(response.content)

   title = root.findall('.//dc:title', namespaces)[0].text
   author =  root.findall('.//dc:creator', namespaces)[0].text
   pubDate =  root.findall('.//pubDate', namespaces)[0].text
   publisher = root.findall('.//dc:publisher', namespaces)[0].text
   try:
      transcript = root.findall('.//dcndl:titleTranscription', namespaces)[0].text
   except:
      transcript = ""
      
   entry = {
      'title':title,
      'author':author,
      'pubDate':pubDate,
      'publisher':publisher,
      'transcript':transcript,
      }

   kvs[isbn] = entry

   print entry['title']
   print entry['author']
   print entry['pubDate']
   print entry['publisher']
   print entry['transcript']

   
if __name__ == '__main__':
   kvs = shelve.open("shelve.db");

   namespaces = {
      'dc': 'http://purl.org/dc/elements/1.1/',
      'dcndl': 'http://ndl.go.jp/dcndl/terms/',
   }

   for prefix, uri in namespaces.iteritems():
      ElementTree.register_namespace(prefix, uri)
   
   if len(sys.argv) < 2:
      print "camera mode"

      subprocess.call("v4l2-ctl --overlay=1".strip().split(" "));

      cmd = "zbarcam -v --nodisplay --prescale=640x480"
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

      subprocess.call("v4l2-ctl --overlay=0".strip().split(" "));
            
   else:
      print "scanner mode"
      isbn = sys.argv[1]
      process_isbn(isbn)
   
   kvs.sync();
   kvs.close();

   
