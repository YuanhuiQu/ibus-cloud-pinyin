namespace icp {
	class Config {
		private static const string version = "0.1.0";
		private static const string global_data_path = "/usr/share/ibus-cloud-pinyin";
		public static string? startup_script = null;
		public static bool show_version;
		public static bool launched_by_ibus;
		public static bool show_xml;

		private Config() { }

		public static void init(string[] args) {
			OptionEntry entrie_script = { "script", 'c', 0, OptionArg.FILENAME, out startup_script, "specify a startup script", "filename" };
			OptionEntry entrie_version = { "version", 'i', 0, OptionArg.NONE, out show_version, "show version information", null };
			OptionEntry entrie_ibus = { "ibus", 'b', 0, OptionArg.NONE, out launched_by_ibus, "run by ibus", null };
			OptionEntry entrie_xml = { "dump-xml", 'x', 0, OptionArg.NONE, out show_xml, "print ibus engine description xml", null };
			OptionEntry entrie_null = { null };

			Error error;
			OptionContext context = new OptionContext("- cloud pinyin client for ibus");
			context.add_main_entries({entrie_script, entrie_version, entrie_ibus, entrie_xml, entrie_null}, null);

			try {
				context.parse(ref args);
			} catch (OptionError e) {
				stderr.printf("option parsing failed: %s\n", e.message);
			}

			if (startup_script == null) startup_script = global_data_path + "/config.lua";
		}
	}
}
