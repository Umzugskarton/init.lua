return {
    "nvim-neotest/neotest",
    dependencies = {
        "nvim-neotest/nvim-nio",
        "nvim-lua/plenary.nvim",
        "antoinemadec/FixCursorHold.nvim",
        "nvim-treesitter/nvim-treesitter",
        "fredrikaverpil/neotest-golang",
        "leoluz/nvim-dap-go",
        "nvim-neotest/neotest-jest",
        "atm1020/neotest-jdtls",
    },
    config = function()
        require("neotest").setup({
            adapters = {

                require('neotest-jdtls'),

                require("neotest-golang")({
                    dap = { justMyCode = false },
                }),

                require("neotest-jest")({
                    jestCommand = "npx jest --colors",
                    jestConfigFile = "jest.config.ts",
                    env = { CI = true },
                    cwd = function(path)
                        return vim.fn.getcwd()
                    end,
                }),
            },
            summary = {
                open = "botright vsplit | vertical resize 50",
            },
        })

        vim.keymap.set("n", "<leader>tr", function()
            require("neotest").run.run({ suite = false, testify = true })
            require("neotest").summary.open()
        end, { desc = "Run Nearest Test & Open Summary" })
        vim.keymap.set("n", "<leader>tv", function() require("neotest").summary.toggle() end, { desc = "Toggle Summary" })
        vim.keymap.set("n", "<leader>ts", function() require("neotest").run.run({ suite = true, testify = true }) end, { desc = "Run Test Suite" })
        vim.keymap.set("n", "<leader>td", function() require("neotest").run.run({ suite = false, testify = true, strategy = "dap" }) end, { desc = "Debug Nearest Test" })
        vim.keymap.set("n", "<leader>to", function() require("neotest").output.open({ enter = true }) end, { desc = "Open Test Output" })
        vim.keymap.set("n", "<leader>ta", function() require("neotest").run.run(vim.fn.getcwd()) end, { desc = "Run All Tests" })
        vim.keymap.set("n", "<leader>tf", function()
            require("neotest").run.run(vim.fn.expand("%"))
        end, { desc = "Run Current File" })
    end
}
