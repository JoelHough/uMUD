/*
******************************************************************
Written for cs3505 spring2012 by: Team Exception: cody curtis, joel hough, bailey malone, james murdock, john wells.
****************************************************************
*/

#include <vector>
#include <iostream>
#include <algorithm>
#include <cctype>
#include <boost/algorithm/string.hpp>

#include "Player.h"

using namespace std;

Player::Player (int sock, int port, const std::string addr, lua_State *l, dBase *db)
  : s (sock), port (port), address (addr), state(NAME), closing (false), 
    loginCount(0), L(l), db(db)
{
  Send("Welcome to uMUD, a TeamException production!");
  Send("New user?  Enter 'new' (no quotes).  Returning users enter your username:");
} // ctor

Player::~Player()
{
  Disconnect();
}

void Player::Disconnect()
{
  if (Connected()){
    closing = true;
    Send("Goodbye " + name);
    ProcessWrite();
    close(s);
    s = NO_SOCKET;
  }
}
void Player::Send(string text)
{
  outbuf += text + "\n";
}

bool allAlpha(string str)
{
  for (uint i = 0; i < str.length(); i++) {
    if (!isalpha(str[i])) {
      return false;
    }
  }
  return true;
}

void Player::ProcessLine(string line)
{
  switch (state) {
  case NAME:
    if (allAlpha(line)) {
      if (boost::iequals(line, "new")) {
        state = NEW_NAME;
        Send("Pick a new character name:");
      } else {
        if (db->userExists(line)) {
          name = line;
          state = PASSWORD;
          Send("Password:");
        } else {
          Send("That player name doesn't exist.  Try again:");
        }
      }
    } else {
      Send("Letters only, please.  Try again:");
    }
    break;
  case PASSWORD:
    if (db->checkLogin(name, line)) {
      state = PLAYING;
      Send("Welcome back, " + name + ".");
      to_lua_new_player(L, name);
    } else {
      if (++loginCount <= 4) {
        Send("That's not the right password. Try again:");
      } else {
        state = NAME;
        loginCount = 0;
        Send("Why don't you try guessing a new username?");
      }
    }
    break;
  case NEW_NAME:
    if (allAlpha(line)) {
      if (db->userExists(line)) {
        Send("That one's taken.  Try another:");
      } else {
        if (line.length() < 2) {
          Send("A little longer of a name, please.  At least two characters!");
        } else {
          name = line;
          state = NEW_PASSWORD;
          Send("Pick a password:");
        }
      }
    } else {
      Send("Letters only, please.  Try again:");      
    }
    break;
  case NEW_PASSWORD:
    state = CONFIRM_NEW_PASSWORD;
    password = line;
    Send("One more time to confirm:");
    break;
  case CONFIRM_NEW_PASSWORD:
    if (line.compare(password) == 0) {
      db->newUser(name, password);
      state = PLAYING;
      Send("Good to go.  Enjoy uMUD!");
      to_lua_new_player(L, name);
    } else {
      state = NEW_PASSWORD;
      Send("Those didn't match.  Try again:");
    }
    break;
  case PLAYING:
    if (to_lua(L, name, line) == -1) {
      Send("Everything jerks slightly, as if the world hiccup'd.  You feel you have made the Gods angry.");
    }
    break;
  }
}

void StripControlChars(string &str)
{
  str.erase(remove_if(str.begin(), str.end(), (int(*)(int))iscntrl), str.end());
}

/* Here when there is outstanding data to be read for this player */
void Player::ProcessRead ()
{
    // I make it static to save allocating a buffer each time.
    // Hopefully this function won't be called recursively.
    static vector<char> buf (1000);  // reserve 1000 bytes for reading into

    int nRead = read (s, &buf [0], buf.size ());

    if (nRead == -1)
    {
        if (errno != EWOULDBLOCK)
            perror ("read from player");
        return;
    }

    if (nRead <= 0)
    {
        close (s);
        cerr << "Connection " << s << " closed" << endl;
        s = NO_SOCKET;
        ProcessLine("disconnect");
        return;
    }

    inbuf += string (&buf [0], nRead);    /* add to input buffer */

    /* try to extract lines from the input buffer */
    for ( ; ; )
    {
        string::size_type i = inbuf.find ('\n');
        if (i == string::npos)
            break;  /* no more at present */

        string sLine = inbuf.substr (0, i);  /* extract first line */
        StripControlChars(sLine);
        inbuf = inbuf.substr (i + 1, string::npos); /* get rest of string */

        // Handle the message....
        ProcessLine(sLine);  /* now, do something with it */
    }
} /* end of tPlayer::ProcessRead */


/* Here when we can send stuff to the player. We are allowing for large
 volumes of output that might not be sent all at once, so whatever cannot
 go this time gets put into the list of outstanding strings for this player. */
void Player::ProcessWrite ()
{
  /* we will loop attempting to write all in buffer, until write blocks */
    while (s != NO_SOCKET && !outbuf.empty ())
    {
      // send a maximum of 512 at a time
        int iLength = min<int> (outbuf.size (), 512);

        // send to player
        int nWrite = write (s, outbuf.c_str (), iLength );

        // check for bad write
        if (nWrite < 0)
        {
            if (errno != EWOULDBLOCK )
                perror ("send to player");  /* some other error? */
            return;
        }

        // remove what we successfully sent from the buffer
        outbuf.erase (0, nWrite);

        // if partial write, exit
        if (nWrite < iLength)
            break;

    } /* end of having write loop */

}   /* end of tPlayer::ProcessWrite  */
