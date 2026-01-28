require("theprimeagen.set")
require("theprimeagen.remap")
require("theprimeagen.lazy_init")

-- DO.not
-- DO NOT INCLUDE THIS

-- If i want to keep doing lsp debugging
-- function restart_htmx_lsp()
--     require("lsp-debug-tools").restart({ expected = {}, name = "htmx-lsp", cmd = { "htmx-lsp", "--level", "DEBUG" }, root_dir = vim.loop.cwd(), });
-- end

-- DO NOT INCLUDE THIS
-- DO.not

local augroup = vim.api.nvim_create_augroup
local ThePrimeagenGroup = augroup('ThePrimeagen', {})

local autocmd = vim.api.nvim_create_autocmd
local yank_group = augroup('HighlightYank', {})

function R(name)
    require("plenary.reload").reload_module(name)
end

vim.filetype.add({
    extension = {
        templ = 'templ',
    }
})

autocmd('TextYankPost', {
    group = yank_group,
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({
            higroup = 'IncSearch',
            timeout = 40,
        })
    end,
})

autocmd({"BufWritePre"}, {
    group = ThePrimeagenGroup,
    pattern = "*",
    command = [[%s/\s\+$//e]],
})

-- autocmd('BufEnter', {
--     group = ThePrimeagenGroup,
--     callback = function()
--         if vim.bo.filetype == "zig" then
--             vim.cmd.colorscheme("rose-pine-moon")
--         else
--             vim.cmd.colorscheme("citruszest")
--         end
--     end
-- })


autocmd('LspAttach', {
    group = ThePrimeagenGroup,
    callback = function(e)
        local opts = { buffer = e.buf }
        vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
        vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
        vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
        vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
        vim.keymap.set("n", "<leader>xc", function() vim.lsp.buf.code_action() end, opts)
        vim.keymap.set("n", "<leader>gr", function() vim.lsp.buf.references() end, opts)
        vim.keymap.set("n", "<leader>rn", function() vim.lsp.buf.rename() end, opts)
        vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
        vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
        vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
    end
})

vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25


local autocmd = vim.api.nvim_create_autocmd

-- Return to the last position.
-- @returns a "clear = true" augroup
local function augroup(name) return vim.api.nvim_create_augroup('sergio-lazyvim_' .. name, { clear = true }) end

autocmd('BufReadPost', {
  group = augroup('restore_position'),
  callback = function()
    local exclude = { 'gitcommit' }
    local buf = vim.api.nvim_get_current_buf()
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) then return end

    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local line_count = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
      vim.api.nvim_feedkeys('zvzz', 'n', true)
    end
  end,
  desc = 'Restore cursor position after reopening file',
})


-- =============================================================================
-- DIRECT TERMINAL ESCAPE SEQUENCE MODE (BRUTE FORCE)
-- =============================================================================

-- 1. Get Colors (Global Truth)
local orange = os.getenv("CURSOR_RETRO_ORANGE") or "#ff9900"
local pink   = os.getenv("CURSOR_RETRO_PINK")   or "#d700ff"

-- 2. Define the exact Escape Sequences (Same as in Zsh)
--    \27 is Lua for \033 (Escape)
--    OSC 12 changes cursor color
local orange_cursor_cmd = "\27]12;" .. orange .. "\7"
local pink_cursor_cmd   = "\27]12;" .. pink   .. "\7"

-- 3. Function to write directly to the terminal (Instant, no flicker)
local function set_cursor_color(color_cmd)
    -- Write to stderr to bypass Neovim's UI buffer
    vim.api.nvim_chan_send(2, color_cmd)
end

-- 4. Hook into the ModeChanged Event
local mode_group = vim.api.nvim_create_augroup("RetroCursorDirect", { clear = true })

vim.api.nvim_create_autocmd("ModeChanged", {
    group = mode_group,
    callback = function()
        local mode = vim.v.event.new_mode
        -- 'i' is insert, 'R' is replace
        if mode:sub(1,1) == "i" or mode == "R" then
            set_cursor_color(orange_cursor_cmd)
        else
            set_cursor_color(pink_cursor_cmd)
        end
    end
})

-- 5. Ensure we start with Orange (Normal Mode)
set_cursor_color(orange_cursor_cmd)

-- 6. Cleanup on Exit (Return to Orange or Default)
vim.api.nvim_create_autocmd("VimLeave", {
    group = mode_group,
    callback = function()
        set_cursor_color(orange_cursor_cmd)
end
})

local function jump_to_next_placeholder()
    -- The marker we are looking for
    local marker = "<++>"

    -- Search for the marker
    -- 'W' = don't wrap around file
    local found = vim.fn.search(marker, "W")

    if found > 0 then
        -- If found, delete the marker and enter Insert mode
        -- "cf>" means: Change (c) until find (f) the character '>'
        -- Adjust this based on your marker length.
        -- For <++>, we can just use "4s" (substitute 4 chars) or "cf>"
        vim.cmd("normal! cf>")
    else
        print("✅ No more placeholders found.")
    end
end

-- Map it to <Tab> (only in Org files)
vim.api.nvim_create_autocmd("FileType", {
    pattern = "org",
    callback = function()
        -- Buffer-local mapping
        vim.keymap.set("n", "<Tab>", jump_to_next_placeholder, { buffer = true, desc = "Jump to next <++>" })
    end,
})
