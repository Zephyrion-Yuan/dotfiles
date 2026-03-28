# Yazi 操作指南

你当前没有自定义 `yazi` 按键文件，所以大部分按键仍然是 `yazi` 默认行为。本配置目前主要改了“文件怎么打开”。

## 当前配置行为

- 文本类文件按回车时，优先走自定义 `edit` opener
- 这个 `edit` opener 会执行 `nvim %s`
- 因此常见的文本文件会默认用 `nvim` 打开

对应配置见 [`yazi.toml`](/Users/yuanhz/.config/yazi/yazi.toml)。

## 常用操作

- `Enter`：打开选中项
- `h`：返回上一级目录
- `l`：进入目录或打开文件
- `j` / `k`：上下移动
- `g`：跳到顶部
- `G`：跳到底部
- `Space`：选择/取消选择文件
- `q`：退出 `yazi`

## 和 Neovim 联动

你现在在 Neovim 里可以这样调用 `yazi`：

- `Space e`：在当前文件位置打开 `yazi`
- `Space -`：在当前文件位置打开 `yazi`
- `Space c w`：在 Neovim 当前工作目录打开 `yazi`
- `Ctrl-Up`：恢复上一次 `yazi` 会话
- `nvim 目录名/`：直接进入 `yazi`

## 说明

如果你后面想给 `yazi` 增加自定义快捷键，需要再创建例如 `keymap.toml` 之类的配置文件；目前这份指南记录的是“当前实际配置”，不是完整默认手册。

