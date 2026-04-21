# 手机端 Termius + 中继 + 反向 SSH 隧道 + dtach 会话保活

一份**从 0 到可用**的部署参考，目标是：手机（iOS/Android Termius）能随时连上一台内网/NAT 后的服务器，断线重连回到断开前的现场，并且不丢失历史输出。

适用场景：服务器没有公网 IP 或端口受限（家庭宽带、实验室内网、学校机房），但能主动出站到一台廉价 VPS。

---

## 0. 架构总览

```
  ┌──────────────┐    1) SSH (public)      ┌──────────────────┐
  │  iOS/Android │  ────────────────────▶  │   Relay / VPS    │
  │   Termius    │   user = <RELAY_USER>   │  (公网 IP)       │
  └──────────────┘    port = 22 (or X)     │                  │
         │                                 │  listens on      │
         │   2) ProxyJump 后               │  127.0.0.1:22222 │
         │   SSH 到 127.0.0.1:22222        │  (由反向隧道建立)│
         ▼                                 └─────────┬────────┘
  ┌──────────────────────────────────────────────────┘
  │                         (本地端口转发)
  ▼
  ┌──────────────────────────────┐    3) autossh  ┌──────────────────┐
  │       Target server          │ ◀────────────  │   Relay / VPS    │
  │    (NAT / 内网)              │   -R tunnel    │                  │
  │  user = <SERVER_USER>        │ ─────────────▶ │                  │
  │  sshd :22                    │                 └──────────────────┘
  │                              │
  │  4) dtach session +          │
  │     script(1) logging        │
  │  ~/.dtach/<name>.sock        │
  │  ~/.dtach/logs/<name>-*.log  │
  └──────────────────────────────┘
```

四条独立但需要一起就位的链路：

1. **手机 → 中继**：公网 SSH，身份是手机的公钥装在中继 `<RELAY_USER>` 的 `authorized_keys`。
2. **中继 → 服务器**：手机侧用 `ProxyJump` 把第二跳指向中继内部的 `127.0.0.1:22222`，落在服务器的 sshd 上。
3. **服务器 → 中继**：`autossh` 持久反向隧道，把中继的 22222 端口映射回服务器的 22。由 systemd 管理，开机自启、掉线自恢复。
4. **服务器内**：`dtach` + `script` 托管 shell，断连不杀进程、不丢输出。

---

## 1. 先决条件与占位符

一张表统一口径，后面 `$()` 都按这张表替换：

| 占位符 | 含义 | 示例 |
|---|---|---|
| `<RELAY_HOST>` | 中继公网 IP 或域名 | `203.0.113.10` |
| `<RELAY_PORT>` | 中继 sshd 端口 | `22`（默认；改非标端口更安全） |
| `<RELAY_USER>` | 中继上给隧道用的账户 | `relay` |
| `<SERVER_USER>` | 目标服务器上的登录账户 | `yuan` |
| `<REMOTE_PORT>` | 反向隧道在中继上暴露的本地端口 | `22222` |
| `<SESSION_NAME>` | dtach session 名，也决定 log 文件名 | `main`、`train`、`watch` |

硬性要求：

- 中继：任何能跑 OpenSSH 服务端的 Linux VPS 都行，1 vCPU / 512 MB 内存足够。
- 服务器：Linux，有出站网络，有 `openssh-server`、`autossh`、`dtach`、`util-linux`（`script`）。
- 手机：Termius（iOS 或 Android）。

---

## 2. 中继服务器（relay）部署

### 2.1 装好系统 + sshd

拿到 VPS 之后（以 Debian/Ubuntu 为例）：

```bash
# 以 root 或能 sudo 的账户登录中继，全部命令在 relay 上执行
sudo apt update
sudo apt install -y openssh-server
sudo systemctl enable --now ssh
```

### 2.2 创建专用中继用户，只允许端口转发

**关键安全决策**：中继账户绝不应该有 shell 访问权限，只允许建立端口转发。一把泄露的手机 key 最坏只能让人借用隧道，拿不到 shell。

