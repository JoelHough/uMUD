/*
******************************************************************
Written for cs3505 spring2012 by: Team Exception: cody curtis, joel hough, bailey malone, james murdock, john wells.
****************************************************************
*/

#include "dbase.h"
#include <iostream>

using namespace std;
static const char *db_path = "umud.db";

dBase::dBase()
{
    db = NULL;
    open(db_path);
}

dBase::~dBase()
{
  close();
}

bool dBase::open(const char* filename)
{
    if(sqlite3_open(filename, &db) == SQLITE_OK)
        return true;

    cerr << "Could not open database. " << sqlite3_errmsg(db);
    return false;
}

void dBase::close()
{
    sqlite3_close(db);
}

bool dBase::initialize()
{
  if (SQLITE_OK != sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS Player(user_id INTEGER, username TEXT NOT NULL COLLATE NOCASE, password TEXT NOT NULL, PRIMARY KEY(user_id), UNIQUE(username));", NULL, NULL, NULL)) {
    cerr << "Could not create player table. " << sqlite3_errmsg(db) << endl;
    return false;
  }
  return true;
}

bool dBase::checkLogin(string name, string password)
{
  sqlite3_stmt *stmt = NULL;
  if (SQLITE_OK != sqlite3_prepare_v2(db, "select exists (select password from Player where username=:name and password=:pass)", -1, &stmt, NULL) ||
      SQLITE_OK != sqlite3_bind_text(stmt, 1, name.c_str(), -1, SQLITE_TRANSIENT) ||
      SQLITE_OK != sqlite3_bind_text(stmt, 2, password.c_str(), -1, SQLITE_TRANSIENT)){
    sqlite3_finalize(stmt);
    cerr << "Could not prepare checkLogin query. " << sqlite3_errmsg(db) << endl;
    return false;
  }

  if (SQLITE_ROW != sqlite3_step(stmt)) {
    cerr << "No result from exists() check" << endl;
    sqlite3_finalize(stmt);
    return false;
  }
  
  bool result = sqlite3_column_int(stmt, 0) == 1;
  sqlite3_finalize(stmt);
  return result;  
}

bool dBase::newUser(string name, string password)
{
  //cerr << "DBase Name: " << name << " of size " << name.size() << endl;
  //cerr << "DBase Password: " << password << " of size " << password.size() << //endl;
  sqlite3_stmt *stmt = NULL;
  if (SQLITE_OK != sqlite3_prepare_v2(db, "insert into Player values(NULL, :name, :pass)", -1, &stmt, NULL) ||
      SQLITE_OK != sqlite3_bind_text(stmt, 1, name.c_str(), -1, SQLITE_TRANSIENT) ||
      SQLITE_OK != sqlite3_bind_text(stmt, 2, password.c_str(), -1, SQLITE_TRANSIENT)) {
    cerr << "Could not prepare new user query. " << sqlite3_errmsg(db) << endl;
    sqlite3_finalize(stmt);
    return false;
  }
  sqlite3_step(stmt);
  sqlite3_finalize(stmt);
  return true;
}

bool dBase::userExists(string name)
{
  sqlite3_stmt *stmt = NULL;
  if (SQLITE_OK != sqlite3_prepare_v2(db, "select exists (select * from Player where username=:name)", -1, &stmt, NULL) ||
      SQLITE_OK != sqlite3_bind_text(stmt, 1, name.c_str(), -1, SQLITE_TRANSIENT)) {
    cerr << "Could not prepare user check query. " << sqlite3_errmsg(db) << endl;
    sqlite3_finalize(stmt);
    return false;
  }

  if (SQLITE_ROW != sqlite3_step(stmt)) {
    cerr << "No result from exists() check" << endl;
    sqlite3_finalize(stmt);
    return false;
  }
  
  bool result = sqlite3_column_int(stmt, 0) == 1;
  sqlite3_finalize(stmt);
  return result;  
}
