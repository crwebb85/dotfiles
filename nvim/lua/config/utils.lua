local Set = require('utils.datastructure').Set

local M = {}

---@param s string the string to trim
---@return string
function M.trim(s)
    --Trim leading and ending whitespace from string
    return s:match('^()%s*$') and '' or s:match('^%s*(.*%S)')
end

function M.delete_buf(bufnr)
    if bufnr ~= nil then vim.api.nvim_buf_delete(bufnr, { force = true }) end
end

function M.split(bufnr, vertical_split)
    local cmd = vertical_split and 'vsplit' or 'split'

    vim.cmd(cmd)
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, bufnr)
end

function M.resize(amount, split_vertical)
    local cmd = split_vertical and 'vertical resize ' or 'resize'
    cmd = cmd .. amount

    vim.cmd(cmd)
end
function M.scheduled_error(err)
    vim.schedule(function() vim.notify(err, vim.log.levels.ERROR) end)
end

--From https://www.lua.org/pil/11.5.html
function M.set(list)
    local set = {}
    for _, l in ipairs(list) do
        set[l] = true
    end
    return set
end

function M.openNewScratchBuffer()
    vim.cmd([[
		execute 'vsplit | enew'
		setlocal buftype=nofile
		setlocal bufhidden=hide
		setlocal noswapfile
	]])
end

function M.compareClipboardToBuffer()
    local ftype = vim.api.nvim_eval('&filetype') -- original filetype
    vim.cmd([[
		tabnew %
		Ns
		normal! P
		windo diffthis
	]])
    vim.cmd('set filetype=' .. ftype)
end

function M.compareClipboardToSelection()
    vim.cmd([[
		" yank visual selection to z register
		normal! gv"zy
		" open new tab, set options to prevent save prompt when closing
		execute 'tabnew | setlocal buftype=nofile bufhidden=hide noswapfile'
		" paste z register into new buffer
		normal! V"zp
		Ns
		normal! Vp
		windo diffthis
	]])
end

function M.get_default_branch_name()
    local res = vim.system(
        { 'git', 'rev-parse', '--verify', 'main' },
        { capture_output = true }
    ):wait()
    return res.code == 0 and 'main' or 'master'
end

--Returns a dot repeatable version of a function to be used in keymaps
--that pressing `.` will repeat the action.
--Example: `vim.keymap.set('n', 'ct', dot_repeat(function() print(os.clock()) end), { expr = true })`
--Setting expr = true in the keymap is required for this function to make the keymap repeatable
--based on gist: https://gist.github.com/kylechui/a5c1258cd2d86755f97b10fc921315c3
function M.dot_repeat(
    callback --[[Function]]
)
    return function()
        _G.dot_repeat_callback = callback
        vim.go.operatorfunc = 'v:lua.dot_repeat_callback'
        return 'g@l'
    end
end

---@class (exact) FormatterDetails
---@field name string
---@field available boolean
---@field available_msg? string
---@field buffer_disabled boolean
---@field project_disabled boolean

---@param bufnr? integer the buffer number. Defaults to buffer 0.
---@return FormatterDetails[]
function M.get_buffer_formatter_details(bufnr)
    ---@type FormatterDetails[]
    local all_info = {}
    if bufnr == nil then bufnr = 0 end
    local buffer_disabled_formatters = vim.b[bufnr].disabled_formatters
    local project_disabled_formatters = vim.g.disabled_formatters

    if buffer_disabled_formatters == nil then
        buffer_disabled_formatters = {}
    end

    if project_disabled_formatters == nil then
        project_disabled_formatters = {}
    end

    local buffer_disabled_formatters_set = Set:new(buffer_disabled_formatters)
    local project_disabled_formatters_set = Set:new(project_disabled_formatters)

    local names = require('conform').list_formatters_for_buffer()
    for _, name in ipairs(names) do
        if type(name) == 'string' then
            local info = require('conform').get_formatter_info(name, bufnr)
            ---@type FormatterDetails
            local details = {
                name = info.name,
                available = info.available,
                available_msg = info.available_msg,
                buffer_disabled = buffer_disabled_formatters_set:has(name),
                project_disabled = project_disabled_formatters_set:has(name),
            }
            table.insert(all_info, details)
        else
            -- If this is an alternation, take the first one that's available
            for _, v in ipairs(name) do
                local info = require('conform').get_formatter_info(v, bufnr)
                if info.available then
                    ---@type FormatterDetails
                    local details = {
                        name = info.name,
                        available = info.available,
                        available_msg = info.available_msg,
                        buffer_disabled = buffer_disabled_formatters_set:has(
                            info.name
                        ),
                        project_disabled = project_disabled_formatters_set:has(
                            info.name
                        ),
                    }
                    table.insert(all_info, details)
                    break
                end
            end
        end
    end
    if require('conform').will_fallback_lsp() then
        for _, lsp_client in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
            if lsp_client.supports_method('textDocument/formatting') then
                ---@type FormatterDetails
                local details = {
                    name = lsp_client.name,
                    available = true,
                    available_msg = nil,
                    buffer_disabled = buffer_disabled_formatters_set:has(
                        lsp_client.name
                    ),
                    project_disabled = project_disabled_formatters_set:has(
                        lsp_client.name
                    ),
                }
                table.insert(all_info, details)
            end
        end
    end
    -- vim.print(all_info)
    return all_info
end
return M
