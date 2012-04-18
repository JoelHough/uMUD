# #---------------------------------------------------------------
# # Author: 	Team Exception
# # Date: 	Spring 2012
# #---------------------------------------------------------------
#
CC              = g++
CFLAGS          = -g -Wall -pedantic -I../include -L../lib
CPPFLAGS        = $(CFLAGS)
OBJS		= server.o dbase.o sqlite3.o
LIBS            = -llua -lpthread -ldl
EXE		= server
#
#
# ################################################################
# # ALL
# #
# # when you run make by itself, this is what it will try to create
# #
all: $(EXE)

sqlite3.o: sqlite3.c
	gcc -c $< -o $@

%.o: %.cpp
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@ 

#
# ################################################################
# #
# # Dependencies
# #
#
$(EXE): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $+ $(LIBS)

#
# ################################################################
# #
# # Clean
# #
#
clean:
	rm -f *.o $(EXE)

rebuild: clean $(EXE)

.PHONY: check-syntax
check-syntax:
	$(CXX) $(CXXFLAGS) -Wall -Wextra -pedantic -fsyntax-only $(CHK_SOURCES)
#
#
#
##EOF