```bash
# 创建 <RELAY_USER>，拒绝登录 shell，保留 SSH 能力
sudo useradd -m -s /usr/sbin/nologin <RELAY_USER>
sudo mkdir -p /home/<RELAY_USER>/.ssh
sudo chown <RELAY_USER>:<RELAY_USER> /home/<RELAY_USER>/.ssh
sudo chmod 700 /home/<RELAY_USER>/.ssh
sudo -u <RELAY_USER> touch /home/<RELAY_USER>/.ssh/authorized_keys
sudo chmod 600 /home/<RELAY_USER>/.ssh/authorized_keys
```

> `nologin` shell + 下面 sshd 侧的 `ForceCommand` 组合起来形成双重限制：即便手机带了 `-t` 也没法 spawn shell。

### 2.3 sshd 配置：允许反向隧道，拒绝 shell/SFTP

编辑 `/etc/ssh/sshd_config.d/90-relay.conf`（新建）：

```conf
# Match block 针对中继账户专门收紧权限
Match User <RELAY_USER>
    AllowTcpForwarding yes
    PermitOpen none
    GatewayPorts no
    X11Forwarding no
    AllowAgentForwarding no
    PermitTTY no
    ForceCommand /usr/sbin/nologin
```

含义：
- `AllowTcpForwarding yes`：允许 `-R` 建立反向隧道（核心功能）。
- `GatewayPorts no`：反向端口只绑 `127.0.0.1`，公网拿不到（**重要**：只有进到中继 shell 内部才能 `ssh 127.0.0.1:<REMOTE_PORT>`，这是安全边界）。
- `PermitTTY no` + `ForceCommand nologin`：杜绝拿 shell。
- `PermitOpen none`：这一条会挡住 `-L` 正向转发。如果你希望手机 side 不借用中继做正向代理，保留 `none`；确实有需要再改成 `PermitOpen 127.0.0.1:<REMOTE_PORT>` 之类精确白名单。

重载 sshd：

```bash
sudo sshd -t && sudo systemctl reload ssh
```

### 2.4（可选但强烈推荐）基础硬化

- 改 sshd 监听端口为非默认（修改 `/etc/ssh/sshd_config` 的 `Port`，别忘了 firewall 放行）。
- 装 `fail2ban`：`sudo apt install -y fail2ban`，开机自启，默认 `sshd` jail 够用。
- 公网账户禁止密码登录：`PasswordAuthentication no`（应该是默认）。

### 2.5 中继侧完成

这时中继的状态是：
- sshd 在监听。
- `<RELAY_USER>` 存在、authorized_keys 为空、能接反向隧道。
- 公网 22（或你选的端口）通；27822/443 之类再议。

---

## 3. 服务器 → 中继的反向隧道

以下命令全部在**目标服务器**上以 `<SERVER_USER>` 身份执行。

### 3.1 装 autossh

```bash
sudo apt install -y autossh openssh-client
```

### 3.2 生成服务器的 SSH key，装到中继

服务器需要一把**自己的** key 用来开隧道（这把 key 和手机 key 互不干涉）：

```bash
ssh-keygen -t ed25519 -f ~/.ssh/relay_tunnel -N '' -C "server-tunnel-$(hostname)"
```

把公钥内容拷到中继上追加到 `<RELAY_USER>` 的 authorized_keys。可以用 `ssh-copy-id` 或手动：

```bash
# 方式 A: 如果中继允许 root 登录，直接 ssh-copy-id
ssh-copy-id -i ~/.ssh/relay_tunnel.pub -p <RELAY_PORT> <RELAY_USER>@<RELAY_HOST>
# 这一步会失败，因为 <RELAY_USER> 是 nologin。改走方式 B：

# 方式 B: 在中继上用有权限的账户粘贴
# 本机 copy 公钥：
cat ~/.ssh/relay_tunnel.pub
# 登中继，切到 root/sudoer，追加
echo 'ssh-ed25519 AAAA... server-tunnel-...' | sudo tee -a /home/<RELAY_USER>/.ssh/authorized_keys
sudo chown <RELAY_USER>:<RELAY_USER> /home/<RELAY_USER>/.ssh/authorized_keys
```

