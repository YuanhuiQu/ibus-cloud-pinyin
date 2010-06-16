/******************************************************************************
 *  ibus-cloud-pinyin - cloud pinyin client for ibus
 *  Copyright (C) 2010 WU Jun <quark@lihdd.net>
 *
 * 
 *  This file is part of ibus-cloud-pinyin.
 *
 *  ibus-cloud-pinyin is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  ibus-cloud-pinyin is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with ibus-cloud-pinyin.  If not, see <http://www.gnu.org/licenses/>.
 *****************************************************************************/

using Gee;
using icp.Pinyin;

namespace icp {
  namespace Database {
    static PhraseDatabase user_db;
    static PhraseDatabase global_db;

/*
    class UserDatabase {
      private static HashMap<string, Response> responses;

      class Response {
        public string content;
        public int priority;
        public Response(string content, int priority) {
          this.content = content;
          this.priority = priority;
        }
      }

      private UserDatabase() { }

      public static bool response (string pinyin,
          string content, int priority) {
        if (!responses.contains(pinyin) 
            || responses.get(pinyin).priority < priority) {
          if (content.length == 0)
            responses.unset(pinyin);
          else
            responses.set(pinyin, new Response(content, priority));
          return true;
        } else {
          return false;
        }
      }

      public static string query (string pinyin) {
        if (responses.contains(pinyin)) {
          return responses.get(pinyin).content;
        } else {
          return "";
        }
      }

      public static void init() {
        responses = new HashMap<string, Response>();
      }
    }
*/


    public class PhraseDatabase {
      private Sqlite.Database db;
      private bool user_db;
      private const int PHRASE_LENGTH_MAX = 15;

      public PhraseDatabase(string? filename = null, bool user_db = false) {
        if (filename == null) filename = Config.global_database;
        assert(Sqlite.Database.open_v2(filename, out db, 
              user_db ? 
              Sqlite.OPEN_READWRITE | Sqlite.OPEN_CREATE
              : Sqlite.OPEN_READONLY) 
            == Sqlite.OK
            );
        this.user_db = user_db;

        if (user_db) {
          StringBuilder builder = new StringBuilder();
          builder.append("BEGIN TRANSACTION;\n");
          // create tables and indexes
          for (int i = 0; i < PHRASE_LENGTH_MAX; i++) {
            builder.append("CREATE TABLE IF NOT EXISTS py_phrase_%d"
                .printf(i)
                );
            builder.append("(phrase TEXT, freq INTEGER, last DATETIME");
            for (int j = 0; j <= i; j++) {
              builder.append(",s%d INTEGER,y%d INTEGER".printf(j, j));
            }
            builder.append(");\n");

            string columns = "";
            for (int j = 0; j <= (i > 4 ? 4 : i); j++) {
              if (j > 0) columns += ",";
              columns += "s%d,y%d".printf(j, j);
            }
            builder.append(
                "CREATE INDEX IF NOT EXISTS index_%d_%d ON py_phrase_%d (%s);\n"
                .printf(i, 0, i, columns)
                );
          }
          builder.append("COMMIT;");

          assert (db.exec(builder.str) == Sqlite.OK);
        }
        db.exec("PRAGMA cache_size = 16384;\n PRAGMA temp_store = MEMORY;");
      }

      public bool reverse_convert(string content, 
          out Pinyin.Sequence pinyins) {
        bool successful = true;
        ArrayList<Pinyin.Id> ids = new ArrayList<Pinyin.Id>();

        for (int pos = 0; pos < content.length; ) {
          // IMPROVE: allow query longer phrases (also need sql index)
          int phrase_length_max = 5;
          if (pos + phrase_length_max >= content.length) 
            phrase_length_max = (int)content.length - pos - 1;

          int matched_length = 0;
          // note that phrase_length is real phrase length - 1 
          // for easily building sql query string
          for (int phrase_length = phrase_length_max; phrase_length >= 0; 
              phrase_length--) {
            string query = "SELECT ";
            for (int i = 0; i <= phrase_length; i++) {
              query += "s%d,y%d%c".printf(i, i,
                  (i == phrase_length) ? ' ':','
                  );
            }
            query += " FROM main.py_phrase_%d WHERE phrase=\"%s\" LIMIT 1"
              .printf(phrase_length, content[pos:pos + phrase_length + 1]);

            // query
            Sqlite.Statement stmt;

            if (db.prepare_v2(query, -1, out stmt, null) != Sqlite.OK)
              continue;

            for (bool running = true; running;) {
              switch (stmt.step()) {
                case Sqlite.ROW: 
                  // got it, matched
                  if (matched_length == 0) {
                    matched_length = phrase_length + 1;
                    for (int i = 0; i <= phrase_length; i++)
                      ids.add(new Pinyin.Id.id(stmt.column_int(i * 2), 
                            stmt.column_int(i * 2 + 1)));
                  }
                  break;
                case Sqlite.BUSY: 
                  Thread.usleep(1024);
                  break;
                default: 
                  running = false;
                  break;
              }
            }

            if (matched_length > 0) break;
          }

          if (matched_length == 0) {
            // try regonise it as a normal pinyin
            int pinyin_length = 6;
            if (pos + pinyin_length >= content.length) 
              pinyin_length = (int)content.length - pos;

            for (; pinyin_length > 0; pinyin_length--) {
              if (content[pos:pos + pinyin_length] in valid_partial_pinyins) {
                // got it
                matched_length = pinyin_length;
                ids.add(new Id(content[pos:pos + pinyin_length]));
                break;
              }
            }
          }

          if (matched_length == 0) {
            // not matched anyway, ignore that character
            successful = false;
            pos++;
          } else {
            pos += matched_length;
          }
        }

        pinyins = new Pinyin.Sequence.ids(ids);
        return successful;
      }

