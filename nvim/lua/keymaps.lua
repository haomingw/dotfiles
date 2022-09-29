local opts = { noremap = true }

local term_opts = { silent = true }

-- Shorten function name
local keymap = vim.api.nvim_set_keymap

-- Functions
function is_macos()
  return vim.fn.has('macunix')
end

-- Remap space as leader key
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

-- Normal --
-- Utils
keymap("n", ";", ":", opts)
keymap("n", "Y", "y$", opts)
-- Wrapped lines goes down/up to next row, rather than next line in file.
keymap("n", "j", "gj", opts)
keymap("n", "k", "gk", opts)

keymap("n", "n", "nzzzv", opts)
keymap("n", "N", "Nzzzv", opts)

-- Editting
keymap("n", "cl", "ggdG", opts)
keymap("n", "<leader>Y", ":%y<cr>", opts)
keymap("i", "<c-j>", "<Esc>o", opts)
keymap("i", "jj", "<Esc>O", opts)

-- Visual shifting (does not exit Visual mode)
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

keymap("n", "{", "{zz", opts)
keymap("n", "}", "}zz", opts)
keymap("n", "[[", "[[zz", opts)
keymap("n", "]]", "]]zz", opts)
keymap("n", "[]", "[]zz", opts)
keymap("n", "][", "][zz", opts)

-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

-- Switch between tabs
if is_macos then
  keymap("n", "˙", "gT", opts)
  keymap("n", "¬", "gt", opts)
else
  keymap("n", "<A-h>", "gT", opts)
  keymap("n", "<A-l>", "gt", opts)
end

-- Split
keymap("n", "<leader>ee", ":e ", opts)
keymap("n", "<leader>es", ":sp ", opts)
keymap("n", "<leader>ev", ":vsp ", opts)
keymap("n", "<leader>et", ":tabe ", opts)
keymap("n", "<leader>rp", ":%s/", opts)

-- Plugins --
keymap("n", "<leader>f", ":Neoformat<cr>", opts)
