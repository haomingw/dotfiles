local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- General
  "romainl/vim-cool",
  "rhysd/clever-f.vim",
  "haomingw/vim-startscreen",
  "michaeljsmith/vim-indent-object",
  {
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
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "kyazdani42/nvim-web-devicons" },
  },
  {
    "nvim-tree/nvim-tree.lua",
    config = function()
      require("nvim-tree").setup({
        disable_netrw = true,
      })
    end
  },
  {
    "junegunn/vim-easy-align",
    config = function()
      vim.cmd[[
        xmap ga <Plug>(EasyAlign)
        nmap ga <Plug>(EasyAlign)
      ]]
    end
  },
  {
    "windwp/nvim-autopairs",
    config = function() require("nvim-autopairs").setup() end
  },

  -- Development
  "lewis6991/gitsigns.nvim",
  "christoomey/vim-tmux-navigator",
  "tpope/vim-surround",
  "tpope/vim-repeat",
  "tpope/vim-fugitive",
  "nathangrigg/vim-beancount",
  "numToStr/Comment.nvim",
  "voldikss/vim-floaterm",

  -- UI & theme
  {
    "lukas-reineke/indent-blankline.nvim",
    config = function()
      require("ibl").setup({
        show_first_indent_level = false,
        show_trailing_blankline_indent = false,
        filetype_exclude = {
          "help",
          "terminal",
          "alpha",
          "lspinfo",
          "startscreen",
          "TelescopePrompt",
          "TelescopeResults",
          "mason",
          "",
        },
      })
    end
  },
  {
      "ellisonleao/gruvbox.nvim",
      priority = 1000,
      config = function()
        require("gruvbox").setup({
          transparent_mode = true,
        })
        vim.cmd("colorscheme gruvbox")
      end
  },
  -- Completion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-cmdline",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-nvim-lua",
    },
  },

  -- Syntax
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
  },

  -- LSP
  {
    "williamboman/mason.nvim", -- simple to use language server installer
    build = ":MasonUpdate", -- :MasonUpdate updates registry contents
  },
  "williamboman/mason-lspconfig.nvim",
  "neovim/nvim-lspconfig", --- enable LSP
  "jose-elias-alvarez/null-ls.nvim", --- LSP diagnostics and code actions

  -- Fuzzy finder
  "nvim-lua/popup.nvim",
  {
    "nvim-telescope/telescope.nvim",
    lazy = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "kdheepak/lazygit.nvim",
    },
  },
})
