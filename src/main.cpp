/*
******************************************************************
Written for cs3505 spring2012 by: Team Exception: cody curtis, joel hough, bailey malone, james murdock, john wells.
****************************************************************
*/

#include "lua_io.h"
#include "server.h"
#include<iostream>

using namespace std;

const char* main_lua_file_path = "../scripts/main.lua";

lua_State* L; //declare the global lua_state variable.

// main program
int main ()
{
  cout << "Starting up uMUD..." << endl;
  cout << "Server version is "<< VERSION << endl;

  L = luaL_newstate(); //initialize the lua state to be used until the game shuts down.

  luaL_openlibs(L); // Gets all the standard libs
  luaopen_lpeg(L); // Loads lpeg, which we have statically linked

  // Register C functions with lua
  lua_register(L, "server_send", from_lua_send);
  lua_register(L, "server_disconnect_player", from_lua_disconnect_player);

  if(luaL_dofile(L, main_lua_file_path) != 0) // if there are no errors luaL_dofile() will return 0
    {
      cerr << "there was an error with luaL_dofile: " << lua_tostring(L, -1) << endl;
      return -1;
    }

  dBase *db = new dBase();
  if (!db->initialize()) {
    cerr << "Database initialization error!  Running without auth." << endl;
  }

  if (InitComms ()) // listen for new connections
    return 1;
  cout << "Accepting connections from port " <<  PORT << endl;

  MainLoop (L, db);    // handle player input/output

  CloseComms ();  // stop listening
  lua_close(L); //close the lua state for we are done with it.
  cout << "Game shut down." << endl;

  return 0;
}   // end of main
