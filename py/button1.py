#!/usr/bin/python
# ButtonPress sample w/ 3 tact switches at GPIO#25,24,23
#
from __future__ import print_function
import time
import RPi.GPIO as GPIO
import shlex
import subprocess

# Button List
pins = {
    25: { # GPIO Pin number
        'name': 'Lend',  # Button name/function
        'value': False,  # Current state
        'edge':  False,  # Whether my state has just changed or not
    },
    24: {
        'name': 'Return',
        'value': False,
        'edge':  False,
    },
    23: {
        'name': 'Cancel',
        'value': False,
        'edge':  False,
    },
}

# Setup GPIO pins as Input
GPIO.setmode(GPIO.BCM)
[GPIO.setup(p, GPIO.IN) for p in pins.keys()]

while True:
    for p in pins.keys():
        current = GPIO.input(p)
        if current != pins[p]['value']:
            pins[p]['value'] = current
            pins[p]['edge'] = True
        else:
            pins[p]['edge'] = False

        if pins[p]['edge'] == True and pins[p]['value'] == True:
            print('Button', pins[p]['name'] ,' pressed')
        
