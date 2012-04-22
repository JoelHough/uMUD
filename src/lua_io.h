#ifndef _LUA_IO_H_
#define _LUA_IO_H_

#include<string>

//including the lua libraries
extern "C"{
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include "lpeg.h"
}

int from_lua_send (lua_State *L);
int from_lua_disconnect_player (lua_State *L);
int to_lua (lua_State *L, std::string name, std::string message);
int to_lua_new_player(lua_State *L, std::string name);

#endif /* _LUA_IO_H_ */