**加固这把 tunnel key 的权限**：只能用于建立特定端口转发，不允许开 shell、不允许跳别的端口。在该 authorized_keys 行前面加 options：

```
restrict,port-forwarding,permitopen="127.0.0.1:<REMOTE_PORT>",command="echo 'tunnel-only'" ssh-ed25519 AAAA... server-tunnel-...
```

含义：
- `restrict` 是 OpenSSH 7.2+ 的伞选项：禁用 X11、agent、TTY、shell、port 开放，再用后续选项开放所需能力。
- `port-forwarding` 反向启用转发。
- `permitopen` 明确限定只能转到 `127.0.0.1:<REMOTE_PORT>`。
- `command` 即使 autossh 试图跑点什么也只会输出那行字。

### 3.3 手动验证一次隧道

```bash
# 先做一次 interactive 的 -R 连接（autossh 不要）
ssh -i ~/.ssh/relay_tunnel -p <RELAY_PORT> \
    -o StrictHostKeyChecking=accept-new \
    -o ExitOnForwardFailure=yes \
    -N -R 127.0.0.1:<REMOTE_PORT>:127.0.0.1:22 \
    <RELAY_USER>@<RELAY_HOST>
```

`-N` = 不执行命令（只建隧道），`-R HOST:PORT:LOCALHOST:LOCALPORT` = 让中继监听 `HOST:PORT`，连进来的流量转到服务器的 `LOCALHOST:LOCALPORT`。

**并行**在**另一个终端**确认中继上的端口在监听：

```bash
# 在服务器上通过 <RELAY_USER> 之外的账户登中继
ssh <你的中继登录账户>@<RELAY_HOST>
ss -lntp | grep <REMOTE_PORT>   # 应看到 127.0.0.1:<REMOTE_PORT> LISTEN
```

再在中继上验证能走隧道回到服务器：

```bash
# 在中继的 shell 里
ssh -p <REMOTE_PORT> <SERVER_USER>@127.0.0.1
# 此时会要求服务器 <SERVER_USER> 的凭据（另一把 key 或密码）
# 暂时先 Ctrl-C 退出，下面第 4 步再给手机装 key
```

确认通过，回到服务器，Ctrl-C 终止手动 `-N -R` 连接，转成 systemd 托管。

### 3.4 autossh + systemd 托管

创建 `/etc/systemd/system/relay-tunnel.service`：

```bash
sudo tee /etc/systemd/system/relay-tunnel.service >/dev/null <<'EOF'
[Unit]
Description=Persistent reverse SSH tunnel to relay
After=network-online.target
Wants=network-online.target

[Service]
User=<SERVER_USER>
Environment="AUTOSSH_GATETIME=0"
ExecStart=/usr/bin/autossh -M 0 -N \
  -p <RELAY_PORT> \
  -i /home/<SERVER_USER>/.ssh/relay_tunnel \
  -o ExitOnForwardFailure=yes \
  -o ServerAliveInterval=15 \
  -o ServerAliveCountMax=3 \
  -o StrictHostKeyChecking=accept-new \
  -o IdentitiesOnly=yes \
  -R 127.0.0.1:<REMOTE_PORT>:127.0.0.1:22 \
  <RELAY_USER>@<RELAY_HOST>
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

关键 flag 说明：

| flag | 作用 |
|---|---|
| `-M 0` | 禁用 autossh 自己的"monitoring port"（用 `ServerAliveInterval` 代替，简洁可靠） |
| `-N` | 不执行远端命令，纯隧道 |
| `AUTOSSH_GATETIME=0` | 首次连接失败也一直重试，适合开机抢跑阶段 |
| `ExitOnForwardFailure=yes` | 一旦 `-R` 绑端口失败就退出，让 systemd 重启（否则会"半成功连上但没隧道") |
| `ServerAliveInterval=15` / `CountMax=3` | 客户端 45 秒未收到响应就放弃，autossh/systemd 再拉起来 |
| `StrictHostKeyChecking=accept-new` | 首次连接自动接受中继指纹（已经 TOFU 过就拒变更） |
| `IdentitiesOnly=yes` | 只用 `-i` 指定的这把 key，避免 agent 里其他 key 乱尝试 |

启用并看状态：

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now relay-tunnel
sudo systemctl status relay-tunnel --no-pager
```

