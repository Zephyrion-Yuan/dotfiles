# dotfiles

个人终端环境配置仓库，覆盖 `tmux`、`neovim`、`yazi` 三个工具的配置。

GitHub 对应仓库：<https://github.com/Zephyrion-Yuan/dotfiles.git>

## 目录结构

```
~/.dotfiles/
├── README.md
├── .gitignore
└── home/
    └── .config/
        ├── tmux/       # tmux 配置 + 状态栏脚本
        ├── nvim/       # Neovim 配置（init.lua + lua/ + lazy-lock.json）
        └── yazi/       # Yazi 文件管理器配置
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

# 3. 建立符号链接
mkdir -p ~/.config
ln -s ~/.dotfiles/home/.config/tmux ~/.config/tmux
ln -s ~/.dotfiles/home/.config/nvim ~/.config/nvim
ln -s ~/.dotfiles/home/.config/yazi ~/.config/yazi

# 4. 安装 tmux 插件管理器 TPM
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# 5. 启动 tmux 后按 prefix + I 安装插件（prefix 已改为 C-s）
tmux new -s main
#   然后按: Ctrl-s, 再按 Shift+i
```

Neovim 首次启动会通过 `lazy.nvim` 自动安装插件，等待提示结束即可。`lazy-lock.json` 已在仓库中，`:Lazy restore` 可以锁定到同一版本。

## 日常同步

仓库是通过符号链接生效的，所以**直接修改 `~/.config/<tool>/` 就是在修改仓库**。

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

> 注意：`home/.gitconfig.local`、`local/`、`*.swp` 等已在 `.gitignore` 中忽略。带有本机敏感信息的文件请放在 `local/` 或命名为 `.local`，不会被提交。

## 三个工具各自的入口

- **tmux**：`home/.config/tmux/tmux.conf`
  - `prefix` 改为 `C-s`（不是默认的 `C-b`）
  - 窗口/面板导航使用 Colemak 友好的 `M-n/e/u/i` 方向键
  - 状态栏由 `tmux-status/left.sh`、`tmux-status/right.sh` 生成
  - 插件通过 TPM：`tmux-resurrect`、`tmux-continuum`（自动保存每 5 分钟）
- **Neovim**：详见 [`home/.config/nvim/guide.markdown`](home/.config/nvim/guide.markdown)
- **Yazi**：详见 [`home/.config/yazi/guide.markdown`](home/.config/yazi/guide.markdown)

## 客户端自适应（桌面 / 手机）

tmux 配置会在客户端 attach 时自动检测窗口宽度，在桌面和手机两种显示模式间切换：

- 客户端宽度 ≥ 100 列：**桌面模式**（默认）
  - `mouse on`、面板边框标题、面板滚动条、完整状态栏
- 客户端宽度 < 100 列（例如手机 Termius SSH）：**手机模式**
  - 关闭 `mouse`，把滚动交还给终端原生手势（Termius 默认的上下滑动）
  - 关闭面板边框标题和滚动条，省出纵向空间
  - 简化状态栏：左侧只显示当前会话名，右侧只显示主机名

切换逻辑在 `home/.config/tmux/scripts/detect_client_mode.sh`。也可以在 tmux 内手动覆盖：

```bash
# 手动切到手机模式
bash ~/.config/tmux/scripts/detect_client_mode.sh mobile

# 手动切回桌面模式
bash ~/.config/tmux/scripts/detect_client_mode.sh desktop

# 再次按实际宽度自动判定
bash ~/.config/tmux/scripts/detect_client_mode.sh auto
```

判定阈值可以通过环境变量 `TMUX_MOBILE_MAX_WIDTH` 覆盖（默认 100）。

## 常见维护命令速查

```bash
# tmux 配置热重载
tmux source ~/.config/tmux/tmux.conf

# 查看当前客户端宽度（用来调试手机/桌面判定）
tmux display-message -p '#{client_width}x#{client_height}'

# Neovim 更新/回滚插件
nvim +Lazy
nvim +"Lazy restore"   # 回到 lazy-lock.json 锁定版本

# 把本机一次性修改应用到仓库并推送
cd ~/.dotfiles && git add -A && git commit -m "..." && git push
```
