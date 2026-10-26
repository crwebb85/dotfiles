--vendored plugin from https://github.com/ThePrimeagen/harpoon/blob/87b1a3506211538f460786c23f98ec63ad9af4e5/lua/harpoon/buffer.lua
local MyHarpoonGroup = require('myconfig.harpoon.autocmd')

local M = {}

local HARPOON_MENU = '__harpoon-menu__'

-- simple reason here is that if we are deving harpoon, we will create several
-- ui objects, each with their own buffer, which will cause the name to be
-- duplicated and then we will get a vim error on nvim_buf_set_name
local harpoon_menu_id = math.random(1000000)

local function get_harpoon_menu_name()
    harpoon_menu_id = harpoon_menu_id + 1
    return HARPOON_MENU .. harpoon_menu_id
end

function M.run_select_command()
    ---@type MyHarpoon
    local harpoon = require('myconfig.harpoon')
    harpoon.logger:log("select by keymap '<CR>'")
    harpoon.ui:select_menu_item()
end

function M.run_toggle_command(key)
    local harpoon = require('myconfig.harpoon')
    harpoon.logger:log("toggle by keymap '" .. key .. "'")
    harpoon.ui:toggle_quick_menu()
end

---@param bufnr number
function M.setup_autocmds_and_keymaps(bufnr)
    local curr_file = vim.api.nvim_buf_get_name(0)
    local cmd = string.format(
        'autocmd Filetype harpoon '
            .. "let path = '%s' | call clearmatches() | "
            -- move the cursor to the line containing the current filename
            .. "call search('\\V'.path.'\\$') | "
            -- add a hl group to that line
            .. "call matchadd('MyHarpoonCurrentFile', '\\V'.path.'\\$')",
        curr_file:gsub('\\', '\\\\')
    )
    vim.cmd(cmd)

    if vim.api.nvim_buf_get_name(bufnr) == '' then
        vim.api.nvim_buf_set_name(bufnr, get_harpoon_menu_name())
    end

    vim.api.nvim_set_option_value('filetype', 'harpoon', {
        buf = bufnr,
    })
    vim.api.nvim_set_option_value('buftype', 'acwrite', { buf = bufnr })
    vim.keymap.set(
        'n',
        'q',
        function() M.run_toggle_command('q') end,
        { buffer = bufnr, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Esc>',
        function() M.run_toggle_command('Esc') end,
        { buffer = bufnr, silent = true }
    )

    vim.keymap.set(
        'n',
        '<CR>',
        function() M.run_select_command() end,
        { buffer = bufnr, silent = true }
    )

    vim.api.nvim_create_autocmd({ 'BufWriteCmd' }, {
        group = MyHarpoonGroup,
        buffer = bufnr,
        callback = function()
            require('myconfig.harpoon').ui:save()
            vim.schedule(function()
                require('myconfig.harpoon').logger:log('toggle by BufWriteCmd')
                require('myconfig.harpoon').ui:toggle_quick_menu()
            end)
        end,
    })

    vim.api.nvim_create_autocmd({ 'BufLeave' }, {
        group = MyHarpoonGroup,
        buffer = bufnr,
        callback = function()
            require('myconfig.harpoon').logger:log('toggle by BufLeave')
            require('myconfig.harpoon').ui:toggle_quick_menu()
        end,
    })
end

---@param bufnr number
function M.get_contents(bufnr)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
    local indices = {}

    for _, line in pairs(lines) do
        table.insert(indices, line)
    end

    return indices
end

function M.set_contents(bufnr, contents)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, contents)
end

return M
