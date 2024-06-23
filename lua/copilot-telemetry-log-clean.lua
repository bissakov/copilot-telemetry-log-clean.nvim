---@class CopilotTelemetryLogCleaner
local M = {}

---@class Options
---@field lsp_log_path string The path to the lsp.log file. If nil, it will use the default log path
---@field condition fun(string): boolean A function that returns a boolean to determine what lines to clean
---@field timeout number The maximum time in milliseconds to attempt the operation
M.opts = {
  lsp_log_path = vim.lsp.get_log_path(),
  condition = function(line)
    return string.find(line, 'telemetry') ~= nil
  end,
  timeout = 5000,
}

---Reads lines from the lsp log and writes non-telemetry lines to a temporary file
---@param opts Options
---@param temp_lsp_log_path string The path to the temporary log file
---@return number found_count The number of telemetry lines found
---@return boolean success
---@return string? error_message
M.process_log_lines = function(opts, temp_lsp_log_path)
  local context_manager = require 'plenary.context_manager'
  local with = context_manager.with
  local open = context_manager.open

  local found_count = 0

  local success = with(open(temp_lsp_log_path, 'w'), function(writer)
    local success = with(open(opts.lsp_log_path, 'r'), function(reader)
      for line in reader:lines() do
        if not opts.condition(line) then
          writer:write(line .. '\n')
        else
          found_count = found_count + 1
        end
      end
      return true
    end)

    if success == false then
      return false, 'Error reading log lines'
    end

    return true, nil
  end)

  if success == false then
    return found_count, false, 'Error processing log lines'
  end

  return found_count, true, nil
end

---Attempt to perform a file operation with retries until timeout
---@param operation function The file operation to perform
---@param timeout number The maximum time in milliseconds to attempt the operation
---@return boolean success
---@return string? error_message
M.retry_with_timeout = function(operation, timeout)
  local start_time = vim.loop.hrtime()
  local timeout_ns = timeout * 1e6

  while true do
    local success, error_message = operation()
    if success then
      return true
    end

    if vim.loop.hrtime() - start_time > timeout_ns then
      return false, error_message
    end

    vim.wait(100)
  end
end

---Replace the original log file with the cleaned temporary log file
---@param opts Options
---@param temp_lsp_log_path string The path to the temporary log file
---@return boolean success
---@return string? error_message
M.replace_log_file = function(opts, temp_lsp_log_path)
  local operations = {
    function()
      return os.remove(opts.lsp_log_path)
    end,
    function()
      return os.rename(temp_lsp_log_path, opts.lsp_log_path)
    end,
    function()
      return os.remove(temp_lsp_log_path)
    end,
  }

  for _, operation in ipairs(operations) do
    local success, error_message = M.retry_with_timeout(operation, opts.timeout)
    if not success then
      return false, error_message
    end
  end

  return true
end

---Clean the copilot log by removing telemetry lines
---@param opts Options
---@return boolean success
---@return string? error_message
M.clean = function(opts)
  local temp_lsp_log_path = opts.lsp_log_path .. '.tmp'

  local found_count, success, error_message = M.process_log_lines(opts, temp_lsp_log_path)
  if not success then
    return false, error_message
  end

  if found_count == 0 then
    success, error_message = os.remove(temp_lsp_log_path)
    if not success then
      return false, error_message
    end

    return true
  end

  success, error_message = M.replace_log_file(opts, temp_lsp_log_path)
  if not success then
    return false, error_message
  end

  return true
end

---Setup the cleaner
---@param opts Options?
function M.setup(opts)
  local fidget = require 'fidget'

  local clients = vim.lsp.get_clients()
  if #clients == 0 then
    return
  end
  for _, client in ipairs(clients) do
    client.stop()
  end

  M.opts = vim.tbl_deep_extend('force', M.opts, opts or {})

  vim.api.nvim_create_autocmd('VimLeavePre', {
    desc = 'Clean GitHub Copilot telemetry and any other possible lines from LSP log',
    group = vim.api.nvim_create_augroup('kickstart-clean-copilot-log', { clear = true }),
    callback = function()
      local success, error_message = M.clean(M.opts)
      if not success then
        fidget.notify('Error cleaning log: ' .. error_message, vim.log.levels.ERROR)
      end
    end,
  })
end

return M
