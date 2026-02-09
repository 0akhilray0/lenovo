-- =========================
-- BASIC SETTINGS (BEGINNER)
-- =========================

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Tabs & indentation
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

-- Searching
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true

-- UI
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"

-- Mouse
vim.opt.mouse = "a"

-- Performance
vim.opt.updatetime = 300
vim.opt.timeoutlen = 500

-- =========================
-- KEYBINDS
-- =========================

vim.g.mapleader = " "

-- Save / Quit
vim.keymap.set("n", "<leader>w", "<cmd>w<CR>")
vim.keymap.set("n", "<leader>q", "<cmd>q<CR>")

-- Exit insert mode
vim.keymap.set("i", "jk", "<Esc>")

-- Window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")

-- =========================
-- CLIPBOARD (HYPRLAND SAFE)
-- =========================
-- No global clipboard override
-- Use these mappings instead

vim.keymap.set({ "n", "v" }, "<leader>c", '"+y') -- copy to system
vim.keymap.set("n", "<leader>v", '"+p')          -- paste from system

-- =========================
-- END
-- =========================

