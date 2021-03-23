
# -Wno-comment: disable warnings for multi-line comments, present in some tests
CFLAGS = -Wall -Wno-comment -Werror -g 
CC     = gcc $(CFLAGS)
SHELL  = /bin/bash
CWD    = $(shell pwd | sed 's/.*\///g')

PROGRAMS = \
	main \

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
%.o : %.c battery.h
	$(CC) -c $<

# build assembly object via gcc + debug flags
update_asm.o : update_asm.s battery.h
	$(CC) -c $<

main : main.o simulate.o update_asm.o 
	$(CC) -o $@ $^

# uses both assmebly and C update functions for incremental testing
hybrid_main : main.o simulate.o update_asm.o update.o
	$(CC) -o $@ $^

