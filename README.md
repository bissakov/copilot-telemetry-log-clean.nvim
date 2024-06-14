# copilot-telemetry-log-clean.nvim

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/ellisonleao/nvim-plugin-template/lint-test.yml?branch=main&style=for-the-badge)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

Clean lsp.log from GitHub Copilot telemetry messages

<!-- TOC -->

- [Motivation](#motivation)
- [Requirements](#requirements)
- [Installation](#installation)

<!-- /TOC -->

## Motivation

GitHub Copilot tends to clutter the lsp.log file with telemetry messages. Especially when the requests to telemetry server are filtered by DNS rules, such as Pi-hole or NextDNS.
Example:
```
[ERROR][2024-06-13 15:00:05] ...lsp/handlers.lua:623	"[default] Error sending telemetry FetchError: getaddrinfo ENOENT copilot-telemetry-service.githubusercontent.com\n    at fetch (C:\\Users\\bissa\\AppData\\Local\\nvim-data\\lazy\\copilot.vim\\node_modules\\@adobe\\helix-fetch\\src\\fetch\\index.js:99:11)\n    at processTicksAndRejections (node:internal/process/task_queues:95:5)\n    at cachingFetch (C:\\Users\\bissa\\AppData\\Local\\nvim-data\\lazy\\copilot.vim\\node_modules\\@adobe\\helix-fetch\\src\\fetch\\index.js:288:16)\n    at Kre.fetch (C:\\Users\\bissa\\AppData\\Local\\nvim-data\\lazy\\copilot.vim\\lib\\src\\network\\helix.ts:78:22) {\n  type: 'system',\n  _name: 'FetchError',\n  code: 'ENOENT',\n  errno: -4058,\n  erroredSysCall: 'getaddrinfo'\n}"
```
This plugin aims to clean the lsp.log file upon exitting Neovim.

## Requirements

- Neovim >= 0.5.0

## Installation

- lazy.nvim

```lua
{
  'bissakov/copilot-telemetry-log-clean.nvim',
  -- default options
  -- opts = {
  --   lsp_log_path = vim.lsp.get_log_path(),
  --   condition = function(line)
  --     return string.find(line, 'telemetry') ~= nil
  --   end,
  --   timeout = 5000,
  -- },
  dependencies = {
    'j-hui/fidget.nvim',
    'nvim-lua/plenary.nvim',
  },
  config = function()
    require('copilot-telemetry-log-clean').setup()
  end,
}
```

