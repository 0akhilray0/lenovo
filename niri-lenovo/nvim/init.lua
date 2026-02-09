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

-- =========================
-- TRANSPARENCY TOGGLE
-- =========================

-- Function to strip background colors from Neovim
local function set_transparency()
    local groups = {
        "Normal", "NormalNC", "SignColumn", "LineNr", 
        "EndOfBuffer", "NormalFloat", "FloatBorder",
    }
    for _, group in ipairs(groups) do
        vim.api.nvim_set_hl(0, group, { bg = "none" })
    end
end

-- 1. SET IT TO TRUE BY DEFAULT
vim.g.is_transparent = true

-- 2. APPLY IT IMMEDIATELY
set_transparency()

-- 3. KEEP IT TRANSPARENT EVEN IF A THEME LOADS
vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = function()
        if vim.g.is_transparent then
            set_transparency()
        end
    end,
})

-- Keybind to toggle transparency (<leader>t)
vim.keymap.set("n", "<leader>t", function()
    if vim.g.is_transparent then
        -- IMPORTANT: Change "default" to your actual theme (e.g., "tokyonight")
        vim.cmd("colorscheme default") 
        vim.g.is_transparent = false
        print("Transparency: OFF")
    else
        set_transparency()
        vim.g.is_transparent = true
        print("Transparency: ON")
    end
end, { desc = "Toggle Transparency" })
