# ccal

一个查看中国农历的命令行日历工具

## 用法

    显示当前月的日历:   
       ccal
    显示当前年的日历:
       ccal -y
    显示当前年9月份的日历:
       ccal 9
    显示公元1983年的日历:
       ccal 1983
    显示公元2012年12月份的日历:
       ccal 2012 12
    显示公元9年的日历:
       ccal -y 9

## 示例 

![image](http://imglf0.ph.126.net/PxI_KslY39drlfK1F55FwQ==/2081788927852049631.png)

![image](http://imglf2.ph.126.net/3OiX1eXdIOExvhcYCdu1Tg==/6597762458983902692.png)

## 安装

```
git clone https://github.com/lululau/ccal
cd ccal/
sudo cp ccal /usr/local/bin
cd lib/
sudo perl Makefile.PL

ccal --help
```