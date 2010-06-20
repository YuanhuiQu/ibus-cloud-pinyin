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
      = ModifierType.SHIFT_MASK | ModifierType.LOCK_MASK
      | ModifierType.CONTROL_MASK | ModifierType.MOD1_MASK
      | ModifierType.MOD4_MASK | ModifierType.MOD5_MASK
      | ModifierType.SUPER_MASK | ModifierType.RELEASE_MASK
      | ModifierType.META_MASK;

    public class CloudPinyinEngine : Engine {
      private string raw_buffer = "";
      private Pinyin.Sequence pinyin_buffer;
      private string pinyin_buffer_preedit;

      // engine states
      private bool chinese_mode;
      private bool correction_mode = false;
      private bool offline_mode;
      private bool traditional_mode;
      private bool last_is_chinese = true;

      // external request list
      class Request {
        public double deadline;

        // multi engines share this 'done'
        public bool done;
      }

      // pending segments
      class PendingSegment {
        public bool need_request;
        public string content;
        public Pinyin.Sequence pinyins;
        public double start_time;
      }

      LinkedList<Request> request_list;
      LinkedList<PendingSegment> pending_segment_listst;

      // only one prerequest per engine allowed
      bool prerequest_done;

      // lookup table and candidates
      LookupTable table;
      ArrayList<string> candidates;
      bool table_visible;
      uint page_index;

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
      // they should be static vars in func,
      // however Vala does not seems to support static vars
      // at the time I write these code ...
      private bool last_chinese_mode = true;
      private bool last_traditional_mode = false;
      private bool last_offline_mode = false;

      // idle animation start and stop
      private int waiting_index = 0;
      private int waiting_index_acc = 1;

      private void start_requesting() {
        if (waiting_animation_timer != null) return;
        waiting_animation_timer = new TimeoutSource(64);
        waiting_animation_timer.set_callback(() => {
            // send another prerequest if current one is done
            if (prerequest_done) {
            send_prerequest();
            update_preedit();
            }
            // update status icon
            // TODO: use idle icon when possible
            if (request_list.size == 0 && prerequest_done) {
            status_icon.set_icon("%s/icons/idle-%d.png"
              .printf(Config.global_data_path, 
              LuaBinding.get_engine_speed_rank())
              );
            } else {
            waiting_index += waiting_index_acc;
            if (waiting_index == (3 * 4 - 1) || waiting_index == 0)
            waiting_index_acc = - waiting_index_acc;
            status_icon.set_icon("%s/icons/waiting-%d.png"
              .printf(Config.global_data_path, waiting_index / 3));
            }
            // update the whole panel
            update_properties();
            // stop if offline mode
            if (offline_mode) stop_requesting();
            return true;
        });
        waiting_animation_timer.attach(icp.main_loop.get_context());
      }

      private void stop_requesting() {
        // TODO: force convert all pending
        if (waiting_animation_timer == null) return;
        if (!waiting_animation_timer.is_destroyed())
          waiting_animation_timer.destroy();
        waiting_animation_timer = null;
      }

      // init, workaround for no ctor
      private bool inited = false;

      private void init() {
        // strings, booleans
        raw_buffer = "";
        last_pinyin_buffer_string = "";
        pinyin_buffer = new Pinyin.Sequence(raw_buffer);
        table_visible = false;

        // switches
        chinese_mode = Config.Switches.default_chinese_mode;
        traditional_mode = Config.Switches.default_traditional_mode;
        offline_mode = Config.Switches.default_offline_mode;
        if (LuaBinding.get_engine_count() == 0) offline_mode = true;
        correction_mode = false;

        // load properties into property list
        panel_prop_list.append(chinese_mode_icon);
        panel_prop_list.append(traditional_conversion_icon);
        panel_prop_list.append(status_icon);
        waiting_animation_timer = null;
        update_properties();

        // lookup table, insert enough dummy labels first
        page_index = 0;
        table = new LookupTable(Config.CandidateLabels.size, 0, false, false);
        candidates = new ArrayList<string>();
        for (int i = 0; i < Config.CandidateLabels.size; i++) {
          table.append_label(new Text.from_string("."));
        }

        // user phrase
        user_pinyins = new ArrayList<Pinyin.Id>();
        user_phrase = "";
        user_phrase_count = 0;

        // request list and pending segment list
        request_list = new LinkedList<Request>();
        pending_segment_listst = new LinkedList<PendingSegment>();
        prerequest_done = true;

        // TODO: dlopen opencc ...
        inited = true;
      }

      private void send_prerequest() {
        if (offline_mode || !prerequest_done) return;
        // scan to a complete pinyin
        int i = pinyin_buffer.size - 1;
        for (; i >= 0 && pinyin_buffer.get_id(i).vowel <= 0; i--);
        if (i <= 0) return;

        string pinyins = pinyin_buffer.to_string(0, i + 1);
        if (DBusBinding.query(pinyins) == "") {

          prerequest_done = false;
          LuaBinding.start_requests(
              pinyins,
              Config.Timeouts.prerequest,
              &prerequest_done
              );
          start_requesting();
        }
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
        update_preedit();
        // force update candidates
        last_pinyin_buffer_string = ".";
        update_candidates();
      }

      public override void focus_out() {
        has_focus = false;
        print("focus out\n");
      }

      public override void property_activate(string prop_name, 
          uint prop_state) {
        switch (prop_name) {
          case "mode":
            chinese_mode = !chinese_mode;
          break;
          case "trad":
            traditional_mode = !traditional_mode;
          break;
          case "status":
            switch_offline_mode();
          break;
        }
        update_properties();
      }

      private void commit(string content) {
        // TODO: check previous commit,
        //       force convert previous if no background allowed
        if (content.length > 0) {
          commit_text(new Text.from_string(content));
        }
        if (content.size() < 2) user_phrase_clear();
      }

      private void switch_offline_mode() {
        offline_mode = !offline_mode;
        if (!offline_mode) {
          if (LuaBinding.get_engine_count() == 0) {
            Frontend.notify(
                "在线模式",
                "无法切换到在线模式\n没有注册过云请求脚本", 
                "error"
                );
            offline_mode = true;
          } else {
            send_prerequest();
          }
        }
      }

      private void commit_buffer() {
        // TODO: use mixed greedy convert if cloud client impled.
        // TODO: send request here
        if (pinyin_buffer.size > 0) {
          commit(pinyin_buffer_preedit);
          last_is_chinese = true;
        }
        raw_buffer = "";
        pinyin_buffer.clear();
        user_phrase_clear();
      }

      // process key event, most important func in engine
      private uint last_state = 0;
      public override bool process_key_event(uint keyval, uint keycode, 
          uint state) {
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

        string action;
        // prevent trigger unwanted hotkeys
        if (((state & ModifierType.RELEASE_MASK) != 0)
            && ((last_state & ModifierType.RELEASE_MASK) != 0))
          action = "";
        else action = Config.KeyActions.get(
            new Config.Key(keyval, state)
            );
        last_state = state;

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
          foreach (string v in action.split(" ")) actions.add(v);

          // consider mode switch action first
          if ((chinese_mode == false && ("chs" in actions))
              || (chinese_mode == true && ("eng" in actions))) {
            // TODO: do something here
            chinese_mode = !chinese_mode;
            if (chinese_mode) last_is_chinese = true;
            handled = true; break;
          }

          if ((traditional_mode && ("simp" in actions))
              || (!traditional_mode && ("trad" in actions))) {
            traditional_mode = !traditional_mode;
            handled = true; break;
          }

          if ((offline_mode && ("online" in actions))
              || (!offline_mode && ("offline" in actions))) {
            switch_offline_mode();
            handled = true; break;
          }

          // then in chinese mode, consider edit / commit things
          // edit raw pinyin buffer (disabled in correction mode)
          // "sep", "back", "clear" here should has state = 0
          if (!correction_mode && chinese_mode) {
            // enter correction mode ?
            if ("correct" in actions) {
              if (raw_buffer.length > 0) {
                if (pinyin_buffer.size > 0) {
                  correction_mode = true;
                  handled = true; break;
                }
              } else {
                // user select some thing, currently buffer is empty,
                // test if it can be reverse converted to pinyin

                // TODO: check no pending requests
                if (Frontend.get_current_time()
                    <= (uint64)(1000000 * Config.Timeouts.selection)
                    + Frontend.clipboard_update_time) {
                  string selection = Frontend.get_selection();
                  if (!selection.contains("\n")
                      && Database.reverse_convert(
                        selection, out pinyin_buffer)) {
                    // reverse convert successful
                    // erase client text
                    commit_text(new Text.from_string(""));
                    correction_mode = true;
                    // rebuild raw_buffer
                    if (Config.Switches.double_pinyin) {
                      raw_buffer = pinyin_buffer.to_double_pinyin_string();
                    } else {
                      raw_buffer = pinyin_buffer.to_string();
                    }
                    handled = true; break;
                  } else {
                    // convert fail, clean buffers
                    pinyin_buffer = new Pinyin.Sequence();
                  }
                }
              }
            }

            if ("clear" in actions) {
              raw_buffer = "";
              pinyin_buffer.clear();
              handled = true; break;
            }

            bool is_backspace = (("back" in actions) 
                && raw_buffer.length > 0
                );
            // check normal pinyin chars
            if (Config.Switches.double_pinyin) {
              // note that ';' can not occur at the beginning
              if ((Pinyin.DoublePinyin.is_valid_key(keyval)
                    && state == 0 && ('z' >= keyval >= 'a'
                      || raw_buffer.length > 0)) || is_backspace) {
                if (is_backspace) raw_buffer = raw_buffer[0:-1];
                else raw_buffer += "%c".printf((int)keyval);
                Pinyin.DoublePinyin.convert(raw_buffer, out pinyin_buffer);
                handled = true; break;
              }
            } else {
              if (('z' >= keyval >= 'a'
                    && state == 0) || is_backspace) {
                if (is_backspace) raw_buffer = raw_buffer[0:-1];
                else raw_buffer += "%c".printf((int)keyval);
                pinyin_buffer = new Pinyin.Sequence(raw_buffer);
                handled = true; break;
              }
              if (("sep" in actions) && raw_buffer.length > 0 
                  && (uint)raw_buffer[raw_buffer.length - 1] != keyval) {
                raw_buffer += "%c".printf((int)keyval);
                handled = true; break;
              }
            }

            // chinese puncs
            if (((state ^ IBus.ModifierType.SHIFT_MASK)
                  == 0 || state == 0)
                && 128 > keyval >= 32 
                && Config.Punctuations.exists((int)keyval)) {

              if (pinyin_buffer.size > 0) last_is_chinese = true;
              string punc = Config.Punctuations.get(
                  (int)keyval, last_is_chinese
                  );
              commit_buffer();
              last_is_chinese = (punc.size() > 2);
              user_phrase_clear();
              commit(punc);
              handled = true; break;
            }
          }

          // raw commit
          if (("raw" in actions)
              && raw_buffer.length > 0) {
            commit(raw_buffer);
            raw_buffer = "";
            pinyin_buffer.clear();
            last_is_chinese = true;
            handled = true; break;
          }

          // commit buffer hotkey
          if (("commit" in actions)
              && pinyin_buffer.size > 0) {
            commit_buffer();
            handled = true; break;
          }

          // lookup table pgup, pgdn, candidate select
          if (table_visible /*&& (correction_mode
                              || !Config.Punctuations.exists((int)keyval) )*/) {
            if ("pgup" in actions) { page_up(); handled = true;}
            if ("pgdn" in actions) { page_down(); handled = true;}
            if (handled) {
              update_lookup_table(table, true);
              break;
            }

            foreach (string s in actions) {
              if (s.has_prefix("cand:")) {
                uint index = 0;
                s.scanf("cand:%u", &index);
                // check if that candidate exists
                if (table.get_number_of_candidates() 
                    > table.get_page_size() * page_index + index) {
                  candidate_clicked(index, 128, 0);
                  handled = true;
                }
                break;
              }
            }
            if (handled) break;
          }

          // non-chinese puncs
          if (((state ^ IBus.ModifierType.SHIFT_MASK)
                == 0 || state == 0)
              && 128 > keyval >= 32) {
            commit_buffer();

            string punc = "%c".printf((int)keyval);
            last_is_chinese = false;
            commit(punc);
            handled = true; break;
          }
        } while (false);

        if (handled) {
          send_prerequest();
          update_preedit();
          update_properties();
          update_candidates();
        }

        return handled;
      }

      private override void page_up() {
        if (table_visible && table.page_up()) {
          update_lookup_table(table, true);
          page_index --;
        }
      }

      private override void page_down() {
        if (table_visible && table.page_down()) {
          update_lookup_table(table, true);
          page_index ++;
        }
      }

      // used to insert to user database
      private ArrayList<Pinyin.Id> user_pinyins;
      private string user_phrase;
      private int user_phrase_count;

      private void user_phrase_clear() {
        user_phrase = "";
        user_phrase_count = 0;
        user_pinyins.clear();
      }

      private override void candidate_clicked (uint index, uint button,
          uint state) {

        index += table.get_page_size() * page_index;
        Text candidate = table.get_candidate(index);
        string content = candidate.text;
        int len = (int)content.length;
        commit(content);

        // append to user dict, insert to user dict
        user_phrase += content;
        for (int i = 0; i < content.length; i++)
          user_pinyins.add(pinyin_buffer.get_id(i));

        Pinyin.Sequence pinyins = new Pinyin.Sequence.ids(user_pinyins);
        Database.insert(user_phrase, pinyins);

        // also update cloud cache with priority = 128
        DBusBinding.set_response(pinyins.to_string(), user_phrase, 128);

        if (user_phrase_count++ > 4) user_phrase_clear();

        // remove heading pinyins (rebuild buffer)
        if (Config.Switches.double_pinyin) {
          raw_buffer = pinyin_buffer.to_double_pinyin_string(len);
          Pinyin.DoublePinyin.convert(raw_buffer, 
              out pinyin_buffer);
        } else {
          raw_buffer = pinyin_buffer.to_string(len);
          pinyin_buffer = new Pinyin.Sequence(raw_buffer);
        }

        if (button != 128) {
          update_preedit();
          update_candidates();
        }
      }

      private void update_preedit() {
        // auxiliary text
        if (pinyin_buffer.size == 0 
            || (!Config.Switches.show_pinyin_auxiliary 
              && !Config.Switches.show_raw_in_auxiliary
              )) {
          hide_auxiliary_text();
        } else {
          string pinyin_buffer_aux 
            = Config.Switches.show_pinyin_auxiliary 
            ? pinyin_buffer.to_string() : "";
          string raw_buffer_aux
            = Config.Switches.show_raw_in_auxiliary 
            ? " [%s]".printf(raw_buffer) : "";

          var text = new Text.from_string(
              "%s%s".printf(pinyin_buffer_aux, raw_buffer_aux)
              );
          Config.Colors.buffer_pinyin.apply(
              text, 0, (int)pinyin_buffer_aux.length
              );
          Config.Colors.buffer_raw.apply(
              text, (uint)pinyin_buffer_aux.length, 
              (int)(pinyin_buffer_aux.length + raw_buffer_aux.length)
              );
          update_auxiliary_text(text, true);          
        }
        // preedit
        // TODO: show request queue
        // TODO: use mixed greedy convert and their color
        //     if cloud client impled.
        {
          int cloud_length;
          string preedit = DBusBinding.convert(
              pinyin_buffer, 
              out cloud_length
              );
          pinyin_buffer_preedit = preedit;

          var text = new Text.from_string(preedit);

          if (correction_mode)
            Config.Colors.preedit_correcting.apply(text);
          else {
            // remote result
            Config.Colors.preedit_remote.apply(text, 0, cloud_length);
            // local database
            Config.Colors.preedit_local.apply(text, cloud_length);
          }

          // apply underline
          text.append_attribute(AttrType.UNDERLINE, 
              AttrUnderline.SINGLE, 0,
              (int)text.get_length()
              );

          update_preedit_text(text,
              correction_mode ? 0 : (int)text.get_length(), true
              );
        }
      }

      private string last_pinyin_buffer_string;
      private bool last_correction_mode = false;
      private void update_candidates() {
        // update candidates according to pinyin_buffer
        if (pinyin_buffer.size > 0 && 
            (Config.Switches.always_show_candidates || correction_mode)) {
          if (last_pinyin_buffer_string != pinyin_buffer.to_string()
              || last_correction_mode != correction_mode) {
            // should update lookup table
            // TODO: append results from userdb
            candidates.clear();
            table.clear();
            page_index = 0;
            Database.query(pinyin_buffer, candidates, 
                Config.Limits.global_db_query_limit
                );

            // update lookup table labels
            for (int i = 0; i < Config.CandidateLabels.size; i++) {
              table.set_label((uint)i, new Text.from_string(
                    Config.CandidateLabels.get(i,
                      (Config.Switches.always_show_candidates 
                       && !correction_mode)))
                  );
            }

            // update candidates
            foreach (string s in candidates) {
              var text = new Text.from_string(s);
              Config.Colors.candidate_local.apply(text);
              table.append_candidate(text);
            }

            table_visible = (candidates.size > 0);
            update_lookup_table(table, table_visible);
            last_pinyin_buffer_string = pinyin_buffer.to_string();
            last_correction_mode = correction_mode;
          }
        } else {
          table_visible = false;
          hide_lookup_table();
          // if nothing to correct, exit correct mode.
          if (pinyin_buffer.size == 0) correction_mode = false;
          last_pinyin_buffer_string = "";
        }
      }

      private void update_properties() {
        if (!enabled) return;
        if (last_chinese_mode != chinese_mode) {
          chinese_mode_icon.set_icon("%s/icons/pinyin-%s.png"
              .printf(Config.global_data_path,
                chinese_mode ? "enabled" : "disabled"));
          last_chinese_mode = chinese_mode;
        }
        if (last_traditional_mode != traditional_mode) {
          traditional_conversion_icon.set_icon(
              "%s/icons/traditional-%s.png"
              .printf(Config.global_data_path,
                traditional_mode ?
                "enabled" : "disabled")
              );
          last_traditional_mode = traditional_mode;
        }
        if (last_offline_mode != offline_mode) {
          if (offline_mode) stop_requesting();
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
          Config.prefix_path
          + "/lib/ibus/ibus-engine-cloud-pinyin --ibus",
          "ibus-cloud-pinyin");
      engine = new EngineDesc ("cloud-pinyin",
          "Cloud Pinyin",
          "A client of cloud pinyin IME on ibus",
          "zh_CN",
          "GPL",
          "WU Jun <quark@lihdd.net>",
          Config.global_data_path
          + "/icons/ibus-cloud-pinyin.png",
          "us");
      component.add_engine (engine);
    }

    public static string get_component_xml() {
      StringBuilder builder = new StringBuilder();
      builder.append(
          "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
          );
      component.output(builder, 4);
      return builder.str;
    }

    public static void register() {
      bus = new Bus();
      if (Config.CommandlineOptions.launched_by_ibus) 
        bus.request_name("org.freedesktop.IBus.cloudpinyin", 0);
      else
        bus.register_component (component);

      factory = new Factory(bus.get_connection());
      factory.add_engine("cloud-pinyin",
          typeof(CloudPinyinEngine)
          );
    }
  }
}

/* vim:set et sts=2 tabstop=2 shiftwidth=2: */
