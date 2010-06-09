using icp;
using Gee;

public class Main {
	public static int main (string[] args) {
		Gdk.threads_init();

		Gdk.init(ref args);
		Gtk.init(ref args);

		Config.init(args);
		
		if (Config.show_version) {
			stdout.printf("ibus-cloud-pinyin %s [built with ibus %d.%d.%d]\nCopyright (c) 2010 WU Jun <quark@lihdd.net>\n",
				Config.version, IBus.MAJOR_VERSION, IBus.MINOR_VERSION, IBus.MICRO_VERSION);
			return 0;
		}

		if (Config.show_xml) {
			IBusBinding.init();
			stdout.printf("%s", IBusBinding.get_component_xml());			
			return 0;
		}

		Pinyin.init();
		Pinyin.Database.init();
		Pinyin.UserDatabase.init();
		LuaBinding.init();
		Frontend.init();
		DBusBinding.init();
		IBusBinding.init();
		IBusBinding.register();

		LuaBinding.load_configuration();  // run in seperated thread

		new MainLoop (null, false).run();
		
		return 0;
	}
}
