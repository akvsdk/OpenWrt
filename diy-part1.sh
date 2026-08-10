#!/bin/bash
set -euo pipefail

cat <<'EOF' >>feeds.conf.default
src-git kixdns https://github.com/JohnsonRan/luci-app-kixdns.git
src-git kdae https://github.com/QiuSimons/luci-app-dae.git;kix
src-git ddnsgo https://github.com/sirpdboy/luci-app-ddns-go.git
src-git quickfile https://github.com/sbwml/luci-app-quickfile.git;main
src-git lucky https://github.com/gdy666/luci-app-lucky.git;main
src-git easytier https://github.com/EasyTier/luci-app-easytier.git;main
src-git istore https://github.com/linkease/istore.git;main
EOF

mkdir -p package/custom
git clone --depth 1 --branch master \
  https://github.com/eamonxg/luci-theme-aurora.git \
  package/custom/luci-theme-aurora
git clone --depth 1 --branch master \
  https://github.com/eamonxg/luci-app-aurora-config.git \
  package/custom/luci-app-aurora-config
