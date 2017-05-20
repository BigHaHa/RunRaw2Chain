#############################################################
#
#              Legacy Reconstruction Chain
#
#   $Id: Makefile 11084 2014-11-09 23:06:06Z munger $
#############################################################

EXE := ShineOffline
XMLS := $(patsubst %.xml.in,%.xml,$(wildcard *.xml.in))

.PHONY: all run clean

SHINEOFFLINECONFIG := shine-offline-config
CONFIGFILES := $(shell $(SHINEOFFLINECONFIG) --config)
DBFILES := $(shell $(SHINEOFFLINECONFIG) --db-path)
DOCPATH := $(shell $(SHINEOFFLINECONFIG) --doc)
TESTFILE := $(DOCPATH)/SampleEvents/run-009917x054_exampleevent.raw
TESTGLOBALKEY := 09_027
all:  $(XMLS)

%: %.in
	@ echo -n "Generating $@ file..."
	@ sed -e 's!@''CONFIGDIR@!$(CONFIGFILES)!g;s!@''SHINEDBDIR@!$(DBFILES)!g' $< >$@
	@ echo "done"
	@chmod +x runModuleSeq.sh

run: $(XMLS)
	./runModuleSeq.sh -i $(TESTFILE) -o test_pp -b bootstrap.xml -k $(TESTGLOBALKEY) -v pp && \
	./runModuleSeq.sh -i $(TESTFILE) -o test_pA -b bootstrap.xml -k $(TESTGLOBALKEY) -v pA && \
	./runModuleSeq.sh -i $(TESTFILE) -o test_pp_static -b bootstrap_static.xml -k $(TESTGLOBALKEY) -v pp && \
	./runModuleSeq.sh -i $(TESTFILE) -o test_pA_static -b bootstrap_static.xml -k $(TESTGLOBALKEY) -v pA && \
        touch $@  
clean:
	- rm -f $(XMLS) run *.root

