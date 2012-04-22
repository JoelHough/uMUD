/*
  The following is *adapted* source code.
  The basic socket-communication-framework was kept.
  -- Team Exception MUD Server --


  -------------------------------------------------------------------
  tinymudserver - an example MUD server

  Author:  Nick Gammon
  http://www.gammon.com.au/

  Date:    22nd July 2004

  (C) Copyright Nick Gammon 2004. Permission to copy, use, modify, sell and
  distribute this software is granted provided this copyright notice appears
  in all copies. This software is provided "as is" without express or implied
  warranty, and with no claim as to its suitability for any purpose.

*/
#include <signal.h>
#include <sys/time.h>
#include <sys/types.h>

// standard library includes ...

#include <string.h>
#include <list>
#include <map>
#include <set>
#include <vector>
#include <stdexcept>
#include <fstream>
#include <iostream>
#include <sstream>
#include <ios>
#include <iterator>
#include <algorithm>
#include <limits>
#include <typeinfo>

#include <boost/algorithm/string.hpp>

#include "network.h"
#include "dbase.h"
#include "server.h"
#include "lua_io.h"

using namespace std;
// configuration constants


// global variables
bool   bStopNow = false;      // when set, the MUD shuts down
time_t tLastMessage = 0;      // time we last sent a periodic message
int    iControl = NO_SOCKET;  // socket for accepting new connections

// comms descriptors
fd_set in_set;
fd_set out_set;
fd_set exc_set;

// player list type
typedef list <Player*> PlayerList;
typedef PlayerList::iterator PlayerListIterator;

// list of all connected players
PlayerList playerList;

/* Here when a signal is raised */
void bailout (int sig)
{
  //cout << "**** Terminated by player on signal " << sig << " ****" << endl << endl;
  bStopNow = true;
} /* end of bailout */

/*
 * Looks for the player with name "n" in the playerList.
 * If found, returns that player.
 * Else, returns NULL.
 */
Player* GetTargetPlayer(string n)
{
  PlayerListIterator i = playerList.begin ();
  while (i != playerList.end ()) {
    if (boost::iequals((*i)->Name(), n)) {
      return (*i);
    }
    ++i;
  }
  return NULL;
}

bool SendTextToPlayer(Player* p, string text)
{
  if (p == NULL) {
    return false;
  }
  p->Send(text);
  return true;
}

bool SendTextToPlayer(string name, string text)
{
  Player* p = NULL;
  p = GetTargetPlayer(name); //get the pointer to the player by looking up his name
  if (p == NULL) {
    std::cerr << "Can't find '" << name << "'!" << endl;
    return false;
  }
  p->Send(text);
  return true;
}

bool DisconnectPlayer(string name)
{
  Player *p = GetTargetPlayer(name);
  if (p == NULL) {
    std::cerr << "Can't find '" << name << "' to kill him!" << endl;
    return false;
  }
  p->Disconnect();
  return true;
}

/* set up comms - get ready to listen for connection */
int InitComms ()
{
  struct sockaddr_in sa;

  try
    {
      // Create the control socket
      if ( (iControl = socket (AF_INET, SOCK_STREAM, 0)) == -1)
        throw runtime_error ("creating control socket");

      // make sure socket doesn't block
      if (fcntl( iControl, F_SETFL, FNDELAY ) == -1)
        throw runtime_error ("fcntl on control socket");

      struct linger ld = linger ();  // zero it

      // Don't allow closed sockets to linger
      if (setsockopt( iControl, SOL_SOCKET, SO_LINGER,
                      (char *) &ld, sizeof ld ) == -1)
        throw runtime_error ("setsockopt (SO_LINGER)");

      int x = 1;

      // Allow address reuse
      if (setsockopt( iControl, SOL_SOCKET, SO_REUSEADDR,
                      (char *) &x, sizeof x ) == -1)
        throw runtime_error ("setsockopt (SO_REUSEADDR)");

      sa.sin_family       = AF_INET;
      sa.sin_port         = htons (PORT);
      sa.sin_addr.s_addr  = INADDR_ANY;   /* change to listen on a specific adapter */

      // bind the socket to our connection port
      if ( bind (iControl, (struct sockaddr *) &sa, sizeof sa) == -1)
        throw runtime_error ("bind");

      // listen for connections
      if (listen (iControl, SOMAXCONN) == -1)  // SOMAXCONN is the backlog count
        throw runtime_error ("listen");

      tLastMessage = time (NULL);
    }  // end of try block

  // problem?
  catch (runtime_error & e)
    {
      cerr << "Cannot initialise comms ..." << endl;
      perror (e.what ());
      return 1;
    }

  // standard termination signals
  signal (SIGINT,  bailout);
  signal (SIGTERM, bailout);
  signal (SIGHUP,  bailout);

  return 0;
}   /* end of InitComms */


