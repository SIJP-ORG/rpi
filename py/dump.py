#!/usr/bin/python
#
# dump KVS (shelve.db) created by barcode.py
#

from __future__ import print_function
import shelve

fields = ['title', 'author', 'pubDate', 'publisher', 'transcript']
kvs = shelve.open("shelve.db")

for k,v in kvs.items():
    print(k, ': {')
    [print('    ', f, ':', v[f]) for f in fields]
    print('},')

kvs.close();
