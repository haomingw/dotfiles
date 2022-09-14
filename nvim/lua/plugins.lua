local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

-- Autocommand that reloads neovim whenever you save the plugins.lua file
vim.cmd [[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
  augroup end
]]

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
  return
end

-- Speed up loading Lua modules in Neovim to improve startup time
pcall(require, 'impatient')

-- Have packer use a popup window
packer.init {
  display = {
    open_fn = function()
      return require("packer.util").float { border = "rounded" }
    end,
  },
}

local keymap = vim.api.nvim_set_keymap
local opts = { noremap = true }

-- Install your plugins here
return packer.startup(function(use)
  use 'wbthomason/packer.nvim'
  -- General
  use 'lewis6991/impatient.nvim'
  use "windwp/nvim-autopairs"
  use "romainl/vim-cool"
  use "nathangrigg/vim-beancount"
  use {
    'nvim-lualine/lualine.nvim',
    requires = { 'kyazdani42/nvim-web-devicons', opt = true },
  }

  -- Development
  use "sbdchd/neoformat"
  use "lewis6991/gitsigns.nvim"
  use "christoomey/vim-tmux-navigator"
  use "tpope/vim-surround"
  use "tpope/vim-fugitive"

  -- Colorschemes
  use {
    "sainnhe/gruvbox-material",
    config = function()
      vim.cmd "colorscheme gruvbox-material"
    end,
  }

  -- Completion
  use {
    "hrsh7th/nvim-cmp",
    requires = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "hrsh7th/cmp-nvim-lsp",
    },
  }

  -- Fuzzy finder
  use "nvim-lua/popup.nvim"
  use {
    "nvim-telescope/telescope.nvim",
    requires = {
      "nvim-lua/plenary.nvim",
    },
  }

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if packer_bootstrap then
    require('packer').sync()
  end
end)