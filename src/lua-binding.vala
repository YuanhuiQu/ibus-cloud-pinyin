/******************************************************************************
 *  ibus-cloud-pinyin - cloud pinyin client for ibus
 *  Copyright (C) 2010 WU Jun <quark@lihdd.net>
 *
 * 
 *  This file is part of ibus-cloud-pinyin.
 *
 *  ibus-cloud-pinyin is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  ibus-cloud-pinyin is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with ibus-cloud-pinyin.  If not, see <http: *www.gnu.org/licenses/>.
 *****************************************************************************/

using Lua;

namespace icp {
  class LuaBinding {
    private static LuaVM vm;
    private static ThreadPool thread_pool;
    private static Posix.pid_t main_pid;
    private static Gee.LinkedList<LuaTrunk> script_pool;

    // since lua binding run one thread per process, keep current_engine
    // static of this class in do_string() to track matched engine ....
    private static IBusBinding.CloudPinyinEngine* current_engine;

    class LuaTrunk {
      public string script;
      public IBusBinding.CloudPinyinEngine* engine;

      public LuaTrunk(string script, IBusBinding.CloudPinyinEngine* engine) {
        this.script = script;
        this.engine = engine;
      }
    }

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
      // check engine available
      return 0;
    }

    private static int l_set_switch(LuaVM vm) {
      if (Posix.getpid() != main_pid) return 0;
      if (!vm.is_table(1)) return 0;

      vm.check_stack(2);
      // traverse that table (at pos 1)
      for (vm.push_nil(); vm.next(1) != 0; vm.pop(1)) {
        if (!vm.is_boolean(-1) || !vm.is_string(-2)) continue;

        string k = vm.to_string(-2);
        bool v = vm.to_boolean(-1);
        bool* bind_value = null;

        switch(k) {
          case "double_pinyin":
            bind_value = &Config.Switches.double_pinyin;
          break;
          case "background_request":
            bind_value = &Config.Switches.background_request;
          break;
          case "always_show_candidates":
            bind_value = &Config.Switches.always_show_candidates;
          break;
          case "show_pinyin_auxiliary":
            bind_value = &Config.Switches.show_pinyin_auxiliary;
          break;
          case "show_raw_in_auxiliary":
            bind_value = &Config.Switches.show_raw_in_auxiliary;
          break;            
          case "offline_mode_auto_commit":
            bind_value = &Config.Switches.offline_mode_auto_commit;
          break;
          case "default_offline_mode":
            bind_value = &Config.Switches.default_offline_mode;
          break;
          case "default_chinese_mode":
            bind_value = &Config.Switches.default_chinese_mode;
          break;
          case "default_traditional_mode":
            bind_value = &Config.Switches.default_traditional_mode;
          break;
        }
        *bind_value = v;
      }

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
      Pinyin.DoublePinyin.clear();

      if (!vm.is_table(1)) return 0;

      int vm_top = vm.get_top();
      vm.check_stack(2);
      // traverse that table (at pos 1)
      for (vm.push_nil(); vm.next(1) != 0; vm.pop(1)) {
        // key is at index -2 and value is at index -1
        if (!vm.is_string(-1) || !vm.is_string(-2)) continue;

        string double_pinyin = vm.to_string(-2);
        string full_pinyin = vm.to_string(-1);
        if (double_pinyin.length != 2) continue;
        Pinyin.DoublePinyin.insert(
            (int)double_pinyin[0], (int)double_pinyin[1], full_pinyin
            );
      }
      assert(vm.get_top() == vm_top);

      return 0;
    }

    private static int l_set_key(LuaVM vm) {
      if (Posix.getpid() != main_pid) return 0;

      if (vm.get_top() < 3 || (!vm.is_string(1) && !vm.is_number(1))
          || !vm.is_string(3) || !vm.is_number(2)) return 0;

      uint key_value = 0;
      if (vm.is_string(1)) {
        string s = vm.to_string(1);
        if (s.length > 0) key_value = (uint)s[0];
      } else key_value = (uint)vm.to_number(1);

      Config.Key key = new Config.Key(key_value, (uint)vm.to_number(2));
      Config.KeyActions.set(key, vm.to_string(3));
      return 0;
    }

    private static int l_set_candidate_labels(LuaVM vm) {
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
      script_pool = new Gee.LinkedList<LuaTrunk>();

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
      vm.register("set_candidate_labels", l_set_candidate_labels);
      // vm.register("enable_double_pinyin", l_enable_double_pinyin);

      vm.register("set_limit", l_set_limit);
      /*
         concurrency_request
         database_candidates
       */
      vm.register("set_key", l_set_key);

      // only make these engines async
      vm.register("register_engine", l_register_engine);
      // vm.register("set_filter", l_set_filter);
      vm.register("set_switch", l_set_switch);
      /*
         double_pinyin = true
         background_request = true
         apply_filter = true
         chinese_mode = true
       */

      try {
        thread_pool = new ThreadPool(do_string_internal, 1, true);
      } catch (ThreadError e) {
        stderr.printf("LuaBinding cannot create thread pool: %s\n", 
          e.message
          );
      }

      main_pid = Posix.getpid();
    }

    private static void do_string_internal(void* ptrunk) {
      // do not execute other script if being forked
      // prevent executing them two times
      LuaTrunk* trunk = (LuaTrunk*)ptrunk;
      current_engine = trunk->engine;
      if (Posix.getpid() != main_pid) return;

      vm.load_string(trunk->script);
      if (vm.pcall(0, 0, 0) != 0) {
        string error_message = vm.to_string(-1);
        if (error_message != "fork_stop")
          Frontend.notify("Lua Error", error_message, "error");
        vm.pop(1);
      }
    }

    public static void
      do_string(string script,
          IBusBinding.CloudPinyinEngine* pengine = null
          ) {
        // do all things in thread pool
        try {
          // attention: script may be unavailabe after pushed into thread_pool
          // thread_pool.push((void*)script);

          // do some cleanning when possible
          if (thread_pool.unprocessed() == 0) script_pool.clear();

          // push script into script_pool to keep it safe
          script_pool.add(new LuaTrunk(script, pengine));
          thread_pool.push((void*)script_pool.last());
        } catch (ThreadError e) {
          stderr.printf(
              "LuaBinding fails to launch thread from thread pool: %s\n",
              e.message);
        }
      }

    public static void load_configuration() {
      do_string("dofile('%s')".printf(Config.startup_script));
    }
  }
}

/* vim:set et sts=2 tabstop=2 shiftwidth=2: */
