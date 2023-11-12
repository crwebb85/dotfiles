function Trim(s)
    --Trim leading and ending whitespace from string
    return s:match '^()%s*$' and '' or s:match '^%s*(.*%S)'
end

function GetBufferViewPath(viewNumber)
    local path = vim.fn.fnamemodify(vim.fn.bufname('%'), ':p')
    if path == nil then
        error("path to buffer is unexpectedly nil")
    end
    -- vim's odd =~ escaping for /
    path = vim.fn.substitute(path, '=', '==', 'g') or ''
    if vim.fn.has_key(vim.fn.environ(), "HOME") then
        path = vim.fn.substitute(path, '^' .. os.getenv("HOME"), '\\~', '') or ''
    end
    path = vim.fn.substitute(path, '/', '=+', 'g') or ''
    path = path .. '='
    -- view directory
    path = vim.opt.viewdir:get() .. path
    if type(viewNumber) == 'number' and 0 < viewNumber and viewNumber <= 9 then
        path = path .. viewNumber .. '.vim'
    end
    return path
end

local TREESITTER_FOLDING_VIEW_FILE_NUMBER = 1
local DIFF_FOLDING_VIEW_FILE_NUMBER = 2
local OTHER_FOLDING_VIEW_FILE_NUMBER = 3

function GetBufferViewFileNumber()
    if vim.api.nvim_get_option_value('foldmethod', {}) == "expr" and vim.api.nvim_get_option_value('foldexpr', {}) == "v:lua.vim.treesitter.foldexpr()" then
        return TREESITTER_FOLDING_VIEW_FILE_NUMBER
    elseif vim.api.nvim_get_option_value("foldmethod", {}) == "expr" then
        return OTHER_FOLDING_VIEW_FILE_NUMBER -- In case, I manually set the folding expr to something else
    elseif vim.api.nvim_get_option_value("diff", {}) then
        return DIFF_FOLDING_VIEW_FILE_NUMBER
    else
        return OTHER_FOLDING_VIEW_FILE_NUMBER
    end
end

-- If my folds get screwed up the following function can be used to delete
-- the view file. I think this should fix my folds but need to test it
function DeleteView(viewNumber)
    local path = GetBufferViewPath(viewNumber)
    vim.fn.delete(path)
    print("Deleted: " .. path)
end

function OpenView(viewNumber)
    local path = GetBufferViewPath(viewNumber)
    vim.cmd('e ' .. path)
end

function PrintViewPath(viewNumber)
    local path = GetBufferViewPath(viewNumber)
    print(path)
end

function ResetView(viewNumber)
    vim.cmd([[
        augroup remember_folds
           autocmd!
        augroup END
    ]])
    DeleteView(viewNumber)
    print("Close and reopen nvim for to finish reseting the view file")
end

function SaveView()
    -- view files are about 500 bytes
    local viewFileNumber = GetBufferViewFileNumber()
    vim.cmd('silent! mkview!' .. viewFileNumber)
end

function LoadView()
    local viewFileNumber = GetBufferViewFileNumber()
    vim.cmd('silent! loadview ' .. viewFileNumber)
end

vim.api.nvim_create_user_command('ViewOpen', function(opts)
    OpenView(tonumber(opts.args))
end, { nargs = '?' })
vim.api.nvim_create_user_command('ViewPrintPath', function(opts)
    PrintViewPath(tonumber(opts.args))
end, { nargs = '?' })
vim.api.nvim_create_user_command('ViewReset', function(opts)
    ResetView(tonumber(opts.args))
end, { nargs = '?' })
vim.api.nvim_create_user_command('ViewDelete', function(opts)
    DeleteView(tonumber(opts.args))
end, { nargs = '?' })