**验证**：

```bash
# 服务器上
ps -ef | grep '[a]utossh'                              # autossh 跑着
ss -tnp 2>/dev/null | grep ':<RELAY_PORT>'             # 到中继的连接 ESTABLISHED

# 中继上
ss -lntp | grep 127.0.0.1:<REMOTE_PORT>                # LISTEN on 22222
```

---

## 4. 手机端的 SSH key

### 4.1 在 Termius 生成 key

Termius → Settings → Keychain → `+` **Generate Key**
- Type: **ED25519**
- Name: 能认出来的，例如 `iphone-<SERVER_USER>`
- 生成后点这把 key → `Copy Public Key`。

### 4.2 把公钥分别装到中继和服务器

**中继**（允许 `<RELAY_USER>` 接手机 SSH）：

```bash
# 在中继上，用 sudoer 账户
echo 'ssh-ed25519 AAAA... iphone-<SERVER_USER>' \
  | sudo tee -a /home/<RELAY_USER>/.ssh/authorized_keys
```

> 手机的公钥**不需要**加 `restrict` 之类 options——它需要正常开 TCP 转发（`-J` 就是基于这个），加限制反而过犹不及。手机 key 的安全边界在"key 只装在手机 Termius keychain 里、不导出、Secure Enclave 保护"这一层。

**服务器**（允许手机最终落地的账户登录）：

