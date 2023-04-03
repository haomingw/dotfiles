local options = {
  mouse = "a",                             -- allow the mouse to be used in neovim
  fileencoding = "utf-8",                  -- the encoding written to a file
  clipboard = "unnamedplus",               -- allows neovim to access the system clipboard
  backup = false,                          -- creates a backup file
  swapfile = false,                        -- creates a swapfile
  writebackup = false,                     -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
  undofile = true,                         -- enable persistent undo
  hlsearch = true,                         -- highlight all matches on previous search pattern
  ignorecase = true,                       -- ignore case in search patterns
  showmode = false,                        -- we don't need to see things like -- INSERT -- anymore
  hidden = true,                           -- allow buffer switching without saving
  joinspaces = false,                      -- prevents inserting two spaces after punctuation on a join (J)
  showcmd = true,                          -- show partial commands in status line
  smartcase = true,                        -- smart case
  cindent = true,                          -- replace autoindent and smartindent
  splitbelow = true,                       -- force all horizontal splits to go below current window
  splitright = true,                       -- force all vertical splits to go to the right of current window
  termguicolors = true,                    -- set term gui colors (most terminals support this)
  timeoutlen = 1000,                       -- time to wait for a mapped sequence to complete (in milliseconds)
  updatetime = 300,                        -- faster completion (4000ms default)
  expandtab = true,                        -- convert tabs to spaces
  shiftwidth = 2,                          -- the number of spaces inserted for each indentation
  tabstop = 2,                             -- insert 2 spaces for a tab
  softtabstop = 2,                         -- let backspace delete indent
  cursorline = true,                       -- highlight the current line
  number = true,                           -- set numbered lines
  relativenumber = true,                   -- set relative numbered lines
  wrap = false,                            -- display lines as one long line
  scrolloff = 8,                           -- lines to scroll when cursor leaves screen
  sidescrolloff = 8,
  completeopt = { "menuone", "noselect" }, -- mostly just for cmp
  list = true,
  listchars = {
    tab = "› ",
    extends = "#",
    trail = "•",
    nbsp = "."
  },
}

for k, v in pairs(options) do
  vim.opt[k] = v
end

vim.opt.shortmess:append "c"
vim.opt.whichwrap:append("<,>,[,],h,l,b,s")
-- vim.cmd.colorscheme "gruvbox"
-- vim.api.nvim_set_hl(0, "Normal", { ctermbg=NONE })


-- vim compatible
vim.cmd [[
  iabbrev tab2 vim: set sw=2 ts=2 sts=2 et
  iabbrev tab4 vim: set sw=4 ts=4 sts=4 et
  iabbrev #! #!/usr/bin/env
]]
