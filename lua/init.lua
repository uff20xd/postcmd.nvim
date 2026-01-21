-- Buffer saved in /tmp or in the current dir
-- You can edit commands as a buffer for testing things quickly.
-- Executes vim commands, not shell commands
local PostCmd = {}

local vapi = vim.api


PostCmd.setup = function()
  PostCmd.buf = vapi.nvim_create_buf(true, true)
  vapi.nvim_buf_set_name(buf, "postcmd")
end

