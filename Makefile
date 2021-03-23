
# -Wno-comment: disable warnings for multi-line comments, present in some tests
CFLAGS = -Wall -Wno-comment -Werror -g 
CC     = gcc $(CFLAGS)
SHELL  = /bin/bash
CWD    = $(shell pwd | sed 's/.*\///g')

PROGRAMS = \
	batt_main \

TESTPROGRAMS = \
	hybrid_main \


all : $(PROGRAMS)

clean :
	rm -f $(PROGRAMS) *.o $(TESTPROGRAMS)

help :
	@echo 'Typical usage is:'
	@echo '  > make                          # build all programs'
	@echo '  > make hybrid_main              # build the combined C/assembly program'
	@echo '  > make clean                    # remove all compiled items'




################################################################################
# battery problem

# build .o files from corresponding .c files
%.o : %.c batt.h
	$(CC) -c $<

# build assembly object via gcc + debug flags
batt_update_asm.o : batt_update_asm.s batt.h
	$(CC) -c $<

batt_main : batt_main.o batt_sim.o batt_update_asm.o 
	$(CC) -o $@ $^

# batt_update functions testing program
test_batt_update : test_batt_update.o batt_sim.o batt_update_asm.o
	$(CC) -o $@ $^

# uses both assmebly and C update functions for incremental testing
hybrid_main : batt_main.o batt_sim.o batt_update_asm.o batt_update.o
	$(CC) -o $@ $^

