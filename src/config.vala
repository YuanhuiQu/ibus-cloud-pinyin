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

using Gee;

namespace icp {
  class Config {
    // project constants
    public static const string version = "0.8.0-alpha";
    public static const string 
      global_data_path = "/usr/share/ibus-cloud-pinyin";

    // command line options
    [Compact]
      public class CommandlineOptions {
        public CommandlineOptions() { assert_not_reached(); }

        public static string? startup_script = null;
        public static bool show_version;
        public static bool launched_by_ibus;
        public static bool do_not_connect_ibus;
        public static bool show_xml;
      }

    // timeouts
    [Compact]
      public class Timeouts {
        public Timeouts() { assert_not_reached(); }

        public static int request = 10000;
        public static int prerequest = 1000;
      }

    // limits
    [Compact]
      public class Limits {
        public Limits() { assert_not_reached(); }

        public static int database_query_limit = 128;
      }

    // enables
    [Compact]
      public class Switches {
        public Switches() { assert_not_reached(); }

        public static bool double_pinyin = false;
        public static bool background_request = true;
        public static bool always_show_candidates = false;
        public static bool show_pinyin_auxiliary = true;
        public static bool show_raw_in_auxiliary = false;

        public static bool default_offline_mode = false;
        public static bool default_chinese_mode = true;
        public static bool default_traditional_mode = false;
      }

    // punctuations
    public class Punctuations {
      private Punctuations() { }

      public class FullPunctuation {
        private ArrayList<string> full_chars;
        public bool only_after_chinese { get; private set; }
        private int index;

        public FullPunctuation(string full_chars, 
            bool only_after_chinese = false) {
          this.full_chars = new ArrayList<string>();
          foreach (string s in full_chars.split(" "))
            this.full_chars.add(s);
          this.only_after_chinese = only_after_chinese;
          index = 0;
        }

        public string get_full_char() {
          string r = full_chars[index];
          if (++index == full_chars.size) index = 0;
          return r;
        }
      }

      private static HashMap<int, FullPunctuation> punctuations;

      public static void init() {
        punctuations = new HashMap<int, FullPunctuation>();
        set('.', "。", true);
        set(',', "，", true);
        set('^', "……");
        set('@', "·");
        set('!', "！");
        set('~', "～");
        set('?', "？");
        set('#', "＃");
        set('$', "￥");
        set('&', "＆");
        set('(', "（");
        set(')', "）");
        set('{', "｛");
        set('}', "｝");
        set('[', "［");
        set(']', "］");
        set(';', "；");
        set(':', "：");
        set('<', "《");
        set('>', "》");
        set('\\', "、");
        set('\'', "‘ ’");
        set('\"', "“ ”");
      }

      public static void set(int half_char, string full_chars, 
          bool only_after_chinese = false) {
        if (full_chars.length == 0) punctuations.remove(half_char);
        else punctuations[half_char] = new FullPunctuation(full_chars, 
            only_after_chinese
            );
      }

      public static string get(int key, bool after_chinese = true) {
        if (!punctuations.contains(key) 
            || (punctuations[key].only_after_chinese 
              && !after_chinese)
           ) return "%c".printf(key);
        return punctuations[key].get_full_char();
      }

      public static bool exists(int key) {
        return punctuations.contains(key);
      }
    }

    // key
    public class Key {
      public uint key { get; private set; }
      public uint state { get; private set; }
      public string label { get; private set; }
      public Key(uint key, uint state = 0, string? label = null) {
        this.key = key;
        this.state = state;
        if (label == null) this.label = "%c".printf((int)key);
        else this.label = label;
      }
      public static uint hash_func(Key a) {
        return a.key | a.state;
      }
      public static bool equal_func(Key a, Key b) {
        return a.key == b.key && a.state == b.state;
      }
    }

    // key actions
    public class KeyActions {
      private KeyActions() { }

      private static HashMap<Key, string> key_actions;

