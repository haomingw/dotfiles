local opts = { noremap = true }

local term_opts = { silent = true }

-- Shorten function name
local keymap = vim.api.nvim_set_keymap

--Remap space as leader key
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
-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)
-- Split
keymap("n", "<leader>ee", ":e ", opts)
keymap("n", "<leader>es", ":sp ", opts)
keymap("n", "<leader>ev", ":vsp ", opts)
keymap("n", "<leader>et", ":tabe ", opts)
keymap("n", "<leader>rp", ":%s/", opts)

-- Plugins --
keymap("n", "<leader>f", ":Neoformat<cr>", opts)
