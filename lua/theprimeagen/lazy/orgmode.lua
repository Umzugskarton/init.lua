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
            { "<leader>ojt", "<cmd>edit ~/orgfiles/refile.org<cr>", desc = "Edit Default Notes" },
        },

        config = function()
            require('orgmode').setup({
                org_agenda_files = '~/orgfiles/**/*',
                org_default_notes_file = '~/orgfiles/refile.org',
                org_highlight_latex_and_related = 'entities',
                org_startup_folded = 'showeverything',

                mappings = {
                    org = {
                        org_deadline = '<leader>od',   -- Remap Deadline to <leader>od
                        org_schedule = '<leader>os',   -- Remap Schedule to <leader>os
                    }
                }
            })

            require('org-bullets').setup({
                symbols = {
                    list = "⟣",
                    headlines = { "⬡", "⌬", "⏣",  "⎊", "⟡"},
                    checkboxes = {
                        todo = { "♢", "@org.keyword.todo" },
                        half = { "⟐", "@org.checkbox.halfchecked" },
                        done = { "⬧", "@org.keyword.done" },
                    },
                },
            })

            -- require('org-bullets').setup({
            --     symbols = {
            --         list = "⟣",
            --         headlines = {"⟡", "⟐", "⬙", "⬘", "※"},
            --     },
            -- })

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
            local function load_template(filename)
                local path = vim.fn.expand("~/orgfiles/templates/" .. filename)
                if vim.fn.filereadable(path) == 1 then
                    -- Read lines and join them into a single string
                    return table.concat(vim.fn.readfile(path), "\n")
                end
                -- Return nil if file is missing so Org-Roam uses a fallback
                return nil
            end
            require("org-roam").setup({
                directory = "~/orgfiles/roam",
                bindings = {
                    prefix = "<leader>m"
                },
                templates = {
                    p = {
                        description = "Project",
                        template = "* %?",
                        target = "projects/%<%Y%m%d%H%M%S>-%[slug].org",
                    },
                    j  = {
                        description = "Daily",
                        template = load_template("default_template.org") or "%?",
                        target = "daily/%<%Y%m%d%H%M%S>-%[slug].org",
                    },
                    n = {
                        description = "Note",
                        template = "* %?",
                        target = "notes/%<%Y%m%d%H%M%S>-%[slug].org",
                    }
                }
            })
        end,
    },

}
