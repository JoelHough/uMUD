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







/*
 *added the database code to handle at least logging on have added
 * code is commented with a -C to make it easier to fi*nd
  * -C
  */
#include <fcntl.h>
#include <signal.h>
#include <sys/time.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/errno.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <unistd.h>

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
#include <stdio.h>
#include <typeinfo>


//include the new class header file -C
#include "dbase.h"


//including the lua libraries -C
extern "C"{
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include "lpeg.h"
}



/*
 * TO-DO
 * -- Process control characters OUT of all incoming messages!
 * -- Check playrlist $ Same player canNOT log in more than once...
 *
 */





using namespace std;
// configuration constants

static const string VERSION = ">>>> 1.2.0";        // server version
static const int PORT = 4000;                 // incoming connections port
static const string PROMPT = ">>>> ";            // normal player prompt
static const string welcome_msg = PROMPT + "Welcome to Team Exception's MUD!\nVersion " + VERSION + "\n";
static const string login_request = ">>>> Enter your name and password, separated by returns                                  \n";

/* Setup --> ***Play/Chat Instructions*** */
static const string tell = "";
static const string interact = "";

// This is the time the "select" waits before timing out.
static const long COMMS_WAIT_SEC = 0;         // time to wait in seconds
static const long COMMS_WAIT_USEC = 500000;   // time to wait in microseconds
static const int NO_SOCKET = -1;              // indicator for no socket connected

// global variables
static bool   bStopNow = false;      // when set, the MUD shuts down
static time_t tLastMessage = 0;      // time we last sent a periodic message
static int    iControl = NO_SOCKET;  // socket for accepting new connections
// comms descriptors
static fd_set in_set;
static fd_set out_set;
static fd_set exc_set;

static dBase *db;
lua_State* L; //declare the global lua_state variable.

/**************************************************
  lua commuication functions added 4/19/12 -C
  *************************************************/
int to_lua (lua_State *L, string name, string message); //declaration to apease the mighty compiler.
int to_lua_new_player(lua_State *L, string name);
/**************************************************
  end lua commuication
  *************************************************/


/* connection states - add more to have more complex connection dialogs */
typedef enum
{
    eAwaitingName,        // we want their player name
    eAwaitingPassword,    // we want their old password

    eAwaitingNewName,     // they have typed 'new' and are being asked for a new name
    eAwaitingNewPassword, // we want a new password
    eConfirmPassword,     // confirm the new password

    ePlaying              // this is the normal 'connected' mode
} tConnectionStates;

/*---------------------------------------------- */
/*  player class - holds details about each connected player */
/*---------------------------------------------- */

class Player
{
private:
    int s;              // socket they connected on
    int port;           // port they connected on

    string outbuf;      // pending output
    string inbuf;       // pending input
    string address;     // address player is from

public:
    tConnectionStates connstate;      /* connection state */
    string prompt;      // the current prompt
    string name;  // player name
    string password;    // their password
    bool is_new_player;
    bool logged_in;
    int loginCount;

    bool closing;     // true if they are about to leave us

    Player (const int sock, const int p, const string a)
        : s (sock), port (p), address (a), closing (false)
    { Init (); } // ctor

    ~Player () // dtor
    {
        ProcessWrite ();    // send outstanding text
        if (s != NO_SOCKET) /* close connection if active */
            close (s);
    }

    void Init ()
    {
        closing = false;
        logged_in = false;
        loginCount = 0;
        connstate = eAwaitingName;
    }

    // Check Login Status
    bool IsLoggedIn() const { return logged_in; }
    // what's our socket?
    int GetSocket () const { return s; }
    // true if connected at all
    bool Connected () const { return s != NO_SOCKET; }
    // true if we have something to send them
    bool PendingOutput () const { return !outbuf.empty (); }
    bool IsValidName(string n);
    bool IsValidPassword(bool newPlayer, string name, string p);
    string Name()  { return this->name; }

    void SetName(string str)  { this->name = str; }
    void SetPassword(string str)  { this->password = str; }
    void ProcessRead ();    // get player input
    void ProcessWrite ();   // output outstanding text
    void ProcessException (); // exception on socket
};

