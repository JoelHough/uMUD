#ifndef _SERVER_H_
#define _SERVER_H_

#include<string>
#include "Player.h"

const std::string VERSION = "0.2.0";        // server version
const int PORT = 4000;                 // incoming connections port

// This is the time the "select" waits before timing out.
const long COMMS_WAIT_SEC = 0;         // time to wait in seconds
const long COMMS_WAIT_USEC = 500000;   // time to wait in microseconds

void bailout (int sig);

Player* GetTargetPlayer(std::string n);
bool DisconnectPlayer(std::string name);
bool SendTextToPlayer(std::string name, std::string text);
bool SendTextToPlayer(Player *p, std::string text);

int InitComms ();
void CloseComms ();

void RemoveInactivePlayers();

void MainLoop (lua_State *l, dBase *db);
#endif /* _SERVER_H_ */
