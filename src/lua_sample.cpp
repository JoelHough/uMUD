#include <stdio.h>
#include <stdlib.h>

extern "C" {
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
}

lua_State* L;

int main(void)
{
  L = luaL_newstate();
  
  luaL_openlibs(L);

  // Do stuff here
 luaL_dofile(L, "script.lua");

  lua_close(L);
  return 0;
}
