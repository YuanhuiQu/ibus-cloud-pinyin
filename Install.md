# 安装 #

## 注意事项 ##

  1. 本项目尚未完成，目前有些功能已经实现，基本可用。请不要在此时提交功能上计划完成而当前未完成的 Issue。
  1. 本项目仅针对 ibus 1.3.4 以及后续版本，不再提供对 ibus 1.2 的支持。

## Archlinux ##

> Archlinux 用户可以从 AUR 安装软件的 svn 版本。例如使用 [yaourt](http://wiki.archlinux.org/index.php/Yaourt) 来安装:
```
sudo yaourt -S ibus-cloud-pinyin-svn
```

## 从源代码安装 ##

  1. 下载源代码，进入 trunk 目录
  1. 编译，在此过程中会试图提示缺失依赖
```
make
```
> > Debian / Ubuntu 系统下若要正常完成此过程，至少需要 liblua5.1-0-dev, liblua5.1-socket2, libsqlite3-dev, libibus-dev, libnotify-dev, lua5.1, libgee-dev, valac, sqlite3
  1. 安装
```
sudo make install
```