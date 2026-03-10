-- =========================================
-- 1. CONTEXT & MEMORY TRACKING
-- =========================================
-- We'll store the last position we were in before entering an Org file
vim.g.last_dev_context = { path = nil, line = 1, text = "" }

vim.api.nvim_create_autocmd("BufLeave", {
    group = vim.api.nvim_create_augroup("OrgContextTracker", { clear = true }),
    pattern = "*",
    callback = function()
        -- If we are leaving a "real" code file, save exactly where we are
        if vim.bo.filetype ~= "org" and vim.bo.filetype ~= "orgagenda" and vim.bo.buftype == "" then
            local path = vim.fn.expand("%:p")
            if path ~= "" then
                vim.g.last_dev_context = {
                    path = path,
                    line = vim.api.nvim_win_get_cursor(0)[1],
                    text = vim.api.nvim_get_current_line():gsub("^%s*", ""),
                    root = require("snacks").git.get_root()
                }
                vim.g.last_dev_root = vim.g.last_dev_context.root
            end
        end
    end,
})

-- =========================================
-- 2. THE "SEXY" FUNCTIONS
-- =========================================

-- Function to extract data from an Org Link [[file:PATH::LINE][DESC]]
local function get_org_link_data()
    local line = vim.api.nvim_get_current_line()
    -- Greedy match to handle absolute paths on Mac /Users/...
    local path, target = line:match("%[%[file:([^%]:%s]+):*:?([^%]]*)%]%]")
    if path then
        return vim.fn.expand(path), tonumber(target) or 1
    end
    return nil, nil
end

-- 'gd' Jump to Source
local function jump_to_org_link()
    local path, row = get_org_link_data()
    if path and vim.fn.filereadable(path) == 1 then
        vim.cmd("edit " .. path)
        vim.api.nvim_win_set_cursor(0, {row, 0})
        vim.cmd("normal! zz")
    else
        vim.lsp.buf.definition()
    end
end

-- 'K' Peek at Source (Fixed for Absolute Paths)
local function peek_org_link()
    local path, row = get_org_link_data()
    if path and vim.fn.filereadable(path) == 1 then
        local win = require("snacks").win({
            file = path,
            width = 0.7, height = 0.5, border = "rounded",
            title = " 󰈙 " .. vim.fn.fnamemodify(path, ":t") .. " ",
            title_pos = "center", style = "minimal",
            keys = {
                ["q"] = "close",
                ["<CR>"] = function()
                    vim.cmd("close") -- Close preview
                    jump_to_org_link() -- Jump to file
                end
            },
        })
        vim.api.nvim_win_call(win.win, function()
            vim.api.nvim_win_set_cursor(0, {row, 0})
            vim.cmd("normal! zz")
            local ns = vim.api.nvim_create_namespace("org_peek")
            vim.api.nvim_buf_add_highlight(0, ns, "CursorLine", row - 1, 0, -1)
            vim.bo.filetype = vim.filetype.match({ filename = path })
        end)
    else
        vim.lsp.buf.hover()
    end
end

-- '<leader>oo' QUICK LINK (Last file/line)
local function insert_last_context_link()
    local ctx = vim.g.last_dev_context
    if ctx and ctx.path then
        local filename = vim.fn.fnamemodify(ctx.path, ":t")
        local clean_text = ctx.text:sub(1, 30) -- Keep it short
        local org_link = string.format("[[file:%s::%d][%s: %s]]", ctx.path, ctx.line, filename, clean_text)
        vim.api.nvim_put({ org_link }, "c", true, true)
        vim.notify("󰄶 Linked last position: " .. filename .. ":" .. ctx.line)
    else
        vim.notify("No code context found!", vim.log.levels.WARN)
    end
end

-- '<leader>ol' SEARCH & LINK
local function insert_org_line_link()
    local search_path = vim.g.last_dev_root or vim.fn.expand("~/projects")
    require("snacks").picker.grep({
        cwd = search_path,
        title = " 󰄶 Link Code From: " .. vim.fn.fnamemodify(search_path, ":~"),
        confirm = function(picker, item)
            picker:close()
            if item then
                local abs_path = vim.fn.fnamemodify(item.file, ":p")
                local filename = vim.fn.fnamemodify(item.file, ":t")
                local clean_text = item.text:gsub("^%s*", ""):gsub("%s*$", "")
                local org_link = string.format("[[file:%s::%d][%s: %s]]", abs_path, item.pos[1], filename, clean_text)
                vim.api.nvim_put({ org_link }, "c", true, true)
            end
        end,
    })
