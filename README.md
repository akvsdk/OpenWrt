# 固件说明文档

**固件版本**：基于 GitHub Actions 编译的自定义 OpenWrt 固件（包含上述所有软件包）

**包含软件包**：
- BPF（内核 eBPF 支持 + BPF 工具链）
- openssh-sftp-server（sftp 服务）
- luci-app-statistics（流量统计与可视化）
- wireguard（WireGuard 协议支持）
- shairport-sync-openssl（AirPlay 接收器）
- luci-app-kixdns（KixDNS DNS 转发与加速工具）
- luci-app-kdae（DAE 透明代理 LuCI 管理界面）
- luci-app-ddns-go（动态域名解析工具）
- hev-socks5-server（高性能 SOCKS5 代理服务器）

# ssh脚本使用方法

```
sudo bash setup-ssh-v4.sh --auto --disable-password --change-port=2222 --no-fail2ban #生产用法（一键安全加固）
sudo bash setup-ssh-v4.sh #手动模式（推荐）
```
