using IBus;
using Gee;

namespace icp {

	class IBusBinding {
		// for connection
		private static EngineDesc engine;
		private static Component component;
		private static Bus bus;
		private static Factory factory;

		// constants
		public static const uint key_state_filter
			= ModifierType.SHIFT_MASK | ModifierType.LOCK_MASK | ModifierType.CONTROL_MASK 
			| ModifierType.MOD1_MASK | ModifierType.MOD4_MASK | ModifierType.MOD5_MASK
			| ModifierType.SUPER_MASK | ModifierType.RELEASE_MASK | ModifierType.META_MASK;

		// active engines
		/*
		   public static HashSet<CloudPinyinEngine*> active_engines;

		   protected static void set_active(CloudPinyinEngine* pengine, bool actived = true) {
		   lock (active_engines) {
		   if (actived)
		   active_engines.add(pengine);
		   else
		// it is ok to remove an non-existed item
		active_engines.remove(pengine);
		}
		}
		 */

		public class CloudPinyinEngine : Engine {
			private string raw_buffer = "";
			private Pinyin.Sequence pinyin_buffer;

			// engine states
			private bool chinese_mode = true;
			private bool correction_mode = false;
			private bool offline_mode = false;
			private bool traditional_mode = false;

			// panel icons
			private Property chinese_mode_icon
				= new Property("mode", PropType.NORMAL, null,
						Config.global_data_path + "/icons/pinyin-enabled.png", 
						new Text.from_string("切换中文/英文模式"),
						true, true, PropState.INCONSISTENT, null);
			private Property traditional_conversion_icon
				= new Property("trad", PropType.NORMAL, null,
						Config.global_data_path + "/icons/traditional-disabled.png", 
						new Text.from_string("切换简体/繁体模式"),
						false, true, PropState.INCONSISTENT, null);
			private Property status_icon 
				= new Property("status", PropType.NORMAL, null, 
						Config.global_data_path + "/icons/idle-0.png",
						new Text.from_string("切换在线/离线模式"),
						true, true, PropState.INCONSISTENT, null);
			private PropList panel_prop_list = new PropList();
			private TimeoutSource waiting_animation_timer = null;

			// used by update_properties() and waiting_animation_timer callback func
			// they should be static vars in func, however Vala does not seems to support
			// static vars at the time I write these code ...
			private bool last_chinese_mode = true;
			private bool last_traditional_mode = false;
			private bool last_offline_mode = false;
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
				panel_prop_list.append(traditional_conversion_icon);
				panel_prop_list.append(status_icon);
				update_properties();

				// TODO: dlopen opencv ...
				inited = true;
			}

			public override void reset() {

			}

			public override void enable() {
				enabled = true;
				if (!inited) init();
				update_properties();
				// set_active(this);
			}

			public override void disable() {
				enabled = false;
				stdout.printf("called disable\n");
				// set_active(this, false);
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
						chinese_mode = !chinese_mode;
					break;
					case "trad":
						traditional_mode = !traditional_mode;
					break;
					case "status":
						offline_mode = !offline_mode;
					break;
				}
				update_properties();
			}

			public override bool process_key_event(uint keyval, uint keycode, uint state) {
				/*
				   keys handle precedence
				   chinese mode:
				   backspace / escape(stop all pending, call reset?)
				   pinyin input (include ';' in some double pinyin scheme)
				   (' ' in full pinyin (seperator))
				   candidates (page up, page down, select)
				   submit (punc, enter, mode switch)

				   english mode:
				   backspace / escape
				   submit directly
				 */
				bool handled = false;
				state = state & key_state_filter;

				string action = Config.get_key_action(
						new Config.Key(keyval, state)
						);

				do {
					// this loop is dummy onlyto enable 'break' for flow control
					if (action.has_prefix("lua:")) {
						// it is a lua script, execute in background
						LuaBinding.do_string(action[4:action.length]);
						handled = true;
						break;
					}

					// otherwise user may specify multi actions seperated by space
					// collect them into a set
					HashSet<string> actions = new HashSet<string>();
					foreach (string v in action.split(" ")) {
						actions.add(v);
					}

					if (chinese_mode) {
						// edit raw pinyin buffer (disabled in correction mode)
						if (state == 0 && !handled && !correction_mode) {
							if ("clear" in actions) {
								raw_buffer = "";
								pinyin_buffer.clear();
								handled = true;
								break;
							}

							bool is_backspace = (("backspace" in actions) && raw_buffer.length > 0);
							if (Config.double_pinyin_enabled) {
								if (Pinyin.DoublePinyin.is_valid_key(keyval) || is_backspace) {
									if (is_backspace) raw_buffer = raw_buffer[0:-1];
									else raw_buffer += "%c".printf((int)keyval);
									Pinyin.DoublePinyin.convert(raw_buffer, out pinyin_buffer);
									handled = true;
									break;
								}
							} else {
								if ('z' >= keyval >= 'a' || is_backspace) {
									if (is_backspace) raw_buffer = raw_buffer[0:-1];
									else raw_buffer += "%c".printf((int)keyval);
									pinyin_buffer = new Pinyin.Sequence(raw_buffer);
									handled = true;
									break;
								}
							}
						}
					}
				} while (false);

				if (handled) update_preedit();

				return handled;
			}

			public void update_preedit() {
				// auxiliary text
				if (pinyin_buffer.size == 0 || !Config.show_pinyin_auxiliary_enabled) {
					hide_auxiliary_text();
				} else {
					var text = new Text.from_string(pinyin_buffer.to_string());
					update_auxiliary_text(text, true);					
				}
				// preedit
				{
					var text = new Text.from_string(
							Pinyin.Database.greedy_convert(pinyin_buffer)
							);
					text.append_attribute(AttrType.UNDERLINE, 
							AttrUnderline.SINGLE, 0, (int)text.get_length()
							);
					update_preedit_text(text, (int)text.get_length(), true);
				}

			}

			public void update_properties() {
				if (!enabled) return;
				if (last_chinese_mode != chinese_mode) {
					chinese_mode_icon.set_icon("%s/icons/pinyin-%s.png"
							.printf(Config.global_data_path,
								chinese_mode ? "enabled" : "disabled"));
					last_chinese_mode = chinese_mode;
				}
				if (last_traditional_mode != traditional_mode) {
					traditional_conversion_icon.set_icon("%s/icons/traditional-%s.png"
							.printf(Config.global_data_path,
								traditional_mode ? "enabled" : "disabled"));
					last_traditional_mode = traditional_mode;
				}
				if (last_offline_mode != offline_mode) {
					status_icon.set_icon("%s/icons/%s.png"
							.printf(Config.global_data_path,
								offline_mode ? "offline" : "idle-4"));
					last_offline_mode = offline_mode;
					// TODO: update status info using data
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

