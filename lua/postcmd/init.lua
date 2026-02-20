-- Buffer saved in /tmp or in the current dir
-- You can edit commands as a buffer for testing things quickly.
-- Executes vim commands, not shell commands
local postcmd = {}

local vim = vim
local vapi = vim.api

postcmd.init_config = function(opts)
  opts = opts or {}
  postcmd.config = {
    winconf = postcmd.init_winconf(opts.winconf or {}),
    binding_file = opts.binding_file or "/tmp/postcmd.sh",
    time_compile = opts.time_compile or false,
  }
end

postcmd.init_winconf = function(opts)
  opts = opts or {}
  local width = opts.width or math.floor(vim.o.columns * 0.8)
  local height = opts.height or math.floor(vim.o.lines * 0.8)

  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  local winconf = {
    relative = opts.relative or "editor",
    height = height,
    width = width,
    row = row,
    col = col,
    style = opts.style or "minimal",
    border = opts.border or "rounded",
  }
  return winconf
end

postcmd.create_buf_win_pair = function(opts)
  opts = opts or {}
  local buf = nil
  if vapi.nvim_buf_is_valid(opts.buf) then
    buf = opts.buf
  else
    buf = vapi.nvim_create_buf(false, true)
  end

  -- vapi.nvim_buf_set_name(buf, opts.name or vapi.nvim_buf_get_name(buf))
  local win = vapi.nvim_open_win(buf, true, postcmd.config.winconf)
  return {buf = buf, win = win}
end

postcmd.toggle_floating_term = function()
  postcmd.term = postcmd.term or { buf = -1, win = -1 }
  if not vapi.nvim_win_is_valid(postcmd.term.win) then
    postcmd.term = postcmd.create_buf_win_pair({buf = postcmd.term.buf, name = "[Postcmd Terminal]"})
    if vim.bo[postcmd.term.buf].buftype ~= "terminal" then
      vim.cmd.terminal()
    end
  else
    vapi.nvim_win_hide(postcmd.term.win)
  end
end

postcmd.toggle_scratch = function()
  postcmd.term = postcmd.term or { buf = -1, win = -1 }
  if not vapi.nvim_win_is_valid(postcmd.term.win) then
    postcmd.term = postcmd.create_buf_win_pair({buf = postcmd.term.buf, name = "[Postcmd Scratch]"})
  else
    vapi.nvim_win_hide(postcmd.term.win)
  end
end

postcmd.init_config()

vapi.nvim_create_user_command("Postcmd",
  function(opts)
    print(opts.args)
    if opts.args == "s" then
      postcmd.toggle_scratch()
    else
      postcmd.toggle_floating_term()
    end
  end,
  {nargs = "?"}
)

postcmd.with_keymaps = function()

  postcmd.init_config()
  vapi.nvim_create_user_command("Postcmd",
    function(opts)
      print(opts.args)
      if opts.args == "s" then
        postcmd.toggle_scratch()
      else
        postcmd.toggle_floating_term()
      end
    end,
    {nargs = "?"}
  )

  vim.keymap.set('n', '<leader>t', postcmd.toggle_floating_term(), { noremap = true, silent = true })
  vim.keymap.set('n', '<leader>bs', postcmd.toggle_scratch(), { noremap = true, silent = true })
end

return postcmd

