--[[----------------------------------------------------------------------------
 ibus-cloud-pinyin - cloud pinyin client for ibus
 Configuration Script

 Copyright (C) 2010 WU Jun <quark@lihdd.net>

 This file is part of ibus-cloud-pinyin.

 ibus-cloud-pinyin is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 ibus-cloud-pinyin is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with ibus-cloud-pinyin.  If not, see <http://www.gnu.org/licenses/>.
--]]----------------------------------------------------------------------------

socket, http, url = require 'socket', require 'socket.http', require 'socket.url'

-- constants
keys = {
	backspace = 0xff08,
	tab = 0xff09,
	enter = 0xff0d,
	escape = 0xff1b,
	delete = 0xffff,
	page_up = 0xff55,
	page_down = 0xff56,
	shift_left = 0xffe1,
	shift_right = 0xffe2,
	ctrl_left = 0xffe3,
	ctrl_right = 0xffe4,
	alt_left = 0xffe9,
	alt_right = 0xffea,
	super_left = 0xffeb,
	super_right = 0xffec,
	space = 0x020,
}

masks = {
	shift = 1,
	lock = 2,
	control = 4,
	mod1 = 8,
	mod4 = 64,
	super = 67108864,
	meta = 268435456,
	release  = 1073741824,
}

-- MSPY double pinyin scheme
set_double_pinyin{
['ca'] = 'ca', ['cb'] = 'cou', ['ce'] = 'ce', ['cg'] = 'ceng', ['cf'] = 'cen', ['ci'] = 'ci', ['ch'] = 'cang', ['ck'] = 'cao', ['cj'] = 'can', ['cl'] = 'cai', ['co'] = 'cuo', ['cp'] = 'cun', ['cs'] = 'cong', ['cr'] = 'cuan', ['cu'] = 'cu', ['cv'] = 'cui', 
['ba'] = 'ba', ['bc'] = 'biao', ['bg'] = 'beng', ['bf'] = 'ben', ['bi'] = 'bi', ['bh'] = 'bang', ['bk'] = 'bao', ['bj'] = 'ban', ['bm'] = 'bian', ['bl'] = 'bai', ['bo'] = 'bo', ['bn'] = 'bin', ['bu'] = 'bu', ['bx'] = 'bie', ['b;'] = 'bing', ['bz'] = 'bei', 
['da'] = 'da', ['dc'] = 'diao', ['db'] = 'dou', ['de'] = 'de', ['dg'] = 'deng', ['di'] = 'di', ['dh'] = 'dang', ['dk'] = 'dao', ['dj'] = 'dan', ['dm'] = 'dian', ['dl'] = 'dai', ['do'] = 'duo', ['dq'] = 'diu', ['dp'] = 'dun', ['ds'] = 'dong', ['dr'] = 'duan', ['du'] = 'du', ['dv'] = 'dui', ['dx'] = 'die', ['d;'] = 'ding', ['dz'] = 'dei', 
['ga'] = 'ga', ['gb'] = 'gou', ['ge'] = 'ge', ['gd'] = 'guang', ['gg'] = 'geng', ['gf'] = 'gen', ['gh'] = 'gang', ['gk'] = 'gao', ['gj'] = 'gan', ['gl'] = 'gai', ['go'] = 'guo', ['gp'] = 'gun', ['gs'] = 'gong', ['gr'] = 'guan', ['gu'] = 'gu', ['gw'] = 'gua', ['gv'] = 'gui', ['gy'] = 'guai', ['gz'] = 'gei', 
['fa'] = 'fa', ['fb'] = 'fou', ['fg'] = 'feng', ['ff'] = 'fen', ['fh'] = 'fang', ['fj'] = 'fan', ['fo'] = 'fo', ['fu'] = 'fu', ['fz'] = 'fei', 
['ia'] = 'cha', ['ib'] = 'chou', ['ie'] = 'che', ['id'] = 'chuang', ['ig'] = 'cheng', ['if'] = 'chen', ['ii'] = 'chi', ['ih'] = 'chang', ['ik'] = 'chao', ['ij'] = 'chan', ['il'] = 'chai', ['io'] = 'chuo', ['ip'] = 'chun', ['is'] = 'chong', ['ir'] = 'chuan', ['iu'] = 'chu', ['iv'] = 'chui', ['iy'] = 'chuai', 
['ha'] = 'ha', ['hb'] = 'hou', ['he'] = 'he', ['hd'] = 'huang', ['hg'] = 'heng', ['hf'] = 'hen', ['hh'] = 'hang', ['hk'] = 'hao', ['hj'] = 'han', ['hl'] = 'hai', ['ho'] = 'huo', ['hp'] = 'hun', ['hs'] = 'hong', ['hr'] = 'huan', ['hu'] = 'hu', ['hw'] = 'hua', ['hv'] = 'hui', ['hy'] = 'huai', ['hz'] = 'hei', 
['ka'] = 'ka', ['kb'] = 'kou', ['ke'] = 'ke', ['kd'] = 'kuang', ['kg'] = 'keng', ['kf'] = 'ken', ['kh'] = 'kang', ['kk'] = 'kao', ['kj'] = 'kan', ['kl'] = 'kai', ['ko'] = 'kuo', ['kp'] = 'kun', ['ks'] = 'kong', ['kr'] = 'kuan', ['ku'] = 'ku', ['kw'] = 'kua', ['kv'] = 'kui', ['ky'] = 'kuai', 
['jc'] = 'jiao', ['jd'] = 'jiang', ['ji'] = 'ji', ['jm'] = 'jian', ['jn'] = 'jin', ['jq'] = 'jiu', ['jp'] = 'jun', ['js'] = 'jiong', ['jr'] = 'juan', ['ju'] = 'ju', ['jt'] = 'jue', ['jw'] = 'jia', ['jv'] = 'jue', ['jx'] = 'jie', ['j;'] = 'jing', 
['ma'] = 'ma', ['mc'] = 'miao', ['mb'] = 'mou', ['me'] = 'me', ['mg'] = 'meng', ['mf'] = 'men', ['mi'] = 'mi', ['mh'] = 'mang', ['mk'] = 'mao', ['mj'] = 'man', ['mm'] = 'mian', ['ml'] = 'mai', ['mo'] = 'mo', ['mn'] = 'min', ['mq'] = 'miu', ['mu'] = 'mu', ['mx'] = 'mie', ['m;'] = 'ming', ['mz'] = 'mei', 
['la'] = 'la', ['lc'] = 'liao', ['lb'] = 'lou', ['le'] = 'le', ['ld'] = 'liang', ['lg'] = 'leng', ['li'] = 'li', ['lh'] = 'lang', ['lk'] = 'lao', ['lj'] = 'lan', ['lm'] = 'lian', ['ll'] = 'lai', ['lo'] = 'luo', ['ln'] = 'lin', ['lq'] = 'liu', ['lp'] = 'lun', ['ls'] = 'long', ['lr'] = 'luan', ['lu'] = 'lu', ['lv'] = 'lve', ['ly'] = 'lv', ['lx'] = 'lie', ['l;'] = 'ling', ['lz'] = 'lei', 
['oa'] = 'a', ['ob'] = 'ou', ['oe'] = 'e', ['of'] = 'en', ['oh'] = 'ang', ['ok'] = 'ao', ['oj'] = 'an', ['ol'] = 'ai', ['oo'] = 'o', ['or'] = 'er', ['oz'] = 'ei', 
['na'] = 'na', ['nc'] = 'niao', ['nb'] = 'nou', ['ne'] = 'ne', ['nd'] = 'niang', ['ng'] = 'neng', ['nf'] = 'nen', ['ni'] = 'ni', ['nh'] = 'nang', ['nk'] = 'nao', ['nj'] = 'nan', ['nm'] = 'nian', ['nl'] = 'nai', ['no'] = 'nuo', ['nn'] = 'nin', ['nq'] = 'niu', ['ns'] = 'nong', ['nr'] = 'nuan', ['nu'] = 'nu', ['nv'] = 'nve', ['ny'] = 'nv', ['nx'] = 'nie', ['n;'] = 'ning', ['nz'] = 'nei', 
['qc'] = 'qiao', ['qd'] = 'qiang', ['qi'] = 'qi', ['qm'] = 'qian', ['qn'] = 'qin', ['qq'] = 'qiu', ['qp'] = 'qun', ['qs'] = 'qiong', ['qr'] = 'quan', ['qu'] = 'qu', ['qt'] = 'que', ['qw'] = 'qia', ['qv'] = 'que', ['qx'] = 'qie', ['q;'] = 'qing', 
['pa'] = 'pa', ['pc'] = 'piao', ['pb'] = 'pou', ['pg'] = 'peng', ['pf'] = 'pen', ['pi'] = 'pi', ['ph'] = 'pang', ['pk'] = 'pao', ['pj'] = 'pan', ['pm'] = 'pian', ['pl'] = 'pai', ['po'] = 'po', ['pn'] = 'pin', ['pu'] = 'pu', ['px'] = 'pie', ['p;'] = 'ping', ['pz'] = 'pei', 
['sa'] = 'sa', ['sb'] = 'sou', ['se'] = 'se', ['sg'] = 'seng', ['sf'] = 'sen', ['si'] = 'si', ['sh'] = 'sang', ['sk'] = 'sao', ['sj'] = 'san', ['sl'] = 'sai', ['so'] = 'suo', ['sp'] = 'sun', ['ss'] = 'song', ['sr'] = 'suan', ['su'] = 'su', ['sv'] = 'sui', 
['rb'] = 'rou', ['re'] = 're', ['rg'] = 'reng', ['rf'] = 'ren', ['ri'] = 'ri', ['rh'] = 'rang', ['rk'] = 'rao', ['rj'] = 'ran', ['ro'] = 'ruo', ['rp'] = 'run', ['rs'] = 'rong', ['rr'] = 'ruan', ['ru'] = 'ru', ['rv'] = 'rui', 
['ua'] = 'sha', ['ub'] = 'shou', ['ue'] = 'she', ['ud'] = 'shuang', ['ug'] = 'sheng', ['uf'] = 'shen', ['ui'] = 'shi', ['uh'] = 'shang', ['uk'] = 'shao', ['uj'] = 'shan', ['ul'] = 'shai', ['uo'] = 'shuo', ['up'] = 'shun', ['ur'] = 'shuan', ['uu'] = 'shu', ['uw'] = 'shua', ['uv'] = 'shui', ['uy'] = 'shuai', ['uz'] = 'shei', 
['ta'] = 'ta', ['tc'] = 'tiao', ['tb'] = 'tou', ['te'] = 'te', ['tg'] = 'teng', ['ti'] = 'ti', ['th'] = 'tang', ['tk'] = 'tao', ['tj'] = 'tan', ['tm'] = 'tian', ['tl'] = 'tai', ['to'] = 'tuo', ['tp'] = 'tun', ['ts'] = 'tong', ['tr'] = 'tuan', ['tu'] = 'tu', ['tv'] = 'tui', ['tx'] = 'tie', ['t;'] = 'ting', 
['wa'] = 'wa', ['wg'] = 'weng', ['wf'] = 'wen', ['wh'] = 'wang', ['wj'] = 'wan', ['wl'] = 'wai', ['wo'] = 'wo', ['wu'] = 'wu', ['wz'] = 'wei', 
['va'] = 'zha', ['vb'] = 'zhou', ['ve'] = 'zhe', ['vd'] = 'zhuang', ['vg'] = 'zheng', ['vf'] = 'zhen', ['vi'] = 'zhi', ['vh'] = 'zhang', ['vk'] = 'zhao', ['vj'] = 'zhan', ['vl'] = 'zhai', ['vo'] = 'zhuo', ['vp'] = 'zhun', ['vs'] = 'zhong', ['vr'] = 'zhuan', ['vu'] = 'zhu', ['vw'] = 'zhua', ['vv'] = 'zhui', ['vy'] = 'zhuai', 
['ya'] = 'ya', ['yb'] = 'you', ['ye'] = 'ye', ['yi'] = 'yi', ['yh'] = 'yang', ['yk'] = 'yao', ['yj'] = 'yan', ['yl'] = 'yai', ['yo'] = 'yo', ['yn'] = 'yin', ['yp'] = 'yun', ['ys'] = 'yong', ['yr'] = 'yuan', ['yu'] = 'yu', ['yt'] = 'yue', ['yv'] = 'yue', ['y;'] = 'ying', 
['xc'] = 'xiao', ['xd'] = 'xiang', ['xi'] = 'xi', ['xm'] = 'xian', ['xn'] = 'xin', ['xq'] = 'xiu', ['xp'] = 'xun', ['xs'] = 'xiong', ['xr'] = 'xuan', ['xu'] = 'xu', ['xt'] = 'xue', ['xw'] = 'xia', ['xv'] = 'xue', ['xx'] = 'xie', ['x;'] = 'xing', 
['za'] = 'za', ['zb'] = 'zou', ['ze'] = 'ze', ['zg'] = 'zeng', ['zf'] = 'zen', ['zi'] = 'zi', ['zh'] = 'zang', ['zk'] = 'zao', ['zj'] = 'zan', ['zl'] = 'zai', ['zo'] = 'zuo', ['zp'] = 'zun', ['zs'] = 'zong', ['zr'] = 'zuan', ['zu'] = 'zu', ['zv'] = 'zui', ['zz'] = 'zei',
['v'] = 'zh', ['i'] = 'ch', ['u'] = 'sh',
}

