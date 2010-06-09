using Gee;

namespace icp {
	namespace Pinyin {
		HashSet<string> valid_partial_pinyins;
		HashSet<string> valid_pinyins;

		HashMap<string, int> consonant_ids;
		HashMap<string, int> vowel_ids;
		
		class Id {
			public int consonant { get; private set; }
			public int vowel { get; private set; }
			public Id(string pinyin) {
				string vowel_str;
				if (pinyin.length > 1 && consonant_ids.contains(pinyin[0:2])) {
					consonant = consonant_ids[pinyin[0:2]];
					vowel_str = pinyin[2:pinyin.length];
				} else if (pinyin.length > 0 && consonant_ids.contains(pinyin[0:1])) {
					consonant = consonant_ids[pinyin[0:1]];
					vowel_str = pinyin[1:pinyin.length];
				} else {
					consonant = 0;
					vowel_str = pinyin;
				}
				if (vowel_ids.contains(vowel_str))
					vowel = vowel_ids[vowel_str];
				else vowel = -1;
			}			
		}

		class Sequence {
			private ArrayList<string> sequence;
			private ArrayList<Id> id_sequence;

			public Sequence(string pinyins) {
				// all characters not belonging to 'a'..'z' are seperators
				sequence = new ArrayList<string>();
				id_sequence = new ArrayList<Id>();

				string pinyins_pre;
				try {
					pinyins_pre = /__+/.replace(/[^a-z]/.replace(pinyins, -1, 0, "_"), -1, 0, "_");
				} catch (RegexError e) {
					pinyins_pre = "";
				}

				for (int pos = 0; pos < pinyins_pre.length;) {
					int len;
					for (len = 6; len > 0; len--) {
						if (pos + len <= pinyins_pre.length)
							if (pinyins_pre[pos:pos + len] in valid_partial_pinyins)
								break;
					}
					if (len == 0) {
						// invalid, skip it
						pos++;
					} else {
						sequence.add(pinyins_pre[pos:pos + len]);
						id_sequence.add(new Id(pinyins_pre[pos:pos + len]));
						pos += len;
					}
				}
			}

			public string to_string(int start = 0, int len = -1) {
				while (start < 0) start = start + sequence.size;
				while (len < 0) len = sequence.size;

				int end = start + len;
				if (end > sequence.size) end = sequence.size;

				var builder = new StringBuilder();
				for (int i = start; i < start + len; i++) {
					if (i > start) builder.append(" ");
					builder.append(sequence.get(i));
				}

				return builder.str;
			}

			public string get(int index) {
				if (index < 0 || index > sequence.size) return "";
				return sequence.get(index);
			}

			public Id get_id(int index) {
				if (index < 0 || index > sequence.size) return new Id("");
				return id_sequence.get(index);
			}

			public int size {
				get {
					return sequence.size;
				}
			}
		}

		class DoublePinyin {
			private HashMap<int, HashMap<int, string> > scheme;

			public DoublePinyin() {
				scheme = new HashMap<char, HashMap<char, string> >();
			}

			public void clear() {
				scheme.clear();
			}

			public void insert(int key1, int key2, string pinyin) {
				if (pinyin.size() == 0) return;
				if (!scheme.contains(key1)) scheme[key1] = new HashMap<int, string>();
				scheme[key1][key2] = pinyin;
			}

			public string query(int key1, int key2 = 0) {
				if (!scheme.contains(key1) || !scheme[key1].contains(key2)) return "";
				return scheme[key1][key2];
			}
		}

