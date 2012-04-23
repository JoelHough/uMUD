/*
 * umud_bot.cpp
 *
 *  Created on: Apr 19, 2012
 *      Author: james murdock
 */


//open socket to irc
//pass credentials to irc
//listen for PING to send PONG :loop
//

/*
** client.c -- a stream socket client demo
*/

#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <netdb.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <cstring>
#include <ctype.h>
#include <sys/time.h>
#include <fcntl.h>
#include <list>
#include <string>
#include <vector>
#include <cctype>
#include <signal.h>

#include <arpa/inet.h>
#include <boost/regex.hpp>
#include <boost/algorithm/string/predicate.hpp>
#include <boost/algorithm/string.hpp>

using namespace std;

#define PORT "6667" // the port client will be connecting to
#define IRCHOST "irc.freenode.net"

const string UMUD_PORT = "4000";
const string UMUD_HOST = "umud.hyob.net";

#define MAXDATASIZE 500 // max number of bytes we can get at once

const string room = "#TeamException";
boost::regex irc_regex("^(:(?<prefix>\\S+) )?(?<command>\\S+)( (?!:)(?<params>.+?))?( :(?<trail>.+))?$");
boost::regex nick_regex("^(?<nick>\\S+)!(?<host>\\S+)$");
boost::regex umud_command_regex("^\\s*umud:\\s*(.*)$");

const int NO_SOCKET = -1;

bool isRunning = true; // Keep looping?
bool isQuitting = false; // Sent a quit?

int ircSocket = NO_SOCKET;
string ircOutBuf;
string ircInBuf;

fd_set in_set;
fd_set out_set;

struct IrcPlayer {
  int socket;

  // These aren't neccessarily the same!  irc is more tolerant than umud
  string name;
  string nick;

  string out_buf;
  string in_buf;
};

// player list type
typedef list <IrcPlayer*> PlayerList;
typedef PlayerList::iterator PlayerListIterator;

PlayerList playerList;

// get sockaddr, IPv4 or IPv6:
void *get_in_addr(struct sockaddr *sa)
{
    if (sa->sa_family == AF_INET) {
        return &(((struct sockaddr_in*)sa)->sin_addr);
    }

    return &(((struct sockaddr_in6*)sa)->sin6_addr);
}

void strip_control_chars(string &str)
{
  str.erase(remove_if(str.begin(), str.end(), (int(*)(int))iscntrl), str.end());
}

bool get_line(string &in_buf, string &out_line)
{
  string::size_type i = in_buf.find ('\n');
  if (i == string::npos)
    return false;

  out_line = in_buf.substr (0, i);  /* extract first line */
  strip_control_chars(out_line);
  in_buf = in_buf.substr (i + 1, string::npos); /* get rest of string */
  return true;
}

void write_from_buffer(int &to_socket, string &from_buf)
{
  while (to_socket != NO_SOCKET && !from_buf.empty ()) {
    // send a maximum of 512 at a time
    int len = min<int> (from_buf.size (), 512);

    // send to player
    int bytes = write (to_socket, from_buf.c_str (), len );

    // check for bad write
    if (bytes < 0) {
      if (errno != EWOULDBLOCK )
        perror ("send to player");  /* some other error? */
      return;
    }

    // remove what we successfully sent from the buffer
    from_buf.erase (0, bytes);

    // if partial write, exit
    if (bytes < len)
      break;

  } /* end of having write loop */
}

bool read_into_buffer(int &from_socket, string &to_buf)
{
  static vector<char> buf (1000);

  int bytes = read (from_socket, &buf [0], buf.size ());

  if (bytes == -1) {
    if (errno != EWOULDBLOCK)
      perror ("read from player");
    return true;
  }

  if (bytes <= 0) {
    close (from_socket);
    cerr << "Connection " << from_socket << " closed" << endl;
    from_socket = NO_SOCKET;
    return false;
  }
  
  to_buf += string (&buf [0], bytes);    /* add to input buffer */
  return true;
}

bool connect_with_nonblocking(int &sock, const string &host, const string &port)
{
  struct addrinfo hints, *servinfo, *p;
  int rv;
  char s[INET6_ADDRSTRLEN];

  memset(&hints, 0, sizeof hints);
  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = SOCK_STREAM;

  if ((rv = getaddrinfo(host.c_str(), port.c_str(), &hints, &servinfo)) != 0) {
    fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(rv));
    return false;
  }

  // loop through all the results and connect to the first we can
  for(p = servinfo; p != NULL; p = p->ai_next) {
    if ((sock = socket(p->ai_family, p->ai_socktype, p->ai_protocol)) == -1) {
      perror("client: socket");
      continue;
    }
    if (connect(sock, p->ai_addr, p->ai_addrlen) == -1) {
      close(sock);
      perror("client: connect");
      continue;
    }
    break;
  }

  if (p == NULL) {
    fprintf(stderr, "client: failed to connect\n");
    return false;
  }

  // Get some ASIO up in here
  if (fcntl( sock, F_SETFL, FNDELAY ) == -1) {
    perror("client: fndelay");
    return false;
  }

  inet_ntop(p->ai_family, get_in_addr((struct sockaddr *)p->ai_addr),
            s, sizeof s);
  printf("client: connecting to %s\n", s);

  freeaddrinfo(servinfo); // all done with this structure
  return true;
}

