local function copy(lines, _) require('osc52').copy(table.concat(lines, '\n')) end

local function paste()
    local reg_value = vim.fn.getreg('')
    if reg_value == nil then reg_value = '' end
    local reg_split = reg_value
    if type(reg_value) == 'string' then
        reg_split = vim.fn.split(reg_value, '\n')
    end
    return { reg_split, vim.fn.getregtype('') }
end

vim.g.clipboard = {
    name = 'osc52',
    copy = { ['+'] = copy, ['*'] = copy },
    paste = { ['+'] = paste, ['*'] = paste },
}

function copy()
    if vim.v.event.operator == 'y' and vim.v.event.regname == '+' then
        require('osc52').copy_register('+')
    end
end
