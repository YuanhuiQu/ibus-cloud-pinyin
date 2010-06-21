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

-- default double pinyin scheme
set_double_pinyin{
	['ba'] = 'ba', ['bc'] = 'biao', ['bf'] = 'ben', ['bg'] = 'beng', ['bh'] = 'bang', ['bi'] = 'bi', ['bj'] = 'ban', ['bk'] = 'bao', ['bl'] = 'bai', ['bm'] = 'bian', ['bn'] = 'bin', ['bo'] = 'bo', ['bu'] = 'bu', ['bx'] = 'bie', ['by'] = 'bing', ['bz'] = 'bei', 
	['ca'] = 'ca', ['cb'] = 'cou', ['ce'] = 'ce', ['cf'] = 'cen', ['cg'] = 'ceng', ['ch'] = 'cang', ['ci'] = 'ci', ['cj'] = 'can', ['ck'] = 'cao', ['cl'] = 'cai', ['co'] = 'cuo', ['cp'] = 'cun', ['cr'] = 'cuan', ['cs'] = 'cong', ['cu'] = 'cu', ['cv'] = 'cui', 
	['da'] = 'da', ['db'] = 'dou', ['dc'] = 'diao', ['de'] = 'de', ['dg'] = 'deng', ['dh'] = 'dang', ['di'] = 'di', ['dj'] = 'dan', ['dk'] = 'dao', ['dl'] = 'dai', ['dm'] = 'dian', ['do'] = 'duo', ['dp'] = 'dun', ['dq'] = 'diu', ['dr'] = 'duan', ['ds'] = 'dong', ['du'] = 'du', ['dv'] = 'dui', ['dx'] = 'die', ['dy'] = 'ding', 
	['fa'] = 'fa', ['fb'] = 'fou', ['ff'] = 'fen', ['fg'] = 'feng', ['fh'] = 'fang', ['fj'] = 'fan', ['fo'] = 'fo', ['fu'] = 'fu', ['fz'] = 'fei', 
	['ga'] = 'ga', ['gb'] = 'gou', ['gd'] = 'guang', ['ge'] = 'ge', ['gf'] = 'gen', ['gg'] = 'geng', ['gh'] = 'gang', ['gj'] = 'gan', ['gk'] = 'gao', ['gl'] = 'gai', ['go'] = 'guo', ['gp'] = 'gun', ['gr'] = 'guan', ['gs'] = 'gong', ['gu'] = 'gu', ['gv'] = 'gui', ['gw'] = 'gua', ['gy'] = 'guai', ['gz'] = 'gei', 
	['ha'] = 'ha', ['hb'] = 'hou', ['hd'] = 'huang', ['he'] = 'he', ['hf'] = 'hen', ['hg'] = 'heng', ['hh'] = 'hang', ['hj'] = 'han', ['hk'] = 'hao', ['hl'] = 'hai', ['ho'] = 'huo', ['hp'] = 'hun', ['hr'] = 'huan', ['hs'] = 'hong', ['hu'] = 'hu', ['hv'] = 'hui', ['hw'] = 'hua', ['hy'] = 'huai', ['hz'] = 'hei', 
	['ia'] = 'cha', ['ib'] = 'chou', ['id'] = 'chuang', ['ie'] = 'che', ['if'] = 'chen', ['ig'] = 'cheng', ['ih'] = 'chang', ['ii'] = 'chi', ['ij'] = 'chan', ['ik'] = 'chao', ['il'] = 'chai', ['io'] = 'chuo', ['ip'] = 'chun', ['ir'] = 'chuan', ['is'] = 'chong', ['iu'] = 'chu', ['iv'] = 'chui', ['iy'] = 'chuai', 
	['jc'] = 'jiao', ['jd'] = 'jiang', ['ji'] = 'ji', ['jm'] = 'jian', ['jn'] = 'jin', ['jp'] = 'jun', ['jq'] = 'jiu', ['jr'] = 'juan', ['js'] = 'jiong', ['jt'] = 'jue', ['ju'] = 'ju', ['jw'] = 'jia', ['jx'] = 'jie', ['jy'] = 'jing', 
	['ka'] = 'ka', ['kb'] = 'kou', ['kd'] = 'kuang', ['ke'] = 'ke', ['kf'] = 'ken', ['kg'] = 'keng', ['kh'] = 'kang', ['kj'] = 'kan', ['kk'] = 'kao', ['kl'] = 'kai', ['ko'] = 'kuo', ['kp'] = 'kun', ['kr'] = 'kuan', ['ks'] = 'kong', ['ku'] = 'ku', ['kv'] = 'kui', ['kw'] = 'kua', ['ky'] = 'kuai', 
	['la'] = 'la', ['lb'] = 'lou', ['lc'] = 'liao', ['ld'] = 'liang', ['le'] = 'le', ['lg'] = 'leng', ['lh'] = 'lang', ['li'] = 'li', ['lj'] = 'lan', ['lk'] = 'lao', ['ll'] = 'lai', ['lm'] = 'lian', ['ln'] = 'lin', ['lo'] = 'luo', ['lp'] = 'lun', ['lq'] = 'liu', ['lr'] = 'luan', ['ls'] = 'long', ['lt'] = 'lue', ['lu'] = 'lu', ['lv'] = 'lv', ['lx'] = 'lie', ['ly'] = 'ling', ['lz'] = 'lei', 
	['ma'] = 'ma', ['mb'] = 'mou', ['mc'] = 'miao', ['me'] = 'me', ['mf'] = 'men', ['mg'] = 'meng', ['mh'] = 'mang', ['mi'] = 'mi', ['mj'] = 'man', ['mk'] = 'mao', ['ml'] = 'mai', ['mm'] = 'mian', ['mn'] = 'min', ['mo'] = 'mo', ['mq'] = 'miu', ['mu'] = 'mu', ['mx'] = 'mie', ['my'] = 'ming', ['mz'] = 'mei', 
	['na'] = 'na', ['nb'] = 'nou', ['nc'] = 'niao', ['nd'] = 'niang', ['ne'] = 'ne', ['nf'] = 'nen', ['ng'] = 'neng', ['nh'] = 'nang', ['ni'] = 'ni', ['nj'] = 'nan', ['nk'] = 'nao', ['nl'] = 'nai', ['nm'] = 'nian', ['nn'] = 'nin', ['no'] = 'nuo', ['nq'] = 'niu', ['nr'] = 'nuan', ['ns'] = 'nong', ['nt'] = 'nue', ['nu'] = 'nu', ['nv'] = 'nv', ['nx'] = 'nie', ['ny'] = 'ning', ['nz'] = 'nei', 
	['oa'] = 'a', ['ob'] = 'ou', ['oe'] = 'e', ['of'] = 'en', ['og'] = 'eng', ['oh'] = 'ang', ['oj'] = 'an', ['ok'] = 'ao', ['ol'] = 'ai', ['or'] = 'er', ['oz'] = 'ei', 
	['pa'] = 'pa', ['pb'] = 'pou', ['pc'] = 'piao', ['pf'] = 'pen', ['pg'] = 'peng', ['ph'] = 'pang', ['pi'] = 'pi', ['pj'] = 'pan', ['pk'] = 'pao', ['pl'] = 'pai', ['pm'] = 'pian', ['pn'] = 'pin', ['po'] = 'po', ['pu'] = 'pu', ['px'] = 'pie', ['py'] = 'ping', ['pz'] = 'pei', 
	['qc'] = 'qiao', ['qd'] = 'qiang', ['qi'] = 'qi', ['qm'] = 'qian', ['qn'] = 'qin', ['qp'] = 'qun', ['qq'] = 'qiu', ['qr'] = 'quan', ['qs'] = 'qiong', ['qt'] = 'que', ['qu'] = 'qu', ['qw'] = 'qia', ['qx'] = 'qie', ['qy'] = 'qing', 
	['rb'] = 'rou', ['re'] = 're', ['rf'] = 'ren', ['rg'] = 'reng', ['rh'] = 'rang', ['ri'] = 'ri', ['rj'] = 'ran', ['rk'] = 'rao', ['ro'] = 'ruo', ['rp'] = 'run', ['rr'] = 'ruan', ['rs'] = 'rong', ['ru'] = 'ru', ['rv'] = 'rui', 
	['sa'] = 'sa', ['sb'] = 'sou', ['se'] = 'se', ['sf'] = 'sen', ['sg'] = 'seng', ['sh'] = 'sang', ['si'] = 'si', ['sj'] = 'san', ['sk'] = 'sao', ['sl'] = 'sai', ['so'] = 'suo', ['sp'] = 'sun', ['sr'] = 'suan', ['ss'] = 'song', ['su'] = 'su', ['sv'] = 'sui', 
	['ta'] = 'ta', ['tb'] = 'tou', ['tc'] = 'tiao', ['te'] = 'te', ['tg'] = 'teng', ['th'] = 'tang', ['ti'] = 'ti', ['tj'] = 'tan', ['tk'] = 'tao', ['tl'] = 'tai', ['tm'] = 'tian', ['to'] = 'tuo', ['tp'] = 'tun', ['tr'] = 'tuan', ['ts'] = 'tong', ['tu'] = 'tu', ['tv'] = 'tui', ['tx'] = 'tie', ['ty'] = 'ting', 
	['ua'] = 'sha', ['ub'] = 'shou', ['ud'] = 'shuang', ['ue'] = 'she', ['uf'] = 'shen', ['ug'] = 'sheng', ['uh'] = 'shang', ['ui'] = 'shi', ['uj'] = 'shan', ['uk'] = 'shao', ['ul'] = 'shai', ['uo'] = 'shuo', ['up'] = 'shun', ['ur'] = 'shuan', ['uu'] = 'shu', ['uv'] = 'shui', ['uw'] = 'shua', ['uy'] = 'shuai', ['uz'] = 'shei', 
	['va'] = 'zha', ['vb'] = 'zhou', ['vd'] = 'zhuang', ['ve'] = 'zhe', ['vf'] = 'zhen', ['vg'] = 'zheng', ['vh'] = 'zhang', ['vi'] = 'zhi', ['vj'] = 'zhan', ['vk'] = 'zhao', ['vl'] = 'zhai', ['vo'] = 'zhuo', ['vp'] = 'zhun', ['vr'] = 'zhuan', ['vs'] = 'zhong', ['vu'] = 'zhu', ['vv'] = 'zhui', ['vw'] = 'zhua', ['vy'] = 'zhuai', 
	['wa'] = 'wa', ['wf'] = 'wen', ['wg'] = 'weng', ['wh'] = 'wang', ['wj'] = 'wan', ['wl'] = 'wai', ['wo'] = 'wo', ['wu'] = 'wu', ['wz'] = 'wei', 
	['xc'] = 'xiao', ['xd'] = 'xiang', ['xi'] = 'xi', ['xm'] = 'xian', ['xn'] = 'xin', ['xp'] = 'xun', ['xq'] = 'xiu', ['xr'] = 'xuan', ['xs'] = 'xiong', ['xt'] = 'xue', ['xu'] = 'xu', ['xw'] = 'xia', ['xx'] = 'xie', ['xy'] = 'xing', 
	['ya'] = 'ya', ['yb'] = 'you', ['ye'] = 'ye', ['yh'] = 'yang', ['yi'] = 'yi', ['yj'] = 'yan', ['yk'] = 'yao', ['yl'] = 'yai', ['yn'] = 'yin', ['yo'] = 'yo', ['yp'] = 'yun', ['yr'] = 'yuan', ['ys'] = 'yong', ['yt'] = 'yue', ['yu'] = 'yu', ['yy'] = 'ying', 
	['za'] = 'za', ['zb'] = 'zou', ['ze'] = 'ze', ['zf'] = 'zen', ['zg'] = 'zeng', ['zh'] = 'zang', ['zi'] = 'zi', ['zj'] = 'zan', ['zk'] = 'zao', ['zl'] = 'zai', ['zo'] = 'zuo', ['zp'] = 'zun', ['zr'] = 'zuan', ['zs'] = 'zong', ['zu'] = 'zu', ['zv'] = 'zui', ['zz'] = 'zei',
	['i'] = 'ch', ['u'] = 'sh', ['v'] = 'zh',
	['m;'] = 'ming',
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

register_engine("sogou", data_path .. '/lua/engine_sogou.lua')
register_engine("qq", data_path .. '/lua/engine_qq.lua')

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