// player list type
typedef list <Player*> PlayerList;
typedef PlayerList::iterator PlayerListIterator;

/*
 * <Utility Function>
 * Takes in a reference to a string and erases all
 * non-alphanumeric characters.
 */
static void EraseWhitespaces(string &str)
{
    for (size_t i = 0; i < str.size(); i++)
    {
        if (!isalpha(str[i]))
        {
            if (str[i] == ' ' || str[i] == '\n' || str[i] == '\t'
                    || str[i] == '\r')
            {
                str.erase(i,1);
            }
        }
    }
}

/* Some globals  */
// list of all connected players
std::vector<Player *> playerList;
//PlayerList playerList;

/* Here when a signal is raised */
void bailout (int sig)
{
    //cout << "**** Terminated by player on signal " << sig << " ****" << endl << endl;
    bStopNow = true;
} /* end of bailout */

/*
 * Tokenizes a parameter string (str) by whitespace
 * and returns a vector of delmited substring tokens.
 */
vector<string>* Tokenize(string str)
{
    //cerr << "Tokenize has --> " << str << endl;

    vector<string> *tokens = new vector<string>();

    int previous_space = 0;
    for (size_t i = 0; i < str.size(); i++)
    {
        if (str[i] == ' ')
        {
            string s = str.substr(previous_space, (i - previous_space));
            EraseWhitespaces(s);
            //cerr << "<token>: " << s << endl;

            previous_space = i;
            tokens->push_back(s);
        }
    }

    return tokens;
}


/*
 * Determines if the string 'msg' is a tell command to
 * say something to another player.
 *
 * INPUT: a string from a connected client
 * OUTPUT: a vector of booleans -- [0] is whether it is a
 *         tell command or not, and [1] name of the target player.
 *         > The return vector's format is:
 *           [0] tell cmd or not, [1] name of target player, [2] message;
 */
vector<string>* IsTellToPlayer(string msg)
{
    //cerr << "<IsTellToPlayer> with " << msg << endl;

    vector<string> *tell_vector = new vector<string>;
    //cerr << "Is Tell? msg(0,6) = " << msg.substr(0,6) << endl;
    //cerr << "Contains \"tell\"? -- " << msg.substr(0,6).find("tell") << endl;
    //cerr << "string::npos = " << string::npos << endl;

    // If the TELL cmd is in the right place...
    if (msg.substr(0,6).find("tell") != string::npos)
    {
        // Tokenize by spaces $ Tell [name] [message to 'name']
        vector<string> *tokens = Tokenize(msg);

        // IS a tell cmd
        tell_vector->push_back("yes");
        // Name of target player
        string Name = tokens->at(1);
        EraseWhitespaces(Name);
        tell_vector->push_back(Name);
        // Set message
        /* Need to amalgamate ALL the remaining tokens.... */
        string message = "";
        vector<string>::iterator it;
        for (it = tokens->begin()+2; it != tokens->end(); ++it)
        {
            //cerr << "Tokens: " << (*it) << endl;
            message += (*it);
            message += " ";
        }

        tell_vector->push_back(message);
    }
    else // NOT a tell command
    {
        tell_vector->push_back("no");
    }

    return tell_vector;
}

vector<string>* IsWorldMessage(string msg)
{
    vector<string> *broadcast = new vector<string>;

    // If the TELL cmd is in the right place...
    if (msg.substr(0,10).find("broadcast") != string::npos)
    {
        // Tokenize by spaces $ Tell [name] [message to 'name']
        vector<string> *tokens = Tokenize(msg);

        // Set message
        /* Need to amalgamate ALL the remaining tokens.... */
        string message = "";
        vector<string>::iterator it;
        for (it = tokens->begin()+1; it != tokens->end(); ++it)
        {
            //cerr << "B_Tokens: " << (*it) << endl;
            message += (*it);
            message += " ";
        }

        //cerr << "<Broadcast Msg>: " << message << endl;

        broadcast->push_back(message);
    }


    return broadcast;
}

/*
 * Looks for the player with name "n" in the playerList.
 * If found, returns that player.
 * Else, returns NULL.
 */