```bash
# 在服务器上
echo 'ssh-ed25519 AAAA... iphone-<SERVER_USER>' >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

---

## 5. Termius 配置

### 5.1 添加中继 host

Termius → Hosts → `+` → New Host：

| 字段 | 值 |
|---|---|
| Alias | `relay` |
| Hostname | `<RELAY_HOST>` |
| Port | `<RELAY_PORT>` |
| Username | `<RELAY_USER>` |
| Key | （刚才生成的 `iphone-<SERVER_USER>`） |

保存。**先单独连一次**，确认 key 对——因为 `<RELAY_USER>` 是 nologin，连上后会看到一行 `tunnel-only` 或连接立刻断（这都属于**登进来成功了**）。重要的是没报 `Permission denied`。

### 5.2 添加服务器 host（带 ProxyJump）

再 `+` → New Host：

| 字段 | 值 |
|---|---|
| Alias | 任取，例如 `myserver` |
| Hostname | `127.0.0.1` |
| Port | `<REMOTE_PORT>` |
| Username | `<SERVER_USER>` |
| Key | `iphone-<SERVER_USER>` |
| **Jump Host / ProxyJump** | `relay` |

保存，**裸连一次**（先不加 startup 命令）。预期结果：看到服务器的 bash 提示符。`exit` 退出。

### 5.3（可选）再添加多个 host 共享同一跳板

想跑多个独立 dtach session（比如 `logs` 和 `train`），直接复制 `myserver`，改 Alias 和后面的 startup command 即可。Jump host 仍然是 `relay`。

---

## 6. 服务器端会话保活：dtach + script

到这一步你已经能 SSH 进服务器了，但**断线会丢现场**、**老输出全没**。下面这套把两个问题一次性解掉。

### 6.1 安装依赖

```bash
sudo apt install -y dtach util-linux
```

`util-linux` 里带 `script(1)`，99% 的 Linux 默认就有。

### 6.2 部署 `mobile-attach` wrapper

推荐：克隆本仓库并 symlink（后续 `git pull` 就能跟进脚本更新）：

```bash
git clone https://github.com/Zephyrion-Yuan/dotfiles.git ~/.dotfiles
mkdir -p ~/.local/bin ~/.dtach
ln -sf ~/.dotfiles/home/.local/bin/mobile-attach ~/.local/bin/mobile-attach
# 确认 ~/.local/bin 在 PATH（Debian/Ubuntu 默认已经在）
echo 'case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH";; esac' >> ~/.bashrc
```

不想引入整套 dotfiles 也行——`mobile-attach` 是单文件 bash 脚本（约 170 行），直接把 `home/.local/bin/mobile-attach` 拷到 `~/.local/bin/` 并 `chmod +x` 一样跑。

### 6.3 Termius 的 Startup Snippet

回到 Termius 里 `myserver` 那个 host 的编辑页，找 **Startup Snippet** / **Initial Command** 字段（iOS 版在"Advanced"分组里），填：

```
~/.local/bin/mobile-attach <SESSION_NAME>
```

例：`~/.local/bin/mobile-attach main`。

之后每次连接：
- 首次连：看到 `Creating new session "main".` + `Logging session to ~/.dtach/logs/main-<ts>.log`，进入 bash。
- 断线重连：看到 `Session "main" already exists, attaching.`，直接回到断开前的 shell，`watch`/`top`/`vim` 会被 SIGWINCH 重绘当前画面。

### 6.4 `mobile-attach` 做了什么

精简叙述，配细节看脚本源码：

1. **Socket 生命周期判断**：`ss -lxH` 查 `~/.dtach/<name>.sock` 是不是 LISTEN 态（半死 server 绕不过去，传统 `fuser` 会误判）。
2. **存活 → 纯接入**：`exec dtach -A <sock> -r winch -z -E bash -l`。`-r winch` 让附着时自动发 SIGWINCH，`watch` 这种只响应窗口变化信号的程序会立刻重绘。
3. **不存活 → 新建 + 日志**：清理僵尸 socket → 生成带时间戳的日志文件 → 用 `script -qfe -c "bash -l" <logfile>` 包裹 shell，全程 PTY 旁录。`script` 的生死严格绑定在 dtach server 上，bash 一 exit 就一层层收尾，不会遗漏进程。
4. **日志滚动**：每个 session 名保留最近 10 份（`MOBILE_ATTACH_KEEP_LOGS` 覆盖），旧的在下次创建时自动删。
5. **权限**：`~/.dtach/logs/` 为 700、每份日志为 600。

关键命令备忘：

```bash
mobile-attach                        # 交互菜单：列出存活 session 选一个
mobile-attach <name>                 # 不存在就建、存在就接，skip 菜单
tail -f ~/.dtach/logs/<name>.current.log   # 在另一个连接里实时跟日志
less -R ~/.dtach/logs/<name>-*.log          # 回放某次 session
export MOBILE_ATTACH_NOLOG=1         # 单次不记日志
export MOBILE_ATTACH_KEEP_LOGS=30    # 每 name 保留 30 份

# 销毁一个 session
fuser -k ~/.dtach/<name>.sock
rm -f ~/.dtach/<name>.sock
```

---

## 7. 端到端验证

### 7.1 建链路检查

```bash
# 服务器上
systemctl is-active relay-tunnel                   # active
ps -ef | grep '[a]utossh'                          # 有进程
ss -tnp 2>/dev/null | grep <RELAY_HOST>            # ESTABLISHED

# 中继上
ss -lntp | grep 127.0.0.1:<REMOTE_PORT>            # LISTEN

# 中继上往回连（验证隧道可用）
ssh -p <REMOTE_PORT> <SERVER_USER>@127.0.0.1 'hostname && date'
```

三条全过就是链路 OK。

### 7.2 手机侧行为回归

用 Termius 连 `myserver`：

1. 看到 `Creating new session "main".` → 进入 shell。
2. 跑 `while sleep 2; do date; done`。
3. Termius 顶栏"断开"或者直接杀 app。
4. 重新打开 Termius，再点 `myserver`。
5. 应当看到 `Session "main" already exists, attaching.` + 继续滚动的 `date` 输出（中间断开那几秒也能在 `~/.dtach/logs/main.current.log` 里找到）。
6. Ctrl-C 停住，`exit` 出 shell → dtach session 退出 → 下次连接是一个全新的 `main`。

### 7.3 历史日志回放

在电脑上（或另一条手机连接里）：

```bash
ssh <任意能登上服务器的方式> \
  less -R ~/.dtach/logs/main.current.log    # 看当前 session 历史
