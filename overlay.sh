#!/bin/bash
if [ "x$1" == "xon" ]; then
    v4l2-ctl --overlay=1
else
    v4l2-ctl --overlay=0
fi

