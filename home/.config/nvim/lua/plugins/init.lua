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
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("config.treesitter")
		end,
	},
	-- markdown-preview
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		ft = { "markdown" },
		init = function()
			vim.g.mkdp_filetypes = { "markdown" }
			vim.g.mkdp_echo_preview_url = 1
		end,
		build = function(plugin)
			local install_cmd = nil
			if vim.fn.executable("npm") == 1 then
				install_cmd = { "npm", "install", "--no-fund", "--no-audit" }
			elseif vim.fn.executable("yarn") == 1 then
				install_cmd = { "yarn", "install" }
			end

			if install_cmd then
				local result = vim.system(install_cmd, {
					cwd = plugin.dir .. "/app",
					text = true,
				}):wait()
				if result.code == 0 then
					return
				end

				vim.notify(
					"markdown-preview.nvim app dependency install failed, falling back to mkdp#util#install()",
					vim.log.levels.WARN
				)
			end

			vim.fn["mkdp#util#install"]()
		end,
	}

}
