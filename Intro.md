Still under development ....

仍在开发中 ....

![http://ibus-cloud-pinyin.googlecode.com/svn/wiki/img/egg.png](http://ibus-cloud-pinyin.googlecode.com/svn/wiki/img/egg.png)

目前已经完成大部分的功能，愿意先睹为快的用户可以尝试使用。

下面的“功能”为计划实现功能，有些在目前还未实现


---


# 简介 #

为 Linux / ibus 设计的一个支持在线云拼音服务的拼音输入法。

## 功能 ##

  * 在线、离线输入，并可快速切换
    * 双拼及全拼，支持已有的和未来的双拼布局以及全拼的拼音分隔符
    * 独创 Tab 键进入纠正模式，对刚选定汉字片段或正在编辑的拼音进行纠正
    * 独创 `jkl;asdf` 键选词（纠正模式中）
    * 简繁体转换（需要 [opencc](http://code.google.com/p/open-chinese-convert/)）
  * 在线输入
    * 多个云拼音引擎同时使用
    * 未完成的部分在后台异步完成，输入过程无阻塞（普通 Web 输入法会阻塞）
  * 离线输入
    * 支持用户自造词，动态调整词频
    * 支持直接导入 scel 词库
    * 支持南方模糊音
  * 灵活的 Lua 脚本作为配置文件
    * 可自定义复杂功能，譬如就地 Google Translate 选定内容
  * DBus 接口