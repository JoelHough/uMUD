/*
  a class for sqlite database communication
  written by cody curtis for cs 3505 project5
  v1 4/10/12

  including this class will most likely require finding the sqlite3 lib on your
  machine and linking it at compile time with "-lsqlite3" If you can't find it
  you will have to download the amalgamation from http://www.sqlite.org/download.html
  otherwise good luck with all the linker errors.
  */
#ifndef DBASE_H
#define DBASE_H

#include <string>
#include <sqlite3.h>

class dBase
{
public:
    dBase();
    ~dBase();

    bool initialize();
    bool checkLogin(std::string name, std::string password);
    bool newUser(std::string name, std::string password);
  bool userExists(std::string name);

private:
  bool open(const char *filename);
  void close();
  sqlite3 *db;
};

#endif // DBASE_H

