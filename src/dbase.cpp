#include "dbase.h"
#include <iostream>
#include <vector>

using namespace std;

dBase::dBase()
{
    db = NULL;
    open("/tmp/mud.db");//a constant. set this method will also set the value of the db file name

}

dBase::~dBase()
{
  delete this;
}

bool dBase::open(char* filename)
{
    if(sqlite3_open(filename, &db) == SQLITE_OK)
        return true;

    return false;
}

vector<vector<string> > dBase::query(const char* query)
{
  /* DEBUG */
  //cerr << query << endl;

    sqlite3_stmt *statement;
    vector<vector<string> > results;
//    cerr << "made it to if in query" << endl;//debug
    if(sqlite3_prepare_v2(db, query, -1, &statement, 0) == SQLITE_OK)
    {
//        cerr << "made it inside if in query" << endl; //debug
        int cols = sqlite3_column_count(statement);
        int result = 0;
        while(true)
        {
            result = sqlite3_step(statement);
//            cerr << "result is: " << result << endl;//debug

            if(result == SQLITE_ROW)
            {
               vector<string> values;
               for(int col = 0; col < cols; col++)
               {
                 std::string  val;
                 char * ptr = (char*)sqlite3_column_text(statement, col);

//                 cerr << "ptr is " << ptr << endl;//debug

                 if(ptr)
                 {
                   val = ptr;// gets set only if ptr is not null
                 }
//                 cerr << "the value val: " << val << endl;//debug
                 values.push_back(val);
               }
               results.push_back(values);
            }
            else
            {
               break;
            }


        }

        sqlite3_finalize(statement);
    }

    string error = sqlite3_errmsg(db);
    if(error != "not an error") cout << query << " from dBase->query " << error << endl;

    return results;
}

void dBase::close()
{
    sqlite3_close(db);
}

bool dBase::initialize()
{
  sqlite3_stmt *statement;
  //query("CREATE TABLE Players(user_id INTEGER, username VARCHAR(20) NOT NULL, password VARCHAR(20) NOT NULL, PRIMARY KEY(user_id), UNIQUE(username);");

  //----Modification by James Murdock 20120418----//
 const char *createTable_players("CREATE TABLE IF NOT EXISTS Players(user_id INTEGER, username VARCHAR(20) NOT NULL, password VARCHAR(20) NOT NULL, PRIMARY KEY(user_id), UNIQUE(username));");
            
 const char *createTable_gd("CREATE TABLE IF NOT EXISTS game_data(gd_id VARCHAR(20), u_id INTEGER, lua_blob BLOB, PRIMARY KEY(gd_id) FOREIGN KEY(u_id) REFERENCES users(user_id));");


  if(sqlite3_prepare_v2(db, createTable_players, -1, &statement, 0) == SQLITE_OK)
    {
      sqlite3_finalize(statement);
    }

  if(sqlite3_prepare_v2(db, createTable_gd, -1, &statement, 0) == SQLITE_OK)
    {
      sqlite3_finalize(statement);
    }
    //----End Modification by James Murdock 20120418----//        
    return true;
}

bool dBase::queryLogin(string name, string password)
{
  bool new_player;
  /* Check Name -- *New* or *Existing* Player? */
  /* <<<This Query is Wrong!>>>
   */
  vector<vector<string> > player_check = query(("SELECT username, password FROM Players WHERE username = '" + name + "';").c_str());

  //cerr << "player_check.size() = " << player_check.size() << endl;

  if (player_check.size() <= 0)
    {
      new_player = true;
      newUser(name, password);
    }
  else
    {
      new_player = false;
    }

  // IF New Player --> Valid Login, return true
  if (new_player)
    {
      //cerr << "New Player!" << endl;

      return true;
    }
  else // Is an existing player --> Verify accuracy of password
    {
      vector<string> row = player_check[0];
      cerr << "row[0] = " << row[0] << endl;
      cerr << "row[1] = " << row[1] << endl;

      return (row[1] == password);
    }
}

void dBase::newUser(string name, string password)
{
  //cerr << "DBase Name: " << name << " of size " << name.size() << endl;
  //cerr << "DBase Password: " << password << " of size " << password.size() << //endl;

  string s1("INSERT INTO Players VALUES('");
  string s2("' , '");
  string s3("')");
  string command = s1 + name + s2 + password + s3;
  //cerr << "CMD: " << command << endl;
  query(command.c_str());
}
