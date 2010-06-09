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
			// TODO: dump xml
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

		//Thread.usleep(10000);

		/* Frontend.notify("hello", "world", "info");
		var p = new Pinyin.Sequence("womenkdln我们amehaohan gede");
		stdout.printf("[%s] %d\n", p.to_string(1, 3), p.size);

		xArrayList<string> candidates = new ArrayList<string>();
		candidates.add("hello");
		Pinyin.Database.query(new Pinyin.Sequence("chunmianbujuexiao"), candidates, 10);

		foreach (var i in candidates) {
			stdout.printf("cand: %s\n", i);
		} */

		//stdout.printf("[%s]\n", Pinyin.Database.greedy_convert(new Pinyin.Sequence("wojuedewozhishiyigeren")));
		/*int a = -2, b = -2;
		pinyin.database.get_pinyin_ids("w", out a, out b);
		stdout.printf("%d %d\n", a, b);
		pinyin.database.get_pinyin_ids("zhuang", out a, out b);
		stdout.printf("%d %d\n", a, b);
		pinyin.database.get_pinyin_ids("", out a, out b);
		stdout.printf("%d %d\n", a, b);
		pinyin.database.get_pinyin_ids("v", out a, out b);
		stdout.printf("%d %d\n", a, b);
		pinyin.database.get_pinyin_ids("zh", out a, out b);
		stdout.printf("%d %d\n", a, b);
		pinyin.database.get_pinyin_ids("ang", out a, out b);
		stdout.printf("%d %d\n", a, b);*/

		// load startup lua script (it will turn into background by calling execute_in_background())
		// threads are terrible in vala s...

		try {
			Thread.create(LuaBinding.load_configuration_thread, false);
		} catch (ThreadError e) {
			stderr.printf("can not create configuration loading thread: %s\n", e.message);
		}
		// LuaBinding.load_configuration_thread();

		new MainLoop (null, false).run();
		
		return 0;
	}
}

