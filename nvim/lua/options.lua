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
  -- pumheight = 10,                          -- pop up menu height
  showmode = false,                        -- we don't need to see things like -- INSERT -- anymore
  hidden = true,                           -- allow buffer switching without saving
  joinspaces = false,                      -- prevents inserting two spaces after punctuation on a join (J)
  showcmd = true,                          -- show partial commands in status line
  smartcase = true,                        -- smart case
  smartindent = true,                      -- make indenting smarter again
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
  -- relativenumber = true,                   -- set relative numbered lines
  signcolumn = "yes",                      -- always show the sign column, otherwise it would shift the text each time
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

-- Colortheme
vim.cmd [[
try
  colorscheme gruvbox-material
catch /^Vim\%((\a\+)\)\=:E185/
  colorscheme default
endtry
]]

vim.api.nvim_set_hl(0, "Normal", { ctermbg=NONE })

vim.opt.shortmess:append "c"
vim.opt.whichwrap:append("<,>,[,],h,l,b,s")
