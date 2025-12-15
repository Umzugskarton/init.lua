return {
  'tpope/vim-projectionist',
  config = function()
    vim.g.projectionist_heuristics = {

      -- [[ 1. Java / Spring Boot Rules ]] --
      -- These trigger only if pom.xml or build.gradle exists
      ["pom.xml|build.gradle"] = {

        -- Navigate from Source Code -> Test
        ["src/main/java/*.java"] = {
          type = "source",
          alternate = "src/test/java/{}Test.java",
        },

        -- Navigate from Test -> Source Code
        ["src/test/java/*Test.java"] = {
          type = "test",
          alternate = "src/main/java/{}.java",
        },

        -- Quick access to resources like application.properties
        ["src/main/resources/*.properties"] = {
          type = "resource"
        },
        ["src/main/resources/*.yaml"] = {
          type = "resource"
        }
      },

      -- [[ 2. Angular / Global Rules ]] --
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
      }
    }
  end
}
