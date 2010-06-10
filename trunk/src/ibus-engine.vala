using IBus;

namespace icp {
	class IBusBinding {
		// for connection
		private static EngineDesc engine;
		private static Component component;
		private static Bus bus;
		private static Factory factory;

		class CloudPinyinEngine : Engine {
			private string preedit;
			private string full_preedit;
			
			

			// override process_key_event to handle key events
			public override bool process_key_event (uint keyval, uint keycode, uint state) {
				// ignore release event
				return false;
			}

			// update preedit text
			private new void update_preedit_text() {
			}

			// update lookup table
			private new void update_lookup_table () {
			}

			// update auxiliary text
			private new void update_auxiliary_text () {
			}
		}

		public static void init() {
			component = new Component (
					"org.freedesktop.IBus.cloudpinyin",
					"Cloud Pinyin", Config.version, "GPL",
					"WU Jun <quark@lihdd.net>",
					"http://code.google.com/p/ibus-cloud-pinyin/",
					Config.global_data_path + "/engine/ibus-cloud-pinyin --ibus",
					"ibus-cloud-pinyin");
			engine = new EngineDesc ("cloud-pinyin",
					"Cloud Pinyin",
					"A client of cloud pinyin IME on ibus",
					"zh_CN",
					"GPL",
					"WU Jun <quark@lihdd.net>",
					Config.global_data_path + "/icons/ibus-cloud-pinyin.png",
					"us");
			component.add_engine (engine);
		}

		public static string get_component_xml() {
			StringBuilder builder = new StringBuilder();
			builder.append("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n");
			component.output(builder, 4);
			return builder.str;
		}

		public static void register() {
			bus = new Bus();
			if (Config.launched_by_ibus) 
				bus.request_name("org.freedesktop.IBus.cloudpinyin", 0);
			else
				bus.register_component (component);

			factory = new Factory(bus.get_connection());
			factory.add_engine("cloud-pinyin", typeof(CloudPinyinEngine));
		}
	}
}

