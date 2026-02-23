local M = {}

M.setup = function()
  local function Path()
    -- local path = vim.fn.expand('%:~:.') -- Relative
    local path = vim.fn.expand('%:~') -- Absolute
    return '%#StatusLine# ' .. path
  end

  WinBarNetRW = function()
    return table.concat {
      Path(),
      "%=",
      "%<",
    }
  end

  vim.api.nvim_create_augroup('netrw', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    group = 'netrw',
    pattern = 'netrw',
    callback = function()
      vim.api.nvim_command('setlocal buftype=nofile')
      vim.api.nvim_command('setlocal bufhidden=wipe')
      vim.opt_local.winbar = '%!v:lua.WinBarNetRW()'
      vim.keymap.set('n', 'e', '<CMD>Ex ~<CR>', { remap = true, silent = true, buffer = true })
      vim.keymap.set('n', 'w', '<CMD>Ex ' .. vim.fn.getcwd() .. '<CR>', { remap = true, silent = true, buffer = true })
      vim.keymap.set('n', 'h', '-', { remap = true, silent = true, buffer = true })
      vim.keymap.set('n', 'l', '<CR>', { remap = true, silent = true, buffer = true })
      vim.keymap.set('n', 'r', 'R', { remap = true, silent = true, buffer = true })
      vim.keymap.set('n', 'c', ':cd %<CR>', { remap = true, silent = true, buffer = true })
      vim.keymap.set('n', '<leader>nt', function() vim.g.netrw_liststyle = 3 end, { remap = true, silent = true, buffer = true })
      vim.keymap.set('n', '<leader>nl', function() vim.g.netrw_liststyle = 1 end, { remap = true, silent = true, buffer = true })
      local _none = {
        '<c-h>', 'a', 'C', 'gp', 'mf', 'mb', 'mB', 'mz', 'gb', 'qb', 'gn', 'mt', 'mT', 'md', 'me', 'cb', 'mr',
      }

      local unbinds = {
        '<F1>', '<del>', '<c-r>', '<c-tab>', 'gd', 'gf', 'I', 'mx',
        'mg', 'mh', 'mu', 'mv', 'mX', 'o', 'O', 'p', 'P',  'qf', 'qF',
        'qL', 'S', 't', 'u', 'U',  'X', 's',
      }
      for _, value in pairs(unbinds) do
        vim.keymap.set('n', value, '<CMD>lua print("Keybind \'' .. value .. '\' has been removed")<CR>', { noremap = true, silent = true, buffer = true })
      end
    end
  })

  vim.g.netrw_banner = 2
  vim.g.netrw_liststyle = 3
  -- vim.g.netrw_preview = 1
  vim.g.netrw_bufsettings = 'nonu nornu noma ro nobl'
  vim.g.netrw_browse_split = 0 -- (4 to open in other window)
  vim.g.netrw_altfile = 0 -- (4 to open in other window)
  vim.g.netrw_special_syntax = 3
  vim.g.netrw_sort_by = 'exten'
end
M.setup()

return M
