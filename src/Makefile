# #---------------------------------------------------------------
# # Author: 	Team Exception
# # Date: 	Spring 2012
# #---------------------------------------------------------------
#
LUA_DIR         = ../lib/lua-5.1.5
CC              = g++
CFLAGS          = -g -Wall -pedantic -I$(LUA_DIR)/include -L$(LUA_DIR)/lib
CPPFLAGS        = $(CFLAGS)
OBJS		= server.o dbase.o sqlite3.o lpeg.o
LIBS            = -llua -lpthread -ldl
EXE		= server
#
#
# ################################################################
# # ALL
# #
# # when you run make by itself, this is what it will try to create
# #
all: lua $(EXE)

lua:
	cd $(LUA_DIR) && $(MAKE) linux local

lpeg.o: lpeg.c
	gcc -c $< -o $@

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