		static void init() {
			valid_pinyins = new HashSet<string>();
			valid_partial_pinyins = new HashSet<string>();

			// hardcoded valid pinyins
			valid_pinyins.add("ba");
			valid_pinyins.add("bo");
			valid_pinyins.add("bai");
			valid_pinyins.add("bei");
			valid_pinyins.add("bao");
			valid_pinyins.add("ban");
			valid_pinyins.add("ben");
			valid_pinyins.add("bang");
			valid_pinyins.add("beng");
			valid_pinyins.add("bi");
			valid_pinyins.add("bie");
			valid_pinyins.add("biao");
			valid_pinyins.add("bian");
			valid_pinyins.add("bin");
			valid_pinyins.add("bing");
			valid_pinyins.add("bu");
			valid_pinyins.add("ci");
			valid_pinyins.add("ca");
			valid_pinyins.add("ce");
			valid_pinyins.add("cai");
			valid_pinyins.add("cao");
			valid_pinyins.add("cou");
			valid_pinyins.add("can");
			valid_pinyins.add("cen");
			valid_pinyins.add("cang");
			valid_pinyins.add("ceng");
			valid_pinyins.add("cu");
			valid_pinyins.add("cuo");
			valid_pinyins.add("cui");
			valid_pinyins.add("cuan");
			valid_pinyins.add("cun");
			valid_pinyins.add("cong");
			valid_pinyins.add("chi");
			valid_pinyins.add("cha");
			valid_pinyins.add("che");
			valid_pinyins.add("chai");
			valid_pinyins.add("chao");
			valid_pinyins.add("chou");
			valid_pinyins.add("chan");
			valid_pinyins.add("chen");
			valid_pinyins.add("chang");
			valid_pinyins.add("cheng");
			valid_pinyins.add("chu");
			valid_pinyins.add("chuo");
			valid_pinyins.add("chuai");
			valid_pinyins.add("chui");
			valid_pinyins.add("chuan");
			valid_pinyins.add("chuang");
			valid_pinyins.add("chun");
			valid_pinyins.add("chong");
			valid_pinyins.add("da");
			valid_pinyins.add("de");
			valid_pinyins.add("dei");
			valid_pinyins.add("dai");
			valid_pinyins.add("dao");
			valid_pinyins.add("dou");
			valid_pinyins.add("dan");
			valid_pinyins.add("dang");
			valid_pinyins.add("deng");
			valid_pinyins.add("di");
			valid_pinyins.add("die");
			valid_pinyins.add("diao");
			valid_pinyins.add("diu");
			valid_pinyins.add("dian");
			valid_pinyins.add("ding");
			valid_pinyins.add("du");
			valid_pinyins.add("duo");
			valid_pinyins.add("dui");
			valid_pinyins.add("duan");
			valid_pinyins.add("dun");
			valid_pinyins.add("dong");
			valid_pinyins.add("fa");
			valid_pinyins.add("fo");
			valid_pinyins.add("fei");
			valid_pinyins.add("fou");
			valid_pinyins.add("fan");
			valid_pinyins.add("fen");
			valid_pinyins.add("fang");
			valid_pinyins.add("feng");
			valid_pinyins.add("fu");
			valid_pinyins.add("ga");
			valid_pinyins.add("ge");
			valid_pinyins.add("gai");
			valid_pinyins.add("gei");
			valid_pinyins.add("gao");
			valid_pinyins.add("gou");
			valid_pinyins.add("gan");
			valid_pinyins.add("gen");
			valid_pinyins.add("gang");
			valid_pinyins.add("geng");
			valid_pinyins.add("gu");
			valid_pinyins.add("gua");
			valid_pinyins.add("guo");
			valid_pinyins.add("guai");
			valid_pinyins.add("gui");
			valid_pinyins.add("guan");
			valid_pinyins.add("gun");
			valid_pinyins.add("guang");
			valid_pinyins.add("gong");
			valid_pinyins.add("ha");
			valid_pinyins.add("he");
			valid_pinyins.add("hai");
			valid_pinyins.add("hei");
			valid_pinyins.add("hao");
			valid_pinyins.add("hou");
			valid_pinyins.add("han");
			valid_pinyins.add("hen");
			valid_pinyins.add("hang");
			valid_pinyins.add("heng");
			valid_pinyins.add("hu");
			valid_pinyins.add("hua");
			valid_pinyins.add("huo");
			valid_pinyins.add("huai");
			valid_pinyins.add("hui");
			valid_pinyins.add("huan");
			valid_pinyins.add("hun");
			valid_pinyins.add("huang");
			valid_pinyins.add("hong");
			valid_pinyins.add("ji");
			valid_pinyins.add("jia");
			valid_pinyins.add("jie");
			valid_pinyins.add("jiao");
			valid_pinyins.add("jiu");
			valid_pinyins.add("jian");
			valid_pinyins.add("jin");
			valid_pinyins.add("jing");
			valid_pinyins.add("jiang");
			valid_pinyins.add("ju");
			valid_pinyins.add("jue");
			valid_pinyins.add("juan");
			valid_pinyins.add("jun");
			valid_pinyins.add("jiong");
			valid_pinyins.add("ka");
			valid_pinyins.add("ke");
			valid_pinyins.add("kai");
			valid_pinyins.add("kao");
			valid_pinyins.add("kou");
			valid_pinyins.add("kan");
			valid_pinyins.add("ken");
			valid_pinyins.add("kang");
			valid_pinyins.add("keng");
			valid_pinyins.add("ku");
			valid_pinyins.add("kua");
			valid_pinyins.add("kuo");
			valid_pinyins.add("kuai");
			valid_pinyins.add("kui");
			valid_pinyins.add("kuan");
			valid_pinyins.add("kun");
			valid_pinyins.add("kuang");
			valid_pinyins.add("kong");
			valid_pinyins.add("la");
			valid_pinyins.add("le");
			valid_pinyins.add("lai");
			valid_pinyins.add("lei");
			valid_pinyins.add("lao");
			valid_pinyins.add("lan");
			valid_pinyins.add("lang");
			valid_pinyins.add("leng");
			valid_pinyins.add("li");
			valid_pinyins.add("ji");
			valid_pinyins.add("lie");
			valid_pinyins.add("liao");
			valid_pinyins.add("liu");
			valid_pinyins.add("lian");
			valid_pinyins.add("lin");
			valid_pinyins.add("liang");
			valid_pinyins.add("ling");
			valid_pinyins.add("lou");
			valid_pinyins.add("lu");
			valid_pinyins.add("luo");
			valid_pinyins.add("luan");
			valid_pinyins.add("lun");
			valid_pinyins.add("long");
			valid_pinyins.add("lv");
			valid_pinyins.add("lue");
			valid_pinyins.add("ma");
			valid_pinyins.add("mo");
			valid_pinyins.add("me");
			valid_pinyins.add("mai");
			valid_pinyins.add("mei");
			valid_pinyins.add("mao");
			valid_pinyins.add("mou");
			valid_pinyins.add("man");
			valid_pinyins.add("men");
			valid_pinyins.add("mang");
			valid_pinyins.add("meng");
			valid_pinyins.add("mi");
			valid_pinyins.add("mie");
			valid_pinyins.add("miao");
			valid_pinyins.add("miu");
			valid_pinyins.add("mian");
			valid_pinyins.add("min");
			valid_pinyins.add("ming");
			valid_pinyins.add("mu");
			valid_pinyins.add("na");
			valid_pinyins.add("ne");
			valid_pinyins.add("nai");
			valid_pinyins.add("nei");
			valid_pinyins.add("nao");
			valid_pinyins.add("nou");
			valid_pinyins.add("nan");
			valid_pinyins.add("nen");
			valid_pinyins.add("nang");
			valid_pinyins.add("neng");
			valid_pinyins.add("ni");
			valid_pinyins.add("nie");
			valid_pinyins.add("niao");
			valid_pinyins.add("niu");
			valid_pinyins.add("nian");
			valid_pinyins.add("nin");
			valid_pinyins.add("niang");
			valid_pinyins.add("ning");
			valid_pinyins.add("nu");
			valid_pinyins.add("nuo");
			valid_pinyins.add("nuan");
			valid_pinyins.add("nong");
			valid_pinyins.add("nv");
			valid_pinyins.add("nue");
			valid_pinyins.add("pa");
			valid_pinyins.add("po");
			valid_pinyins.add("pai");
			valid_pinyins.add("pei");
			valid_pinyins.add("pao");
			valid_pinyins.add("pou");
			valid_pinyins.add("pan");
			valid_pinyins.add("pen");
			valid_pinyins.add("pang");
			valid_pinyins.add("peng");
			valid_pinyins.add("pi");
			valid_pinyins.add("pie");
			valid_pinyins.add("piao");
			valid_pinyins.add("pian");
			valid_pinyins.add("pin");
			valid_pinyins.add("ping");
			valid_pinyins.add("pu");
			valid_pinyins.add("qi");
			valid_pinyins.add("qia");
			valid_pinyins.add("qie");
			valid_pinyins.add("qiao");
			valid_pinyins.add("qiu");
			valid_pinyins.add("qian");
			valid_pinyins.add("qin");
			valid_pinyins.add("qiang");
			valid_pinyins.add("qing");
			valid_pinyins.add("qu");
			valid_pinyins.add("que");
			valid_pinyins.add("quan");
			valid_pinyins.add("qun");
			valid_pinyins.add("qiong");
			valid_pinyins.add("ri");
			valid_pinyins.add("re");
			valid_pinyins.add("rao");
			valid_pinyins.add("rou");
			valid_pinyins.add("ran");
			valid_pinyins.add("ren");
			valid_pinyins.add("rang");
			valid_pinyins.add("reng");
			valid_pinyins.add("ru");
			valid_pinyins.add("ruo");
			valid_pinyins.add("rui");
			valid_pinyins.add("ruan");
			valid_pinyins.add("run");
			valid_pinyins.add("rong");
			valid_pinyins.add("si");
			valid_pinyins.add("sa");
			valid_pinyins.add("se");
			valid_pinyins.add("sai");
			valid_pinyins.add("san");
			valid_pinyins.add("sao");
			valid_pinyins.add("sou");
			valid_pinyins.add("sen");
			valid_pinyins.add("sang");
			valid_pinyins.add("seng");
			valid_pinyins.add("su");
			valid_pinyins.add("suo");
			valid_pinyins.add("sui");
			valid_pinyins.add("suan");
			valid_pinyins.add("sun");
			valid_pinyins.add("song");
			valid_pinyins.add("shi");
			valid_pinyins.add("sha");
			valid_pinyins.add("she");
			valid_pinyins.add("shai");
			valid_pinyins.add("shei");
			valid_pinyins.add("shao");
			valid_pinyins.add("shou");
			valid_pinyins.add("shan");
			valid_pinyins.add("shen");
			valid_pinyins.add("shang");
			valid_pinyins.add("sheng");
			valid_pinyins.add("shu");
			valid_pinyins.add("shua");
			valid_pinyins.add("shuo");
			valid_pinyins.add("shuai");
			valid_pinyins.add("shui");
			valid_pinyins.add("shuan");
			valid_pinyins.add("shun");
			valid_pinyins.add("shuang");
			valid_pinyins.add("ta");
			valid_pinyins.add("te");
			valid_pinyins.add("tai");
			valid_pinyins.add("tao");
			valid_pinyins.add("tou");
			valid_pinyins.add("tan");
			valid_pinyins.add("tang");
			valid_pinyins.add("teng");
			valid_pinyins.add("ti");
			valid_pinyins.add("tie");
			valid_pinyins.add("tiao");
			valid_pinyins.add("tian");
			valid_pinyins.add("ting");
			valid_pinyins.add("tu");
			valid_pinyins.add("tuan");
			valid_pinyins.add("tuo");
			valid_pinyins.add("tui");
			valid_pinyins.add("tun");
			valid_pinyins.add("tong");
			valid_pinyins.add("wu");
			valid_pinyins.add("wa");
			valid_pinyins.add("wo");
			valid_pinyins.add("wai");
			valid_pinyins.add("wei");
			valid_pinyins.add("wan");
			valid_pinyins.add("wen");
			valid_pinyins.add("wang");
			valid_pinyins.add("weng");
			valid_pinyins.add("xi");
			valid_pinyins.add("xia");
			valid_pinyins.add("xie");
			valid_pinyins.add("xiao");
			valid_pinyins.add("xiu");
			valid_pinyins.add("xian");
			valid_pinyins.add("xin");
			valid_pinyins.add("xiang");
			valid_pinyins.add("xing");
			valid_pinyins.add("xu");
			valid_pinyins.add("xue");
			valid_pinyins.add("xuan");
			valid_pinyins.add("xun");
			valid_pinyins.add("xiong");
			valid_pinyins.add("yi");
			valid_pinyins.add("ya");
			valid_pinyins.add("yo");
			valid_pinyins.add("ye");
			valid_pinyins.add("yai");
			valid_pinyins.add("yao");
			valid_pinyins.add("you");
			valid_pinyins.add("yan");
			valid_pinyins.add("yin");
			valid_pinyins.add("yang");
			valid_pinyins.add("ying");
			valid_pinyins.add("yu");
			valid_pinyins.add("yue");
			valid_pinyins.add("yuan");
			valid_pinyins.add("yun");
			valid_pinyins.add("yong");
			valid_pinyins.add("yu");
			valid_pinyins.add("yue");
			valid_pinyins.add("yuan");
			valid_pinyins.add("yun");
			valid_pinyins.add("yong");
			valid_pinyins.add("zi");
			valid_pinyins.add("za");
			valid_pinyins.add("ze");
			valid_pinyins.add("zai");
			valid_pinyins.add("zao");
			valid_pinyins.add("zei");
			valid_pinyins.add("zou");
			valid_pinyins.add("zan");
			valid_pinyins.add("zen");
			valid_pinyins.add("zang");
			valid_pinyins.add("zeng");
			valid_pinyins.add("zu");
			valid_pinyins.add("zuo");
			valid_pinyins.add("zui");
			valid_pinyins.add("zun");
			valid_pinyins.add("zuan");
			valid_pinyins.add("zong");
			valid_pinyins.add("zhi");
			valid_pinyins.add("zha");
			valid_pinyins.add("zhe");
			valid_pinyins.add("zhai");
			valid_pinyins.add("zhao");
			valid_pinyins.add("zhou");
			valid_pinyins.add("zhan");
			valid_pinyins.add("zhen");
			valid_pinyins.add("zhang");
			valid_pinyins.add("zheng");
			valid_pinyins.add("zhu");
			valid_pinyins.add("zhua");
			valid_pinyins.add("zhuo");
			valid_pinyins.add("zhuai");
			valid_pinyins.add("zhuang");
			valid_pinyins.add("zhui");
			valid_pinyins.add("zhuan");
			valid_pinyins.add("zhun");
			valid_pinyins.add("zhong");

			valid_pinyins.add("a");
			valid_pinyins.add("e");
			valid_pinyins.add("ei");
			valid_pinyins.add("ai");
			valid_pinyins.add("ei");
			valid_pinyins.add("ao");
			valid_pinyins.add("o");
			valid_pinyins.add("ou");
			valid_pinyins.add("an");
			valid_pinyins.add("en");
			valid_pinyins.add("ang");
			valid_pinyins.add("eng");
			valid_pinyins.add("er");

			// calculate valid_partial_pinyins
			foreach (string s in valid_pinyins) {
				for (int i = 1; i <= s.length; i++) {
					valid_partial_pinyins.add(s[0:i]);
				}
			}

			consonant_ids = new HashMap<string, int>();
			vowel_ids = new HashMap<string, int>();

			consonant_ids["b"] = 1;
			consonant_ids["c"] = 2;
			consonant_ids["ch"] = 3;
			consonant_ids["d"] = 4;
			consonant_ids["f"] = 5;
			consonant_ids["g"] = 6;
			consonant_ids["h"] = 7;
			consonant_ids["j"] = 8;
			consonant_ids["k"] = 9;
			consonant_ids["l"] = 10;
			consonant_ids["m"] = 11;
			consonant_ids["n"] = 12;
			consonant_ids["p"] = 13;
			consonant_ids["q"] = 14;
			consonant_ids["r"] = 15;
			consonant_ids["s"] = 16;
			consonant_ids["sh"] = 17;
			consonant_ids["t"] = 18;
			consonant_ids["w"] = 19;
			consonant_ids["x"] = 20;
			consonant_ids["y"] = 21;
			consonant_ids["z"] = 22;
			consonant_ids["zh"] = 23;

			vowel_ids["a"] = 24;
			vowel_ids["ai"] = 25;
			vowel_ids["an"] = 26;
			vowel_ids["ang"] = 27;
			vowel_ids["ao"] = 28;
			vowel_ids["e"] = 29;
			vowel_ids["ei"] = 30;
			vowel_ids["en"] = 31;
			vowel_ids["eng"] = 32;
			vowel_ids["er"] = 33;
			vowel_ids["i"] = 34;
			vowel_ids["ia"] = 35;
			vowel_ids["ian"] = 36;
			vowel_ids["iang"] = 37;
			vowel_ids["iao"] = 38;
			vowel_ids["ie"] = 39;
			vowel_ids["in"] = 40;
			vowel_ids["ing"] = 41;
			vowel_ids["iong"] = 42;
			vowel_ids["iu"] = 43;
			vowel_ids["o"] = 44;
			vowel_ids["ong"] = 45;
			vowel_ids["ou"] = 46;
			vowel_ids["u"] = 47;
			vowel_ids["ua"] = 48;
			vowel_ids["uai"] = 49;
			vowel_ids["uan"] = 50;
			vowel_ids["uang"] = 51;
			vowel_ids["ue"] = 52;
			vowel_ids["ve"] = 52;
			vowel_ids["ui"] = 53;
			vowel_ids["un"] = 54;
			vowel_ids["uo"] = 55;
			vowel_ids["v"] = 56;
		}
	}
}

