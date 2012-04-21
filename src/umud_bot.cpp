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

#include <arpa/inet.h>
#include <boost/regex.hpp>

#define PORT "6667" // the port client will be connecting to

#define MAXDATASIZE 500 // max number of bytes we can get at once

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
    bool run = true;
    while(run)
    {
    	cout << "---RUN Loop0---" << endl;
    	cout << "---RUN Loop1---" << endl;
    	cout << "---RUN Loop2---" << endl;
    	if ((numbytes = recv(sockfd, buf, MAXDATASIZE-1, 0)) == -1)
    	{
    		cout << "---ERROR RECV---" << endl;
			perror("recv");
			exit(1);
		}
    	cout << "---PRIOR PRINT---" << endl;
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
			boost::regex srvName("[:][^\\s][a-zA-Z0-9-]*[.][a-zA-Z0-9-]*[.][a-zA-Z]{2,4}[^\\s]", boost::regex_constants::perl);
			boost::regex msgData("[:][a-zA-Z0-9-]*[!][~a-zA-Z0-9]*@[a-zA-Z0-9-\\.]*\\sPRIVMSG\\s#TeamException\\s[:].*[^\r\n]", boost::regex_constants::perl);
			//[:][a-zA-Z0-9-]*[!][~a-zA-Z0-9]*@[a-zA-Z0-9-.]*\\s[P][R][I][V][M][S][G]\\s[#][T][e][a][m][E][x][c][e][p][t][i][o][n]\\s[:].*[\r\n]
			size_t endpos;

			if(bufstr.find("NOTICE * :*** No Ident response") != string::npos)
			{
					cout << "---SENDING NICK---" << endl;

					if (send(sockfd, "NICK uMUDbot\n", 13, 0) == -1)
					{
						perror("send");
						exit(1);
					}
					cout << "---SENDING Ident---" << endl;
					if (send(sockfd, "USER ident * 8 :uMUD BOT\n", 25, 0) == -1)
					{
						perror("send");
						exit(1);
					}
			}

			if(bufstr.find(":End of /MOTD command") != string::npos)
			{
				cout << "---END OF MOTD FOUND---" << endl;
				if (send(sockfd, "JOIN #TeamException\n", 20, 0) == -1)
					perror("send");
			}

			if(regex_search(bufstr.c_str(), match, srvName))
			{
				cout << "---srvName FOUND---" << endl;
				endpos = match.str().find(":");
				srvName = match.str().substr(endpos+1);
				cout << "Debug srvName = " << srvName << endl;
			}

			if(regex_search(bufstr.c_str(), match, msgData))
			{
				cout << "---msgData FOUND---" << endl;
				endpos = match.str().find("!");
				nick = match.str().substr(1,endpos-1);

				string newMatch = match.str().substr(1);
				endpos = newMatch.find(":");
				msg = newMatch.substr(endpos+1);

				if(msg.find("umud:") != string::npos)
				{
					cout << "---umud: FOUND---" << endl;
					string str = "PRIVMSG #TeamException :umudbot says hello ";
					str += nick;
					str += "\n";

					if (send(sockfd, (void*)str.c_str(), sizeof(str), 0) == -1)
						perror("send");
				}
			}

			if(bufstr.find("PING") != string::npos)
			{
				cout << "---PING FOUND---" << endl;
				string str = "PONG :";
				str += srvrName;
				str += "\n";

				if (send(sockfd, (void*)str.c_str(), sizeof(str), 0) == -1)
					perror("send");
			}

			if(bufstr.find("ERROR :Closing Link") != string::npos)
			{
				run = false;
			}

//			int lineEndPos = bufstr.find("\n");
//			bufstr = bufstr.substr(lineEndPos+1);
			cout << "---RESETING bufstr---" << endl;
			bufstr = "";
		}
		//bufstr = "";
		cout << "---ENDING Nested While---" << endl;
    }
    /*--End add by James Murdock--*/
    cout << "---ENDING Program---" << endl;
    close(sockfd);

    return 0;
}
