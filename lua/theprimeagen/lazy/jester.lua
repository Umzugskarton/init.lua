return {
  "David-Kunz/jester",
  -- ❗ Jester requires nvim-treesitter and nvim-dap
  --    Make sure you have these plugins installed and configured.
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "mfussenegger/nvim-dap",
  },
  -- Set up sensible keymaps
  keys = {
    {
      "<leader>tr",
      function() require("jester").run() end,
      desc = "Run Nearest Test",
    },
    {
      "<leader>tf",
      function() require("jester").run_file() end,
      desc = "Run Tests in File",
    },
    {
      "<leader>tl",
      function() require("jester").run_last() end,
      desc = "Run Last Test",
    },
    {
      "<leader>td",
      function() require("jester").debug() end,
      desc = "Debug Nearest Test",
    },
    {
      "<leader>tD",
      function() require("jester").debug_file() end,
      desc = "Debug Tests in File",
    },
  },
  -- Default options (optional, you can uncomment to override)
  -- The `opts` table is passed directly to the plugin's `setup()` function
  opts = {
    -- cmd = "jest -t '$result' -- $file",
    -- identifiers = { "test", "it" },
    -- prepend = { "describe" },
    -- expressions = { "call_expression" },
    -- path_to_jest_run = "jest",
  },
}
