using IBus;

namespace icp {
	class IBusBinding {
		// for connection
		private static EngineDesc engine;
		private static Component component;
		private static Bus bus;
		private static Factory factory;

		class CloudPinyinEngine : Engine {
			private string preedit = "";
			private string full_preedit = "";

			// engine states
			private bool pinyin_enabled = true;

			// panel icons
			private Property chinese_mode_icon
				= new Property("mode", PropType.NORMAL, null,
						Config.global_data_path + "/icons/pinyin-enabled.png", null,
						true, true, PropState.INCONSISTENT, null);
			private Property status_icon 
				= new Property("status", PropType.NORMAL, null, 
						Config.global_data_path + "/icons/idle-0.png", null,
						true, true, PropState.INCONSISTENT, null);
			private PropList panel_prop_list = new PropList();
			private TimeoutSource waiting_animation_timer = null;

			// used by update_properties() and waiting_animation_timer callback func
			private bool last_pinyin_enabled = true;
			private int waiting_index = 0;
			private int waiting_index_acc = 1;

			private void start_waiting_animation() {
				waiting_animation_timer = new TimeoutSource(200);
				waiting_animation_timer.set_callback(() => {
						// update status icon
						waiting_index += waiting_index_acc;
						if (waiting_index == 3 || waiting_index == 0)
						waiting_index_acc = - waiting_index_acc;
						status_icon.set_icon("%s/icons/waiting-%d.png"
							.printf(Config.global_data_path, waiting_index));
						// update the whole panel
						update_properties();
						return true;
						});
				waiting_animation_timer.attach(icp.main_loop.get_context());
			}

			private void stop_waiting_animation() {
				if (!waiting_animation_timer.is_destroyed())
					waiting_animation_timer.destroy();
				waiting_animation_timer = null;
			}

			// workaround for no ctor
			private bool inited = false;

			private void init() {
				panel_prop_list.append(chinese_mode_icon);
				panel_prop_list.append(status_icon);
				update_properties();

				inited = true;
			}

			public override void reset() {
			}

			public override void enable() {
				enabled = true;
				if (!inited) init();
				update_properties();
			}

			public override void disable() {
				enabled = false;
				stdout.printf("called disable\n");
			}

			public override void focus_in() {
				has_focus = true;
				if (!inited) init();
				update_properties();
			}

			public override void focus_out() {
				has_focus = false;
			}

			public override void property_activate(string prop_name, uint prop_state) {
				switch (prop_name) {
					case "mode":
						pinyin_enabled = !pinyin_enabled;
						break;
					case "status":
						if (waiting_animation_timer == null)
							start_waiting_animation();
						else 
							stop_waiting_animation();
						break;
				}
				update_properties();
			}
	
			public override bool process_key_event(uint keyval, uint keycode, uint state) {
				// ignore release event
				return false;
			}

			public void update_properties() {
				if (!enabled) return;
				if (last_pinyin_enabled != pinyin_enabled) {
					chinese_mode_icon.set_icon("%s/icons/pinyin-%s.png"
							.printf(Config.global_data_path,
								pinyin_enabled ? "enabled" : "disabled"));
					last_pinyin_enabled = pinyin_enabled;
				}

				register_properties(panel_prop_list);
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

