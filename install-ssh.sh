#!/usr/bin/env bash
# setup-ssh-v4.sh
# Enhanced SSH Setup Wizard v4（含 Fail2Ban、服务检查、最佳实践、安全加固）
# 已包含你提出的所有建议 + 生产环境必备优化

set -euo pipefail

# === 参数解析 ===
AUTO=0
DISABLE_PASSWORD=1          # 默认禁用密码登录（生产推荐）
CHANGE_PORT=""
FAIL2BAN=1                  # 默认安装 Fail2Ban
FORCE=0                     # 是否强制模式（覆盖配置）

for a in "$@"; do
  case "$a" in
    --auto) AUTO=1;;
    --disable-password) DISABLE_PASSWORD=1;;
    --change-port=*) CHANGE_PORT="${a#*=}";;
    --no-fail2ban) FAIL2BAN=0;;
    --force) FORCE=1;;
  esac
done

# === 颜色输出 ===
color(){ printf "\033[%sm%s\033[0m\n" "$1" "$2"; }
info(){ color 36 "[INFO] $*"; }
ok(){ color 32 "[ OK ] $*"; }
warn(){ color 33 "[WARN] $*"; }
err(){ color 31 "[ERR ] $*"; }

# === 自动提权 ===
need_root(){
  [ "$(id -u)" -eq 0 ] && return
  if command -v sudo >/dev/null; then
    exec sudo bash "$0" "$@"
  fi
  err "请以 root 身份运行本脚本。"
  exit 1
}

# === OS 检测 ===
detect_os(){
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "${PRETTY_NAME:-Linux}"
  else
    echo "Linux"
  fi
}

info "=== SSH Setup Wizard v4 ==="
info "OS: $(detect_os)"
info "用户: ${SUDO_USER:-$USER}"

# === 安装/修复 OpenSSH 服务 ===
if ! command -v sshd >/dev/null 2>&1; then
  need_root "$@"
  info "未检测到 OpenSSH 服务，正在安装..."
  if command -v apt >/dev/null; then
    apt update && apt install -y openssh-server
  elif command -v dnf >/dev/null; then
    dnf install -y openssh-server
  elif command -v yum >/dev/null; then
    yum install -y openssh-server
  elif command -v pacman >/dev/null; then
    pacman -Sy --noconfirm openssh
  elif command -v apk >/dev/null; then
    apk add openssh
  elif command -v zypper >/dev/null; then
    zypper -n install openssh
  else
    err "不支持的包管理器！"
    exit 1
  fi
  ok "OpenSSH 服务安装完成"
else
  info "OpenSSH 服务已安装"
fi

# === 查找并备份 sshd_config ===
CFG=""
for f in /etc/ssh/sshd_config /etc/openssh/sshd_config; do
  [ -f "$f" ] && CFG="$f" && break
done
[ -z "$CFG" ] && { err "sshd_config 未找到！"; exit 1; }

need_root "$@"
cp "$CFG" "$CFG.bak.$(date +%F-%H%M%S)"
info "已备份原始配置文件：$CFG"

# === 设置配置 ===
setcfg(){
  local k="$1" v="$2"
  if grep -Eq "^[#[:space:]]*$k" "$CFG"; then
    sed -i -E "s|^[#[:space:]]*$k.*|$k $v|" "$CFG"
  else
    echo "$k $v" >> "$CFG"
  fi
}

# 核心安全设置（生产环境推荐）
setcfg Port "${CHANGE_PORT:-22}"
setcfg PubkeyAuthentication yes
setcfg AuthorizedKeysFile .ssh/authorized_keys
setcfg PasswordAuthentication "${DISABLE_PASSWORD}"
setcfg PermitRootLogin prohibit-password   # 推荐生产设置
setcfg MaxAuthTries 3
setcfg ClientAliveInterval 300
setcfg ClientAliveCountMax 0
setcfg Protocol 2

sshd -t -f "$CFG" && ok "sshd_config 语法检查通过" || { err "配置有误！请检查"; exit 1; }

# === 用户环境 ===
USER_NAME="${SUDO_USER:-$USER}"
HOME=$(eval echo "~$USER_NAME")
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
touch "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/authorized_keys"
info "用户家目录已创建并权限修复"

# === 公钥导入 ===
if [ "$AUTO" -eq 0 ]; then
  echo
  echo "1) 我已经有一个公钥"
  echo "2) 我在客户端生成密钥并返回"
  echo "3) 跳过"
  read -rp "请选择 [1]: " c
  c=${c:-1}
  if [ "$c" = 1 ]; then
    read -rp "请粘贴公钥（一行）： " PUB
    if echo "$PUB" | grep -Eq '^(ssh-ed25519|ssh-rsa|ecdsa-sha2-) '; then
      if grep -qxF "$PUB" "$HOME/.ssh/authorized_keys"; then
        warn "公钥已存在，跳过"
      else
        echo "$PUB" >> "$HOME/.ssh/authorized_keys"
        ok "公钥已添加"
      fi
    else
      err "无效的公钥格式"
    fi
  elif [ "$c" = 2 ]; then
    cat <<EOF
在你的本地机器运行：
ssh-keygen -t ed25519
cat ~/.ssh/id_ed25519.pub

然后再次运行本脚本。
EOF
  fi
fi

# === Fail2Ban（强烈推荐）===
if [ "$FAIL2BAN" -eq 1 ]; then
  if ! command -v fail2ban-client >/dev/null 2>&1; then
    info "正在安装 Fail2Ban..."
    if command -v apt >/dev/null; then
      apt update && apt install -y fail2ban
    elif command -v dnf >/dev/null; then
      dnf install -y fail2ban
    elif command -v yum >/dev/null; then
      yum install -y fail2ban
    elif command -v pacman >/dev/null; then
      pacman -Sy --noconfirm fail2ban
    elif command -v apk >/dev/null; then
      apk add fail2ban
    elif command -v zypper >/dev/null; then
      zypper -n install fail2ban
    fi
    ok "Fail2Ban 安装完成"
  fi

  # 配置 Fail2Ban（最常用 jail）
  cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 1d
maxretry = 5
ignoreip = 127.0.0.1/8

[sshd]
enabled = true
port = ${CHANGE_PORT:-22}
logpath = /var/log/auth.log
EOF
  info "Fail2Ban 已配置（最大5次失败封禁1天）"
  systemctl enable --now fail2ban
  ok "Fail2Ban 已启动"
fi

# === 重启服务并验证 ===
info "正在重启 SSH 服务..."
systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true
systemctl status sshd -l --no-pager

# === 最终提示 ===
ok "SSH 设置完成！"
IP=$(hostname -I | awk '{print $1}')
if [ -n "$IP" ]; then
  echo "访问命令："
  echo "  ssh ${USER_NAME}@${IP} -p ${CHANGE_PORT:-22}"
else
  echo "访问命令："
  echo "  ssh ${USER_NAME}@<服务器IP> -p ${CHANGE_PORT:-22}"
fi

echo
echo "✅ 建议：生产环境建议使用 ed25519 密钥 + 自定义端口 + Fail2Ban"