      public static void init() {
        key_actions = new HashMap<Key, string>
          ((HashFunc) Key.hash_func, (EqualFunc) Key.equal_func);      
        set(new Key(IBus.Tab), "correct");
        set(new Key(IBus.BackSpace), "back");
        set(new Key(IBus.space), "sep commit");
        set(new Key(IBus.Escape), "clear");
        set(new Key(IBus.Page_Down), "pgdn");
        set(new Key((uint)'h'), "pgdn");
        set(new Key((uint)']'), "pgdn");
        set(new Key((uint)'='), "pgdn");
        set(new Key(IBus.Page_Up), "pgup");
        set(new Key((uint)'g'), "pgup");
        set(new Key((uint)'['), "pgup");
        set(new Key((uint)'-'), "pgup");
        set(new Key((uint)'\''), "sep");
        set(new Key((uint)'P',
              IBus.ModifierType.RELEASE_MASK | IBus.ModifierType.CONTROL_MASK 
              | IBus.ModifierType.SHIFT_MASK), "offline online");
        set(new Key(IBus.Shift_L, 
              IBus.ModifierType.RELEASE_MASK | IBus.ModifierType.SHIFT_MASK),
            "eng chs"
           );
        set(new Key(IBus.Shift_R, 
              IBus.ModifierType.RELEASE_MASK | IBus.ModifierType.SHIFT_MASK),
            "trad simp"
           );
        set(new Key(IBus.Return), "raw");

        string labels = "jkl;asdf";
        for (int i = 0; i < labels.length; i++) {
          set(new Key(labels[i]), "cand:%d".printf(i));
          set(new Key(i + '1'), "cand:%d".printf(i));
        }
      }

      public static void set(Key key, string action) {
        if (action.length == 0) key_actions.remove(key);
        else key_actions[key] = action;
      }

      public static string get(Key key) {
        if (!key_actions.contains(key)) return "";
        return key_actions[key];
      }
    }

    // lookup table labels
    public class CandidateLabels {
      private CandidateLabels() { }

      private static ArrayList<ArrayList<string> > labels;

      public static void clear() {
        labels[0].clear();
        labels[1].clear();
      }

      public static void add(string label, string? label_alternative = null) {
        labels[0].add(label);
        labels[1].add(label_alternative ?? label);
      }

      public static void set(int index, string? label = null,
          string? label_alternative = null) {
        if (index < 0 || index >= size) return;        
        if (label != null)
          labels[0].set(index, label);
        if (label_alternative != null) 
          labels[1].set(index, label_alternative);
      }

      public static string get(int index, bool use_alternative = false) {
        if (index < 0 || index >= size) return "";
        return labels[use_alternative ? 1 : 0].get(index);
      }

      public static int size {
        get {
          assert(labels[0].size == labels[1].size);
          return labels[0].size;
        }
      }

      public static void init() {
        labels = new ArrayList<ArrayList<string> >();
        labels.add(new ArrayList<string>());
        labels.add(new ArrayList<string>());

        string labels = "jkl;asdf";
        for (int i = 0; i < labels.length; i++) {
          add(labels[i:i+1], "%d".printf(i + 1));
        }
      }
    }

    // init
    public static void init(string[] args) {
      KeyActions.init();
      CandidateLabels.init();
      Punctuations.init();

      // command line options
      // workaround for vala 0.8.0 and 0.9.0 not allowing nested
      // struct assignments
      OptionEntry entrie_script = { "script", 'c', 0, OptionArg.FILENAME, 
        out CommandlineOptions.startup_script, "specify a startup script",
        "filename" };
      OptionEntry entrie_version = { "version", 'i', 0, OptionArg.NONE,
        out CommandlineOptions.show_version, "show version information", 
        null };
      OptionEntry entrie_ibus = { "ibus", 'b', 0, OptionArg.NONE,
        out CommandlineOptions.launched_by_ibus, "run by ibus", null };
      OptionEntry entrie_no_ibus = { "no-ibus", 'n', 0, OptionArg.NONE,
        out CommandlineOptions.do_not_connect_ibus,
        "do not register at ibus, use this if ibus-daemon is not running",
        null };
      OptionEntry entrie_xml = { "dump-xml", 'x', 0, OptionArg.NONE,
        out CommandlineOptions.show_xml, "print ibus engine description xml", 
        null };
      OptionEntry entrie_null = { null };

      OptionContext context =
        new OptionContext("- cloud pinyin client for ibus");

      context.add_main_entries({entrie_script, entrie_version, entrie_ibus,
          entrie_no_ibus, entrie_xml, entrie_null}, null);

      try {
        context.parse(ref args);
      } catch (OptionError e) {
        stderr.printf("option parsing failed: %s\n", e.message);
      }

      if (CommandlineOptions.startup_script == null)
        CommandlineOptions.startup_script = global_data_path + "/config.lua";
    }

    // this class is used as namespace
    private Config() { }
  }
}

/* vim:set et sts=2 tabstop=2 shiftwidth=2: */
