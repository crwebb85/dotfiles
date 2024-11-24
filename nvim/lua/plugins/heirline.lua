local get_icon = require('config.icons').get_icon
local config = function()
    local heirline = require('heirline')
    local conditions = require('heirline.conditions')
    local heirlineUtils = require('heirline.utils')
    local colors = require('tokyonight.colors').setup()

    heirline.load_colors(colors)

    local background_color = colors.bg_dark
    local active_background_color = colors.fg_dark
    local inactive_background_color = background_color

    local recording_background_color = colors.bg_highlight
    local diagnostics_error_foreground = colors.red
    local recording_foreground_color = colors.red
    local scrollbar_foreground_color = colors.fg_sidebar
    local scrollbar_background_color = background_color
    local diagnostics_warning_foreground_color = colors.warning
    local diagnostics_info_foreground_color = colors.info
    local diagnostics_hint_foreground_color = colors.hint
    local git_branch_name_foreground_color = colors.green2
    local gitsigns_add_foreground_color = colors.git.add
    local gitsigns_delete_foreground_color = colors.git.delete
    local gitsigns_change_foreground_color = colors.git.change
    local macro_recording_forground_color = colors.red1
    local filename_foreground_color = colors.magenta2
    local file_flags_foreground_color = colors.green2
    local filetype_foreground_color = colors.magenta
    local buftype_foreground_color = colors.green2

    local winbar_inactive = {
        buftype = { 'nofile', 'prompt', 'quickfix', 'terminal' },
        filetype = { 'toggleterm', 'qf', 'terminal', 'gypsy' },
    }

    local Align = { provider = '%=' }
    local Space = { provider = ' ' }
    local Seperator = { provider = '|' }

    local diagnostics_spacer = ' '
    local Diagnostics = {
        condition = conditions.has_diagnostics,
        static = {
            info_icon = get_icon('diagnostics_info'),
            hint_icon = get_icon('diagnostics_hint'),
            warn_icon = get_icon('diagnostics_warn'),
            error_icon = get_icon('diagnostics_error'),
        },
        init = function(self)
            local buf_sev_counts = vim.diagnostic.count(0, {})
            self.errors = buf_sev_counts[vim.diagnostic.severity.ERROR] or 0
            self.warnings = buf_sev_counts[vim.diagnostic.severity.WARN] or 0
            self.hints = buf_sev_counts[vim.diagnostic.severity.HINT] or 0
            self.info = buf_sev_counts[vim.diagnostic.severity.INFO] or 0
        end,
        update = { 'DiagnosticChanged', 'BufEnter', 'WinEnter' },
        Space,
        {
            provider = function(self)
                return self.errors > 0
                        and (self.error_icon .. self.errors .. diagnostics_spacer)
                    or ''
            end,
            hl = { fg = diagnostics_error_foreground },
        },
        {
            provider = function(self)
                return self.warnings > 0
                    and (self.warn_icon .. self.warnings .. diagnostics_spacer)
            end,
            hl = { fg = diagnostics_warning_foreground_color },
        },
        {
            provider = function(self)
                return self.info > 0
                    and (self.info_icon .. self.info .. diagnostics_spacer)
            end,
            hl = { fg = diagnostics_info_foreground_color },
        },
        {
            provider = function(self)
                return self.hints > 0
                    and (self.hint_icon .. self.hints .. diagnostics_spacer)
            end,
            hl = { fg = diagnostics_hint_foreground_color },
        },
        hl = { bg = background_color },
    }

    -- Show which vim mode I am using
    local ViMode = {
        -- get vim current mode, this information will be required by the provider
        -- and the highlight functions, so we compute it only once per component
        -- evaluation and store it as a component attribute
        init = function(self)
            self.mode = vim.fn.mode(1) -- :h mode()
        end,
        -- Now we define some dictionaries to map the output of mode() to the
        -- corresponding string and color. We can put these into `static` to compute
        -- them at initialisation time.
        static = {
            mode_names = {
                n = 'N',
                no = 'N?',
                nov = 'N?',
                noV = 'N?',
                ['no\22'] = 'N?',
                niI = 'Ni',
                niR = 'Nr',
                niV = 'Nv',
                nt = 'Nt',
                v = 'V',
                vs = 'Vs',
                V = 'V_',
                Vs = 'Vs',
                ['\22'] = '^V',
                ['\22s'] = '^V',
                s = 'S',
                S = 'S_',
                ['\19'] = '^S',
                i = 'I',
                ic = 'Ic',
                ix = 'Ix',
                R = 'R',
                Rc = 'Rc',
                Rx = 'Rx',
                Rv = 'Rv',
                Rvc = 'Rv',
                Rvx = 'Rv',
                c = 'C',
                cv = 'Ex',
                r = '...',
                rm = 'M',
                ['r?'] = '?',
                ['!'] = '!',
                t = 'T',
            },
            mode_colors = {
                n = 'red',
                i = 'green',
                v = 'cyan',
                V = 'cyan',
                ['\22'] = 'cyan',
                c = 'orange',
                s = 'purple',
                S = 'purple',
                ['\19'] = 'purple',
                R = 'orange',
                r = 'orange',
                ['!'] = 'red',
                t = 'red',
            },
        },
        -- We can now access the value of mode() that, by now, would have been
        -- computed by `init()` and use it to index our strings dictionary.
        -- note how `static` fields become just regular attributes once the
        -- component is instantiated.
        -- To be extra meticulous, we can also add some vim statusline syntax to
        -- control the padding and make sure our string is always at least 2
        -- characters long. Plus a nice Icon.
        provider = function(self)
            return get_icon('mode_icon')
                .. '%2('
                .. self.mode_names[self.mode]
                .. '%)'
        end,
        -- Same goes for the highlight. Now the foreground will change according to the current mode.
        hl = function(self)
            local mode = self.mode:sub(1, 1) -- get only the first mode character
            return { fg = self.mode_colors[mode], bold = true }
        end,
        -- Re-evaluate the component only on ModeChanged event!
        -- Also allows the statusline to be re-evaluated when entering operator-pending mode
        update = {
            'ModeChanged',
            pattern = '*:*',
            callback = vim.schedule_wrap(
                function() vim.cmd('redrawstatus') end
            ),
        },
    }

    local Git = {
        condition = conditions.is_git_repo,
        init = function(self)
            self.status_dict = vim.b.gitsigns_status_dict
            self.has_changes = self.status_dict.added ~= 0
                or self.status_dict.removed ~= 0
                or self.status_dict.changed ~= 0
        end,
        Space,
        {
            provider = function(self)
                return get_icon('git_branch')
                    .. ' '
                    .. self.status_dict.head
                    .. ' '
            end,
            hl = {
                fg = git_branch_name_foreground_color,
                bold = true,
                italic = true,
            },
        },
        {
            condition = function(self) return self.has_changes end,
            {
                provider = function(self)
                    local count = self.status_dict.added or 0
                    return count > 0 and ('+' .. count .. ' ')
                end,
                hl = { fg = gitsigns_add_foreground_color, bold = true },
            },
            {
                provider = function(self)
                    local count = self.status_dict.removed or 0
                    return count > 0 and ('-' .. count .. ' ')
                end,
                hl = { fg = gitsigns_delete_foreground_color, bold = true },
            },
            {
                provider = function(self)
                    local count = self.status_dict.changed or 0
                    return count > 0 and ('~' .. count .. ' ')
                end,
                hl = { fg = gitsigns_change_foreground_color, bold = true },
            },
            hl = { bg = background_color },
        },
        Seperator,
    }

    ---@return string
    local function get_yaml_schema_name()
        local schema = require('yaml-companion').get_buf_schema(0)
        if schema.result[1].name == 'none' then return '' end
        return schema.result[1].name
    end

    ---@type StatusLine
    local LSPActive = {
        condition = conditions.lsp_attached,
        update = { 'LspAttach', 'LspDetach', 'BufEnter' },

        Space,
        {
            provider = function()
                local names = {}
                for _, client in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
                    local name = client.name
                    if client.name == 'yamlls' then
                        name = 'yamlls(' .. get_yaml_schema_name() .. ')'
                    end
                    table.insert(names, tostring(client.id) .. ':' .. name)
                end
                return get_icon('lsp_icon')
                    .. ' ['
                    .. table.concat(names, ' ')
                    .. ']'
            end,
            hl = { fg = 'green', bold = true },
        },
        Space,
        Seperator,
    }

    local formatter_component_block = {
        update = {
            'User',
            pattern = { 'FormatterChange.*', 'MyHeirlineProxiedBufEnter' },
        },
        init = function(self)
            -- vim.print(self)
            local children = {}
            local bufnr = vim.api.nvim_get_current_buf()
            local filetype = vim.bo[bufnr].filetype
            local formatters =
                require('config.formatter').properties.get_project_formatters(
                    filetype
                )

            local project_disabled_formatters =
                require('config.formatter').properties.get_project_disabled_formatters_set()
            local buffer_disabled_formatters =
                require('config.formatter').properties.get_buffer_disabled_formatters_set(
                    bufnr
                )
            local lsp_format_strategy =
                require('config.formatter').determine_conform_lsp_fallback(
                    bufnr
                )

            local is_any_formatter_enabled = false
            if lsp_format_strategy ~= 'prefer' then
                for i, formatter in pairs(formatters) do
                    ---@type StatusLine
                    local formatter_component = {
                        provider = vim.fn.trim(formatter),
                    }
                    if
                        not require('conform').get_formatter_info(formatter).available
                    then
                        formatter_component.hl =
                            { fg = 'red', bold = true, strikethrough = true }
                    elseif project_disabled_formatters[formatter] then
                        formatter_component.hl = { fg = 'red', bold = true }
                    elseif buffer_disabled_formatters[formatter] then
                        formatter_component.hl = { fg = 'orange', bold = true }
                    else
                        is_any_formatter_enabled = true
                    end
                    table.insert(children, formatter_component)
                    if i < #formatters then table.insert(children, Space) end
                end
            end

            if
                lsp_format_strategy == 'last'
                or lsp_format_strategy == 'prefer'
                or (
                    lsp_format_strategy == 'fallback'
                    and not is_any_formatter_enabled
                )
            then
                if #children > 0 then table.insert(children, Space) end
                -- add lsp formatters to the end of the list
                local lsp_formatters =
                    require('config.formatter').get_buffer_lsp_formatters(bufnr)
                for i, lsp_formatter in ipairs(lsp_formatters) do
                    ---@type StatusLine
                    local formatter_component = {
                        provider = vim.fn.trim(lsp_formatter.name),
                    }
                    table.insert(children, formatter_component)
                    if i < #formatters then table.insert(children, Space) end
                end
            elseif lsp_format_strategy == 'first' then
                -- add lsp formatters to the begining of the list
                local alt_children = {}
                local lsp_formatters =
                    require('config.formatter').get_buffer_lsp_formatters(bufnr)
                for i, lsp_formatter in ipairs(lsp_formatters) do
                    ---@type StatusLine
                    local formatter_component = {
                        provider = vim.fn.trim(lsp_formatter.name),
                    }
                    table.insert(alt_children, formatter_component)
                    if i < #formatters then
                        table.insert(alt_children, Space)
                    end
                end
                for _, child in ipairs(children) do
                    table.insert(alt_children, child)
                end
                children = alt_children
            end
            self.child = self:new(children, 1)
        end,
        provider = function(self) return self.child:eval() end,
    }

    ---Need to proxy the BufEnter event as a User event so that I can match the
    ---pattern of user commands in my formatter block
    vim.api.nvim_create_autocmd({ 'BufEnter' }, {
        group = vim.api.nvim_create_augroup(
            'MyHeirlineProxiedBufEnter',
            { clear = true }
        ),
        callback = function(_)
            vim.api.nvim_exec_autocmds('User', {
                pattern = 'MyHeirlineProxiedBufEnter',
            })
        end,
    })

    ---@type StatusLine
    local FormatterActive = {
        condition = function(_)
            local buffer_formatter_details =
                require('config.formatter').get_buffer_enabled_formatter_list()
            local lsp_formatters =
                require('config.formatter').get_buffer_lsp_formatters()
            return #buffer_formatter_details > 0 or #lsp_formatters > 0
        end,
        update = {
            'User',
            pattern = { 'FormatterChange.*', 'MyHeirlineProxiedBufEnter' },
        },
        Space,
        {
            {
                provider = get_icon('format_icon'),
            },
            Space,
            {
                provider = '[',
            },

            formatter_component_block,
            {
                provider = ']',
            },

            hl = function()
                local is_format_after_save_enabled =
                    require('config.formatter').properties.is_format_after_save_enabled(
                        vim.bo.filetype
                    )
                if
                    require('config.formatter').properties.is_project_autoformat_disabled()
                then
                    return {
                        fg = 'red',
                        bold = true,
                        italic = is_format_after_save_enabled,
                    }
                elseif
                    require('config.formatter').properties.is_buffer_autoformat_disabled(
                        vim.api.nvim_get_current_buf()
                    )
                then
                    return { fg = 'orange', bold = true }
                else
                    return {
                        fg = 'green',
                        bold = true,
                        italic = is_format_after_save_enabled,
                    }
                end
            end,
        },
        Space,
        Seperator,
    }

    local MacroRecording = {
        condition = conditions.is_active,
        init = function(self)
            self.reg_recording = vim.fn.reg_recording()
            self.status_dict = vim.b.gitsigns_status_dict
                or { added = 0, removed = 0, changed = 0 }
            self.has_changes = self.status_dict.added ~= 0
                or self.status_dict.removed ~= 0
                or self.status_dict.changed ~= 0
        end,
        {
            condition = function(self) return self.reg_recording ~= '' end,
            Space,
            {
                provider = get_icon('macro_recording'),
                hl = { fg = macro_recording_forground_color },
            },
            Space,
            Space,
            {
                provider = function(self) return '@' .. self.reg_recording end,
                hl = { italic = false, bold = true },
            },
            {
                Space,
            },
            hl = {
                bg = recording_background_color,
                fg = recording_foreground_color,
            },
        },
        update = { 'RecordingEnter', 'RecordingLeave' },
    }

    ---@type StatusLine
    local Snippets = {
        -- check that we are in insert or select mode
        condition = function()
            return vim.tbl_contains({ 's', 'i' }, vim.fn.mode())
                and require('luasnip').in_snippet()
        end,
        Space,
        {
            provider = function()
                local backward = require('luasnip').jumpable(-1)
                        and get_icon('snippet_jumpable_left')
                    or ''
                local forward = require('luasnip').jumpable(1)
                        and get_icon('snippet_jumpable_right')
                    or ''
                return backward .. get_icon('snippet_icon') .. forward
            end,
            hl = { fg = 'red', bold = true },
        },
        Space,
        Seperator,
    }

    local function rpad(child)
        return {
            condition = child.condition,
            child,
            Space,
        }
    end
    local function OverseerTasksForStatus(status)
        return {
            condition = function(self) return self.tasks[status] end,
            provider = function(self)
                return string.format(
                    '%s%d',
                    self.symbols[status],
                    #self.tasks[status]
                )
            end,
            hl = function(_)
                return {
                    fg = heirlineUtils.get_highlight(
                        string.format('Overseer%s', status)
                    ).fg,
                }
            end,
        }
    end

    local Overseer = {
        condition = function() return package.loaded.overseer end,
        init = function(self)
            local tasks =
                require('overseer.task_list').list_tasks({ unique = true })
            local tasks_by_status =
                require('overseer.util').tbl_group_by(tasks, 'status')
            self.tasks = tasks_by_status
        end,
        static = {
            symbols = {
                ['CANCELED'] = get_icon('overseer_status_canceled'),
                ['FAILURE'] = get_icon('overseer_status_failure'),
                ['SUCCESS'] = get_icon('overseer_status_success'),
                ['RUNNING'] = get_icon('overseer_status_running'),
            },
        },
        Space,

        rpad(OverseerTasksForStatus('CANCELED')),
        rpad(OverseerTasksForStatus('RUNNING')),
        rpad(OverseerTasksForStatus('SUCCESS')),
        rpad(OverseerTasksForStatus('FAILURE')),
    }

    -- Note that we add spaces separately, so that only the icon characters will be clickable
    local DAPMessages = {
        condition = function()
            return package.loaded.dap and require('dap').session() ~= nil
        end,
        {
            provider = function()
                return get_icon('debug_debugging_active')
                    .. ' '
                    .. require('dap').status()
                    .. ' '
            end,
            on_click = {
                callback = function() require('dap').focus_frame() end,
                name = 'heirline_dap_goto',
            },
        },
        hl = 'Debug',

        {
            provider = get_icon('debug_play'),
            on_click = {
                callback = function() require('dap').continue() end,
                name = 'heirline_dap_play',
            },
        },
        { provider = ' ' },
        {
            provider = get_icon('debug_step_into'),
            on_click = {
                callback = function() require('dap').step_into() end,
                name = 'heirline_dap_step_into',
            },
        },
        { provider = ' ' },
        {
            provider = get_icon('debug_step_over'),
            on_click = {
                callback = function() require('dap').step_over() end,
                name = 'heirline_dap_step_over',
            },
        },
        { provider = ' ' },
        {
            provider = get_icon('debug_step_out'),
            on_click = {
                callback = function() require('dap').step_out() end,
                name = 'heirline_dap_step_out',
            },
        },
        -- { provider = ' ' },
        -- {
        --     provider = get_icon('debug_step_back'),
        --     on_click = {
        --         callback = function() require('dap').step_back() end,
        --         name = 'heirline_dap_step_back',
        --     },
        -- },
        { provider = ' ' },
        {
            provider = get_icon('debug_run_last'),
            on_click = {
                callback = function() require('dap').run_last() end,
                name = 'heirline_dap_run_last',
            },
        },
        { provider = ' ' },
        {
            provider = get_icon('debug_terminate'),
            on_click = {
                callback = function()
                    require('dap').terminate()
                    require('dapui').close({})
                end,
                name = 'heirline_dap_close',
            },
        },
        { provider = ' ' },
    }

    ---@type StatusLine
    local Ruler = {
        -- %l = current line number
        -- %L = number of lines in the buffer
        -- %c = column number
        -- %P = percentage through file of displayed window
        provider = '%7(%l/%3L%):%2c %P',
    }

    local ScrollBar = {
        static = {
            sbar = { '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█' },
        },
        provider = function(self)
            local curr_line = vim.api.nvim_win_get_cursor(0)[1]
            local lines = vim.api.nvim_buf_line_count(0)
            local i = math.floor((curr_line - 1) / lines * #self.sbar) + 1
            return string.rep(self.sbar[i], 2)
        end,
        hl = {
            fg = scrollbar_foreground_color,
            bg = scrollbar_background_color,
        },
    }

    local ComponentDelimiter = { '', ' |' }

    ---@type StatusLine
    local StatusLines = {
        MacroRecording,
        heirlineUtils.surround(ComponentDelimiter, nil, ViMode),
        Git,
        LSPActive,
        FormatterActive,
        Snippets,
        Overseer,
        DAPMessages,
        Align,
        Diagnostics,
        Ruler,
        ScrollBar,
        hl = { bg = background_color },
    }

    ---------------------------------------------------------------------------
    -- Winbar

    -- Italicizes the buffer file name if it has been modified
    ---@type StatusLine
    local FileNameModifer = {
        hl = function()
            if vim.bo.modified then return { italic = true, force = true } end
        end,
    }

    local FileIcon = {
        init = function(self)
            local filename = self.filename
            -- local get_hex = function(hl)
            --     if hl == nil then return nil end
            --     return string.format(
            --         '#%06x',
            --         vim.api.nvim_get_hl(0, { name = hl }).fg or 7176326
            --     )
            -- end
            -- local hl = nil
            -- self.icon, hl = require('mini.icons').get('file', filename)
            -- self.icon_color = get_hex(hl)
            self.icon, self.icon_hl_group =
                require('mini.icons').get('file', filename)
            self.icon_hl = vim.api.nvim_get_hl(0, { name = self.icon_hl_group })

            -- local extension = vim.fn.fnamemodify(filename, ':e')
            -- self.icon, self.icon_color =
            --     require('nvim-web-devicons').get_icon_color(
            --         filename,
            --         extension,
            --         { default = true }
            --     )
        end,
        provider = function(self)
            if self.filename == '' then
                return ''
            else
                return self.icon and (self.icon .. ' ')
            end
        end,
        -- hl = function(self) return { fg = self.icon_color } end,
        hl = function(self) return self.icon_hl or {} end,
    }

    local FileName = {
        provider = function(self)
            local filename = vim.fn.fnamemodify(self.filename, ':~:.')
            if filename == '' then return '' end
            if not conditions.width_percent_below(#filename, 1) then
                filename = vim.fn.pathshorten(filename)
            end
            return filename
        end,
        hl = { fg = filename_foreground_color, bold = true },
    }

    ---@type StatusLine
    local FileFlags = {
        {
            -- shows if buffer is unsaved
            provider = function()
                if vim.bo.modified then return '[+] ' end
            end,
            hl = {
                fg = file_flags_foreground_color,
                bold = true,
                italic = true,
            },
        },
        {
            -- shows a lock if the file is readonly
            provider = function()
                if not vim.bo.modifiable or vim.bo.readonly then
                    return get_icon('file_readonly') .. ' '
                end
            end,
            hl = {
                fg = file_flags_foreground_color,
                bold = true,
                italic = true,
            },
        },
    }

    local FileNameBlock = {
        init = function(self) self.filename = vim.api.nvim_buf_get_name(0) end,
        FileFlags,
        heirlineUtils.insert(FileNameModifer, FileName, Space, FileIcon),
        { provider = '%<' },
    }

    local WinBarTitleBlock = {
        fallthrough = false, -- only display the first element that the condition matches
        {
            condition = function() return vim.wo.previewwindow end,
            {
                provider = 'Preview: ',
            },
            FileNameBlock,
            hl = { fg = filename_foreground_color, bold = true },
        },
        {
            condition = function() return vim.bo.filetype == 'help' end,
            provider = function()
                local filename = vim.api.nvim_buf_get_name(0)
                return 'Help: ' .. vim.fn.fnamemodify(filename, ':t')
            end,
            hl = { fg = filename_foreground_color, bold = true },
        },
        {
            condition = function() return vim.bo.buftype == 'quickfix' end,
            provider = "%t%{exists('w:quickfix_title')? ' '.w:quickfix_title : ''}",
            hl = { fg = filename_foreground_color, bold = true },
        },
        {
            condition = function() return vim.bo.buftype == 'terminal' end,
            provider = function()
                local tname, _ = vim.api.nvim_buf_get_name(0):gsub('.*:', '')
                return get_icon('terminal_icon') .. ' ' .. tname
            end,
            hl = { fg = filename_foreground_color, bold = true },
        },
        FileNameBlock,
        hl = function()
            if conditions.is_active() then
                return { bg = active_background_color }
            else
                return { bg = inactive_background_color }
            end
        end,
    }

    ---@type StatusLine
    local FileType = {
        provider = function() return vim.bo.filetype end,
        hl = { fg = filetype_foreground_color, bold = true },
    }

    ---@type StatusLine
    local BufType = {
        provider = function() return vim.bo.buftype end,
        hl = { fg = buftype_foreground_color, bold = true },
    }

    local FileEncoding = {
        provider = function()
            local enc = (vim.bo.fenc ~= '' and vim.bo.fenc) or vim.o.enc -- :h 'enc'
            return enc:upper()
        end,
    }

    local FileFormat = {

        provider = function()
            local fmt = vim.bo.fileformat
            return fmt:upper()
        end,
    }

    ---@type StatusLine
    local WinBars = {
        {
            WinBarTitleBlock,
            Align,
            BufType,
            Space,
            FileType,
            Space,
            FileEncoding,
            Space,
            FileFormat,
            Space,
            {
                provider = function(_)
                    return 'bufnr:' .. vim.api.nvim_get_current_buf()
                end,
            },
            Space,
            {
                provider = function(_) return 'winid:' .. vim.fn.win_getid() end,
            },
            Space,
            {
                provider = function(_) return 'winnr:' .. vim.fn.winnr() end,
            },
        },
    }
    ---------------------------------------------------------------------------
    -- Heirline Setup
    heirline.setup({
        statusline = StatusLines,
        winbar = WinBars,
        opts = {
            disable_winbar_cb = function(args)
                return conditions.buffer_matches(winbar_inactive, args.buf)
            end,
        },
    })
    vim.o.winbar = "%{%v:lua.require'heirline'.eval_winbar()%}"
end

return {
    'rebelot/heirline.nvim',
    config = config,
    event = 'BufReadPre',
}
