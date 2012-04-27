/*
******************************************************************
Written for cs3505 spring2012 by: Team Exception: cody curtis, joel hough, bailey malone, james murdock, john wells.
****************************************************************
*/

#include "lua_io.h"

#include "server.h"
#include<iostream>
#include<vector>

using namespace std;

/*
  int from_lua_send (lua_State *L)
  a function that will be registered in main with the lua state and then can be called from lua.
  lua can provide it any number of arguments and it will push them into a vector.
  as it is written now it only uses the first two args which needs to be a string!! as of now.
  it returns 1 if all goes well if fact it will always return 1 but that give the option
  later to return something else.
  */
int from_lua_send(lua_State *L)
{
    int argCount = lua_gettop(L);
    //debug
    cerr << "debug-- from_lua called with " << argCount
         << " arguments. -server.cpp L:148" << endl;
    vector <string> values;
    for ( int n=1; n<=argCount; ++n ) { // the first arg is at 1

        //debug
        std::cerr << "-- argument " << n << ": "
                  << lua_tostring(L, n) << "@" << __FILE__ << ":" << __LINE__ << endl;
        values.push_back(lua_tostring(L,n));
    }
    string name = values[0];
    string message = values[1];
    lua_pop(L,1);
    lua_pushnumber(L,1);// push the number one to indicate success.

    SendTextToPlayer(name, message);
    
    values.clear(); // clear out the vector. not necesary but what the hell.
    return 1;
}

int from_lua_disconnect_player(lua_State *L)
{
  string name = lua_tostring(L, 1);
  lua_pop(L, 1);
  lua_pushnumber(L, 1);
  DisconnectPlayer(name);
  return 1;
}

/*
  int to_lua (lua_State *L, string name, string message)
  a function that will try to call the function got_player_text(name, text) from the lua
  state L. passing it the strings name and message. if succesful it will return1
  if not it will return -1. right now the lua function cannot return anything.
  but that can change if need be.
  **note: this is delaired on L:119**
  */
int to_lua (lua_State *L, string name, string message)
{
    lua_getglobal(L, "got_player_text");
    if(!lua_isfunction(L,-1))
    {
        lua_pop(L,1); //it wasn't a function better remove it from the stack!
        return -1; // return failure
    }
    lua_pushstring(L, name.c_str());   // push 1st argument
    lua_pushstring(L, message.c_str());   // push 2nd argument


    if (lua_pcall(L, 2, 0, 0) != 0) //do the call (2 arguments, 0 result) if it fails.. report it.
    {
        cerr << "error running function 'got_player_text': " << lua_tostring(L, -1) << endl;
        return -1;
    }
    //no need to pop anything off because pcall didn't return and results.
    return 1; // return success
}

int to_lua_new_player(lua_State *L, string name)
{
  lua_getglobal(L, "new_player");
  if (!lua_isfunction(L, -1)) {
    lua_pop(L, 1);
    return -1;
  }
  lua_pushstring(L, name.c_str());
  if (lua_pcall(L, 1, 0, 0) != 0) {
    cerr << "error running function 'new_player': " << lua_tostring(L, -1) << endl;
    return -1;
  }
  return 0;
}

/*
  void report_errors(lua_State *L, int status)
  this function will cerr out an error in the lua set up if there is one and then pops
  the error off the stack. it takes in the lua_State and the return value of
  a std lua function.

  */
void report_errors(lua_State *L, int status)
{
  if ( status!=0 ) {
    std::cerr << "-- there was a lua error with: " << lua_tostring(L, -1) << std::endl;
    lua_pop(L, 1); // remove error message
  }
}
/**************************************************
  end lua commuication functions
  *************************************************/
