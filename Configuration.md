# 配置 #

## 注意事项 ##
  1. 最新的配置内容以及默认配置请以全局配置文件内的注释为准
  1. Release 之前此部分内容可能被修改，现有内容仅供参考

## 文件位置 ##

  * 全局配置文件：`/usr/share/ibus-cloud-pinyin/lua/config.lua`
  * 用户配置文件：`${XDG_CONFIG_HOME:-$HOME/.config}/ibus/cloud-pinyin/config.lua`

> 配置文件是 lua 脚本，其中可以用 dofile 加载其他的文件。全局配置文件默认加载了用户配置文件

## 说明 ##

全局配置文件的注释中已经包含了所有输入法提供的接口的说明，配置时请参考该文件

下图说明一些配置选项应该使用的接口函数，关于具体函数详细使用方法请参考全局配置文件：

![http://ibus-cloud-pinyin.googlecode.com/svn/wiki/img/1.png](http://ibus-cloud-pinyin.googlecode.com/svn/wiki/img/1.png)

  1. 云服务器提供的结果
    * 颜色
```
set_color{ preedit_remote = ... }
```
  1. 本地词库转换结果
    * 颜色，对于直接提交的内容，比如中文标点，使用 preedit\_fixed 设置颜色
```
set_color{ preedit_local = ... , preedit_fixed = ... }
```
  1. 候选词列表
    * 默认在按下 Tab 进入纠正模式后显示
    * 设置为一直显示
```
set_switch{ always_show_candidates = true }
```
    * 服务器词条颜色
```
set_color{ candidate_remote = ... }
```
    * 本地词条颜色
```
set_color{ candidate_local = ... }
```
    * 标签文字
```
set_candidate_labels(labels_correction_mode, labels_normal_mode)
```
  1. 正在编辑的拼音串
    * 默认显示，设置为隐藏
```
set_switch{ show_pinyin_auxiliary = false }
```
    * 颜色
```
set_color{ buffer_pinyin = ... }
```
  1. 正在编辑的拼音串的原始输入内容
    * 默认隐藏，设置为显示
```
set_switch{ show_raw_in_auxiliary = true }
```
    * 颜色
```
set_color{ buffer_raw = ... }
```

![http://ibus-cloud-pinyin.googlecode.com/svn/wiki/img/2.png](http://ibus-cloud-pinyin.googlecode.com/svn/wiki/img/2.png)

  1. 中英文切换
    * 默认热键：左 Shift
      * 使用左 Ctrl 切换
```
set_key(keys.ctrl_left, masks.control + masks.release, "eng chs")
```
      * 使用左 Shift 切换到英文，右 Shift 中文
```
set_key(keys.shift_left, masks.shift + masks.release, "eng")
set_key(keys.shift_right, masks.shift + masks.release, "chs")
```
    * 默认中文，设为默认英文：
```
set_switch{ default_chinese_mode = false }
```
  1. 简繁体切换
    * 需要 libopencc 支持
    * 默认 Ctrl + Shift + L 切换
    * 默认简体，设置为默认繁体：
```
set_switch{ default_traditional_mode = true }
```
  1. 在线，离线切换
    * 离线模式使用灰色方块表示，在线模式时，如果后台有未完成的请求，使用蓝色方块动画表示，如果没有未完成的请求，绿色方块表示近期网络状况
    * 默认热键：右 Shift，通过 set\_key 可设置
    * 默认在线，设置为默认离线
```
set_switch{ default_offline_mode = true }
```
  1. 工具菜单

图中没有提到的可设置项：
  * 热键动作
    * 可以为各种组合键指定动作，支持用 lua 脚本完成复杂动作
  * 超时、限制、双拼、后台请求等设置
    * 设置超时时间或者词条个数、重试次数的限制，详见全局配置文件中 set\_timeouts， set\_limits 以及 set\_switch
    * 例如，禁止后台请求（不再会将未有完成请求结果的待定文字段放在后台，每次确认文字段都会直接强制上屏），同时启用双拼：
```
set_switch{ background_request = false, double_pinyin = true }
```
  * 注册、注销云请求脚本
    * 见 register\_engine
    * 一个云请求脚本将使用 pinyin 全局变量，该变量是用空格分开的全拼字符串，脚本应该发送该拼音到服务器并将结果字符串作为 response() 函数第一个参数调用 response。无需刻意在脚本中控制超时
  * 设置双拼方案
    * 见 set\_double\_pinyin
    * 一些方案可参考[这里](http://code.google.com/p/ibus-cloud-pinyin/wiki/DoublePinyinScheme)
  * 设置全角标点
    * 见 set\_punctuation
  * 设置云请求缓存
    * 见 set\_response
    * 例如，设置 'yi' => '咦'：
```
set_response('yi', '咦')
```
  * 其他可能用在热键动作中的接口
    * 见 notify, get\_selection 以及 commit