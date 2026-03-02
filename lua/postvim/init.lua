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
-- Sektion: BufList
----------------------------------------------------
local buffer_menu = {}

buffer_menu.init_menu_conf = function (opts)
  opts = opts or {}
  local menu_conf = {
    winconfig = buf_utils.init_winconf(opts.winconf or {}),
    select_key_bind = opts.select_key_bind or "l",
    save_key_bind = opts.save_key_bind or "<leader>w",
    list_style = opts.list_style or "name",
    buf_config = opts.buf_config or {}
  }
  return menu_conf
end

buffer_menu.select_buf = function(opts, buf_list, buf, current_win)
  local line = vim.api.nvim_win_get_cursor(0);
  local new_buf_name = vapi.nvim_buf_get_lines(buf, line[1] - 1, line[1], false)[1]
  vapi.nvim_win_set_buf(current_win, buf_list[new_buf_name])
  vapi.nvim_buf_delete(buf, {})
end

buffer_menu.open = function(opts)
  local conf = buffer_menu.init_menu_conf(opts)
  local current_win = vapi.nvim_get_current_win()
  local menu_pair = buf_utils.create_buf_win_pair(conf)
  local menu_buf = menu_pair.buf
  local menu_win = menu_pair.win
  local buffer_list = {}
  local raw_buffer_list = vapi.nvim_list_bufs()
  local i = 1
  for _, buffer in ipairs(raw_buffer_list) do
    local buf_name = vapi.nvim_buf_get_name(buffer)
    if buf_name ~= "" and vapi.nvim_get_option_value("buflisted", { buf = buffer }) then
      buffer_list[buf_name] = buffer
      vapi.nvim_buf_set_lines(menu_buf, i - 1, i, false, { buf_name })
      i = i + 1
    end
  end
  vim.keymap.set("n", conf.select_key_bind, function() buffer_menu.select_buf(conf, buffer_list, menu_buf, current_win) end, {noremap = true, silent = true, buffer = menu_buf})
  vim.keymap.set("n", conf.save_key_bind, function() buffer_menu.save_menu(conf, buffer_list, current_win, menu_buf, menu_win) end, {noremap = true, silent = true, buffer = menu_buf})
  return {buf = menu_buf, win = menu_win}
end


buffer_menu.save_menu = function(opts, buf_list, current_win, menu_buf, menu_win)
  local buf_len = vapi.nvim_buf_line_count(menu_buf)
  local new_list = {}
  for i = 1, buf_len do
    local new_buf_name = vapi.nvim_buf_get_lines(menu_buf, i - 1, i, false)[1]
    new_list[new_buf_name] = buf_list[new_buf_name]
  end
  for k, v in pairs(buf_list) do
    if new_list[k] == nil then
      local _, _ = pcall(vapi.nvim_buf_delete, buf_list[k], {})
    end
  end
  -- vapi.nvim_buf_delete(buf_list[new_buf_name], {})
  vapi.nvim_win_close(menu_win, {})
  vapi.nvim_buf_delete(menu_buf, {})
end

postvim.buffer_menu = buffer_menu

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

  opts.action_menu = opts.action_menu or {}
  opts.action_menu.enable = opts.action_menu.enable or true
  if opts.action_menu.enable then
    local conf = {
      actions = {
        {name = "Enable  Treesitter", action = vim.treesitter.start, desc = "Enables Treesitter in the current buffer."},
        {name = "Disable Treesitter", action = vim.treesitter.stop, desc = "Disables Treesitter in the current buffer."},
      }
    }
    local bind = "<leader>a"

    vim.keymap.set("n", bind, function()
      local pair = action_menu.create(conf)
      vim.keymap.set("n", bind, function() vapi.nvim_buf_delete(pair.buf, {}) end, {noremap = true, silent = true, buffer = pair.buf})
    end, { noremap = true, silent = true})
  end

  opts.buffer_menu = opts.buffer_menu or {}
  opts.buffer_menu.enable = opts.buffer_menu.enable or true
  if opts.buffer_menu.enable then
    local conf = {}
    local bind = "<leader>bl"
    vim.keymap.set("n", bind, function()
      local pair = buffer_menu.open(conf)
      vim.keymap.set("n", bind, function() vapi.nvim_buf_delete(pair.buf, {}) end, {noremap = true, silent = true, buffer = pair.buf})
    end, { noremap = true, silent = true})
  end
end

postvim.setup()

return postvim
