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

namespace icp {
  class DBusBinding {
    private static DBus.Connection conn;
    private static dynamic DBus.Object bus;
    private static CloudPinyin server;

    private class Response {
      public string content { get; private set; }
      public int priority { get; private set; }

      public Response(string content, int priority) {
        this.content = content;
        this.priority = priority;
      }
    }

    private static HashMap<string, Response> responses;

    // for server use, internal
    public static string query(string pinyins) {
      if (responses.contains(pinyins)) return responses[pinyins].content;
      else return "";
    }

    public static bool set_response(string pinyins, string content, int priority = 1) {
      print("set response:%s,%s,%d\n", pinyins, content, priority);
      if (!responses.contains(pinyins) || responses[pinyins].priority
          < priority) {
        responses[pinyins] = new Response(content, priority);
        return true;
      } return false;
    }

    // server dbus object

    // keep this server only running by main process
    // must not fork() in thread excuting glib main loop in main process 
    [DBus (name = "org.ibus.CloudPinyin")]
      public class CloudPinyin : Object {

        // key interface for child processes to call
        public bool cloud_set_response(string pinyins, string content, 
          int priority) {
          return set_response(pinyins, content, priority);
        }

        // other programs use ...
        public string cloud_try_query(string pinyins) {
          return DBusBinding.query(pinyins);
        }

        public string local_convert(string pinyins) {
          return Database.greedy_convert(
              new Pinyin.Sequence(pinyins)
              );
        }

        public void local_remember_phrase(string phrase) {
          Pinyin.Sequence sequence;
          Database.reverse_convert(phrase, out sequence);
          Database.insert(phrase, sequence);
        }

        public string local_reverse_convert(string content) {
          Pinyin.Sequence ps;
          Database.reverse_convert(content, out ps);
          return ps.to_string();
        }
      }

    // for client
    public static void send_response(string pinyins, string content, 
      int priority) {
      var conn = DBus.Bus.get (DBus.BusType. SESSION);
      dynamic DBus.Object test_server_object 
        = conn.get_object ("org.ibus.CloudPinyin",
            "/org/ibus/CloudPinyin",
            "org.ibus.CloudPinyin");
      bool ret = test_server_object.cloud_set_response(pinyins, 
        content, priority
        );
    }

    // for server init
    public static void init() {
      responses = new HashMap<string, Response>();

      try {
        conn = DBus.Bus.get(DBus.BusType.SESSION);
        bus = conn.get_object("org.freedesktop.DBus",
            "/org/freedesktop/DBus",
            "org.freedesktop.DBus");

        uint request_name_result
          = bus.request_name("org.ibus.CloudPinyin", (uint) 0);

        if (request_name_result == DBus.RequestNameReply.PRIMARY_OWNER) {
          server = new CloudPinyin ();
          conn.register_object ("/org/ibus/CloudPinyin", server);
        } else {
          stderr.printf("FATAL: register DBus fail!\n"
            + "Please do not run this program multi times manually.\n");
          assert_not_reached();
        }
      } catch (GLib.Error e) {
        stderr.printf("Error: %s\n", e.message);
      }
    }
  }
}

/* vim:set et sts=2 tabstop=2 shiftwidth=2: */
