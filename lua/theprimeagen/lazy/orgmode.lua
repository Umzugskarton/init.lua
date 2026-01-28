-- Fetch city from ipinfo.io (with a 1-second timeout to prevent freezing)
local function get_city()
    local city = vim.fn.system("curl -s --max-time 1 ipinfo.io/city"):gsub("\n", "")
    -- If the command failed or we are offline, return a fallback
    if city == "" or city == nil then
        return "Unknown Location"
    end
    return city
end

local function load_template(filename, city)
    local path = vim.fn.expand("~/orgfiles/templates/" .. filename)
    if vim.fn.filereadable(path) == 1 then
        local content = table.concat(vim.fn.readfile(path), "\n")
        -- local city = get_city() -- too slow find better solution
        content = content:gsub("%%LOCATION%%",city)

        return content
    end
    return nil
end

local city = get_city();
return {
    -- =========================================
    -- 1. BASE ORGMODE & UI PLUGINS
    -- =========================================
    {
        'nvim-orgmode/orgmode',
        event = 'VeryLazy',
        dependencies = {
            'akinsho/org-bullets.nvim',
            'lukas-reineke/headlines.nvim',
        },

        keys = {
            { "<leader>ojt", "<cmd>edit ~/orgfiles/tasks.org<cr>", desc = "Edit tasks" },
        },

        config = function()
            local org = require('orgmode')

            org.setup({
                org_agenda_files = {
                    '~/orgfiles/*.org',
                    '~/orgfiles/roam/**/*',
                    '~/orgfiles/projects/**/*',
                },

                org_default_notes_file = '~/orgfiles/refile.org',
                org_highlight_latex_and_related = 'entities',
                org_startup_folded = 'showeverything',

                org_todo_keywords = { 'TODO', 'PROG', '|', 'DONE' },

                org_todo_keyword_faces = {
                    PROG = ':foreground orange :weight bold', -- "PROG" will be Orange
                    DONE = ':foreground green :weight bold',
                },

                -- Logbook Configuration
                org_log_done = 'time',           -- Insert a timestamp when closing a task
                org_log_into_drawer = 'LOGBOOK', -- Put all times/clocks into the :LOGBOOK: drawer

                org_capture_templates = {
                    t = 't',
                    tp = {
                        description = "persional task",
                        template = load_template("task_template.org", city) or "* TODO %?",
                        target = "~/orgfiles/private.org",
                    },
                    tw = {
                        description = "work task",
                        template = load_template("task_template.org", city) or "* TODO %?",
                        target = "~/orgfiles/work.org",
                    },

                    ts = {
                        description = "scheduled task",
                        template = load_template("scheduled_task_template.org", city) or "* TODO %?",
                        target = "~/orgfiles/calendar.org",
                    },

                    h = {
                        description = "habit",
                        template = load_template("habit_template.org", city) or "* TODO %?",
                        target = "~/orgfiles/habits.org",
                    },
                },

                mappings = {
                    org = {
                        org_deadline = '<leader>od',
                        org_schedule = '<leader>os',
                        -- Useful clock mappings just in case
                        org_clock_in = '<leader>oi',
                        org_clock_out = '<leader>ok',
                    }
                }
            })

            require('org-bullets').setup({
                symbols = {
                    list = "⟣",
                    headlines = { "⟡","◇","▽","⬡","⌬"},
                    checkboxes = {
                        todo = { "♢", "@org.keyword.todo" },
                        half = { "⟐", "@org.checkbox.halfchecked" },
                        done = { "◈", "@org.keyword.done" },
                    },
                },
            })

            require('headlines').setup({
                org = {

                    dash_string = "─",
                    fat_headlines = false,

                    bullets = false,
                }
            })

            -- toggle between reocurring task schedule
            local function toggle_org_repeater()
                local line = vim.api.nvim_get_current_line()

                -- 1. Check if +1d exists -> Switch to +1m
                if line:find(" %+1d") then
                    line = line:gsub(" %+1d>", " +1w>")
                    print("📅 Repeater set to: Weekly (+1w)")

                    -- 2. Check if +1m exists -> Switch to +1y
                elseif line:find(" %+1w>") then
                    line = line:gsub(" %+1w>", " +1m>")
                    print("📅 Repeater set to: Monthly (+1m)")

                    -- 2. Check if +1m exists -> Switch to +1y
                elseif line:find(" %+1m>") then
                    line = line:gsub(" %+1m>", " +1y>")
                    print("📅 Repeater set to: Yearly (+1y)")

                    -- 3. Check if +1y exists -> Remove it
                elseif line:find(" %+1y>") then
                    line = line:gsub(" %+1y>", ">")
                    print("📅 Repeater removed")

                    -- 4. If no repeater found, add +1d to the timestamp
                else
                    -- Matches standard org timestamp: <2023-10-27 Fri>
                    -- We capture everything inside <...> and append +1d before the closing >
                    local new_line, count = line:gsub("(%<[^>]+)(%>)", "%1 +1d%2", 1)

                    if count > 0 then
                        line = new_line
                        print("📅 Repeater set to: Daily (+1d)")
                    else
                        print("⚠️ No active timestamp found on this line.")
                    end
                end

                vim.api.nvim_set_current_line(line)
            end
            local clock_overlays_active = false

            -- Set the Keymap (e.g., <leader>or for "Org Repeat")
            vim.keymap.set('n', '<leader>oq', toggle_org_repeater, { desc = 'Toggle Org Repeater (+1d/m/y)' })

            -- =========================================
            --  CUSTOM TODO STATE CHANGER
            -- =========================================
            local function advance_todo_state_and_clock()
                local org = require('orgmode')

                -- 1. Trigger the normal "Next State" action
                --    (This is equivalent to what 'cit' usually does)
                org.action('org_mappings.todo_next_state')

                -- 2. Wait a tiny bit (5ms) for the state to update in the text
                vim.defer_fn(function()
                    -- 3. Read the text of the current line
                    local line = vim.api.nvim_get_current_line()

                    -- 4. Check which keyword is now in the line
                    --    We look for "* PROG " or "* DONE " patterns

                    if line:match("%*+%s+PROG%s+") then
                        -- STATE IS NOW: PROG
                        org.clock:org_clock_in()
                        vim.notify("⏱️  Clock Started (PROG)", vim.log.levels.INFO)

                    elseif line:match("%*+%s+DONE%s+") then
                        -- STATE IS NOW: DONE
                        org.clock:org_clock_out()
                        vim.notify("✅  Clock Stopped (DONE)", vim.log.levels.INFO)

                    elseif line:match("%*+%s+TODO%s+") or line:match("%*+%s+WAITING%s+") then
                        -- Lua API: Clock Out (Pause)
                        -- We use pcall because if no clock was running, this function might error
                        local status, err = pcall(function() org.clock:org_clock_out() end)
                        if status then
                            vim.notify("⏸️ Clock Paused", vim.log.levels.WARN)
                        end
                    else
                        vim.notify("No TODO Found")

                    end
                end, 50)
            end

            vim.keymap.set('n', '<leader>cit', advance_todo_state_and_clock, {
                desc = "Advance State & Update Clock"
            })
        end,

    },

    -- =========================================
    -- 2. ORG ROAM (Zettelkasten)
    -- =========================================
    {
        "chipsenkbeil/org-roam.nvim",
        -- IMPORTANT: Remove the tag to get the latest 'main' branch.
        -- 0.2.0 is often too old for the new Lua APIs you are trying to use.
        dependencies = {
            { "nvim-orgmode/orgmode" },
        },
        config = function()
            require("org-roam").setup({
                directory = "~/orgfiles/roam",

                bindings = {
                    prefix = "<leader>m"
                },

                templates = {
                    d = {
                        description = "Documentation",
                        template = load_template("documentation_template.org", city) or "%?",
                        target = "projects/%[slug].org",
                    },
                    p = {
                        description = "Project",
                        template = "* %?",
                        target = "projects/%[slug].org",
                    },
                    j  = {
                        description = "Daily",
                        template = load_template("default_template.org", city) or "%?",
                        target = "daily/%<%Y%m%d%H%M%S>-%[slug].org",
                    },
                    n = {
                        description = "Note",
                        template = "* %?",
                        target = "notes/%<%Y%m%d%H%M%S>-%[slug].org",
                    },
                    x = {
                        description = "Poem",
                        template = load_template("poem_template.org", city) or "%?",
                        target = "poems/%[slug].org",
                    },
                }
            })
        end,
    },

}
