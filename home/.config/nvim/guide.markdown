# Neovim 操作指南

当前配置里的 `leader` 键是空格，也就是 `<leader>` = `Space`。

## 文件管理

- `Space e`：打开 `yazi`，起点为当前文件所在位置
- `Space -`：打开 `yazi`，起点为当前文件所在位置
- `Space c w`：在 Neovim 当前工作目录打开 `yazi`
- `Ctrl-Up`：恢复上一次的 `yazi` 会话
- 直接执行 `nvim 目录名/`：会进入 `yazi`，不再走 `netrw`

## LSP 与诊断

这些快捷键在 LSP 挂载后生效。

- `g d`：跳转到定义
- `g D`：跳转到声明
- `g i`：跳转到实现
- `g r`：查看引用
- `K`：显示悬浮信息
- `Ctrl-k`：显示函数签名帮助
- `Space r n`：重命名符号
- `Space c a`：代码动作
- `Space D`：跳转到类型定义
- `Space f`：格式化当前缓冲区
- `Space w a`：添加 workspace folder
- `Space w r`：移除 workspace folder
- `Space w l`：列出 workspace folders

诊断相关快捷键全局可用：

- `Space e`：弹出当前诊断信息
- `[ d`：跳到上一个诊断
- `] d`：跳到下一个诊断
- `Space q`：把诊断写入 location list

注意：`Space e` 现在同时被你用于打开 `yazi`。如果 LSP 诊断弹窗比文件管理更常用，建议后面再给其中一个换键位。

## 测试

- `Space t o`：切换 `neotest` 输出面板
- `Space t f`：运行当前文件内的测试
- `Space t n`：运行当前光标位置附近的测试
- `Space t d`：打开当前测试详细输出

## Python

- `Space p y`：保存当前文件并执行 `python3 %`

## Markdown 预览

当前没有单独绑定快捷键，使用命令：

- `:MarkdownPreview`：启动预览
- `:MarkdownPreviewStop`：停止预览
- `:MarkdownPreviewToggle`：切换预览

