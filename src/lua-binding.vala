using Lua;

namespace icp {
	class LuaBinding {
		private static LuaVM vm;
		private static ThreadPool thread_pool;
		private static Posix.pid_t main_pid;

		private LuaBinding() {
			// this class is used as namespace
		}

		private static int l_get_selection(LuaVM vm) {
			// refuse to do anything in non-main process
			// for example, a requesting thread
			// it should only return string, no operation to ime
			if (Posix.getpid() != main_pid) return 0;

			// lock is no more needed because only one thread per process
			// use this lua vm.
			// lock(vm_lock) {
			vm.check_stack(1);
			vm.push_string(icp.Frontend.get_selection());
			return 1;
			// }
		}

		private static int l_notify(LuaVM vm) {
			if (Posix.getpid() != main_pid) return 0;
			if (vm.is_string(1)) {
				string title = vm.to_string(1);
				string content = "", icon = "";
				if (vm.is_string(2)) content = vm.to_string(2);
				if (vm.is_string(3)) icon = vm.to_string(3);
				icp.Frontend.notify(title, content, icon);
			}
			// IMPROVE: use lua_error to report error
			return 0;
		}

		private static int l_set_response(LuaVM vm) {
			if (Posix.getpid() != main_pid) return 0;
			if (vm.is_string(1) && vm.is_string(2)) {
				string pinyins = vm.to_string(1);
				string content = vm.to_string(2);
				int priority = 127;
				if (vm.is_number(3)) priority = vm.to_integer(3);
				icp.Pinyin.UserDatabase.response(pinyins, content, priority);
			}
			return 0;
		}

		private static int l_action(LuaVM vm) {
			if (Posix.getpid() != main_pid) return 0;
			return 0;
		}

		private static int l_set_enable(LuaVM vm) {
			if (Posix.getpid() != main_pid) return 0;
			return 0;
		}

		private static int l_set_timeout(LuaVM vm) {
			if (Posix.getpid() != main_pid) return 0;
			return 0;
		}

		private static int l_set_limit(LuaVM vm) {
			if (Posix.getpid() != main_pid) return 0;
			return 0;
		}

		private static int l_set_double_pinyin(LuaVM vm) {
			if (Posix.getpid() != main_pid) return 0;
			return 0;
		}

		private static int l_register_key(LuaVM vm) {
			if (Posix.getpid() != main_pid) return 0;
			return 0;
		}

		private static int l_register_engine(LuaVM vm) {
			if (Posix.getpid() != main_pid) return 0;
			return 0;
		}

		private static int l_get_status(LuaVM vm) {
			if (Posix.getpid() != main_pid) return 0;
			return 0;
		}

		private static int l_go_background(LuaVM vm) {
			// fork, do nothing if already in background 
			if (Posix.getpid() != main_pid) return 0;

			Posix.pid_t pid;
			pid = Posix.fork();
			if (pid == 0) {
				// child continue to execute lua script
			} else {
				// emit an known error to stop execute lua script
				vm.check_stack(1);
				vm.push_string("fork_stop");
				vm.error();
			}
			return 0;
		}


		public static void init() {
			vm = new LuaVM();
			vm.open_libs();

			vm.register("go_background", l_go_background);

			vm.register("notify", l_notify);
			vm.register("set_response", l_set_response);

			vm.register("get_selection", l_get_selection);
			vm.register("action", l_action);
			vm.register("get_status", l_get_status);

			// vm.register("set_mode", l_set_mode); // in 1, bool
			// vm.register("set_color", l_set_color);

			vm.register("set_timeout", l_set_timeout);
			/*
in : a table
set_timeout:
prerequest = 0.3
request = 
correction = 
			 */
			vm.register("set_double_pinyin", l_set_double_pinyin);
			// vm.register("enable_double_pinyin", l_enable_double_pinyin);

			vm.register("set_limit", l_set_limit);
			/*
			   concurrency_request
			   database_candidates
			 */
			vm.register("register_key", l_register_key);

			// only make these engines async
			vm.register("register_engine", l_register_engine);
			// vm.register("set_filter", l_set_filter);
			vm.register("set_enable", l_set_enable);
			/*
			   double_pinyin = true
			   background_request = true
			   apply_filter = true
			   chinese_mode = true
			 */

			try {
				thread_pool = new ThreadPool(do_string_internal, 1, true);
			} catch (ThreadError e) {
				stderr.printf("LuaBinding cannot create thread pool: %s\n", e.message);
			}

			main_pid = Posix.getpid();
		}

		private static void do_string_internal(void * pscript) {
			// do not execute other script if being forked
			// prevent executing them two times
			if (Posix.getpid() != main_pid) return;

			string script = "%s".printf((string)pscript);
			vm.load_string(script);
			if (vm.pcall(0, 0, 0) != 0) {
				string error_message = vm.to_string(-1);
				if (error_message != "fork_stop")
					Frontend.notify("Lua Error", error_message, "error");
				vm.pop(1);
			}
		}

		public static void do_string(string script) {
			// do all things in thread pool
			try {
				thread_pool.push((void*)script);
			} catch (ThreadError e) {
				stderr.printf("LuaBinding fails to launch thread from thread pool: %s\n", e.message);
			}
		}

		public static void load_configuration() {
			do_string("dofile('%s')".printf(Config.startup_script));
		}
	}
}
