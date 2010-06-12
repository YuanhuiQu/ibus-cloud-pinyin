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
		public static bool show_raw_in_auxiliary_enabled = false;
		public static bool offline_mode_auto_commit_enabled = false;

		public static bool default_offline_mode = false;
		public static bool default_chinese_mode = true;
		public static bool default_traditional_mode = false;
		
		// punctuation		
		public class FullPunctuation {
			private ArrayList<string> full_chars;
			public bool only_after_chinese { get; private set; }
			private int index;

			public FullPunctuation(string full_chars, bool only_after_chinese = false) {
				this.full_chars = new ArrayList<string>();
				foreach (string s in full_chars.split(" "))
					this.full_chars.add(s);
				this.only_after_chinese = only_after_chinese;
				index = 0;
			}

			public string get_full_char() {
				string r = full_chars[index];
				if (++index == full_chars.size) index = 0;
				return r;
			}
		}

		private static HashMap<int, FullPunctuation> punctuations;
		public static void set_punctuation(int half_char, string full_chars, 
				bool only_after_chinese = false) {
			lock (punctuations) {
				if (full_chars.length == 0) punctuations.remove(half_char);
				else punctuations[half_char] = new FullPunctuation(full_chars, only_after_chinese);
			}
		}
		public static string get_punctuation(int key, bool after_chinese = true) {
			lock (punctuations) {
				if (!punctuations.contains(key) || (punctuations[key].only_after_chinese 
					&& !after_chinese)) return "%c".printf(key);
				return punctuations[key].get_full_char();
			}
		}

		// key actions
		public class Key {
			public uint key;
			public uint state;
			public Key(uint key, uint state = 0) {
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

		// init
		public static void init(string[] args) {
			// key actions
			key_actions = new HashMap<Key, string>
				((HashFunc) Key.hash_func, (EqualFunc) Key.equal_func);
			set_key_action(new Key(IBus.BackSpace), "back");
			set_key_action(new Key(IBus.space), "sep commit");
			set_key_action(new Key(IBus.Escape), "clear");
			set_key_action(new Key((uint)'\''), "sep");
			set_key_action(new Key((uint)'P',
				IBus.ModifierType.RELEASE_MASK | IBus.ModifierType.CONTROL_MASK 
				| IBus.ModifierType.SHIFT_MASK), "offline online");
			set_key_action(new Key(IBus.Shift_L, 
				IBus.ModifierType.RELEASE_MASK | IBus.ModifierType.SHIFT_MASK), "eng chs");
			set_key_action(new Key(IBus.Shift_R, 
				IBus.ModifierType.RELEASE_MASK | IBus.ModifierType.SHIFT_MASK), "trad simp");
			set_key_action(new Key(IBus.Return), "raw");

			// punctuations
			punctuations = new HashMap<int, FullPunctuation>();
			set_punctuation('.', "。", true);
			set_punctuation(',', "，", true);
			set_punctuation('^', "……");
			set_punctuation('@', "·");
			set_punctuation('!', "！");
			set_punctuation('~', "～");
			set_punctuation('?', "？");
			set_punctuation('#', "＃");
			set_punctuation('$', "￥");
			set_punctuation('&', "＆");
			set_punctuation('(', "（");
			set_punctuation(')', "）");
			set_punctuation('{', "｛");
			set_punctuation('}', "｝");
			set_punctuation('[', "［");
			set_punctuation(']', "］");
			set_punctuation(';', "；");
			set_punctuation(':', "：");
			set_punctuation('<', "《");
			set_punctuation('>', "》");
			set_punctuation('\\', "、");
			set_punctuation('\'', "‘ ’");
			set_punctuation('\"', "“ ”");

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
