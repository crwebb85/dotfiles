local config = function()
    local heirline = require('heirline')
    local conditions = require('heirline.conditions')
    local heirlineUtils = require('heirline.utils')
    local colors = require('tokyonight.colors').setup()

    heirline.load_colors(colors)

    local status_inactive = {
        buftype = {
            'dashboard',
            'quickfix',
            'locationlist',
            'quickfix',
            'scratch',
            'prompt',
            'nofile',
        },
        filetype = {
            'dashboard',
            'harpoon',
            'startuptime',
            'mason.nvim',
            'terminal',
            'gypsy',
        },
    }
    local winbar_inactive = {
        buftype = { 'nofile', 'prompt', 'quickfix', 'terminal' },
        filetype = { 'toggleterm', 'qf', 'terminal', 'gypsy' },
    }
    local cmdtype_inactive = {
        ':',
        '/',
        '?',
    }

    local recording_background_color = colors.bg_highlight
    local recording_foreground_color = colors.red
    local active_background_color = colors.bg_popup
    local active_foreground_color = colors.fg_popup
    local inactive_background_color = colors.bg_dark
    local scrollbar_foreground_color = colors.fg_sidebar
    local scrollbar_background_color = active_background_color

    local scrollbar_enabled = function()
        return vim.api.nvim_buf_line_count(0) > 99 and conditions.is_active()
    end

    local Align = { provider = '%=' }
    local Space = { provider = ' ' }
    local Seperator = { provider = '|' }
    local LeftSep = { provider = '' }
    local RightSep = { provider = '' }

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
            self.errors = #vim.diagnostic.get(
                0,
                { severity = vim.diagnostic.severity.ERROR }
            )
            self.warnings = #vim.diagnostic.get(
                0,
                { severity = vim.diagnostic.severity.WARN }
            )
            self.hints = #vim.diagnostic.get(
                0,
                { severity = vim.diagnostic.severity.HINT }
            )
            self.info = #vim.diagnostic.get(
                0,
                { severity = vim.diagnostic.severity.INFO }
            )
        end,
        update = { 'DiagnosticChanged', 'BufEnter', 'WinEnter' },
        {
            RightSep,
            hl = function()
                if conditions.is_active() then
                    return {
                        fg = active_foreground_color,
                        bg = active_background_color,
                    }
                else
                    return {
                        fg = active_foreground_color,
                        bg = inactive_background_color,
                    }
                end
            end,
        },
        Space,
        {
            provider = function(self)
                return self.errors > 0
                        and (self.error_icon .. self.errors .. diagnostics_spacer)
                    or ''
            end,
            hl = { fg = colors.red },
        },
        {
            provider = function(self)
                return self.warnings > 0
                    and (self.warn_icon .. self.warnings .. diagnostics_spacer)
            end,
            hl = { fg = colors.warning },
        },
        {
            provider = function(self)
                return self.info > 0
                    and (self.info_icon .. self.info .. diagnostics_spacer)
            end,
            hl = { fg = colors.info },
        },
        {
            provider = function(self)
                return self.hints > 0
                    and (self.hint_icon .. self.hints .. diagnostics_spacer)
            end,
            hl = { fg = colors.hint },
        },
        {
            condition = function() return not scrollbar_enabled() end,
            {
                Space,
            },
        },
        hl = { bg = active_foreground_color },
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
            hl = { fg = colors.green2, bold = true, italic = true },
        },
        {
            condition = function(self) return self.has_changes end,
            {
                provider = function(self)
                    local count = self.status_dict.added or 0
                    return count > 0 and ('+' .. count .. ' ')
                end,
                hl = { fg = colors.gitSigns.add, bold = true },
            },
            {
                provider = function(self)
                    local count = self.status_dict.removed or 0
                    return count > 0 and ('-' .. count .. ' ')
                end,
                hl = { fg = colors.gitSigns.delete, bold = true },
            },
            {
                provider = function(self)
                    local count = self.status_dict.changed or 0
                    return count > 0 and ('~' .. count .. ' ')
                end,
                hl = { fg = colors.gitSigns.change, bold = true },
            },
            hl = { bg = active_foreground_color },
        },
        Seperator,
    }

    local LSPActive = {
        condition = conditions.lsp_attached,
        update = { 'LspAttach', 'LspDetach' },

        Space,
        {
            provider = function()
                local names = {}
                for i, server in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
                    table.insert(names, server.name)
                    if i > 4 then
                        table.insert(names, '...') -- I don't want the list of LSP's to get too long
                        break
                    end
                end
                return ' [' .. table.concat(names, ' ') .. ']'
            end,
            hl = { fg = 'green', bold = true },
        },
        Space,
        Seperator,
    }

    local FormatterActive = {
        condition = function(self)
            local ok, conform = pcall(require, 'conform')
            self.conform = conform
            return ok
                and require('conform').formatters_by_ft[vim.bo.filetype]
                    ~= nil
        end,
        update = {
            'BufEnter',
            'User',
            pattern = { '*.*', 'DisabledFormatter', 'EnabledFormatter' },
        },
        Space,
        {
            provider = function()
                local names = {}
                local formatters =
                    require('conform').formatters_by_ft[vim.bo.filetype]
                if formatters == nil then formatters = {} end
                for i, formatterName in pairs(formatters) do
                    table.insert(
                        names,
                        require('config.utils').trim(formatterName)
                    )
                    if i > 4 then
                        table.insert(names, '...') -- I don't want the list of LSP's to get too long
                        break
                    end
                end
                return ' [' .. table.concat(names, ' ') .. ']'
            end,
            hl = function()
                if vim.g.disable_autoformat or vim.b[0].disable_autoformat then
                    return { fg = 'red', bold = true }
                else
                    return { fg = 'green', bold = true }
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
            {
                condition = function(self) return self.has_changes end,
                LeftSep,
                hl = {
                    bg = recording_background_color,
                    fg = active_background_color,
                },
            },
            {
                provider = '   ',
                hl = { fg = colors.red1 },
            },
            {
                provider = function(self) return '@' .. self.reg_recording end,
                hl = { italic = false, bold = true },
            },
            {
                Space,
            },
            {
                LeftSep,
                hl = {
                    bg = active_background_color,
                    fg = recording_background_color,
                },
            },
            hl = {
                bg = recording_background_color,
                fg = recording_foreground_color,
            },
        },
        update = { 'RecordingEnter', 'RecordingLeave' },
    }

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

    local Ruler = {
        condition = function() return scrollbar_enabled() end,
        -- %l = current line number
        -- %L = number of lines in the buffer
        -- %c = column number
        -- %P = percentage through file of displayed window
        provider = '%7(%l/%3L%):%2c %P',
    }

    local ScrollBar = {
        condition = function() return scrollbar_enabled() end,
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

    local InactiveStatusline = {
        condition = function() conditions.buffer_matches(status_inactive) end,
        provider = function() return '%=' end,
        hl = function()
            if conditions.is_active() then
                return { bg = active_background_color }
            else
                return { bg = inactive_background_color }
            end
        end,
    }

    local ComponentDelimiter = { '', ' |' }

    local ActiveStatusline = {
        condition = function()
            return not conditions.buffer_matches(status_inactive)
        end,
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
        hl = function()
            if conditions.is_active() then
                return { bg = active_background_color }
            else
                return { bg = inactive_background_color }
            end
        end,
    }

    local StatusLines = {
        condition = function()
            for _, c in ipairs(cmdtype_inactive) do
                if vim.fn.getcmdtype() == c then return false end
            end
            return true
        end,
        InactiveStatusline,
        ActiveStatusline,
    }

    ---------------------------------------------------------------------------
    -- Winbar
    local ActiveWindow = {
        hl = function()
            if conditions.is_active() then
                return { bg = active_background_color }
            else
                return { bg = inactive_background_color }
            end
        end,
    }

    local ActiveBlock = {
        hl = function()
            if conditions.is_active() then
                return { bg = active_foreground_color }
            else
                return { bg = active_foreground_color }
            end
        end,
    }

    local ActiveSep = {
        hl = function()
            if conditions.is_active() then
                return { fg = active_background_color }
            else
                return { fg = inactive_background_color }
            end
        end,
    }

    -- Italicizes the buffer file name if it has been modified
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
            local filename = vim.fn.fnamemodify(self.filename, ':t')
            if filename == '' then return '' end
            if not conditions.width_percent_below(#filename, 0.1) then
                filename = vim.fn.pathshorten(filename)
            end
            return filename
        end,
        hl = { fg = colors.magenta2, bold = true },
    }

    local FileFlags = {
        {
            -- shows if buffer is unsaved
            provider = function()
                if vim.bo.modified then return '[+] ' end
            end,
            hl = { fg = colors.green, bold = true, italic = true },
        },
        {
            -- shows a lock if the file is readonly
            provider = function()
                if not vim.bo.modifiable or vim.bo.readonly then
                    return ' '
                end
            end,
            hl = { fg = colors.green2, bold = true, italic = true },
        },
    }

    local FileType = {
        condition = function()
            return conditions.buffer_matches({ filetype = { 'coderunner' } })
        end,
        provider = function() return vim.bo.filetype end,
        hl = { fg = colors.magenta, bold = true },
    }

    local FileNameBlock = {
        init = function(self) self.filename = vim.api.nvim_buf_get_name(0) end,
        FileType,
        heirlineUtils.insert(ActiveSep, LeftSep),
        Space,
        unpack(FileFlags),
        heirlineUtils.insert(FileNameModifer, FileName, Space, FileIcon),
        { provider = '%<' },
    }

    local ActiveWinbar = {
        condition = function()
            local empty_buffer = function()
                return vim.bo.ft == '' and vim.bo.buftype == ''
            end
            -- return not conditions.buffer_matches(winbar_inactive) and not empty_buffer()
            return not empty_buffer()
        end,
        heirlineUtils.insert(ActiveBlock, FileNameBlock),
    }

    local WinBars = {
        heirlineUtils.insert(ActiveWindow, ActiveWinbar),
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
    vim.opt.winbar = "%{%v:lua.require'heirline'.eval_winbar()%}"
end

return {
    'rebelot/heirline.nvim',
    config = config,
    event = 'BufReadPre',
    dependencies = 'nvim-tree/nvim-web-devicons',
}