ls ~/.dtach/logs/                            # 浏览所有 session 的日志
```

---

## 8. 故障排查表

| 症状 | 排查 |
|---|---|
| Termius 连 `relay` 就失败 | 公钥没装到中继 `<RELAY_USER>/.ssh/authorized_keys`；或 sshd_config 的 Match 块打错 |
| `relay` 通，`myserver` 连不上 | (a) 反向隧道没起（看 `systemctl status relay-tunnel` 和中继上的 `ss -lntp`）；(b) 手机公钥没装到服务器 `<SERVER_USER>/.ssh/authorized_keys`；(c) 服务器 sshd 没起 |
| 隧道频繁掉线 | 中继/服务器任一侧的 `ServerAliveInterval` 太长；中间 NAT 会话表短。设 15–30 秒 |
| 反向端口占用 / `ExitOnForwardFailure` | 中继上有旧连接遗留，或有别人也拿同一个 `<REMOTE_PORT>`。`ss -lntp` 查，`pkill -f sshd.*22222` 清或换端口 |
| `mobile-attach main` 每次都 Creating | 你的 dtach session 真的死了——看 `ls ~/.dtach/logs/`，旧的日志还在；可能 `exit` 退出过。确认断连靠关 Termius app 而不是 Ctrl-D |
| 重连看不到 watch/top 画面 | 老 session 是旧版 mobile-attach 建的、没有 `-r winch`。杀掉重建一次即可 |
| 隧道慢 / 手机侧延迟大 | 中继地理位置太远；考虑换个近点的 VPS。SSH 本身对 RTT 极敏感（每个按键往返一次） |

---

## 9. 日常运维

- **重启整条链路**：服务器上 `sudo systemctl restart relay-tunnel`，再让手机重连。
- **查看哪些 session 还活着**：服务器上 `ls ~/.dtach/*.sock && ss -lx | grep dtach`。
- **跨设备同步 `mobile-attach`**：它就在这个 dotfiles repo 里。新机器部署时 clone + symlink 一遍即可。
- **换手机 / 多手机**：给新手机生成新 key，追加到 `<RELAY_USER>` 和 `<SERVER_USER>` 的 authorized_keys；旧 key 从 authorized_keys 删掉即吊销。
- **日志磁盘占用**：调小 `MOBILE_ATTACH_KEEP_LOGS`，或者定期 `rm ~/.dtach/logs/*-20241*.log` 清历史。

---

## 10. 可选强化

- **中继用 WireGuard 代替 autossh**：对隧道有更细粒度控制，适合多服务器；代价是运维复杂度上一档。
- **服务器 → 中继走 mosh**：不适用，mosh 解决的是不稳定网络下的"客户端"体验，我们这里不稳的是"服务器 → 中继"出站段，应该继续走 autossh。
- **限制 `<SERVER_USER>` 只能跑 `mobile-attach`**：在 `~/.ssh/authorized_keys` 里对手机 key 加 `command="~/.local/bin/mobile-attach main",restrict`。代价：想开别的 shell 需要另外装一把 key，或新建一个 host profile 用不带 startup snippet 的配置。安全收益对多数个人场景属于过度设计。
- **多手机的会话隔离**：每台手机用不同的 `<SESSION_NAME>`（`mobile-attach iphone`、`mobile-attach ipad`）。它们完全独立，互不影响各自的现场。

---

## 附：最小可行代码速览

如果某台服务器你只想把关键文件搬过去、不要整个 dotfiles，下面三样就够了。

### 服务器 systemd unit

见 §3.4，把占位符换掉写进 `/etc/systemd/system/relay-tunnel.service`。

### `~/.local/bin/mobile-attach`

从这个 repo：`home/.local/bin/mobile-attach`。单文件拷贝即可。

### Termius Startup Snippet

```
~/.local/bin/mobile-attach main
```

就这么多。所有"体验层面的打磨"（LISTEN 态探活、日志滚动、SIGWINCH 重绘、僵尸清理）都封装在 `mobile-attach` 里，服务器端不需要额外 shell rc 改动。
