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

#include <arpa/inet.h>
#include <boost/regex.hpp>
#include <boost/algorithm/string.hpp>

#define PORT "6667" // the port client will be connecting to
#define IRCHOST "irc.freenode.net"

#define MAXDATASIZE 500 // max number of bytes we can get at once

int sock;            /* The socket file descriptor for our "listening"
                   	socket */
int connectlist[5];  /* Array of connected sockets so we know who
	 		we are talking to */
fd_set socks;        /* Socket file descriptors we want to wake
			up for, using select() */
int highsock;	     /* Highest #'d file descriptor, needed for select() */


using namespace std;

// get sockaddr, IPv4 or IPv6:
void *get_in_addr(struct sockaddr *sa)
{
    if (sa->sa_family == AF_INET) {
        return &(((struct sockaddr_in*)sa)->sin_addr);
    }

    return &(((struct sockaddr_in6*)sa)->sin6_addr);
}

int main(int argc, char *argv[])
{
    int sockfd, numbytes;
    char buf[MAXDATASIZE];
    struct addrinfo hints, *servinfo, *p;
    int rv;
    char s[INET6_ADDRSTRLEN];

    if (argc != 2) {
        fprintf(stderr,"usage: client hostname\n");
        exit(1);
    }

    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;

    if ((rv = getaddrinfo(argv[1], PORT, &hints, &servinfo)) != 0) {
        fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(rv));
        return 1;
    }

    // loop through all the results and connect to the first we can
    for(p = servinfo; p != NULL; p = p->ai_next) {
        if ((sockfd = socket(p->ai_family, p->ai_socktype,
                p->ai_protocol)) == -1) {
            perror("client: socket");
            continue;
        }

        if (connect(sockfd, p->ai_addr, p->ai_addrlen) == -1) {
            close(sockfd);
            perror("client: connect");
            continue;
        }

        break;
    }

    if (p == NULL) {
        fprintf(stderr, "client: failed to connect\n");
        return 2;
    }

    inet_ntop(p->ai_family, get_in_addr((struct sockaddr *)p->ai_addr),
            s, sizeof s);
    printf("client: connecting to %s\n", s);

    freeaddrinfo(servinfo); // all done with this structure

    /*--Begin add by James Murdock--*/
    //const sockaddr *umudSrvrHost = '166.70.129.150';
    //int umudSrvrPort(4000);

    sockaddr_in uMUDsrv;
    uMUDsrv.sin_addr.s_addr = inet_addr("166.70.129.150");
    uMUDsrv.sin_family = AF_INET;
    uMUDsrv.sin_port = htons(4000);
    char FDbuf[MAXDATASIZE];
    //max user file descriptor number
	int maxUserFD;
	//tracking file descriptor
	int trackingFD;
	//last file descriptor
	int lastFD;
	//FD buffer bytes
	int nbytes;
	//master file descriptor list
	fd_set master;
	//temp file descriptor list for select()
	fd_set read_fds;
	//zeroize master and temp file descriptor lists
	FD_ZERO(&master);
	FD_ZERO(&read_fds);
	//add the tracker to the master set
	FD_SET(sockfd, &master);
	//keep track of the biggest file descriptor
	maxUserFD = sockfd;

	bool run = true;
    while(run)
    {
//    	cout << "---RUN Loop0---" << endl;
//    	cout << "---RUN Loop1---" << endl;
//    	cout << "---RUN Loop2---" << endl;
    	if ((numbytes = recv(sockfd, buf, MAXDATASIZE-1, 0)) == -1)
    	{
//    		cout << "---ERROR RECV---" << endl;
			perror("recv");
			exit(1);
		}
//    	cout << "---PRIOR PRINT---" << endl;
    	printf("client: received '%s'\n",buf);
    	string bufstr(buf);
    	buf[numbytes] = '\0';


		while(bufstr.length() > 0)
		{
			string nick;
			string srvrName;
			string msg;
			bool srvrSection=false;
			boost::cmatch match;
			boost::regex srvName(":[^\\s][a-zA-Z0-9-]*\\.[a-zA-Z0-9-]*\\.[a-zA-Z]{2,4}[^\\s]", boost::regex_constants::perl);
			boost::regex msgData(":[a-zA-Z0-9-]*![~a-zA-Z0-9]*@[a-zA-Z0-9\\./-]*\\sPRIVMSG\\s#TeamException\\s:.*[^\r\n]", boost::regex_constants::perl);
			//[:][a-zA-Z0-9-]*[!][~a-zA-Z0-9]*@[a-zA-Z0-9-.]*\\s[P][R][I][V][M][S][G]\\s[#][T][e][a][m][E][x][c][e][p][t][i][o][n]\\s[:].*[\r\n]
			//[:][a-zA-Z0-9-]*[!][~a-zA-Z0-9]*@[a-zA-Z0-9-\\.]*\\sPRIVMSG\\s#TeamException\\s[:].*[^\r\n]
			//:[a-zA-Z0-9-]*![~a-zA-Z0-9]*@[a-zA-Z0-9-\\.]*\\sPRIVMSG\\s#TeamException\\s:umud:
			size_t endpos;

			if(bufstr.find("NOTICE * :*** No Ident response") != string::npos)
			{
//					cout << "---SENDING NICK---" << endl;

					if (send(sockfd, "NICK uMUDbot\n", 13, 0) == -1)
					{
						perror("send");
						exit(1);
					}
//					cout << "---SENDING Ident---" << endl;
					if (send(sockfd, "USER uMUDbot * 8 :uMUD BOT\n", 25, 0) == -1)
					{
						perror("send");
						exit(1);
					}

					if (send(sockfd, "PRIVMSG nickserv :IDENTIFY l3tm3!n101\n", 38, 0) == -1)
					{
						perror("send");
						exit(1);
					}
			}

			if(bufstr.find(":End of /MOTD command") != string::npos)
			{
//				cout << "---END OF MOTD FOUND---" << endl;
				if (send(sockfd, "JOIN #TeamException\n", 20, 0) == -1)
					perror("send");

				if (send(sockfd, "PRIVMSG ChanServ :OP #TeamException uMUDbot\n", 44, 0) == -1)
					perror("send");
			}

			if(regex_search(bufstr.c_str(), match, srvName))
			{
//				cout << "---srvName FOUND---" << endl;
				endpos = match.str().find(":");
				srvName = match.str().substr(endpos+1);
//				cout << "Debug srvName = " << srvName << endl;
			}

			if(regex_search(bufstr.c_str(), match, msgData))
			{
//				cout << "---msgData FOUND---" << endl;
				endpos = match.str().find("!");
				nick = match.str().substr(1,endpos-1);

				string newMatch = match.str().substr(1);
				endpos = newMatch.find(":");
				msg = newMatch.substr(endpos+1);

				if(msg.find("umud:") != string::npos)
				{
					int cmdOpt;
					string str;

					endpos = msg.find("umud:");
					cout << "endpos = " << endpos << endl;
					string cmd = msg.substr(endpos+5);
					endpos = cmd.find("\n");
					cmd = cmd.substr(0, endpos);
					if(cmd.find("hi") != string::npos || cmd.find("hello") != string::npos || cmd.find("sup") != string::npos)
					{
						cmdOpt = 1;
					}
					else if(cmd.find("play") != string::npos)
					{
						cmdOpt = 2;
					}
					else if(cmd.find("/me") != string::npos)
					{
						cmdOpt = 3;
					}
					else
					{
						cmdOpt = 0;
					}

					cout << "cmdOpt = " << cmdOpt << endl;
					switch(cmdOpt)
					{
						case 1:
							str = "PRIVMSG #TeamException :";
							str += cmd;
							str += " ";
							str += nick;
							str += "\n";

							if (send(sockfd, (void*)str.c_str(), str.length(), 0) == -1)
								perror("send");
							break;
						case 2:
							str = "PRIVMSG #TeamException :";
							str += "Do something with sockets here one day!\n";
							if (send(sockfd, (void*)str.c_str(), str.length(), 0) == -1)
								perror("send");
							//do socket stuff here
							//open a socket to umud.hyob.net 4000
							//send the response from the server to nick as a PRIVMSG nick :<server response>
							//each nick must identify to a select() socket

							/* handle new connections */
							/* Get a socket descriptor */
							if((trackingFD = socket(AF_INET, SOCK_STREAM, 0)) < 0)
							{
								perror("Server-socket() error");
								/* Just exit */
								exit (-1);
							}
//							else
//							{
//								printf("Server-socket() is OK...\n");
//
//								//FD_SET(trackingFD, &master); /* add to master set */
//								if(trackingFD > maxUserFD)
//								{ /* keep track of the maximum */
//									maxUserFD = trackingFD;
//								}
//							}
							if ((lastFD = connect(trackingFD, (sockaddr *)&uMUDsrv, sizeof(uMUDsrv))) == -1) {
								close(trackingFD);
								perror("client: connect");
								continue;
							}
							else
							{
								FD_SET(lastFD, &master);
								if(lastFD > maxUserFD)
								{ /* keep track of the maximum */
									maxUserFD = lastFD;
								}
							}
							break;
						case 3:
							str = "ME #TeamException :";
							str += cmd;
							str += " ";
							str += nick;
							str += "\n";

							if (send(sockfd, (void*)str.c_str(), str.length(), 0) == -1)
								perror("send");
							break;
						default:
							str = "PRIVMSG #TeamException :";
							str += "I do not understand your command, try umud:play or umud:<cmd>\n";
							if (send(sockfd, (void*)str.c_str(), str.length(), 0) == -1)
								perror("send");
					}
					//look for a command to send the user to a uMUD session
					cout << "---umud: FOUND---" << endl;
				}
			}

			if(bufstr.find("PING") != string::npos)
			{
				cout << "---PING FOUND---" << endl;
				string str = "PONG :";
				str += srvrName;
				str += "\n";

				if (send(sockfd, (void*)str.c_str(), str.length(), 0) == -1)
					perror("send");
			}

			if(bufstr.find("ERROR :Closing Link") != string::npos)
			{
				run = false;
			}

//			int lineEndPos = bufstr.find("\n");
//			bufstr = bufstr.substr(lineEndPos+1);
//			cout << "---RESETING bufstr---" << endl;
			bufstr.clear();
		}
		//bufstr = "";
//		cout << "---ENDING Nested While---" << endl;

		/*check for data from the uMUD server and pass to the respected user*/
		//copy master as the last file descriptor
		read_fds = master;
		if(select(maxUserFD+1, &read_fds, NULL, NULL, NULL) == -1)
		{
			perror("Server-select() error!");
			exit(1);
		}
		for(int i = 0; i <= maxUserFD; i++)
		{
			if(FD_ISSET(i, &read_fds))
			{
				/* handle data from the server */
				if((nbytes = recv(i, FDbuf, sizeof(FDbuf), 0)) <= 0)
				{
					/* got error or connection closed by server */
					if(nbytes == 0)
						/* connection closed */
						printf("%s: socket %d hung up\n", argv[0], i);
					else
						perror("recv() error!");
					/* close it... */
					close(i);
					/* remove from master set */
					FD_CLR(i, &master);
				}
				else
				{
					/* we got some data from the server*/
					for(int j = 0; j <= maxUserFD; j++)
					{
						/* send to everyone! */
						//I would rather send specific socket to associated nick
						if(FD_ISSET(j, &master))
						{
						   /* except the trackingFD and ourselves */
						   if(j != trackingFD && j != i)
						   {
							  if(send(j, FDbuf, nbytes, 0) == -1)
								 perror("send() error!");
						   }
						}
					}
				}
			}
		}
    }
    /*--End add by James Murdock--*/