Player* GetTargetPlayer(string n)
{
    Player *p = NULL;

    //cerr << "Get the Player \"" << n << "\"" << endl;

    for (size_t i = 0; i < playerList.size(); i++)
    {
        /* DEBUG -- What's in the playerList here? */
        //cerr << "PlayerList(i) = \"" << playerList.at(i)->Name() <<"\""<< endl;
        //cerr << "PlayerList(i).compare(name) = " <<
        //playerList.at(i)->Name().compare(n) << endl;

        if (playerList.at(i)->Name().compare(n) == 0)
        {
            //cerr << "<Target Confirmed>" << endl;
            p = playerList.at(i);
        }
    }

    return p;
}


void TryToTellPlayer(Player *p, vector<string> *input)
{
    /* CODE: Tell to the player in msg! */
    // Is the player online/available?
    string targetName = input->at(1);
    Player *target = GetTargetPlayer(targetName);

    if (target) // NON-Null target player -- Send Tell!
    {
        string says = "(" + p->Name() + "): " + input->at(2) + "\n";
        const char *tell = says.c_str();
        write(target->GetSocket(), tell, says.size());
    }
    else  // Player either does not exist OR is offline -- inform sender
    {
        string playerNotFound = "Uh oh! That player is not online!\n";
        const char *inform = playerNotFound.c_str();
        write(p->GetSocket(), inform, playerNotFound.size());
    }
}

