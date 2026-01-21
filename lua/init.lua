-- Buffer saved in /tmp or in the current dir
-- You can edit commands as a buffer for testing things quickly.
-- Executes vim commands, not shell commands
local PostCmd = {}

local vapi = vim.api

PostCmd.open = function()
  if PostCmd.binding_file == NULL then
    return
  end
  if PostCmd.show then
    PostCmd.show = false
  else
    PostCmd.win = vapi.nvim_open_win(PostCmd.buf, true, {relative='win', row=3, col=3, width=40, height=4})
    PostCmd.show = true
  end
end

PostCmd.setup = function()
  PostCmd.buf = vapi.nvim_create_buf(true, true)
  PostCmd.binding_file = "/tmp/postcmd-session.sh"
  vapi.nvim_buf_set_name(buf, "postcmd")
end

return PostCmd

