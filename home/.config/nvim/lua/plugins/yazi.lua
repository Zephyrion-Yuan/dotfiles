---@type LazySpec
return {
  "mikavilpas/yazi.nvim",
  event = "VeryLazy",
  init = function()
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
  end,
  keys = {
    {
      "<leader>e",
      function()
        require("yazi").yazi()
      end,
      desc = "Open yazi at the current file",
    },
    {
      "<leader>-",
      function()
        require("yazi").yazi()
      end,
      desc = "Open yazi at the current file",
    },
    {
      "<leader>cw",
      function()
        require("yazi").yazi(nil, vim.fn.getcwd())
      end,
      desc = "Open yazi in nvim's working directory",
    },
    {
      "<c-up>",
      function()
        require("yazi").toggle()
      end,
      desc = "Resume the last yazi session",
    },
  },
  ---@type YaziConfig
  opts = {
    open_for_directories = true,
  },
}
