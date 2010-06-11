using Gee;

namespace icp {
	class Config {
		public static const string version = "0.8.0-alpha";
		public static const string global_data_path = "/usr/share/ibus-cloud-pinyin";

		// command line options
		public static string? startup_script = null;
		public static bool show_version;
		public static bool launched_by_ibus;
		public static bool do_not_connect_ibus;
		public static bool show_xml;

		// timeouts
		public static int request_timeout = 10000;
		public static int quick_request_timeout = 1000;

		// limits
		public static int database_query_limit = 256;

		// enables
		public static bool double_pinyin_enabled = false;
		public static bool background_request_enabled = true;
		public static bool always_show_candidates_enabled = false;
		public static bool show_pinyin_auxiliary_enabled = true;
		public static bool offline_mode_auto_commit_enabled = false;

		// punctuation		
		public class FullPunctuation {
			private ArrayList<string> full_chars;
			private bool only_after_chinese;
			private int index;

			public FullPunctuation(string full_chars, bool only_after_chinese = false) {
				this.full_chars = new ArrayList<string>();
				for (int i = 0; i < full_chars.length; i++) {
					this.full_chars.add(full_chars[i:i+1]);
				}
				this.only_after_chinese = only_after_chinese;
				index = 0;
			}

			public string get_full_char() {
				string r = full_chars[index];
				if (++index == full_chars.size) index = 0;
				return r;
			}
		}
		private static HashMap<int?, FullPunctuation> punctuations;
		public static void set_punctuation(int half_char, string full_chars, 
				bool only_after_chinese = false) {
			if (full_chars.length > 0) punctuations.remove(half_char);
			else punctuations[half_char] = new FullPunctuation(full_chars, only_after_chinese);
		}

		// registered keys
		public class Key {
			public uint key;
			public uint state;
			public Key(uint key, uint state) {
				this.key = key;
				this.state = state;
			}
			public static uint hash_func(Key a) {
				return a.key | a.state;
			}
			public static bool equal_func(Key a, Key b) {
				return a.key == b.key && a.state == b.state;
			}
		}
		private static HashMap<Key, string> key_actions;

		public static void set_key_action(Key key, string action) {
			lock (key_actions) {
				if (action.length == 0) key_actions.remove(key);
				else key_actions[key] = action;
			}
		}

		public static string get_key_action(Key key) {
			lock (key_actions) {
				if (!key_actions.contains(key)) return "";
				return key_actions[key];
			}
		}

		private Config() { }

		public static void init(string[] args) {
			// key actions
			key_actions = new HashMap<Key, string>
				((HashFunc) Key.hash_func, (EqualFunc) Key.equal_func);
			set_key_action(new Key(IBus.BackSpace, 0), "backspace");
			set_key_action(new Key(IBus.Escape, 0), "clear");

			// punctuations
			punctuations = new HashMap<int?, FullPunctuation>();

			// command line options
			OptionEntry entrie_script = { "script", 'c', 0, OptionArg.FILENAME, 
				out startup_script, "specify a startup script", "filename" };
			OptionEntry entrie_version = { "version", 'i', 0, OptionArg.NONE,
				out show_version, "show version information", null };
			OptionEntry entrie_ibus = { "ibus", 'b', 0, OptionArg.NONE,
				out launched_by_ibus, "run by ibus", null };
			OptionEntry entrie_no_ibus = { "no-ibus", 'n', 0, OptionArg.NONE,
				out do_not_connect_ibus,
				"do not register at ibus, use this if ibus-daemon is not running", null };			
			OptionEntry entrie_xml = { "dump-xml", 'x', 0, OptionArg.NONE,
				out show_xml, "print ibus engine description xml", null };
			OptionEntry entrie_null = { null };

			OptionContext context = new OptionContext("- cloud pinyin client for ibus");
			context.add_main_entries({entrie_script, entrie_version, entrie_ibus,
					entrie_no_ibus, entrie_xml, entrie_null}, null);

			try {
				context.parse(ref args);
			} catch (OptionError e) {
				stderr.printf("option parsing failed: %s\n", e.message);
			}

			if (startup_script == null) startup_script = global_data_path + "/config.lua";
		}
	}
}
