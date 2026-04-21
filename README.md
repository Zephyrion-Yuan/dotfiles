# dotfiles

个人终端环境配置仓库，覆盖 `tmux`、`neovim`、`yazi` 三个工具的配置，以及手机 Termius SSH 用的 `mobile-attach` 会话包装器。

GitHub：<https://github.com/Zephyrion-Yuan/dotfiles>

> **与 [`mobile-relay-setup`](https://github.com/Zephyrion-Yuan/mobile-relay-setup) 的分工**：本仓库是"clone + symlink 即部署"型 dotfile 集合，只放用户态可直接生效的文件。手机端那套完整链路（中继 VPS 硬化、autossh + systemd 反向隧道、Termius ProxyJump 配置、一键 installer 脚本）因为需要 sudo + 在多台机器上布置，分到了 `mobile-relay-setup` repo。两个 repo 共同维护 `mobile-attach`：本仓库是上游，另一个 vendored 一份手工同步。

## 目录结构

```
~/.dotfiles/
├── README.md
├── .gitignore
└── home/
    ├── .config/
    │   ├── tmux/       # tmux 配置 + 状态栏脚本 + 客户端自适应脚本
    │   ├── nvim/       # Neovim 配置（init.lua + lua/ + lazy-lock.json）
    │   └── yazi/       # Yazi 文件管理器配置
    └── .local/
        └── bin/
            └── mobile-attach   # 手机端 dtach 会话包装器（见下文）
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

# 6. （可选）手机端 dtach 会话持久化
sudo apt install -y dtach util-linux
mkdir -p ~/.local/bin ~/.dtach
ln -sf ~/.dotfiles/home/.local/bin/mobile-attach ~/.local/bin/mobile-attach
# 完整链路（中继/隧道/Termius）见 mobile-relay-setup 仓库；详细用法见下文 §手机端 mobile-attach。
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

频繁切换客户端后如果状态栏、面板边框、面板布局看起来"卡在旧尺寸上"，按 `prefix C-r` 可以强制重绘：清掉 `@ui_mode` 守卫、删除状态栏缓存、重跑一次自动检测，然后向每个已连接的客户端发 `refresh-client`，并按当前布局做一次 `select-layout` 让面板重新贴边。

## 手机端 mobile-attach（dtach + script 会话包装器）

> **只想看"怎么把新服务器接进手机"的人**：直接去 [`mobile-relay-setup`](https://github.com/Zephyrion-Yuan/mobile-relay-setup)，里面有架构图、两条 installer 命令和 Termius 侧的完整步骤。下面这一节讲的是 `mobile-attach` 脚本本身的行为——上游实现就在这个 repo，要改也是改这里。

tmux 在手机 Termius 上的根本困扰是 alternate screen——一进 tmux，Termius 就识别为 alt-screen TUI，把单/双指上下滑动合成成方向键 / `PageUp`、`PageDown`，本地 scrollback 失效。手机轻度使用（看 logs、跑命令、断线复连）不需要多窗口/多面板，可以**直接绕开 tmux**，改用 [`dtach`](https://dtach.sourceforge.net/)：只做"进程保活 + detach/attach"，不切 alt-screen，Termius 的本地滚动条/手势全程可用。

`home/.local/bin/mobile-attach` 是一层 wrapper：

- 列出 `~/.dtach/*.sock` 里**真正存活**的 dtach session——优先用 `ss -lxH` 查 unix socket 的 LISTEN 状态（这是最严格的存活判定，半死的 dtach server 绕不过去），无 `ss` 时退回 `fuser`/`lsof`。
- 顺手把僵尸 socket 文件删掉——dtach server 被 `kill -9` 或机器宕机后会留下死 socket 文件，菜单里不会再看到。
- 默认按回车 = 接最新一条 session（绝大多数情况就是上次断开的那个）；输入数字接旧 session；`n` 新建；`q` 退出。
- session 名字 sanitize 成 `[A-Za-z0-9._-]`。
- 也可以 `mobile-attach <name>` 直接跳过菜单，"存在则接入，不存在则新建"——这是 Termius startup snippet 的推荐写法。

### 新建 socket 触发条件 / 复用 vs 新建

只有以下三种路径会在 `~/.dtach/` 下产生**新的** `.sock` 文件，其它任何操作都是 attach 到已有 socket：

| 触发方式 | 新建条件 | 行为 |
|---|---|---|
| 菜单一进来就显示 `No live dtach sessions` | 目录被 sweep 后没有任何存活 session | 提示 `Name for new session [main]:`，回车默认 `main` |
| 菜单选 `n` | 输入的名字**不**对应一个存活的 socket | 打印 `Creating new session "<name>".` |
| `mobile-attach <name>` | 同上 | 打印 `Creating new session "<name>".` |

如果输入的名字命中了一个**存活**的 socket（在菜单的 `n` 里输入了已有名字，或 `mobile-attach <name>` 撞名），脚本会显式打印 `Session "<name>" already exists, attaching.` 而不是默默 dtach 进去——这层提示是为了避开 `dtach -A` 默认"找不到才创建、找到就 attach"那条隐式语义带来的误会。

如果输入的名字命中的是一个**僵尸** socket（文件存在但 server 已死），脚本会先 `rm -f` 掉再创建新的——所以同名"僵尸→新建"是允许且无声的，不会被误以为接入旧数据。

本机安装步骤已经收录在上面 `§安装` 的第 6 步（`apt install dtach util-linux` + `mkdir` + `ln`）。Termius 侧把目标 host 的 **Startup Snippet / Initial Command** 设成下面任一条：

```bash
~/.local/bin/mobile-attach main          # 最常用：固定接入 main session，零按键
~/.local/bin/mobile-attach               # 无参：每次进菜单自己挑
```

固定名字的好处是断线重连零按键就能回到上次现场（包括跑了一半的 Claude Code、`tail -f`、训练任务等）。中继 / 隧道 / Termius host 配置见 [`mobile-relay-setup`](https://github.com/Zephyrion-Yuan/mobile-relay-setup)。

手动管理小抄：

```bash
mobile-attach                                # 菜单式进入
mobile-attach <name>                         # 跳过菜单，存在则接入/不存在则新建
dtach -A ~/.dtach/<name>.sock -z -E bash -l  # 等价的纯 dtach 写法
dtach -a ~/.dtach/<name>.sock -E             # 只接入（不存在则报错）
ls -lt ~/.dtach/                             # 看现有 socket
# detach: 直接关掉 SSH 连接即可（dtach 设了 -E 关掉了 ^\ 转义键）

# 显式销毁一个 session
sock=~/.dtach/<name>.sock
fuser -k "$sock" && rm -f "$sock"            # 杀 server + 立刻清理 socket 文件
```

### 自动日志（解决 dtach 64KB 回放缓冲不够大的问题）

每次 `mobile-attach` **新建** session 时（命中已存在的 live session 时不会重复建日志），会在 `~/.dtach/logs/<name>-<ISO时间>.log` 留一份完整 PTY 旁录：

- 实现方式：在 dtach 的 server 命令里套一层 `script -qfe -c "bash -l" <log>`，因此 `script` 的生命周期严格绑在 dtach server 上——`bash` 退出 → `script` 退出 → dtach server 收工 → socket 清理 → 日志收尾，没有遗留进程。
- `~/.dtach/logs/<name>.current.log` 是个符号链接，永远指向对应 session 当前活跃的那份日志，方便 `less -R` / `tail -f`。
- `-f` 每次写都 flush，所以断电/崩溃不会丢最近几秒的内容；`tail -f` 实时跟随也没问题。
- 默认每个 session 名只保留**最近 10 份**日志（旧的自动删），用 `MOBILE_ATTACH_KEEP_LOGS` 环境变量覆盖。
- 完全不想记日志：`export MOBILE_ATTACH_NOLOG=1` 即可跳过 `script` 那一层。
- 目录权限：`~/.dtach/logs/` 为 `700`、每份日志为 `600`，只有你能读——因为终端输出可能含敏感字符。

查看历史输出的典型用法：

```bash
# 在另一个连接里实时跟当前 session 的输出
tail -f ~/.dtach/logs/main.current.log

# 完整回放某次 session（像录像一样，ANSI 会被终端解释）
less -R ~/.dtach/logs/main-20260421T143000.log

# 只搜文本内容（剔除控制序列）
grep -a "some keyword" ~/.dtach/logs/main-*.log

# 删除某个 name 的所有历史日志
rm ~/.dtach/logs/name-*.log ~/.dtach/logs/name.current.log
```

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
