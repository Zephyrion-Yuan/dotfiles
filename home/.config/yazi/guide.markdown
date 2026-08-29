# Yazi 操作指南

大部分按键仍然是 `yazi` 默认行为；自定义部分主要是文件打开方式和两个系统集成快捷键。

## 当前配置行为

- 文本类文件按回车时，优先走自定义 `edit` opener
- 这个 `edit` opener 会执行 `nvim %s`
- 因此常见的文本文件会默认用 `nvim` 打开
- `Ctrl-o`：在 Finder 中显示当前文件（macOS）
- `F`：使用操作系统默认应用打开

对应配置见 [`yazi.toml`](yazi.toml) 和 [`keymap.toml`](keymap.toml)。

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

这份指南记录的是当前实际配置，不是完整默认手册。