end

-- Helper for city (kept from your original)
local function get_city()
    local city = vim.fn.system("curl -s --max-time 1 ipinfo.io"):gsub("\n", "")
    return (city == "" or city == nil) and "Unknown Location" or city
end

local function load_template(filename, city)
    local path = vim.fn.expand("~/orgfiles/templates/" .. filename)
    if vim.fn.filereadable(path) == 1 then
        local content = table.concat(vim.fn.readfile(path), "\n")
        return content:gsub("%%LOCATION%%", city)
    end
    return nil
end

local city = get_city()

-- =========================================
-- 3. RETURN LAZY SPEC
-- =========================================
return {
    {
        'nvim-orgmode/orgmode',
        event = 'VeryLazy',
        dependencies = {
            'akinsho/org-bullets.nvim',
            'lukas-reineke/headlines.nvim',
            'folke/snacks.nvim',
        },
        keys = {
            { "<leader>ojt", "<cmd>edit ~/orgfiles/tasks.org<cr>", desc = "Edit tasks" },
            { "K", peek_org_link, desc = "Sexy Org Peek" },
            -- { "gd", jump_to_org_link, desc = "Jump to Source" },
            { "<leader>ol", insert_org_line_link, desc = "Search & Link Code" },
            { "<leader>ov", insert_last_context_link, desc = "Quick Link Last Pos" },
        },
        config = function()
            local org = require('orgmode')
            org.setup({
                org_agenda_files = { '~/orgfiles/*.org', '~/orgfiles/roam/**/*', '~/orgfiles/projects/**/*' },
                org_default_notes_file = '~/orgfiles/refile.org',
                org_todo_keywords = { 'TODO', 'PROG', '|', 'DONE' },
                org_todo_keyword_faces = { PROG = ':foreground orange :weight bold', DONE = ':foreground green :weight bold' },
                org_capture_templates = {
                    t = 't',
                    tp = { description = "personal task", template = load_template("task_template.org", city) or "* TODO %?", target = "~/orgfiles/private.org" },
                    tw = { description = "work task", template = load_template("task_template.org", city) or "* TODO %?", target = "~/orgfiles/work.org" },
                    ts = { description = "scheduled task", template = load_template("scheduled_task_template.org", city) or "* TODO %?", target = "~/orgfiles/calendar.org" },
                    h = { description = "habit", template = load_template("habit_template.org", city) or "* TODO %?", target = "~/orgfiles/habits.org" },
                },
                mappings = {
                    org = {
                        org_edit_special = '<leader>oe',
                        org_deadline = '<leader>od',
                        org_schedule = '<leader>os',
                        org_clock_in = '<leader>oi',
                        org_clock_out = '<leader>ok',
                    }
                }
            })

            -- Visuals
            require('org-bullets').setup({
                symbols = {
                    list = "⟣", headlines = { "⟡","◇","▽","⬡","⌬"},
                    checkboxes = { todo = { "♢", "@org.keyword.todo" }, half = { "⟐", "@org.checkbox.halfchecked" }, done = { "◈", "@org.keyword.done" } },
                },
            })

            require('headlines').setup({
                org = { codeblock_highlight = "CodeBlock", dash_string = "─", fat_headlines = false, bullets = false }
            })

            -- (Include your toggle_org_repeater and advance_todo_state functions here...)
        end,
    },

    {
        "chipsenkbeil/org-roam.nvim",
        dependencies = { { "nvim-orgmode/orgmode" } },
        config = function()
            require("org-roam").setup({
                directory = "~/orgfiles/roam",
                bindings = { prefix = "<leader>m" },
                templates = {
                    d = { description = "Documentation", template = load_template("documentation_template.org", city) or "%?", target = "projects/%[slug].org" },
                    c = { description = "Contact", template = load_template("contact_template.org", city) or "%?", target = "contacts/%[slug].org" },
                    p = { description = "Project", template = "* %?", target = "projects/%[slug].org" },
                    j = { description = "Daily", template = load_template("default_template.org", city) or "%?", target = "daily/%<%Y%m%d%H%M%S>-%[slug].org" },
                    n = { description = "Note", template = "* %?", target = "notes/%<%Y%m%d%H%M%S>-%[slug].org" },
                    x = { description = "Poem", template = load_template("poem_template.org", city) or "%?", target = "poems/%[slug].org" },
                }
            })
        end,
    },
}
