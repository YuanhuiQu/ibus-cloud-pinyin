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

				// key interface for async engine call back
				public bool response (string pinyins, string content, int priority) {
					return icp.Pinyin.UserDatabase.response(pinyins, content, priority);
				}

				// for later web ime use ...
				public string try_request (string pinyins) {
					return icp.Pinyin.UserDatabase.request(pinyins);
				}

				public string quick_convert (string pinyins) {
					return icp.Pinyin.Database.greedy_convert(new Pinyin.Sequence(pinyins));
				}

				public string quick_reverse_convert (string content) {
					Pinyin.Sequence ps;
					icp.Pinyin.Database.reverse_convert(content, out ps);
					return ps.to_string();
				}
			}

		public static void init() {
			try {
				conn = DBus.Bus.get(DBus.BusType.SESSION);
				bus = conn.get_object("org.freedesktop.DBus",
						"/org/freedesktop/DBus",
						"org.freedesktop.DBus");

				uint request_name_result = bus.request_name("org.ibus.CloudPinyin", (uint) 0);

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

