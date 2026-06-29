# dotfiles

个人终端环境配置仓库，覆盖 `tmux`、`neovim`、`yazi`、`wezterm` 四个工具的配置，以及可移植的 `zsh` 配置。

GitHub：<https://github.com/Zephyrion-Yuan/dotfiles>

## 目录结构

```
~/.dotfiles/
├── README.md
├── .gitignore
└── home/
    ├── .zshrc           # 可移植的 zsh 配置（机器私有部分见 ~/.zshrc.local）
    └── .config/
        ├── tmux/        # tmux 配置 + 状态栏脚本
        ├── nvim/        # Neovim 配置（init.lua + lua/ + lazy-lock.json）
        ├── yazi/        # Yazi 文件管理器配置
        └── wezterm/     # WezTerm 终端配置（浅/深色跟随系统）
```

`home/` 下的结构与实际家目录一一对应，所有真实配置通过符号链接指向本仓库。

## 安装（首次部署到新机器）

```bash
# 1. 克隆仓库到固定位置
git clone https://github.com/Zephyrion-Yuan/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# 2. 备份已有配置（如有）
mv ~/.config/tmux ~/.config/tmux.bak 2>/dev/null || true
mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null || true
mv ~/.config/yazi ~/.config/yazi.bak 2>/dev/null || true
mv ~/.config/wezterm ~/.config/wezterm.bak 2>/dev/null || true
mv ~/.zshrc ~/.zshrc.bak 2>/dev/null || true

# 3. 建立符号链接
mkdir -p ~/.config
ln -s ~/.dotfiles/home/.config/tmux    ~/.config/tmux
ln -s ~/.dotfiles/home/.config/nvim    ~/.config/nvim
ln -s ~/.dotfiles/home/.config/yazi    ~/.config/yazi
ln -s ~/.dotfiles/home/.config/wezterm ~/.config/wezterm
ln -s ~/.dotfiles/home/.zshrc          ~/.zshrc

# 4. 机器私有的 zsh 配置（密钥 / 代理 / 公司 VPN 等，不进 git）
#    ~/.zshrc 末尾会自动 source 它
cat > ~/.zshrc.local <<'EOF'
# export SOME_API_KEY=...
# proxy_on() { ... }
EOF

# 5. 安装 tmux 插件管理器 TPM
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# 6. 启动 tmux 后按 prefix + I 安装插件（prefix 已改为 C-s）
tmux new -s main
#   然后按: Ctrl-s, 再按 Shift+i
```

Neovim 首次启动会通过 `lazy.nvim` 自动安装插件，等待提示结束即可。`lazy-lock.json` 已在仓库中，`:Lazy restore` 可以锁定到同一版本。

## 日常同步

仓库是通过符号链接生效的，所以**直接修改 `~/.config/<tool>/`（或 `~/.zshrc`）就是在修改仓库**。

```bash
# 拉取远端最新配置
cd ~/.dotfiles
git pull --rebase

# 推送本地修改
cd ~/.dotfiles
git status                # 查看变动
git add -A
git commit -m "调整说明"
git push
```

> 注意：`home/.gitconfig.local`、`home/.zshrc.local`、`local/`、`*.bak`、`*.swp` 等已在 `.gitignore` 中忽略。带有本机敏感信息的内容请放在 `~/.zshrc.local` 或 `local/`，不会被提交。

## 四个工具 + zsh 的入口

- **tmux**：`home/.config/tmux/tmux.conf`
  - `prefix` 改为 `C-s`（不是默认的 `C-b`）
  - 窗口/面板导航使用 Colemak 友好的 `M-n/e/u/i` 方向键
  - 状态栏由 `tmux-status/left.sh`、`tmux-status/right.sh` 生成
  - 插件通过 TPM：`tmux-resurrect`、`tmux-continuum`（自动保存每 5 分钟）
- **WezTerm**：`home/.config/wezterm/wezterm.lua`
  - 配色跟随 macOS 系统外观自动切换（浅色 Catppuccin Latte / 深色 Mocha）
  - `Cmd+点击` 打开链接（即使在 tmux 内也生效）
- **Yazi**：详见 [`home/.config/yazi/guide.markdown`](home/.config/yazi/guide.markdown)
  - 文本默认 nvim；图片/视频/PDF 等走系统默认 App；`<C-o>` 在 Finder 中显示
- **Neovim**：详见 [`home/.config/nvim/guide.markdown`](home/.config/nvim/guide.markdown)
- **zsh**：`home/.zshrc`（可移植：conda/nvm 懒加载、PATH、yazi `y` 包装）；
  机器私有的密钥/代理/VPN 放在不进 git 的 `~/.zshrc.local`，由 `~/.zshrc` 末尾 source。

## 常见维护命令速查

```bash
# tmux 配置热重载
tmux source ~/.config/tmux/tmux.conf

# Neovim 更新/回滚插件
nvim +Lazy
nvim +"Lazy restore"   # 回到 lazy-lock.json 锁定版本

# 把本机一次性修改应用到仓库并推送
cd ~/.dotfiles && git add -A && git commit -m "..." && git push
```
