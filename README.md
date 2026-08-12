# 固件说明文档

**固件版本**：基于 GitHub Actions 编译的自定义 OpenWrt 固件（包含上述所有软件包）

**包含软件包**：
- bpf
- alsa-utils
- alsa-utils-tests
- shairport-sync-openssl
- komd-usb-audio
- wireguard
- openssh-sftp-server
- luci
	- dae
	- kixdns
	- ddns-go
	- statistics
	

# ssh脚本使用方法

```
sudo bash setup-ssh-v4.sh --auto --disable-password --change-port=2222 --no-fail2ban #生产用法（一键安全加固）
sudo bash setup-ssh-v4.sh #手动模式（推荐）
```