//    cout << "---ENDING Program---" << endl;
    close(sockfd);

    return 0;
}

//void setnonblocking(sock)
//int sock;
//{
//	int opts;
//
//	opts = fcntl(sock,F_GETFL);
//	if (opts < 0) {
//		perror("fcntl(F_GETFL)");
//		exit(EXIT_FAILURE);
//	}
//	opts = (opts | O_NONBLOCK);
//	if (fcntl(sock,F_SETFL,opts) < 0) {
//		perror("fcntl(F_SETFL)");
//		exit(EXIT_FAILURE);
//	}
//	return;
//}
//
//void build_select_list() {
//	int listnum;	     /* Current item in connectlist for for loops */
//
//	/* First put together fd_set for select(), which will
//	   consist of the sock veriable in case a new connection
//	   is coming in, plus all the sockets we have already
//	   accepted. */
//
//
//	/* FD_ZERO() clears out the fd_set called socks, so that
//		it doesn't contain any file descriptors. */
//
//	FD_ZERO(&socks);
//
//	/* FD_SET() adds the file descriptor "sock" to the fd_set,
//		so that select() will return if a connection comes in
//		on that socket (which means you have to do accept(), etc. */
//
//	FD_SET(sock,&socks);
//
//	/* Loops through all the possible connections and adds
//		those sockets to the fd_set */
//
//	for (listnum = 0; listnum < 5; listnum++) {
//		if (connectlist[listnum] != 0) {
//			FD_SET(connectlist[listnum],&socks);
//			if (connectlist[listnum] > highsock)
//				highsock = connectlist[listnum];
//		}
//	}
//}
//
//void handle_new_connection() {
//	int listnum;	     /* Current item in connectlist for for loops */
//	int connection; /* Socket file descriptor for incoming connections */
//
//	/* We have a new connection coming in!  We'll
//	try to find a spot for it in connectlist. */
//	connection = accept(sock, NULL, NULL);
//	if (connection < 0) {
//		perror("accept");
//		exit(EXIT_FAILURE);
//	}
//	setnonblocking(connection);
//	for (listnum = 0; (listnum < 5) && (connection != -1); listnum ++)
//		if (connectlist[listnum] == 0) {
//			printf("\nConnection accepted:   FD=%d; Slot=%d\n",
//				connection,listnum);
//			connectlist[listnum] = connection;
//			connection = -1;
//		}
//	if (connection != -1) {
//		/* No room left in the queue! */
//		printf("\nNo room left for new client.\n");
//		sock_puts(connection,"Sorry, this server is too busy.  "
//					Try again later!\r\n");
//		close(connection);
//	}
//}
//
//void deal_with_data(
//	int listnum			/* Current item in connectlist for for loops */
//	) {
//	char buffer[80];     /* Buffer for socket reads */
//	char *cur_char;      /* Used in processing buffer */
//
//	if (sock_gets(connectlist[listnum],buffer,80) < 0) {
//		/* Connection closed, close this end
//		   and free up entry in connectlist */
//		printf("\nConnection lost: FD=%d;  Slot=%d\n",
//			connectlist[listnum],listnum);
//		close(connectlist[listnum]);
//		connectlist[listnum] = 0;
//	} else {
//		/* We got some data, so upper case it
//		   and send it back. */
//		printf("\nReceived: %s; ",buffer);
//		cur_char = buffer;
//		while (cur_char[0] != 0) {
//			cur_char[0] = toupper(cur_char[0]);
//			cur_char++;
//		}
//		sock_puts(connectlist[listnum],buffer);
//		sock_puts(connectlist[listnum],"\n");
//		printf("responded: %s\n",buffer);
//	}
//}
//
//void read_socks() {
//	int listnum;	     /* Current item in connectlist for for loops */
//
//	/* OK, now socks will be set with whatever socket(s)
//	   are ready for reading.  Lets first check our
//	   "listening" socket, and then check the sockets
//	   in connectlist. */
//
//	/* If a client is trying to connect() to our listening
//		socket, select() will consider that as the socket
//		being 'readable'. Thus, if the listening socket is
//		part of the fd_set, we need to accept a new connection. */
//
//	if (FD_ISSET(sock,&socks))
//		handle_new_connection();
//	/* Now check connectlist for available data */
//
//	/* Run through our sockets and check to see if anything
//		happened with them, if so 'service' them. */
//
//	for (listnum = 0; listnum < 5; listnum++) {
//		if (FD_ISSET(connectlist[listnum],&socks))
//			deal_with_data(listnum);
//	} /* for (all entries in queue) */
//}

