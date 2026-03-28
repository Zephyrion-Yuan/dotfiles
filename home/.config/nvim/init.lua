require('config.lazy')
require('lsp')
require('keymaps')
require('colorscheme')
vim.opt.relativenumber = true

require'nvim-treesitter.configs'.setup {
	ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline", "python", "bash"},
  	sync_install = false,
  	auto_install = true,
  	highlight = {
    	enable = true,
        additional_vim_regex_highlighting = false,
  	},
}

vim.api.nvim_set_option("clipboard", "unnamed")

