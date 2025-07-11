  return {
    {
      "folke/tokyonight.nvim",
      lazy = false,    -- Load during startup
      priority = 1000, -- Ensure it loads before other plugins
      opts = {
        style = "night", -- Options: "storm", "moon", "night", "day"
        transparent = false, -- Enable/disable background transparency
      },
      config = function(_, opts)
        require("tokyonight").setup(opts)
        vim.cmd([[colorscheme tokyonight]])
      end,
    },
  }

