local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath("data").."/site/pack/packer/start/packer.nvim"
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({"git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path})
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
pcall(require, "impatient")

-- Have packer use a popup window
packer.init {
  display = {
    open_fn = function()
      return require("packer.util").float { border = "rounded" }
    end,
  },
}

-- Install your plugins here
return packer.startup(function(use)
  use "wbthomason/packer.nvim"
  -- General
  use "lewis6991/impatient.nvim"
  use "romainl/vim-cool"
  use "rhysd/clever-f.vim"
  use "haomingw/vim-startscreen"
  use {
    "kana/vim-textobj-user",
    config = function()
      vim.cmd[[
        call textobj#user#plugin('line', {
        \ '-': {
        \   'select-i-function': 'CurrentLineI',
        \   'select-i': 'il',
        \ },
        \})

        function! CurrentLineI()
          normal! ^
          let head_pos = getpos('.')
          normal! g_
          let tail_pos = getpos('.')
          let non_blank_char_exists_p = getline('.')[head_pos[2] - 1] !~# '\s'
          return
          \ non_blank_char_exists_p
          \ ? ['v', head_pos, tail_pos]
          \ : 0
        endfunction
      ]]
    end
  }
  use {
    "nvim-lualine/lualine.nvim",
    requires = { "kyazdani42/nvim-web-devicons", opt = true },
  }
  use {
    "nvim-tree/nvim-tree.lua",
    config = function()
      require("nvim-tree").setup({
        disable_netrw = true,
      })
    end
  }
  use {
    "junegunn/vim-easy-align",
    config = function()
      vim.cmd[[
        xmap ga <Plug>(EasyAlign)
        nmap ga <Plug>(EasyAlign)
      ]]
    end
  }

  -- Development
  use "lewis6991/gitsigns.nvim"
  use "christoomey/vim-tmux-navigator"
  use "tpope/vim-surround"
  use "tpope/vim-repeat"
  use "tpope/vim-fugitive"
  use "nathangrigg/vim-beancount"
  use "numToStr/Comment.nvim"

  -- Colorschemes
  use {
    "ellisonleao/gruvbox.nvim",
    config = function()
      require("gruvbox").setup({
        transparent_mode = true,
      })
      vim.cmd("colorscheme gruvbox")
      -- vim.api.nvim_set_hl(0, "Normal", { ctermbg=NONE })
    end
  }

  -- Completion
  use {
    "hrsh7th/nvim-cmp",
    requires = {
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-cmdline",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-nvim-lua",
    },
  }

  -- Syntax
  use "nvim-treesitter/nvim-treesitter"

  -- LSP
  use "williamboman/mason.nvim" -- simple to use language server installer
  use "williamboman/mason-lspconfig.nvim" -- simple to use language server installer
  use "neovim/nvim-lspconfig" -- enable LSP
  use "jose-elias-alvarez/null-ls.nvim" -- LSP diagnostics and code actions

  -- Fuzzy finder
  use "nvim-lua/popup.nvim"
  use {
    "nvim-telescope/telescope.nvim",
    requires = {
      "nvim-lua/plenary.nvim",
      "kdheepak/lazygit.nvim",
    },
  }

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if packer_bootstrap then
    require("packer").sync()
  end
end)