--[[
set_switch{
	default_offline_mode = false,
	default_traditional_mode = false,
	double_pinyin = false,
	show_raw_in_auxiliary = false,
	always_show_candidates = false,
	show_pinyin_auxiliary = true,
}
--]]

-- paths
local user_config_path = user_config_path .. '/config.lua'
local engines_file_path = user_config_path .. '/engines.lua'
local autoload_file_path = '/tmp/.cloud-pinyin-autoload.lua'

-- wrapped dofile
function try_dofile(path)
	local file = io.open(path, 'r')
	if file then file:close() pcall(function() dofile(path) end) end
end

-- some engines, may be outdated
-- TODO: move these settings into user config file
register_engine("Sogou", data_path .. '/lua/engine_sogou.lua')
register_engine("QQ", data_path .. '/lua/engine_qq.lua')

-- load various script files if exists
try_dofile(user_config_path)
try_dofile(engines_file_path)
try_dofile(autoload_file_path)


-- update various things in background
go_background()
http.TIMEOUT = 10
if false and not do_not_update_cloud_engines then
	os.execute("mkdir '"..config_path.."' -p 2> /dev/null")
	local ret, c = http.request('http://ibus-cloud-pinyin.googlecode.com/svn/trunk/engines.lua')
	if c == 200 and ret and ret:match('ibus%-cloud%-pinyin%-engines%-end') then
		local engines_file = io.open(engines_file_path, 'w')
		engines_file:write(ret)
		engines_file:close()
	end
end

if false and not do_not_load_remote_script then
	http.TIMEOUT = 5
	os.execute("mkdir '"..ime.USERCACHEDIR.."' -p")
	local autoload_file_path = ime.USERCACHEDIR..'/autoload.lua'
	local ret, c = http.request('http://ibus-cloud-pinyin.googlecode.com/svn/trunk/autoload.lua')
	if c == 200 and ret and ret:match('ibus%-cloud%-pinyin%-autoload%-end') then
		local autoload_file = io.open(autoload_file_path, 'w')
		autoload_file:write(ret)
		autoload_file:close()
	end
end

