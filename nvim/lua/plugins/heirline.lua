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
            error_icon = 'E',
            warn_icon = 'W',
            info_icon = 'I',
            hint_icon = 'H',
            -- error_icon = vim.fn.sign_getdefined("DiagnosticSignError")[1].text,
            -- warn_icon = vim.fn.sign_getdefined("DiagnosticSignWarn")[1].text,
            -- info_icon = vim.fn.sign_getdefined("DiagnosticSignInfo")[1].text,
            -- hint_icon = vim.fn.sign_getdefined("DiagnosticSignHint")[1].text,
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
            return ' %2(' .. self.mode_names[self.mode] .. '%)'
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
                return ' ' .. self.status_dict.head .. ' '
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
                return ' [' .. table.concat(names, ' ') .. ']'
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
            local formatter_details_list =
                require('config.formatter').get_buffer_formatter_details()
            local is_formatter_available = false
            for i, formatter_details in pairs(formatter_details_list) do
                ---@type StatusLine
                local formatter_component = {
                    provider = require('config.utils').trim(
                        formatter_details.name
                    ),
                }
                if not formatter_details.available then
                    formatter_component.hl = { fg = 'red', bold = true }
                elseif formatter_details.project_disabled then
                    formatter_component.hl = { fg = 'orange', bold = true }
                elseif formatter_details.buffer_disabled then
                    formatter_component.hl = { fg = 'yellow', bold = true }
                else
                    is_formatter_available = true
                end
                table.insert(children, formatter_component)
                if i < #formatter_details_list then
                    table.insert(children, Space)
                end
            end
            local conform_params =
                require('config.formatter').construct_conform_formatting_params()
            -- vim.print(
            --     require('config.formatter').get_buffer_formatter_details()
            -- )
            if
                conform_params.lsp_fallback == 'always'
                or (
                    conform_params.lsp_fallback == true
                    and is_formatter_available == false
                )
            then
                local lsp_formatters =
                    require('config.formatter').get_buffer_lsp_formatters()
                if #lsp_formatters > 0 and #formatter_details_list > 0 then
                    table.insert(children, Space)
                end
                for i, lsp_name in pairs(lsp_formatters) do
                    ---@type StatusLine
                    local formatter_component = {
                        provider = require('config.utils').trim(lsp_name),
                    }
                    table.insert(children, formatter_component)
                    if i < #lsp_formatters then
                        table.insert(children, Space)
                    end
                end
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
                require('config.formatter').get_buffer_formatter_details()
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
            provider = ' ',
        },
        {
            {
                provider = '[',
            },

            formatter_component_block,
            {
                provider = ']',
            },
            hl = function()
                if
                    require('config.formatter').properties.is_buffer_autoformat_disabled(
                        0 --TODO determine if this works correctly when not my active buffer
                    )
                then
                    return { fg = 'red', bold = true }
                end
            end,
        },
        Space,
        Seperator,
        hl = function()
            local is_format_after_save_enabled =
                require('config.formatter').properties.is_format_after_save_enabled(
                    vim.bo[0].filetype
                )
            if
                require('config.formatter').properties.is_project_autoformat_disabled()
            then
                return {
                    fg = 'red',
                    bold = true,
                    italic = is_format_after_save_enabled,
                }
            else
                return {
                    fg = 'green',
                    bold = true,
                    italic = is_format_after_save_enabled,
                }
            end
        end,
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
            {
                provider = '   ',
                hl = { fg = macro_recording_forground_color },
            },
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
                local backward = require('luasnip').jumpable(-1) and ' '
                    or ''
                local forward = require('luasnip').jumpable(1) and ' ' or ''
                return backward .. '' .. forward
            end,
            hl = { fg = 'red', bold = true },
        },
        Space,
        Seperator,
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
            local extension = vim.fn.fnamemodify(filename, ':e')
            self.icon, self.icon_color =
                require('nvim-web-devicons').get_icon_color(
                    filename,
                    extension,
                    { default = true }
                )
        end,
        provider = function(self)
            if self.filename == '' then
                return ''
            else
                return self.icon and (self.icon .. ' ')
            end
        end,
        hl = function(self) return { fg = self.icon_color } end,
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
                    return ' '
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
        unpack(FileFlags),
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
                return ' ' .. tname
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
    dependencies = 'nvim-tree/nvim-web-devicons',
}
