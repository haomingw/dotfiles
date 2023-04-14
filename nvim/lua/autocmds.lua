-- Auto commands
-- strip trailing whitespaces on saving
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  pattern = "*",
  command = [[%s/\s\+$//e]],
})
local vimrc = vim.api.nvim_create_augroup("vimrc", { clear = true })

-- Highlight on yank
local yankGrp = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Hightlight selection on yank",
  group = yankGrp,
  callback = function()
    vim.highlight.on_yank { higroup = "IncSearch", timeout = 100 }
  end,
})

-- Filetypes
vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
  group = vimrc,
  pattern = {"*.ptest"},
  command = "set filetype=json",
})

-- Insert mode
vim.api.nvim_create_autocmd({"InsertEnter"}, {
  group = vimrc,
  command = "set norelativenumber",
})

vim.api.nvim_create_autocmd({"InsertLeave"}, {
  group = vimrc,
  command = "set relativenumber",
})

-- Restore cursor style & position
vim.api.nvim_create_autocmd({"VimLeave", "VimSuspend"}, {
  group = vimrc,
  command = "set guicursor=a:hor20",
})

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = vimrc,
  pattern = "*",
  command = [[if line("'\"") <= line("$") | execute "normal! g`\"" | endif]],
})
