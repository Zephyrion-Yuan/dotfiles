return {
    	-- ColorThemes
	"tanvirtin/monokai.nvim",
	-- Vscode-like pictograms
	{
		"onsails/lspkind.nvim",
		event = { "VimEnter" },
	},
	-- Auto-completion engine
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"lspkind.nvim",
			"hrsh7th/cmp-nvim-lsp", -- lsp auto-completion
			"hrsh7th/cmp-buffer", -- buffer auto-completion
			"hrsh7th/cmp-path", -- path auto-completion
			"hrsh7th/cmp-cmdline", -- cmdline auto-completion
		},
		config = function()
			require("config.nvim-cmp")
		end,
	},
	-- Code snippet engine
	{
		"L3MON4D3/LuaSnip",
		version = "v2.*",
	},
	-- LSP manager
	"williamboman/mason.nvim",
	"williamboman/mason-lspconfig.nvim",
	"neovim/nvim-lspconfig",
	-- Treesitter
	{
		'nvim-treesitter/nvim-treesitter',
		run = ':TSUpdate'
	},
	-- markdown-preview
	{
    		"iamcco/markdown-preview.nvim",
    		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" 			},
    		ft = { "markdown" },
    		build = function() vim.fn["mkdp#util#install"]() end,
	}

}
