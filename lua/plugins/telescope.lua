return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.8',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- file icons in pickers
  },
  config = function()
    require('telescope').setup({
      defaults = {
        layout_config = {
          horizontal = { preview_width = 0.5 },
        },
        path_display = { "smart" },
      },
    })
  end,
}

