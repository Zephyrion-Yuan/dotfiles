# dotfiles

个人可移植终端环境配置。仓库以当前机器的实际配置为准，覆盖 Herdr、Alacritty、
WezTerm、Neovim、Yazi 和 Bash；密钥、日志、socket、会话状态及设备绑定配置不入库。

GitHub：<https://github.com/Zephyrion-Yuan/dotfiles>

## 在另一台机器安装

```bash
git clone https://github.com/Zephyrion-Yuan/dotfiles.git ~/.dotfiles
bash ~/.dotfiles/scripts/install-nerd-font.sh
~/.dotfiles/install.sh
```

字体脚本会在缺少时安装 `Hack Nerd Font Mono`：macOS 使用 Homebrew cask，
Linux 安装到 `~/.local/share/fonts`。它是 Alacritty 图标与终端提示符的字形依赖。

`install.sh` 会先把目标机器已有配置改名为
`*.pre-dotfiles-YYYYMMDD-HHMMSS`，再建立符号链接，因此仓库版本会覆盖旧设置，
同时保留可恢复的备份。Herdr 目录中有运行时状态，所以脚本只链接
`~/.config/herdr/config.toml`，不会碰会话与日志。

建议先安装：`herdr`、`alacritty` 或 `wezterm`、`neovim` 和 `yazi`。
首次启动 Neovim 会通过 `lazy.nvim` 安装插件；`lazy-lock.json` 固定了当前插件版本。

## 当前设置摘要

### Herdr

- Prefix：`Ctrl-s`。
- 外观：跟随终端浅/深色；浅色 `catppuccin-latte`，深色 `catppuccin`。
- 其余动作沿用 Herdr 默认绑定。常用组合为：
  `Ctrl-s ?` 帮助、`Ctrl-s s` 设置、`Ctrl-s w` 工作区选择、
  `Ctrl-s c` 新标签、`Ctrl-s p/n` 前后标签、`Ctrl-s 1..9` 切换标签、
  `Ctrl-s v/-` 分屏、`Ctrl-s h/j/k/l` 切换面板、`Ctrl-s z` 缩放、
  `Ctrl-s q` 分离。

### Alacritty

- Gruvbox Light，14pt `Hack Nerd Font Mono`，透明标题栏与紧凑内边距。
- 选中文本自动进入剪贴板；`Cmd+点击` 打开 URL。
- `Cmd+Left/Right` 到行首/行尾，`Option+Left/Right` 按单词移动。

### WezTerm

- 作为备选终端保留；跟随 macOS 外观切换 Catppuccin Latte/Mocha。
- 14pt、半透明背景；`Cmd+点击` 打开链接。
- `Cmd+Left/Right` 到行首/行尾，`Option+Left/Right` 按单词移动。

### Neovim

- 浅色 `dayfox` 主题，相对行号，系统剪贴板。
- 插件由 `lazy.nvim` 管理，包括 LSP/Mason、补全、Treesitter、Yazi、
  Neotest 与 Markdown Preview。
- Leader 为 `Space`；完整快捷键见
  [`home/.config/nvim/guide.markdown`](home/.config/nvim/guide.markdown)。

### Yazi 与 Bash

- Yazi 使用 Catppuccin Frappe；文本默认用 Neovim，`Ctrl-o` 在 Finder 中显示，
  `F` 用系统应用打开。详见
  [`home/.config/yazi/guide.markdown`](home/.config/yazi/guide.markdown)。
- Bash 对 conda/nvm 做懒加载，并提供退出 Yazi 后自动 `cd` 的 `y` 包装。
- 密钥、代理、VPN 和机器专属 PATH 放入 `~/.bashrc.local`；主配置会自动载入，
  此文件不会提交。

## 目录结构

```text
~/.dotfiles/
├── install.sh
├── scripts/install-nerd-font.sh
└── home/
    ├── .bashrc
    └── .config/
        ├── alacritty/
        ├── herdr/config.toml
        ├── nvim/
        ├── wezterm/
        └── yazi/
```

## 日常同步

真实配置通过符号链接指向仓库，因此修改 `~/.config/<tool>/` 或 `~/.bashrc`
就等于修改仓库。

```bash
cd ~/.dotfiles
git pull --rebase
git add -A
git commit -m "更新终端配置"
git push
```

常用维护命令：

```bash
herdr config check
herdr server reload-config
nvim +Lazy
nvim +"Lazy restore"
```

本机私有内容请放在 `~/.bashrc.local` 或仓库的 `local/`。Karabiner 的当前配置
含具体设备记录，Herdr 的 `session.json` 含本机路径与会话 ID，这些都有意排除。