void MakeWorldBroadcast(vector<string> *world_message)
{
    string msg = "<WorldMessage>: " + world_message->at(0) + "\n";
    const char *cast = msg.c_str();

    //cerr << "...making world broadcast of \""<<msg<<"\""<<endl;

    for (size_t i = 0; i < playerList.size(); i++)
    {
        write((playerList.at(i))->GetSocket(), cast, msg.size());
    }
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
        cerr << PROMPT << "Cannot initialise comms ..." << endl;
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



/* *****
 * Takes the input for any NON-login client input.
 * --> Starting point for deciding what to do with the input.
 * *****
 */
void RemoveInactivePlayers (string n);

void ActOnPlayerInput(Player *p, string msg)
{
  if (to_lua(L,p->name, msg) == -1) {
    string oops = "Everything jerks slightly, as if the world hiccup'd.  You feel you have made the Gods angry.\n";
    write(p->GetSocket(), oops.c_str(), oops.size());
  }
}


void ProcessPlayerInput (Player * p, const string & s)
{
    /* DEBUG -- Print received messages! */
    //cerr << "MSG: " << s << endl;

    /*
   * TO-DO IMPLEMENTATION
   * --> Handle Login messages (how to tell? bool flag?)
   *    > Set Player.logged_in to TRUE when logged in,
   * --> Handle normal chat (echo...)
   */
    try
    {
        string msg = s;
        //cerr << "Process Input -- " << s << endl;

        if (!p->IsLoggedIn())
        {
            //if (p->loginCount == 0 && IsValidName(s))
            if (p->loginCount == 0)
            {
                bool newName = !p->IsValidName(s); // True -- NOT new

                // False -- new
                if (newName)
                {
                    //cerr << "<NEW PLAYER>" << endl;
                    p->is_new_player = true;

                }
                else // NOT a New player...
                {
                    //cerr << "<EXISTING PLAYER>" << endl;
                    p->is_new_player = false;
                }

                //EraseNonAlphas(msg)
                EraseWhitespaces(msg);
                p->SetName(msg);
                p->loginCount++;
            }
            else if (p->loginCount == 1)
            {
                bool valid_pwd = p->IsValidPassword(p->is_new_player, p->name, s);

                //cerr << "Valid Password ~ " << valid_pwd << endl;

                if (valid_pwd)
                {
                    EraseWhitespaces(msg);
                    p->SetPassword(msg);
                    p->loginCount++;
                    p->logged_in = true;

                    // Write out Successful_Login message!
                    string successful_login;
                    if (!p->is_new_player)
                        successful_login = ">>>> Welcome back " + p->Name() + "\n";
                    else
                        successful_login = ">>>> Welcome " + p->Name() + "\n";
                    const char *success = successful_login.c_str();

                    write(p->GetSocket(), success, successful_login.size());
                }
                else // Invalid Password! --> Set for new player, re-prompt for
                    // existing player
                {
                    if (p->is_new_player) // Set new player's password...
                    {
                        /* <SQLite Stuff> */

                        //EraseNonAlphas(s)
                        p->SetPassword(msg);
                        p->loginCount++;
                        p->logged_in = true;

                        //will add a player/pwd combination into the database
                        //probably needs to be tweeked bailey -C
                        // *******************************
                        db->newUser(p->name, p->password);
                        // *******************************

                        // Write out Successful_Login message!
                        string successful_login = ">>>> Welcome " + p->Name() + "\n";
                        const char *success = successful_login.c_str();
                        write(p->GetSocket(), success, successful_login.size());
                        to_lua_new_player(L, p->Name());
                    }
                    else /* Re-Prompt for login! */
                    {
                        //  Login Prompt
                        string invalid = PROMPT + "No one is sorry, but that is the wrong password for " + p->Name() + "\n";
                        const char *wrong_pwd = invalid.c_str();
                        write(p->GetSocket(), wrong_pwd, invalid.size());
                        const char *login_req = login_request.c_str();
                        write(p->GetSocket(), login_req, login_request.size());

                        // Reset Login Vars
                        p->loginCount = 0;
                        p->SetName("");
                        p->SetPassword("");
                    }
                }
            }
        }
        else // Player IS logged in --> Handle Normal InGame Input!
        {
            ActOnPlayerInput(p, msg);
        }
    } // end of try block

    // all errors during input processing will be caught here
    catch (runtime_error & e)
    {
        string err = e.what();
        const char *error = err.c_str();
        write(p->GetSocket(), error, err.size());
    }
} /* end of ProcessPlayerInput */

/*
 * <SQLite Method>
 * Verify with the SQLite database that this is a valid name.
 *
 * If Not --> Create new. **(How to indicate\handle new creation?)**
 */
bool Player::IsValidName(string name)
{
    /* SQLite stuff here... */
    string s1("SELECT username FROM Players WHERE username = '");
    string s2("';");
    // Make sure only alpha-characters have been passed -- else erase those
    EraseWhitespaces(name);

    string s = s1 + name + s2;
    const char *Q = s.c_str();
    cerr << "Q --> " << Q << endl;
    vector< vector<string> > results = db->query(Q);

    // Was the Player's name already in the DB?
    if (results.size() < 1)
    {
        cerr << "New Player Name EXCITING" << endl;
        return false;
    }
    else
    {
        //cerr << "Player Already Exists" << endl;
        return true;
    }
}

/*
 * <SQLite Method>
 * Verify, using the parameter name, the validity of the password.
 *
 * Calling function handles determining if an invalid passwowd
 * is invalid as it is for a new player or not.
 */
bool Player::IsValidPassword(bool is_new_player, string name, string pwd)
{
    /* SQLite stuff here... */
    string s1("SELECT password FROM Players WHERE password = '");
    string s2("';");
    // Make sure only alpha-characters have been passed -- else erase those
    EraseWhitespaces(pwd);

    string s = s1 + pwd + s2;
    const char *Q = s.c_str();
    cerr << "Q --> " << Q << endl;
    vector< vector<string> > results = db->query(Q);

    // Consider password validity -- is it wrong or a new player's?
    if (results.size() < 1)
    {
        return false;
    }
    else // Password WAS found
    {
        return true;
    }
}


/* new player has connected */
void ProcessNewConnection ()
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

        Player * p = new Player (s, port, address);
        playerList.push_back (p);

        cout << PROMPT << "New player accepted on socket " << s <<
                ", from address " << address << ", port " << port << endl;

        // Send Welcome Message & Login Request
        const char *welcome = welcome_msg.c_str();
        write(p->GetSocket(), welcome, welcome_msg.size());
        const char *login_req = login_request.c_str();
        write(p->GetSocket(), login_req, login_request.size());

    } /* end of processing *all* new connections */
} /* end of ProcessNewConnection */


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
        ProcessPlayerInput (this, "quit");  // tell others the s/he has left
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
        inbuf = inbuf.substr (i + 1, string::npos); /* get rest of string */

        // Handle the message....
        ProcessPlayerInput (this, sLine);  /* now, do something with it */
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
            //if (!p->closing)
            {
                FD_SET( p->GetSocket (), &in_set  );
                FD_SET( p->GetSocket (), &exc_set );
            }
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
        if (p->Connected() && FD_ISSET (p->GetSocket (), &in_set) && !p->closing)
            p->ProcessRead ();

        /* look for ones we can write to, provided they aren't closed */
        if (p->Connected() && FD_ISSET (p->GetSocket (), &out_set) && !p->closing)
            p->ProcessWrite ();
    } // end of operator()

};  // end of processDescriptors

