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
 *  along with ibus-cloud-pinyin.  If not, see <http://www.gnu.org/licenses/>.
 *****************************************************************************/

using Lua;

namespace icp {
  class LuaBinding {
    private static LuaVM vm;
    private static ThreadPool thread_pool;
    private static Posix.pid_t main_pid;
    private static Gee.LinkedList<string> script_pool;

    // only in_configuration = true, can some settings be done.
    // this provides extended thread safty.
    // main glib loop will be delayed ~0.1s. in this time, global
    // configuration should make all settings done...
    // i hate locks ...
    private static bool in_configuration;

    private LuaBinding() {
      // this class is used as namespace
    }

    private static bool check_permissions(bool should_in_configuration = true) {
      if (Posix.getpid() != main_pid) {
        stderr.printf("LUA-WARNING: IME native functions are disabled after go_background().\n");
        return false;
      }

      if (should_in_configuration && !in_configuration) {
        Frontend.notify("No permission", 
            "Configurations must be done in startup script.", 
            "stop"
            );
        return false;
      }
      return true;
    }

    private static int l_get_selection(LuaVM vm) {
      // refuse to do anything in non-main process
      // for example, a requesting thread
      // it should only return string, no operation to ime
      if (!check_permissions(false)) return 0;

      // lock is no more needed because only one thread per process
      // use this lua vm. however this thread is not main glib loop
      // lock(vm_lock) {
      vm.check_stack(1);
      vm.push_string(icp.Frontend.get_selection());
      return 1;
      // }
    }

    private static int l_notify(LuaVM vm) {
      if (!check_permissions(false)) return 0;
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
      if (!check_permissions()) return 0;
      if (vm.is_string(1) && vm.is_string(2)) {
        string pinyins = vm.to_string(1);
        string content = vm.to_string(2);
        int priority = 127;
        if (vm.is_number(3)) priority = vm.to_integer(3);
        icp.Pinyin.UserDatabase.response(pinyins, content, priority);
      }
      return 0;
    }

    private static int l_set_color(LuaVM vm) {
      if (!check_permissions()) return 0;
      if (!vm.is_table(1)) return 0;

      vm.check_stack(2);
      for (vm.push_nil(); vm.next(1) != 0; vm.pop(1)) {
        // format: 'name' = '[fgcolor],[bgcolor],[1/0]'
        if (!vm.is_string(-1) || !vm.is_string(-2)) continue;

        string k = vm.to_string(-2);
        string v = vm.to_string(-1);

        int i = 0;
        bool underlined = false;
        int? foreground = null;
        int? background = null;

        foreach (string s in v.split(",")) {
          int t = -1;
          s.scanf("%x", &t);
          switch (i) {
            case 0:
              if (t != -1) foreground = t;
              break;
            case 1:
              if (t != -1) background = t;
              break;
            case 2:
              underlined = (t > 0);
              break;
          }
          i++;
        }

        switch(k) {
          case "buffer_raw":
            Config.Colors.buffer_raw
            = new Config.Colors.Color(foreground, background, underlined);
          break;
          case "buffer_pinyin":
            Config.Colors.buffer_pinyin
            = new Config.Colors.Color(foreground, background, underlined);
          break;
          case "candidate_local":
            Config.Colors.candidate_local
            = new Config.Colors.Color(foreground, background, underlined);
          break;
          case "candidate_remote":
            Config.Colors.candidate_remote
            = new Config.Colors.Color(foreground, background, underlined);
          break;
          case "preedit_correcting":
            Config.Colors.preedit_correcting
            = new Config.Colors.Color(foreground, background, underlined);
          break;            
          case "preedit_local":
            Config.Colors.preedit_local
            = new Config.Colors.Color(foreground, background, underlined);
          break;
          case "preedit_remote":
            Config.Colors.preedit_remote
            = new Config.Colors.Color(foreground, background, underlined);
          break;
          case "preedit_fixed":
            Config.Colors.preedit_fixed
            = new Config.Colors.Color(foreground, background, underlined);
          break;
        }
      }

      return 0;
    }

    private static int l_set_switch(LuaVM vm) {
      if (!check_permissions(false)) return 0;
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
      if (!check_permissions(false)) return 0;
      if (!vm.is_table(1)) return 0;

      vm.check_stack(2);
      // traverse that table (at pos 1)
      for (vm.push_nil(); vm.next(1) != 0; vm.pop(1)) {
        if (!vm.is_number(-1) || !vm.is_string(-2)) continue;

        string k = vm.to_string(-2);
        double v = vm.to_number(-1);
        double* bind_value = null;

        switch(k) {
          case "request":
            bind_value = &Config.Timeouts.request;
          break;
          case "prerequest":
            bind_value = &Config.Timeouts.prerequest;
          break;
          case "selection":
            bind_value = &Config.Timeouts.selection;
          break;
        }
        *bind_value = v;
      }

      return 0;
    }

