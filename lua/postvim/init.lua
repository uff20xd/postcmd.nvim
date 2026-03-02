local postvim = {}
local vim = vim
local vapi = vim.api


----------------------------------------------------
-- Sektion: Buf Utils
----------------------------------------------------

local buf_utils = {}

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
  opts.win = opts.win or -1
  opts.buf = opts.buf or -1
  opts.buf_config = opts.buf_config or {}
  local buf = nil
  if vapi.nvim_buf_is_valid(opts.buf) then
    buf = opts.buf
  else
    buf = vapi.nvim_create_buf(opts.buf_config.listed or false, opts.buf_config.scratch or true)
  end
  local win = vapi.nvim_open_win(buf, true, buf_utils.init_winconf(opts.winconfig))
  return {buf = buf, win = win}
end

buf_utils.toggle_floating_term = function(opts)
  local pair = buf_utils.toggle_floating_win(opts)
  if vim.bo[pair.buf].buftype ~= "terminal" then
    vim.cmd.terminal()
  end
  return pair
end

buf_utils.toggle_floating_win = function(opts)
  opts = opts or {}
  opts.win = opts.win or -1
  opts.buf = opts.buf or -1
  local pair = {}
  if not vapi.nvim_win_is_valid(opts.win) then
    pair = buf_utils.create_buf_win_pair({
      buf = opts.buf,
      winconfig = buf_utils.init_winconf(opts.winconfig or {})
    })
  else
    vapi.nvim_win_hide(opts.win)
  end

  return {win = pair.win or opts.win, buf = pair.buf or opts.buf}
end

postvim.buf_utils = buf_utils

----------------------------------------------------
-- Sektion: Action Menu
----------------------------------------------------

local action_menu = {}

action_menu.init_menu_conf = function(opts)
  opts = opts or {}
  local menu_conf = {
    winconfig = buf_utils.init_winconf(opts.winconf or {}),
    actions = opts.actions or {
      {name = "Empty Action", action = function() end, desc = "Empty Description"}
    },
    select_key = opts.select_key or "l",
    buf_config = opts.buf_config or {}
  }
  return menu_conf
end

action_menu.select_action = function(opts, buf)
  local line = vim.api.nvim_win_get_cursor(0);
  vapi.nvim_buf_delete(buf, {})
  local _ = opts.actions[line[1]].action()
end

action_menu.create = function(opts)
  local conf = action_menu.init_menu_conf(opts)
  local menu_pair = buf_utils.create_buf_win_pair(conf)
  local menu_buf = menu_pair.buf
  local menu_win = menu_pair.win
  for i, action in ipairs(conf.actions) do
    vapi.nvim_buf_set_lines(menu_buf, i - 1, i, false, { (action.name .. ": " .. (action.desc or "//")) })
  end
  vim.bo[menu_buf].modifiable = false
  vim.keymap.set("n", conf.select_key, function() action_menu.select_action(conf, menu_buf) end, {noremap = true, silent = true, buffer = menu_buf})
  return {buf = menu_buf, win = menu_win}
end

postvim.action_menu = action_menu
----------------------------------------------------
-- Sektion: Config
----------------------------------------------------
postvim.prequire = function(package)
  local ok, mod = pcall(require, package)
  if not ok then
    mod = nil
  end
  return mod
end

postvim.inbuilt = {
  scratch = {},
  fterm = {},
  action_menu = {}
}

postvim.setup = function(opts)
  opts = opts or {}
  opts.fterm = opts.fterm or {}
  opts.fterm.enable = opts.fterm.enable or true
  if opts.fterm.enable then
    vim.keymap.set('n', '<leader>t',
    function()
      postvim.inbuilt.fterm = buf_utils.toggle_floating_term(postvim.inbuilt.fterm)
    end, { noremap = true, silent = true, desc = "Toggles a persistent floating terminal. (PostVim)" })

    vim.keymap.set('n', '<leader>bs',
    function()
      postvim.inbuilt.scratch = buf_utils.toggle_floating_win(postvim.inbuilt.scratch)
    end, { noremap = true, silent = true, desc = "Toggles a persistent scratch buffer. (PostVim)" })
  end

  opts.action_menu = opts.fterm or {}
  opts.action_menu.enable = opts.fterm.enable or true
  if action_menu then
    local conf = {
      actions = {
        {name = "Enable  Treesitter", action = vim.treesitter.start, desc = "Enables Treesitter in the current buffer."},
        {name = "Disable Treesitter", action = vim.treesitter.stop, desc = "Disables Treesitter in the current buffer."},
      }
    }
    vim.keymap.set("n", "<leader>a", function()
      local pair = action_menu.create(conf)

      vim.keymap.set("n", "<leader>a", function() vapi.nvim_buf_delete(pair.buf, {}) end, {noremap = true, silent = true, buffer = pair.buf})
    end, { noremap = true, silent = true})

  end
end

postvim.setup()

return postvim
