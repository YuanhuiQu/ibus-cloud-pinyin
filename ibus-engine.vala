using IBus;

namespace icp {
	class IBusBinding {
		private static EngineDesc engine;
		private static Component component;
		private static Bus bus;
		private static Factory factory;

		class CloudPinyinEngine : Engine {
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
			bus = new Bus();
			factory = new Factory(bus.get_connection());
			factory.add_engine("vala-debug", typeof(CloudPinyinEngine));
			component = new Component (
					"org.freedesktop.IBus.Vala",
					"ValaTest", "0.0.1", "GPL",
					"Peng Huang <shawn.p.huang@gmail.com>",
					"http://code.google.com/p/ibus/",
					"",
					"ibus-vala");
			engine = new EngineDesc ("vala-debug",
					"Vala (debug)",
					"Vala demo input method",
					"zh_CN",
					"GPL",
					"Peng Huang <shawn.p.huang@gmail.com>",
					"",
					"us");
			component.add_engine (engine);
			bus.register_component (component);
		}
	}
}

