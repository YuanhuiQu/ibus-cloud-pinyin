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

    // keep this server only running by main process
    // must not fork() in thread excuting glib main loop in main process 
    [DBus (name = "org.ibus.CloudPinyin")]
      public class CloudPinyin : Object {

        // key interface for child processes to call
        public bool
        response (string pinyins, string content, int priority) {
          // return Database.user_db.response(pinyins, content, priority);
          return false;
        }

        // other programs use ...
        public string try_request (string pinyins) {
          // return Database.user_db.query(pinyins);
          return "";
        }

        public string quick_convert (string pinyins) {
          return Database.greedy_convert(
            new Pinyin.Sequence(pinyins)
            );
        }

        public void remember(string phrase) {
          Pinyin.Sequence sequence;
          Database.reverse_convert(phrase, out sequence);
          Database.insert(phrase, sequence);
        }

        public string quick_reverse_convert (string content) {
          Pinyin.Sequence ps;
          Database.reverse_convert(content, out ps);
          return ps.to_string();
        }

        public string format_pinyins (string pinyins) {
          Pinyin.Sequence ps = new Pinyin.Sequence(pinyins);
          return ps.to_string();
        }
      }

    public static void init() {
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
        }
      } catch (GLib.Error e) {
        stderr.printf("Error: %s\n", e.message);
      }
    }
  }
}

/* vim:set et sts=2 tabstop=2 shiftwidth=2: */