      public void query(Pinyin.Sequence pinyins, 
          ArrayList<string> candidates, 
          int limit = 0, double phrase_adjust = 2.4) {

        // candidates is already a ref type, directly modify it
        string where = "", query = "SELECT phrase, freqadj FROM (";

        for (int id = 0; id < pinyins.size; ++id) {
          if (id > PHRASE_LENGTH_MAX) break;

          Id pinyin_id = pinyins.get_id(id);
          int cid = pinyin_id.consonant, vid = pinyin_id.vowel;

          if (cid == 0 && vid == -1) break;
          // refuse to lookup single character with partial pinyin
          if (vid == -1 && id == 0) break;
          if (where.length != 0) where += " AND ";
          where += "s%d=%d".printf(id, cid);
          if (vid != -1) where += " AND y%d=%d".printf(id, vid);
          if (id > 0) query += " UNION ALL ";

          query += 
            "SELECT phrase, freq*%f AS freqadj FROM main.py_phrase_%d WHERE %s"
            .printf(Math.pow(1.0 + (double)id, phrase_adjust), id, where);
        }

        query += ") GROUP BY phrase ORDER BY freqadj DESC";
        if (limit > 0) query += " LIMIT %d".printf(limit);

        Sqlite.Statement stmt;

        if (db.prepare_v2(query, -1, out stmt, null) != Sqlite.OK) return;

        for (bool running = true; running;) {
          switch (stmt.step()) {
            case Sqlite.ROW: 
              {
                string phrase = stmt.column_text(0);
                candidates.add(phrase);
                break;
              }
            case Sqlite.DONE: 
              {
                running = false;
                break;
              }
            case Sqlite.BUSY: 
              {
                Thread.usleep(1024);
                break;
              }
            case Sqlite.MISUSE:
            case Sqlite.ERROR: 
            default: 
              {
                running = false;
                break;
              }
          }
        }
      }

      public string greedy_convert(Pinyin.Sequence pinyins, 
          double phrase_adjust = 4) {

        string r = "";
        if (pinyins.size == 0) return r;

        for (int id = (int) pinyins.size - 1; id >= 0;) {
          int length_max = id + 1;
          if (length_max > PHRASE_LENGTH_MAX) length_max = PHRASE_LENGTH_MAX;

          string query = "SELECT phrase, freqadj FROM (", phrase = "";

          for (int l = length_max; l > 0; --l) {
            // try construct from pinyins[id - l + 1 .. id]
            string where = "";
            for (int p = id - l + 1; p <= id; p++) {
              Id pinyin_id = pinyins.get_id(p);
              if (where.length > 0) where += " AND ";
              where += "s%d=%d".printf(p - (id - l + 1), pinyin_id.consonant);
              if (pinyin_id.vowel != -1) 
                where += " AND y%d=%d"
                  .printf(p - (id - l + 1), pinyin_id.vowel);
            }
            if (l != length_max) query += " UNION ALL ";
            query +=
              "SELECT phrase, freq*%f AS freqadj FROM main.py_phrase_%d WHERE %s"
              .printf(Math.pow((double)l, phrase_adjust), l - 1, where);
          }
          query += ") GROUP BY phrase ORDER BY freqadj DESC LIMIT 1";

          Sqlite.Statement stmt;
          if (db.prepare_v2(query, -1, out stmt, null) != Sqlite.OK) {
            return "";
          }

          for (bool running = true; running;) {
            switch (stmt.step()) {
              case Sqlite.ROW:
                {
                  phrase = stmt.column_text(0);
                  break;
                }
              case Sqlite.DONE:
                {
                  running = false;
                  break;
                }
              case Sqlite.BUSY:
                {
                  Thread.usleep(1024);
                  break;
                }
              case Sqlite.MISUSE:
              case Sqlite.ERROR:
              default:
                {
                  running = false;
                  break;
                }
            }
          }

          int match_length = (int)phrase.length;
          if (match_length == 0) {
            // can't convert just skip this pinyin -,-
            r = pinyins.get(id) + r;
            id--;
          } else {
            r = phrase + r;
            id -= match_length;
          }
        }
        return r;
      }
    } // class PhraseDatabase

    static void init() {
      // create essential directories
      string path = "";
      foreach (string dir in Config.user_cache_path.split("/")) {
        path += "/%s".printf(dir);
        Posix.mkdir(path, Posix.S_IRWXU);
      }

      global_db = new PhraseDatabase();
      user_db = new PhraseDatabase(Config.user_database, false);
    }
  } // namespace Database
} // namespace icp

/* vim:set et sts=2 tabstop=2 shiftwidth=2: */
