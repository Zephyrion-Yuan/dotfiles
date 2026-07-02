#!/usr/bin/env bash
set -euo pipefail

# 幂等安装 Nerd Font。
#
# 背景：tmux 状态栏 / pane 边框、starship 提示符依赖 Nerd Font 私有区字形
# （powerline 分隔符 U+E0B0、各类图标）。macOS 上终端一般已配好 Nerd Font，
# 但新的 Linux 机器默认没有，会把这些字形渲染成方框 / 空白。
# 本脚本检测缺失时自动下载安装 JetBrainsMono Nerd Font 并刷新字体缓存。
#
# 用法：bash ~/.dotfiles/scripts/install-nerd-font.sh
# 已安装任意 Nerd Font 时直接跳过（可加 --force 强制重装）。

FONT_NAME="JetBrainsMono"                 # ryanoasis/nerd-fonts 的 release 资产名
FAMILY="JetBrainsMono Nerd Font"          # 装好后在终端里选的 family 名
FALLBACK_TAG="v3.4.0"                     # GitHub API 不可用时的兜底版本
DEST="${HOME}/.local/share/fonts/JetBrainsMonoNerdFont"

force=0
[[ "${1:-}" == "--force" ]] && force=1

have_nerd_font() {
  command -v fc-list >/dev/null 2>&1 || return 1
  # 先把 fc-list 结果收进变量再匹配：避免 `fc-list | grep -q` 在 pipefail 下
  # 因 grep -q 命中即关管道、fc-list 收到 SIGPIPE 而被误判为失败。
  local list
  list="$(fc-list 2>/dev/null || true)"
  grep -qi "Nerd Font" <<<"$list"
}

if [[ "$force" -eq 0 ]] && have_nerd_font; then
  echo "✅ 已检测到 Nerd Font，跳过安装。终端字体请选：${FAMILY}"
  exit 0
fi

# macOS：交给 Homebrew，别手动往 ~/Library/Fonts 塞
if [[ "$(uname -s)" == "Darwin" ]]; then
  if command -v brew >/dev/null 2>&1; then
    echo "🍎 macOS：用 Homebrew 安装 font-jetbrains-mono-nerd-font …"
    brew install --cask font-jetbrains-mono-nerd-font
    echo "✅ 完成。终端字体请选：${FAMILY}"
  else
    echo "🍎 macOS 未装 Homebrew。请手动安装 Nerd Font，或先装 brew：" >&2
    echo "   https://github.com/ryanoasis/nerd-fonts/releases" >&2
    exit 1
  fi
  exit 0
fi

# Linux：下载 + 解压到 ~/.local/share/fonts + fc-cache
for tool in curl unzip fc-cache; do
  command -v "$tool" >/dev/null 2>&1 || { echo "❌ 缺少依赖：$tool，请先安装。" >&2; exit 1; }
done

echo "🔎 查询 nerd-fonts 最新版本 …"
tag="$(curl -sL --max-time 15 https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest \
        | grep -oP '"tag_name":\s*"\K[^"]+' | head -1 || true)"
if [[ -z "$tag" ]]; then
  echo "⚠️  GitHub API 不可用，回退到 ${FALLBACK_TAG}"
  tag="$FALLBACK_TAG"
fi

url="https://github.com/ryanoasis/nerd-fonts/releases/download/${tag}/${FONT_NAME}.zip"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "⬇️  下载 ${FONT_NAME} Nerd Font (${tag}) …"
curl -fL --max-time 180 -o "$tmp/font.zip" "$url"

echo "📦 解压到 ${DEST} …"
mkdir -p "$DEST"
unzip -o -q "$tmp/font.zip" '*.ttf' -d "$DEST"

echo "🔄 刷新字体缓存 …"
fc-cache -f "${HOME}/.local/share/fonts" >/dev/null 2>&1

if have_nerd_font; then
  echo "✅ 安装完成。终端字体请选：${FAMILY}"
  echo "   （已存在的终端窗口需重开才会应用新字体）"
else
  echo "⚠️  安装后仍未检测到 Nerd Font，请检查 ${DEST} 及 fontconfig。" >&2
  exit 1
fi