void RemoveInactivePlayers (string n)
{
    //for (PlayerListIterator i = playerList.begin (); i != playerList.end (); )
    for (std::vector<Player *>::iterator i = playerList.begin();
         i != playerList.end(); ++i)
    {
        //if (!(*i)->Connected ())        // no longer connected
        if ((*i)->Name().compare(n) == 0)
        {
            /* DEBUG */
            //cerr << "Erasing " << (*i)->Name() << endl;
            playerList.erase(i);
            return;
        }
    } /* end of looping through players */
} // end of RemoveInactivePlayers



/**************************************************
  lua commuication functions added 4/19/12 -C
  *************************************************/
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
    string message = values[1] + "\n";
    lua_pop(L,1);
    lua_pushnumber(L,1);// push the number one to indicate success.
    //need to call a function to put send this out to telnet yo!
    //this may need to be modified to suit our later needs -C

    Player* p = NULL;
    p = GetTargetPlayer(name); //get the pointer to the player by looking up his name
    if (p == NULL) {
      std::cerr << "Can't find '" << name << "'!" << endl;
      return 1;
    }
    write(p->GetSocket(), message.c_str(), message.size()); //send out the message to the player
    values.clear(); // clear out the vector. not necesary but what the hell.
    return 1;
}

int from_lua_disconnect_player(lua_State *L)
{
  string name = lua_tostring(L, 1);
  lua_pop(L, 1);
  lua_pushnumber(L, 1);
  Player *p = GetTargetPlayer(name);
  string goodbye = PROMPT + "Goodbye " + p->Name() + "\n";
  const char *bye_msg = goodbye.c_str();
  write(p->GetSocket(), bye_msg, goodbye.size());
  p->closing = true;
  // Remove anyone that's left from the playerList
  close(p->GetSocket()); // Close the Socket
  RemoveInactivePlayers(p->Name());
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



// main processing loop
void MainLoop ()
{
    // loop processing input, output, events
    do
    {
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
        if (select (iMaxdesc + 1, &in_set, &out_set, &exc_set, &timeout) > 0)
        {
            // New connection on control port?
            if (FD_ISSET (iControl, &in_set))
                ProcessNewConnection ();

            // handle all player input/output
            for_each (playerList.begin (), playerList.end (),
                      processDescriptors ());
        } // end of something happened

    }  while (!bStopNow);   // end of looping processing input

}   // end of MainLoop



// main program
int main ()
{
    //may be a better place for this but for now create the database object here -C
    db = new dBase();
    db->initialize();
    L = luaL_newstate(); //initialize the lua state to be used until the game shuts down.

    const char* path = "../scripts/main.lua"; // the relative path that should work normally
    // const char* path = "../../../../uMUD/scripts/main.lua"; // the relative path i need to use at home -C



    luaL_openlibs(L); //open the libs. I think this will open them all.
    luaopen_lpeg(L);
    // make from_lua(lua_State *L) available to Lua functions
    lua_register(L, "server_send", from_lua_send);
    lua_register(L, "server_disconnect_player", from_lua_disconnect_player);

    if(luaL_dofile(L, path) != 0) // if there are no errors luaL_dofile() will rerturn 0
    {
        cerr << "there was an error with luaL_dofile: " << lua_tostring(L, -1) << endl;
    }

    cout << "Tiny MUD server version " << VERSION << endl;

    if (InitComms ()) // listen for new connections
        return 1;

    cout << "Accepting connections from port " <<  PORT << endl;

    MainLoop ();    // handle player input/output
    CloseComms ();  // stop listening

    cout << "Game shut down." << endl;
    lua_close(L); //close the lua state for we are done with it.
    return 0;
}   // end of main
