return {

  { -- Linting
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'
      lint.linters.flake8 = {
        name = 'flake8',
        cmd = vim.fn.expand '~/.local/share/nvim/mason/bin/flake8', -- Add the Mason path
        args = {}, -- Optional: customize args
        stdin = false, -- Flake8 does not support stdin
        stream = 'stderr', -- flake8 outputs messages to stderr
        parser = function(output, _)
          print('Flake8 Output:\n' .. output)

          local diagnostics = {}
          for _, line in ipairs(vim.split(output, '\n')) do
            local filename, row, col, code, message = line:match '([^:]+):(%d+):(%d+):%s*(%w+)%s+(.*)'
            if filename and row and col and code and message then
              local severity = vim.lsp.protocol.DiagnosticSeverity.Warning -- Default severity
              if code:sub(1, 1) == 'E' then
                severity = vim.lsp.protocol.DiagnosticSeverity.Error
              end
              table.insert(diagnostics, {
                source = 'flake8',
                lnum = tonumber(row) - 1, -- line number (0-indexed)
                col = tonumber(col) - 1, -- column number (0-indexed)
                message = message,
                severity = severity,
                code = code,
              })
            end
          end
          return diagnostics
        end,
      }
      lint.linters_by_ft = {
        python = { 'flake8' },
      }

      -- Create autocommand which carries out the actual linting
      -- on the specified events.
      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          -- Only run the linter in buffers that you can modify in order to
          -- avoid superfluous noise, notably within the handy LSP pop-ups that
          -- describe the hovered symbol using Markdown.
          if vim.bo.modifiable then
            lint.try_lint()
          end
        end,
      })
    end,
  },
}
