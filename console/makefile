progname := res/prog
srcdir = src

files = main

CFLAGS  = -Os -Wall -MD -MP -MT build/$(*F).$(arch).o -MF build/dep/$(@F).mk
#-D_REENTERAN
CXXFLAGS = $(CFLAGS) -std=c++11

LDFLAGS = -lm

# Выбор архитектуры
arch := lin64
#arch := win32

# Выбор режима
mode := 


##############################################################################################
##############################################################################################
#  Реализации
##############################################################################################
##############################################################################################

CC = $(COMP_PREFIX_$(arch))gcc$(COMP_SUFFIX_$(arch))
CXX= $(COMP_PREFIX_$(arch))g++$(COMP_SUFFIX_$(arch))
AR = $(COMP_PREFIX_$(arch))gcc-ar$(COMP_SUFFIX_$(arch))
RLIB=$(COMP_PREFIX_$(arch))gcc-ranlib$(COMP_SUFFIX_$(arch))

## LIN 64 ##
cflags_lin64	:=
ldflags_lin64	:= 
name_lin64 	:= $(progname)64

## WIN 32 ##
cflags_win32	:= -I./lib/win32/include
ldflags_win32	:= -static-libgcc -static-libstdc++ -Llib/win32/lib -lmingw32 -mconsole -mwindows
COMP_PREFIX_win32 := i686-w64-mingw32-
COMP_SUFFIX_win32 := -win32
name_win32	:= $(progname)32.exe

##############################################################################################
CFLAGS	+= $(cflags_$(arch))
CFLAGS	+= $(mode_$(mode)_cflags)
LDFLAGS	+= $(ldflags_$(arch))
LDFLAGS += $(mode_$(mode)_ldflags)
resname := $(name_$(arch))

objects = $(addprefix build/,$(addsuffix .$(arch).o,$(files)))
objects += $(addprefix build/,$(addsuffix .$(arch).o, $(mode_$(mode)_src)))

.PHONY: clean cleanall

all:	$(objects) 
	echo $<
	mkdir -p res
	$(CXX) $(objects) $(LDFLAGS) -o $(resname)
remake: 
	make clean
	make -j 10 all
clean:
	rm -f $(objects)
	rm -f $(resname)
	rm -rf build/dep
release:	allarch
	rm -rf build
	
cleanall:
	rm -rf build
	rm -f $(progname)*
allarch:
	make -r -j 10 arch=lin64
	make -r -j 10 arch=win32

build/%.$(arch).o: $(srcdir)/%.c $(srcdir)/$(mode_$(mode)_hdr)
	mkdir -p build
	$(CC) -c $(CFLAGS) $< -o $@
build/%.$(arch).o: $(srcdir)/%.cpp $(srcdir)/$(mode_$(mode)_hdr)
	mkdir -p build
	$(CXX) -c $(CXXFLAGS) $< -o $@

-include $(shell mkdir -p build/dep) $(wildcard build/dep/*)
