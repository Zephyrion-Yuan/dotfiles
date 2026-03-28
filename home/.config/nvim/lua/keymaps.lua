-- Pytest
-- 设置选项
local opts = { noremap = true, silent = true }

-- 打开和关闭 Neotest 输出面板
vim.keymap.set("n", "<leader>to", ":lua require('neotest').output_panel.toggle()<CR>", opts)

-- 运行当前文件的所有测试
vim.keymap.set("n", "<leader>tf", ":lua require('neotest').run.run(vim.fn.expand('%'))<CR>", opts)

-- 运行光标所在位置的最近测试
vim.keymap.set("n", "<leader>tn", ":lua require('neotest').run.run()<CR>", opts)

-- 打开当前测试的详细输出
vim.keymap.set("n", "<leader>td", ":lua require('neotest').output.open({ enter = true })<CR>", opts)


-- Run python
function RunCurrentPythonFile()
  vim.cmd('w')           -- 保存当前文件
  vim.cmd('!python3 %')  -- 执行当前文件
end

vim.keymap.set('n', '<leader>py', ':lua RunCurrentPythonFile()<CR>', { noremap = true, silent = true })
