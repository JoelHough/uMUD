# #---------------------------------------------------------------
# # Author: 	Team Exception
# # Date: 	Spring 2012
# #---------------------------------------------------------------
#
CC              = g++
CFLAGS          = -g -Wall -I/home/jhough/include -L/home/jhough/lib
CPPFLAGS        = $(CFLAGS)
OBJS		= server.o dbase.o sqlite3.o lpeg.o Player.o lua_io.o main.o
LIBS            = -llua -lpthread -ldl
EXE		= server
#
#
# ################################################################
# # ALL
# #
# # when you run make by itself, this is what it will try to create
# #
all: $(EXE) bot

bot: umud_bot.o
	$(CC) $(CFLAGS) -o $@ $+ -lboost_regex

lpeg.o: lpeg.c
	gcc $(CFLAGS) $(INCLUDES) -c $< -o $@

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
	rm -f *.o $(EXE) bot

rebuild: clean $(EXE) bot

.PHONY: check-syntax
check-syntax:
	$(CXX) $(CXXFLAGS) -Wall -Wextra -pedantic -fsyntax-only $(CHK_SOURCES)
#
#
#
##EOF
