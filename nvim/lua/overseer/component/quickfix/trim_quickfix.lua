return {
    desc = 'Opens the hurl results',
    -- Define parameters that can be passed in to the component
    params = {
        items_to_append = {
            type = 'list',
            desc = 'A list of lines to append to the end of the quick fix list',
            subtype = {
                type = 'string',
            },
            delimiter = ',',
            default = {},
        },
    },
    -- Optional, default true. Set to false to disallow editing this component in the task editor
    editable = true,
    -- Optional, default true. When false, don't serialize this component when saving a task to disk
    serializable = true,
    -- The params passed in will match the params defined above
    constructor = function(params)
        -- You may optionally define any of the methods below
        return {
            ---@param _status overseer.Status Can be CANCELED, FAILURE, or SUCCESS
            ---@param _result table A result table.
            on_complete = function(_self, _task, _status, _result)
                local items = vim.fn.getqflist()
                local index = #items
                while index >= 1 do
                    local item = items[index]
                    if item.text ~= '' then break end
                    index = index - 1
                end

                local new_items = {}
                for i, item in ipairs(items) do
                    if i > index then break end
                    table.insert(new_items, item)
                end
                for _, item_text in ipairs(params.items_to_append) do
                    table.insert(new_items, {
                        text = item_text,
                        valid = 0,
                    })
                end
                vim.fn.setqflist({}, 'r', { items = new_items })
            end,
        }
    end,
}
