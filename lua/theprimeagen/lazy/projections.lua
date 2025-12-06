return {
  'tpope/vim-projectionist',
  config = function()
    -- This table defines project-type detection rules.
    -- The key "angular.json" means: "If you find an 'angular.json'
    -- in the project root, apply the following rules."
    vim.g.projectionist_heuristics = {
      ["*"] = {
        ["*.component.ts"] = {
          type = "component",
          alternate = {
            "{}.component.html",
            "{}.component.spec.ts",
            "{}.component.scss"
          }
        },
        ["*.component.html"] = {
          type = "template",
          alternate = {
            "{}.component.spec.ts",
            "{}.component.scss",
            "{}.component.ts"
          }
        },
        ["*.component.spec.ts"] = {
          type = "test",
          alternate = {
            "{}.component.scss",
            "{}.component.ts",
            "{}.component.html"
          }
        },
        ["*.component.scss"] = {
          type = "style",
          alternate = {
            "{}.component.ts",
            "{}.component.html",
            "{}.component.spec.ts"
          }
        },
        ["*.service.ts"] = {
          type = "service",
          alternate = {
            "{}.service.spec.ts",
          }
        },
        ["*.service.spec.ts"] = {
          type = "test",
          alternate = {
            "{}.service.ts",
          }
        },
        ["*.pipe.ts"] = {
          type = "style",
          alternate = {
            "{}.pipe.spec.ts",
          }
        },
        ["*.pipe.spec.ts"] = {
          type = "style",
          alternate = {
            "{}.pipe.ts",
          }
        }
        -- You can add more rules here for services, modules, etc.
        -- ["src/app/**/*.service.ts"] = {
        --   alternate = "{}.service.spec.ts"
        -- },
        -- ["src/app/**/*.service.spec.ts"] = {
        --   alternate = "{}.service.ts"
        -- }
      }
    }
  end
}
