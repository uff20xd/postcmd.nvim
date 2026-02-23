-- Buffer saved in /tmp or in the current dir
-- You can edit commands as a buffer for testing things quickly.
-- Executes vim commands, not shell commands
local buf_utils = {}

local vim = vim
local vapi = vim.api

buf_utils.init_config = function(opts)
  opts = opts or {}
  buf_utils.config = {
    winconf = buf_utils.init_winconf(opts.winconf or {}),
    binding_file = opts.binding_file or "/tmp/buf_utils.sh",
    time_compile = opts.time_compile or false,
  }
end

buf_utils.init_winconf = function(opts)
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

buf_utils.create_buf_win_pair = function(opts)
  opts = opts or {}
  local buf = nil
  if vapi.nvim_buf_is_valid(opts.buf) then
    buf = opts.buf
  else
    buf = vapi.nvim_create_buf(opts.buf_config.listed or false, opts.buf_config.scratch or true)
  end

  -- vapi.nvim_buf_set_name(buf, opts.name or vapi.nvim_buf_get_name(buf))
  local win = vapi.nvim_open_win(buf, true, opts.winconfig or buf_utils.config.winconf)
  return {buf = buf, win = win}
end

buf_utils.toggle_floating_term = function(opts)
  opts = opts or {}
  buf_utils.term = buf_utils.term or { buf = -1, win = -1 }
  if not vapi.nvim_win_is_valid(buf_utils.term.win) then
    buf_utils.term = buf_utils.create_buf_win_pair({buf = buf_utils.term.buf, winconfig = opts.winconfig or buf_utils.config.winconf})
    if vim.bo[buf_utils.term.buf].buftype ~= "terminal" then
      vim.cmd.terminal()
    end
  else
    vapi.nvim_win_hide(buf_utils.term.win)
  end
end

buf_utils.toggle_scratch = function(opts)
  opts = opts or {}
  buf_utils.scratch = buf_utils.scratch or { buf = -1, win = -1 }
  if not vapi.nvim_win_is_valid(buf_utils.scratch.win) then
    buf_utils.scratch = buf_utils.create_buf_win_pair({buf = buf_utils.scratch.buf, winconfig = opts.winconfig or buf_utils.config.winconf})
  else
    vapi.nvim_win_hide(buf_utils.scratch.win)
  end
end


buf_utils.setup = function(opts)
  opts = opts or {}

  buf_utils.config = buf_utils.init_config(opts.config or {})
  if opts.with_keymaps then
    vim.keymap.set('n', '<leader>t', buf_utils.toggle_floating_term, { noremap = true, silent = true })
    vim.keymap.set('n', '<leader>bs', buf_utils.toggle_scratch, { noremap = true, silent = true })
  end
end

buf_utils.setup()

return buf_utils
