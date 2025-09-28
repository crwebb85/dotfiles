---based on https://github.com/nvim-neotest/neotest/blob/2cf3544fb55cdd428a9a1b7154aea9c9823426e8/lua/neotest/consumers/output_panel/init.lua?plain=1#L1
--- 1. switched from a terminal buffer to regular buffer to fix issues with lines
---    longer than the window column size
---    a. terminal windows have a bug where resizing causes text longer than the new
---       window size to be clipped
---    b. terminal windows add a line terminator to break up lines longer than the
---       window column length. This is a problem for long file paths in the output
---       because you can't use the `gf` and `gF` keymaps on them

require('neotest') -- Make sure neotest is setup before using this consumer
local nio = require('nio')
local config = require('neotest.config')
local lib = require('neotest.lib')

---@class neotest.MyOutputPanel
---@field client neotest.Client
---@field win neotest.PersistentWindow
---@private
local OutputPanel = {}

function OutputPanel:new(client)
    self.__index = self
    return setmetatable({
        client = client,
        win = lib.persistent_window.panel({
            name = 'My Neotest Output Panel',
            open = config.output_panel.open,
            bufopts = {
                filetype = 'myneotest-output-panel',
            },
        }),
    }, self)
end

---@private
---@type neotest.OutputPanel
local panel

local neotest = {}

--- A consumer that streams all output of tests to an output window.
---@class neotest.consumers.myoutput_panel
neotest.myoutput_panel = {}

---@param client neotest.Client
---@private
local init = function(client)
    panel = OutputPanel:new(client)

    ---@param results table<string, neotest.Result>
    client.listeners.results = function(adapter_id, results, partial)
        if partial then return end

        local files_to_read = {}

        local tree = client:get_position(nil, { adapter = adapter_id })
        assert(tree, 'No tree for adapter ' .. adapter_id)
        for pos_id, result in pairs(results) do
            if
                result.output
                and not files_to_read[result.output]
                and tree:get_key(pos_id)
                and tree:get_key(pos_id):data().type == 'test'
            then
                files_to_read[result.output] = true
            end
        end

        --Clear output panel
        vim.schedule(function()
            local bufnr = panel.win:buffer()
            vim.bo[bufnr].modifiable = true
            nio.api.nvim_buf_set_lines(bufnr, -0, -1, false, {})
            vim.bo[bufnr].modifiable = false
        end)

        --TODO sort the results like I do with the QF list
        for file, _ in pairs(files_to_read) do
            local output = lib.files.read(file)
            local normalized_output = output:gsub('\r\n', '\n'):gsub('\r', '\n')
            local output_lines = vim.split(normalized_output, '\n')
            table.insert(output_lines, '--------')
            table.insert(output_lines, '')

            vim.schedule(function()
                local bufnr = panel.win:buffer()
                vim.bo[bufnr].modifiable = true
                nio.api.nvim_buf_set_lines(bufnr, -1, -1, false, output_lines)
                vim.bo[bufnr].modifiable = false
            end)
        end
    end
end

--- Open the output panel
--- ```vim
---   lua require("neotest").myoutput_panel.open()
--- ```
function neotest.myoutput_panel.open() panel.win:open() end

--- Close the output panel
--- ```vim
---   lua require("neotest").myoutput_panel.close()
--- ```
function neotest.myoutput_panel.close() panel.win:close() end

--- Toggle the output panel
--- ```vim
---   lua require("neotest").myoutput_panel.toggle()
--- ```
function neotest.myoutput_panel.toggle()
    if panel.win:is_open() then
        neotest.myoutput_panel.close()
    else
        neotest.myoutput_panel.open()
    end
end

--- Clears the output panel
--- >vim
---   lua require("neotest").myoutput_panel.clear()
--- <
function neotest.myoutput_panel.clear()
    local bufnr = panel.win:buffer()
    vim.bo[bufnr].modifiable = true
    nio.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
    vim.bo[bufnr].modifiable = false
end

--- Returns the buffer of the output panel
--- ```vim
---   lua require("neotest").myoutput_panel.buffer()
--- ```
function neotest.myoutput_panel.buffer() return panel.win:buffer() end

neotest.myoutput_panel = setmetatable(neotest.myoutput_panel, {
    __call = function(_, client)
        init(client)
        return neotest.myoutput_panel
    end,
})

return neotest.myoutput_panel