/* close listening port */
void CloseComms ()
{
  cerr << "Closing all comms connections." << endl;

  // close listening socket
  if (iControl != NO_SOCKET)
    close (iControl);

} /* end of CloseComms */

/* new player has connected */
void ProcessNewConnection (lua_State *L, dBase *db)
{
  static struct sockaddr_in sa;
  socklen_t sa_len = sizeof sa;

  int s;    /* incoming socket */

  /* loop until all outstanding connections are accepted */
  while (true)
    {
      s = accept ( iControl, (struct sockaddr *) &sa, &sa_len);

      /* a bad socket probably means no more connections are outstanding */
      if (s == NO_SOCKET)
        {

          /* blocking is OK - we have accepted all outstanding connections */
          if ( errno == EWOULDBLOCK )
            return;

          perror ("accept");
          return;
        }

      /* here on successful accept - make sure socket doesn't block */
      if (fcntl (s, F_SETFL, FNDELAY) == -1)
        {
          perror ("fcntl on player socket");
          return;
        }

      string address = inet_ntoa ( sa.sin_addr);
      int port = ntohs (sa.sin_port);

      Player * p = new Player (s, port, address, L, db);
      playerList.push_back (p);

      cout << "New player accepted on socket " << s <<
        ", from address " << address << ", port " << port << endl;

    } /* end of processing *all* new connections */
} /* end of ProcessNewConnection */

// prepare for comms
struct setUpDescriptors
{
  int iMaxdesc;

  setUpDescriptors (const int i) : iMaxdesc (i) {}

  // check this player
  void operator() (const Player * p)
  {
    /* don't bother if connection is closed */
    if (p->Connected ())
      {
        iMaxdesc = max (iMaxdesc, p->GetSocket ());
        // don't take input if they are closing down
        if (!p->Closing())
        {
          FD_SET( p->GetSocket (), &in_set  );
          FD_SET( p->GetSocket (), &exc_set );
        }
        if (p->PendingWrite()) FD_SET( p->GetSocket (), &out_set );
      } /* end of active player */
  } // end of operator()

  int GetMax () const { return iMaxdesc; }

};  // end of setUpDescriptors

// handle comms
struct processDescriptors
{
  // handle this player
  void operator() (Player * p)
  {
    /* look for ones we can read from, provided they aren't closed */
    if (p->Connected() && FD_ISSET (p->GetSocket (), &in_set) && !p->Closing())
      p->ProcessRead ();

    /* look for ones we can write to, provided they aren't closed */
    if (p->Connected() && FD_ISSET (p->GetSocket (), &out_set) && !p->Closing())
      p->ProcessWrite ();
  } // end of operator()

};  // end of processDescriptors

void RemoveInactivePlayers()
{
  PlayerListIterator i = playerList.begin ();
  while (i != playerList.end ())
    {
      Player *player = (*i);
      PlayerListIterator prev = i;
      i++;
      if (!player->Connected ()) {
        cerr << "Erasing " << player->Name() << " for being lazy." << endl;
        playerList.erase(prev);
        delete player;
        player = 0;
      }
    } /* end of looping through players */
} // end of RemoveInactivePlayers

// main processing loop
void MainLoop (lua_State *L, dBase *db)
{
  // loop processing input, output, events
  do {
    // get ready for "select" function ...
    FD_ZERO (&in_set);
    FD_ZERO (&out_set);
    FD_ZERO (&exc_set);

    // add our control socket (for new connections)
    FD_SET (iControl, &in_set);

    // set bits in in_set, out_set etc. for each connected player
    int iMaxdesc = for_each (playerList.begin (), playerList.end (),
                             setUpDescriptors (iControl)).GetMax ();

    // set up timeout interval
    struct timeval timeout;
    timeout.tv_sec = COMMS_WAIT_SEC;    // seconds
    timeout.tv_usec = COMMS_WAIT_USEC;  // + 1000th. of second

    // check for activity, timeout after 'timeout' seconds
    if (select (iMaxdesc + 1, &in_set, &out_set, &exc_set, &timeout) > 0) {
      // New connection on control port?
      if (FD_ISSET (iControl, &in_set))
        ProcessNewConnection(L, db);
      
      // handle all player input/output
        for_each (playerList.begin (), playerList.end (),
                  processDescriptors ());
    } // end of something happened
    RemoveInactivePlayers();
  }  while (!bStopNow);   // end of looping processing input
}   // end of MainLoop

