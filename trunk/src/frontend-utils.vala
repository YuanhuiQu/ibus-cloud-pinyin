namespace icp {
	class Frontend {
		private static string? _selection;
		private static unowned Gtk.Clipboard clipboard;
		
		private Frontend() {
			// this class is used as namespace
		}

		public static string get_selection() {
			return _selection ?? "";
		}
		
		public static uint64 clipboard_update_time {
			get; private set;
		}

		public static void notify(string title, string? content = null, string? icon = null) {
			Notify.Notification notification
				= new Notify.Notification(title, content, icon, null);
			try {
				notification.show();
			} catch (Error e) {
				stdout.printf("Notification: %s %s %s\n", title, content, icon);
				// then, just ignore
				;
			}
		}

		public static uint64 get_current_time() {
			TimeVal tv = GLib.TimeVal();
			tv.get_current_time();
			return tv.tv_usec + (uint64)tv.tv_sec * 1000000;
		}

		public static void init() {
			// assume gtk and gdk are inited
			if (Notify.is_initted()) return;
			Notify.init("ibus-cloud-pinyin");
			clipboard = Gtk.Clipboard.get_for_display(
				Gdk.Display.get_default(),
				Gdk.SELECTION_PRIMARY);
			clipboard.owner_change.connect(
				() => {
					lock(_selection) {
						_selection = clipboard.wait_for_text();
						clipboard_update_time = get_current_time();
					}
				}
			);
		}

	}
}

