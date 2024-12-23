# Build-OpenWrt

## 云编译OpenWRT固件

[![OpenWrt](https://img.shields.io/badge/OpenWrt-Official-red.svg?style=flat&logo=appveyor)](https://github.com/openwrt/openwrt) [![immortalwrt](https://img.shields.io/badge/OpenWrt-ImmortalWrt-orange.svg?style=flat&logo=appveyor)](https://github.com/immortalwrt/immortalwrt) [![Lean](https://img.shields.io/badge/OpenWrt-Lede-blueviolet.svg?style=flat&logo=appveyor)](https://github.com/coolsnowwolf/lede) 

## 固件简要说明：

固件每天早上2点，检查上游源代码，自动编译。

固件信息里的时间为编译开始的时间，方便核对上游源码提交时间。

主要用于云编译官方`OpenWrt`或`ImmortalWrt`，已删除<s>Lede</s>相关部分。

## 目录简要说明：

workflows——actions脚本

config——自定义配置

- general.config 为通用配置文件，用于设定各平台都用得到的插件。

- x86_64.config为amd64设备主要配置文件，其他机型需要添加。

scripts——自定义脚本

settings——设置文件

- settings.ini——设置源码以及分支等

### 使用方法：

需要在`Token`里面添加如下信息：

- REPO_TOKEN

  > REPO_TOKEN密匙制作教程：https://github.com/danshui-git/shuoming/blob/master/jm.md


- SCKEY

  > ServerChan工具的token教程：
  >
  > 1、获取SCKEY：[点击这里](https://sct.ftqq.com/login)，微信扫码，扫码后再点登录（需要两步），就可以看到你的token了
  >
  > 2、绑定微信：点击导航栏的 [微信推送]，用微信扫描二维码关注公众号并在页面中 [检查结果并确认绑定] 即可。
  >
  > 3、测试一下：直接在 [发送消息] 页面的在线发送消息工具中填写标题和消息内容，点击发送消息就可以测试通知效果了。
  > 
  > 4、添加token：复制好你的`SCKEY`后，接下来到你自己的仓库，点Settings，再点左边的Secrets，然后点右上角的New repositonry secret，然后在Name下面的方框写上名字，名字为（SCKEY）不包括括号，Value下面大方框放进密匙，点下面的绿色按钮Add secret保存即完成
