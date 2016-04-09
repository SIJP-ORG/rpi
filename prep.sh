#!/bin/bash
sudo modprobe bcm2835-v4l2
killall -q zbarcam
#v4l2-ctl --overlay=1
#zbarcam -v --nodisplay --prescale=640x480