    private static int l_set_limit(LuaVM vm) {
      if (!check_permissions(false)) return 0;
      if (!vm.is_table(1)) return 0;

      vm.check_stack(2);
      // traverse that table (at pos 1)
      for (vm.push_nil(); vm.next(1) != 0; vm.pop(1)) {
        if (!vm.is_number(-1) || !vm.is_string(-2)) continue;

        string k = vm.to_string(-2);
        int v = vm.to_integer(-1);
        int* bind_value = null;

        switch(k) {
          case "database_query_limit":
            bind_value = &Config.Limits.database_query_limit;
          break;
        }
        *bind_value = v;
      }

      return 0;
    }

    private static int l_set_double_pinyin(LuaVM vm) {
      if (!check_permissions()) return 0;
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
        if (double_pinyin.length > 2) continue;
        Pinyin.DoublePinyin.insert(double_pinyin, full_pinyin);
      }
      assert(vm.get_top() == vm_top);

      return 0;
    }

    private static int l_set_key(LuaVM vm) {
      if (!check_permissions()) return 0;

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
      if (!check_permissions()) return 0;
      // accept two strings, only one unichar per label
      if (!vm.is_string(1)) return 0;

      string labels = vm.to_string(1);
      string alternative_labels = labels;
      if (vm.is_string(2)) alternative_labels = vm.to_string(2);

      Config.CandidateLabels.clear();
      for (int i = 0; i < labels.length; i++) {
        Config.CandidateLabels.add (labels[i:i+1],
            (i < alternative_labels.length) ? alternative_labels[i:i+1] : null
            );
      }
      return 0;
    }

    private static int l_register_engine(LuaVM vm) {
      if (!check_permissions()) return 0;
      // TODO: register request engine at Config...
      return 0;
    }

    private static int l_go_background(LuaVM vm) {
      // fork, do nothing if already in background 
      if (!check_permissions(false)) return 0;

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
      in_configuration = false;
      script_pool = new Gee.LinkedList<string>();

      vm = new LuaVM();
      vm.open_libs();

      vm.register("go_background", l_go_background);
      vm.register("notify", l_notify);
      vm.register("get_selection", l_get_selection);
      
      vm.register("set_response", l_set_response);
      vm.register("set_double_pinyin", l_set_double_pinyin);
      vm.register("set_key", l_set_key);
      vm.register("set_candidate_labels", l_set_candidate_labels);

      vm.register("set_switch", l_set_switch);
      vm.register("set_timeout", l_set_timeout);
      vm.register("set_limit", l_set_limit);
      vm.register("set_color", l_set_color);

      // these engines' requests will be async (in sep process)
      vm.register("register_engine", l_register_engine);

      try {
        thread_pool = new ThreadPool(do_string_internal, 1, true);
      } catch (ThreadError e) {
        stderr.printf("LuaBinding cannot create thread pool: %s\n", 
            e.message
            );
      }

      main_pid = Posix.getpid();
    }

    private static void do_string_internal(void* data) {
      if (Posix.getpid() != main_pid) return;

      // do not execute other script if being forked
      // prevent executing them two times
      string script = (string)data;

      switch(script) {
        case ".stop_conf":
          in_configuration = false;
        break;
        default:
        vm.load_string(script);
        if (vm.pcall(0, 0, 0) != 0) {
          string error_message = vm.to_string(-1);
          if (error_message != "fork_stop")
            Frontend.notify("Lua Error", error_message, "error");
          vm.pop(1);
        }
        break;
      }
    }

    public static void do_string(string script) {
      // do all things in thread pool
      try {
        // attention: script may be unavailabe after pushed into thread_pool
        // thread_pool.push((void*)script);

        // do some cleanning when possible
        if (thread_pool.unprocessed() == 0) script_pool.clear();

        // push script into script_pool to keep it safe
        script_pool.add(script);
        thread_pool.push((void*)script_pool.last());
      } catch (ThreadError e) {
        stderr.printf(
            "LuaBinding fails to launch thread from thread pool: %s\n",
            e.message);
      }
    }

    public static void load_configuration() {
      in_configuration = true;
      do_string("dofile('%s')".printf(
            Config.CommandlineOptions.startup_script)
          );
      do_string(".stop_conf");
    }
  }
}

/* vim:set et sts=2 tabstop=2 shiftwidth=2: */
