local opt = vim.opt
local g  = vim.g

g.mapleader = ' '

-- Indentation
opt.smartindent = true
opt.autoindent = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true

-- Use system clipboard
opt.clipboard = "unnamedplus"

-- Use mouse
opt.mouse = "a"

-- Additional UI settings
opt.termguicolors = true
opt.number = true
opt.relativenumber = true

-- Convenience settings
opt.smartcase = true
opt.hidden = true
opt.incsearch = true

