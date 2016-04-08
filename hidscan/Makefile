###########################################
# Simple Makefile for HIDAPI test program
#
# Alan Ott
# Signal 11 Software
# 2010-06-01
###########################################

all: hidscan

CC       ?= gcc
CFLAGS   ?= -Wall -g -fpic

CXX      ?= g++
CXXFLAGS ?= -Wall -g -fpic -std=c++11

LDFLAGS  ?= -Wall -g

COBJS_LIBUSB = hid.o
COBJS = $(COBJS_LIBUSB)
CPPOBJS   = hidtest.o
OBJS      = $(COBJS) $(CPPOBJS)
LIBS_USB  = `pkg-config libusb-1.0 --libs` -lrt -lpthread
LIBS      = $(LIBS_USB)
INCLUDES ?= -I. `pkg-config libusb-1.0 --cflags`


# Console Test Program
hidscan: $(COBJS_LIBUSB) $(CPPOBJS)
	$(CXX) $(LDFLAGS) $^ $(LIBS_USB) -o $@

# Objects
$(COBJS): %.o: %.c
	$(CC) $(CFLAGS) -c $(INCLUDES) $< -o $@

$(CPPOBJS): %.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $(INCLUDES) $< -o $@

clean:
	rm -f $(OBJS) hidscan hidtest.o hid.o

.PHONY: clean libs
