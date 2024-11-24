local nerd_font_enabled = require('config.config').nerd_font_enabled

local M = {}

-- -@type table<string, {[1]:string, [2]:string }>
local nerd_font_icons_and_fallback = {
    ---------------------------------------------------------------------------
    ---General Icons
    git_branch = { '', 'G' },
    lsp_icon = { '', 'LSP' },
    format_icon = { '', 'F' },
    macro_recording = { '', 'REC' },
    file_readonly = { '', 'L' },
    terminal_icon = { '', 'term' },
    mode_icon = { ' ', '' }, --including spaces here so I don't need to refactor heirline component

    ---------------------------------------------------------------------------
    ---Snippets
    snippit_jumpable_left = { ' ', '<- ' }, --including spaces here so I don't need to refactor heirline component
    snippit_jumpable_right = { ' ', ' ->' }, --including spaces here so I don't need to refactor heirline component
    snippit_icon = { '', 'snip' },

    ---------------------------------------------------------------------------
    ---Debug (DAP)
    debug_pause = { '', '||' },
    debug_play = { '', '|>' },
    debug_step_into = { '', 'v' },
    debug_step_over = { '', '>' },
    debug_step_out = { '', '^' },
    debug_step_back = { '', '<' },
    debug_run_last = { '', 'rl' },
    debug_terminate = { '', '|=|' },
    debug_disconnect = { '', 'x' },
    debug_debugging_active = { '', 'dap' },

    ---------------------------------------------------------------------------
    ---Overseer task runner
    overseer_status_canceled = { ' ', '[C]' },
    overseer_status_failure = { '󰅚 ', '[F]' },
    overseer_status_success = { '󰄴 ', '[S]' },
    overseer_status_running = { '󰑮 ', '[R]' },

    ---------------------------------------------------------------------------
    ---Diagnostics
    diagnostics_info = { ' ', 'I' },
    diagnostics_hint = { ' ', 'H' },
    diagnostics_warn = { ' ', 'W' },
    diagnostics_error = { ' ', 'E' },

    ---------------------------------------------------------------------------
    ---Neotest
    neotest_child_indent = { '│', '| ' },
    neotest_child_prefix = { '├', '|-' },
    neotest_collapsed = { '─', '--' },
    neotest_expanded = { '╮', '-v' },
    neotest_failed = { '', 'X' },
    neotest_final_child_indent = { ' ', ' ' },
    neotest_final_child_prefix = { '╰', 'L' },
    neotest_non_collapsible = { '─', '--' },
    neotest_notify = { '', 'T' },
    neotest_passed = { '', 'P' },
    neotest_running = { '', 'R' },
    neotest_skipped = { '', 'X' },
    neotest_unknown = { '', '?' },
    neotest_watching = { '', 'W' },
}

---@param name string
---@return string
M.get_icon = function(name)
    if nerd_font_icons_and_fallback[name] == nil then
        return ''
    elseif nerd_font_enabled then
        return nerd_font_icons_and_fallback[name][1]
    else
        return nerd_font_icons_and_fallback[name][2]
    end
end

return M
