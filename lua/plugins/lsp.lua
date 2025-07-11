return {
  { 
  "neovim/nvim-lspconfig",
  dependencies = {
    {
      "folke/lazydev.nvim",
      ft = "lua", -- only load on lua files
      opts = {
	library = {
	  -- See the configuration section for more details
	  -- Load luvit types when the `vim.uv` word is found
	  { path = "${3rd}/luv/library", words = { "vim%.uv" } },
	},
      },
    },
  },
  config = function()
    require("lspconfig").lua_ls.setup {}
    require("lspconfig").pyright.setup{}
--    require("lspconfig").ts_ls.setup{}
    vim.lsp.enable('basedpyright')
    vim.lsp.config('ts_ls', {
      init_options = {
	plugins = {
	  {
	    name = "@vue/typescript-plugin",
	    location = "/usr/local/lib/node_modules/@vue/typescript-plugin",
	    languages = {"javascript", "typescript", "vue"},
	  },
	},
      },
      filetypes = {
	"javascript",
	"typescript",
	"vue",
      },
    })
  end,
  }
}
