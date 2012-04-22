#ifndef _PLAYER_H_
#define _PLAYER_H_

#include<string>
#include "network.h"
#include "lua_io.h"
#include "dbase.h"

typedef enum {
  NAME,
  PASSWORD,
  NEW_NAME,
  NEW_PASSWORD,
  CONFIRM_NEW_PASSWORD,
  PLAYING
} PlayerState;

/*---------------------------------------------- */
/*  player class - holds details about each connected player */
/*---------------------------------------------- */
class Player
{
private:
  int s;              // socket they connected on
  int port;           // port they connected on
  std::string address;     // address player is from
  PlayerState state;      /* connection state */
  bool closing;     // true if they are about to leave us
  int loginCount;
  lua_State *L;
  dBase *db;

  std::string outbuf;      // pending output
  std::string inbuf;       // pending input

  std::string name;  // player name
  std::string password;    // their password

  void ProcessLine(std::string line);
public:

  Player (int sock, int port, const std::string addr, lua_State *l, dBase *db);
  ~Player ();

  void Send(std::string text);

  // true if connected at all
  bool Connected () const { return s != NO_SOCKET; }
  int GetSocket() const {return s;}
  bool PendingWrite() const { return !outbuf.empty(); }
  std::string Name() const { return name; }
  bool Closing() const { return closing; }

  void Disconnect();
  void ProcessRead ();    // get player input
  void ProcessWrite ();   // output outstanding text
};

#endif /* _PLAYER_H_ */