void irc_send_line(string line)
{
  // Toss it in the buffer.  The io loop will get it.
  cout << ">" << line << endl;
  ircOutBuf += line + "\n";
}

void irc_command(string command, string param, string trail)
{
  irc_send_line(command + " " + param + " :" + trail);
}

void say_to(string nick, string text)
{
  irc_command("PRIVMSG", nick, text);
}

void say_to_room(string text)
{
  say_to(room, text);
}

void me_say_to(string nick, string text)
{
  say_to(nick, "\001ACTION " + text + "\001");
}

void me_say_to_room(string text)
{
  me_say_to(room, text);
}

void irc_quit()
{
  say_to_room("Peace out, bitches!");
  irc_send_line("QUIT :Like tears in the rain, time to die.");
}

void close_comms()
{
  // Disconnect players
  for (PlayerListIterator i = playerList.begin(); i != playerList.end(); ++i) {
    if ((*i)->socket != NO_SOCKET) {
      close((*i)->socket);
      delete (*i);
    }
  }
  playerList.clear();

  // Disconnect irc
  if (ircSocket != NO_SOCKET) {
    close(ircSocket);
  }
}

// For signal handling
void bailout (int sig)
{
  if (isQuitting) {
    // Be more forceful the second time through here
    isRunning = false;
  } else {
    irc_quit();
    isQuitting = true;
  }
}

IrcPlayer *get_player_from_nick(string nick)
{
  for (PlayerListIterator i = playerList.begin(); i != playerList.end(); ++i) {
    if ((*i)->socket != NO_SOCKET) {
      if (boost::iequals((*i)->nick, nick)) {
        return (*i);
      }
    }
  }  
  return NULL;
}

bool add_player(string nick)
{
  say_to(nick, "Would you like to play a game?");
  say_to(nick, "How about global thermonuclear war?");
  say_to(nick, "Or how about some MF'n uMUD!?");
  int sock;
  if (!connect_with_nonblocking(sock, UMUD_HOST, UMUD_PORT)) {
    say_to(nick, "Or not, cause the uMUD server rejected you.");
    cout << "Couldn't connect to uMUD" << endl;
    return false;
  }
  IrcPlayer *player = new IrcPlayer();
  player->nick = nick;
  player->socket = sock;
  playerList.push_front(player);
  return true;
}

void process_room_umud_command(string command, string nick)
{
  if (boost::iequals(command, "play")) {
    // Initiate a game of umud in a private room
    say_to_room("Do something with sockets one day.");
    add_player(nick);
  } else if (boost::starts_with(command, "/me ")) {
    // Dance for the people!
    me_say_to_room(command.substr(4));
  }
}

void process_player_command(IrcPlayer *player, string command)
{
  // TODO: Handle ACTION->emote conversion
  player->out_buf += command + "\n";
}

void irc_process_line(string line)
{
  string prefix, command, params, trail, nick, umud_command;
  boost::cmatch result;
  if (boost::regex_match(line.c_str(), result, irc_regex)) {
    // Grab all the tasty captures!
    prefix = result.str("prefix");
    command = result.str("command");
    params = result.str("params");
    trail = result.str("trail");
  } else {
    // Malformed message from the server.  This should not happen.
    cout << "No regex match!" << endl;
    return;
  }
  if (command == "NOTICE" && trail == "*** No Ident response") {
    irc_send_line("NICK uMUDbot");
    irc_send_line("USER uMUDbot * 8 :uMUD BOT");
    irc_send_line("PRIVMSG nickserv :IDENTIFY l3tm3!n101");
  } else if(command == "376") { // :End of /MOTD command.
    irc_send_line("JOIN " + room);
    irc_send_line("PRIVMSG ChanServ :OP " + room + " uMUDbot");
  } else if(command == "ERROR" && boost::starts_with(trail, "Closing Link")) {
    isRunning = false;
  } else if(command == "PING") {
    irc_send_line("PONG :" + trail);
  } else if(command == "PRIVMSG") {
    // We got a message!
    if (boost::regex_match(prefix.c_str(), result, nick_regex)) {
      // Found out who is talking
      nick = string(result[1].first, result[1].second);
      if (boost::iequals(params, room)){
        // From the lobby
        if (boost::regex_match(trail.c_str(), result, umud_command_regex)) {
          // This is a command for us.
          umud_command = string(result[1].first, result[1].second);
          process_room_umud_command(umud_command, nick);
        }
      } else { // Prolly equals my nick, don't bother checking (famous last words)
        // From somewhere else.  Perhaps from the nick themself?
        IrcPlayer *player = get_player_from_nick(nick);
        if (player) {
          process_player_command(player, trail);
        } else {
          say_to(nick, "You aren't connected to the game!  Go to " + room + " and ask to play.");
        }
      }
    } else {
      cout << "Can't find a nick on this msg" << endl;
    }
  } else {
    cout << "Ignoring " << "(" << prefix << ")(" << command << ")(" << params << ")(" << trail << ")" << endl;
    return;
  }
  cout << "(" << prefix << ")(" << command << ")(" << params << ")(" << trail << ")" << endl;
}

