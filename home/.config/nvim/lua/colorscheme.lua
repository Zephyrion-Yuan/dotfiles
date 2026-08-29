-- Nightfox's light variant.
vim.opt.background = "light"
local colorscheme = "dayfox"

local is_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)
if not is_ok then
    vim.notify('colorscheme ' .. colorscheme .. ' not found!')
    return
end
