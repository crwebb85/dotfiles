function GetBufferViewPath()
    local path = vim.fn.fnamemodify(vim.fn.bufname('%'), ':p')
    -- vim's odd =~ escaping for /
    path = vim.fn.substitute(path, '=', '==', 'g')
    if vim.fn.has_key(vim.fn.environ(), "HOME") then
        path = vim.fn.substitute(path, '^' .. os.getenv("HOME"), '\\~', '')
    end
    path = vim.fn.substitute(path, '/', '=+', 'g') .. '='
    -- view directory
    path = vim.opt.viewdir:get() .. path
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
function DeleteView()
    local path = GetBufferViewPath()
    vim.fn.delete(path)
    print("Deleted: " .. path)
end

function OpenView()
    local path = GetBufferViewPath()
    vim.cmd('e ' .. path)
end

function PrintViewPath()
    local path = GetBufferViewPath()
    print(path)
end

function ResetView()
    vim.cmd([[
        augroup remember_folds
           autocmd!
        augroup END
    ]])
    DeleteView()
    print("Close and reopen nvim for to finish reseting the view file")
end

function SaveView()
    -- view files are about 500 bytes

    -- print("--")
    -- print("buffer number " .. vim.api.nvim_get_current_buf())
    -- print("buffer modified " .. tostring(vim.bo.modified))
    -- print("save view for buffer " .. vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()))
    -- print("save view for buffer " .. vim.api.nvim_buf_get_name(0))
    -- print("--")
    local viewFileNumber = GetBufferViewFileNumber()
    vim.cmd('silent! mkview!' .. viewFileNumber)
end

function LoadView()
    -- print("--")
    -- print("load view for buffer " .. vim.api.nvim_buf_get_name(0))
    -- print("load view for buffer " .. vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()))
    -- print("--")
    local viewFileNumber = GetBufferViewFileNumber()
    vim.cmd('silent! loadview ' .. viewFileNumber)
end

vim.api.nvim_create_user_command('OpenView', OpenView, {})
vim.api.nvim_create_user_command('PrintViewPath', PrintViewPath, {})
vim.api.nvim_create_user_command('ResetView', ResetView, {})
vim.api.nvim_create_user_command('DeleteView', DeleteView, {})
