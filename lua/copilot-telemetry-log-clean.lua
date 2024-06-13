---@class CopilotTelemetryLogCleaner
local M = {}

---@class Options
---@field lsp_log_path string The path to the lsp.log file. If nil, it will use the default log path
---@field condition fun(string): boolean A function that returns a boolean to determine what lines to clean
M.opts = {
  lsp_log_path = vim.lsp.get_log_path(),
  condition = function(line)
    return string.find(line, 'telemetry') ~= nil
  end,
}

---Clean the copilot log by removing telemetry lines
---@param opts Options
---@return boolean success
---@return string? error_message
M.clean = function(opts)
  vim.notify('Cleaning GitHub Copilot telemetry from LSP log', vim.log.levels.INFO)

  local context_manager = require 'plenary.context_manager'
  local with = context_manager.with
  local open = context_manager.open

  local temp_lsp_log_path = opts.lsp_log_path .. '.tmp'

  local telemetry_lines = 0
  local total_lines = 0

  local writer_result = with(open(temp_lsp_log_path, 'w'), function(writer)
    local reader_result = with(open(opts.lsp_log_path, 'r'), function(reader)
      for line in reader:lines() do
        if not opts.condition(line) then
          writer:write(line .. '\n')
        else
          telemetry_lines = telemetry_lines + 1
        end
      end
      return telemetry_lines
    end)
    return reader_result
  end)

  if writer_result == nil then
    vim.notify('Error cleaning log', vim.log.levels.ERROR)
    return false, 'Error cleaning log'
  end

  vim.notify(
    'Deleted ' .. telemetry_lines .. ' telemetry lines from ' .. total_lines .. ' total lines',
    vim.log.levels.INFO
  )

  local success, error_message = os.remove(opts.lsp_log_path)
  if not success then
    vim.notify('Error removing log: ' .. error_message, vim.log.levels.ERROR)
    return false, error_message
  end

  success, error_message = os.rename(temp_lsp_log_path, opts.lsp_log_path)
  if not success then
    vim.notify('Error renaming temp log: ' .. error_message, vim.log.levels.ERROR)
    return false, error_message
  end

  success, error_message = os.remove(temp_lsp_log_path)
  if not success then
    vim.notify('Error removing temp log: ' .. error_message, vim.log.levels.ERROR)
    return false, error_message
  end

  return true
end

---Setup the cleaner
---@param opts Options
function M.setup(opts)
  M.opts = vim.tbl_deep_extend('force', M.opts, opts or {})

  vim.api.nvim_create_autocmd('VimLeave', {
    desc = 'Clean GitHub Copilot telemetry and any other possible lines from LSP log',
    group = vim.api.nvim_create_augroup('kickstart-clean-copilot-log', { clear = true }),
    callback = function()
      M.clean(M.opts)
    end,
  })
end

return M
