return {
    "askfiy/smart-translate.nvim",
    dependencies = { "askfiy/http.nvim" },
    event = 'VeryLazy',
    default = {
        cmds = {
            source = "auto",
            target = "en-US",
            handle = "float",
            engine = "google",
        },
        cache = true,
    },
    config = function()
        require("smart-translate").setup({
            default = {
                cmds = {
                    source = "auto",    -- Auto-detect language of the word
                    target = "en",      -- Force target to English (try "en" instead of "en-US" for broader support)
                    handle = "float",   -- Show in floating window
                    engine = "google",  -- Use Google Translate
                },
                cache = true,
            },
        })

        _G.op_translate = function(type)
            -- 1. Get the position of the marks set by the motion
            -- Mark [ is the start, Mark ] is the end
            local start_pos = vim.api.nvim_buf_get_mark(0, '[')
            local end_pos = vim.api.nvim_buf_get_mark(0, ']')

            -- Marks are (1-based-row, 0-based-col). The API expects 0-based rows.
            local start_row = start_pos[1] - 1
            local start_col = start_pos[2]
            local end_row = end_pos[1] - 1
            local end_col = end_pos[2]

            -- 2. Extract the text based on the motion type
            local lines = {}

            if type == 'line' then
                -- For line motions (like 'ip' or '_'), get full lines
                lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
            elseif type == 'char' then
                -- For char motions (like 'w' or '$'), get precise text range
                -- We add +1 to end_col because the API is end-exclusive
                -- We use pcall just in case the motion hits the very end of the file/line causing an index error
                local ok, result = pcall(vim.api.nvim_buf_get_text, 0, start_row, start_col, end_row, end_col + 1, {})
                if ok then
                    lines = result
                else
                    -- Fallback: if +1 fails (end of line), try without +1 or just grab lines
                    lines = vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {})
                end
            end

            -- 3. Join the lines into a single string
            local text = table.concat(lines, " ")

            -- 4. Execute the command safely
            if #text > 0 then
                -- Using nvim_cmd (Nvim 0.8+) prevents issues if your text has special chars like "|"
                vim.api.nvim_cmd({ cmd = 'Translate', args = { text } }, {})
            end
        end

        -- Keymap: Normal Mode
        vim.keymap.set("n", "<leader>t", function()
            vim.go.operatorfunc = "v:lua.op_translate"
            return "g@"
        end, { expr = true, desc = "Translate Motion" })

        -- Keymap: Visual Mode
        vim.keymap.set("v", "<leader>t", ":Translate<CR>", { desc = "Translate Selection" })
    end,
}