void irc_process_lines()
{
  string line;
  while (get_line(ircInBuf, line)) {
    irc_process_line(line);
  }
}

void player_process_line(IrcPlayer *player, string line)
{
  say_to(player->nick, line);
}

void player_process_lines(IrcPlayer *player)
{
  string line;
  while (get_line(player->in_buf, line)) {
    player_process_line(player, line);
  }  
}

void players_process_lines()
{
  for (PlayerListIterator i = playerList.begin(); i != playerList.end(); ++i) {
    if ((*i)->socket != NO_SOCKET) {
      player_process_lines((*i));
    }
  }
}

void remove_disconnected_players()
{
  PlayerListIterator i = playerList.begin ();
  while (i != playerList.end ()) {
    IrcPlayer *player = (*i);
    PlayerListIterator prev = i;
    i++;
    if (player->socket == NO_SOCKET) {
      say_to(player->nick, "You are now disconnected from uMUD");
      playerList.erase(prev);
      delete player;
      player = 0;
    }
  } /* end of looping through players */
}

int set_descriptors()
{
  FD_ZERO(&in_set);
  FD_ZERO(&out_set);

  int max_socket = ircSocket;
  
  // We want IO from irc
  FD_SET(ircSocket, &in_set);
  if (!ircOutBuf.empty()) {
    FD_SET(ircSocket, &out_set);
  }
  
  // And IO from players
  for (PlayerListIterator i = playerList.begin(); i != playerList.end(); ++i) {
    if ((*i)->socket != NO_SOCKET) {
      max_socket = max ((*i)->socket, max_socket);
      FD_SET((*i)->socket, &in_set);
      if (!(*i)->out_buf.empty()) {
        FD_SET((*i)->socket, &out_set);
      }
    }
  }  
  return max_socket;
}

void fill_buffers()
{
  if (FD_ISSET(ircSocket, &in_set)) {
    // Handle the irc happenings
    read_into_buffer(ircSocket, ircInBuf);
  }
  if (FD_ISSET(ircSocket, &out_set)) {
    // Send that irc shit out!
    write_from_buffer(ircSocket, ircOutBuf);
  }

  // Loop through the players, checking the status, handling the buffers
  for (PlayerListIterator i = playerList.begin(); i != playerList.end(); ++i) {
    if ((*i)->socket != NO_SOCKET) {
      if (FD_ISSET((*i)->socket, &in_set)) {
        read_into_buffer((*i)->socket, (*i)->in_buf);
      }
      if (FD_ISSET((*i)->socket, &out_set)) {
        write_from_buffer((*i)->socket, (*i)->out_buf);
      }
    }
  }
}

void io_loop()
{
  // select timeout
  struct timeval timeout;
  timeout.tv_sec = 0;
  timeout.tv_usec = 500 * 1000;

  cout << "Entering io loop" << endl;
  while (isRunning) {

    int max_socket = set_descriptors();

    if (select(max_socket + 1, &in_set, &out_set, NULL, &timeout) > 0) {
      fill_buffers();
    }

    irc_process_lines();
    players_process_lines();

    remove_disconnected_players();
  }
  cout << "io loop done" << endl;
}


int main(int argc, char *argv[])
{
  cout << "uMUD bot starting up" << endl;
  if (argc < 2) {
    cout << "Usage: bot host" << endl;
    return -1;
  }
 
  signal (SIGINT,  bailout);
  signal (SIGTERM, bailout);
  signal (SIGHUP,  bailout);

  if (!connect_with_nonblocking(ircSocket, argv[1], PORT)) {
    return -1;
  }

  io_loop();

  close_comms();
  return 0;
}
