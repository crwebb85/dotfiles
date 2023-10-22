local init_group = 'init'

vim.api.nvim_create_augroup(init_group, { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', { group = init_group, callback = function() vim.highlight.on_yank() end })

vim.api.nvim_create_autocmd("VimEnter", {
    desc = "Auto select virtualenv Nvim open",
    pattern = "*",
    callback = function()
        local venv = vim.fn.findfile("requirements.txt", vim.fn.getcwd() .. ";")
        --local venv = vim.fn.findfile("pyproject.toml", vim.fn.getcwd() .. ";")
        if venv ~= "" then
            require("venv-selector").retrieve_from_cache()
        end
    end,
    once = true,
})

vim.cmd([[
augroup remember_folds
  autocmd!
  " view files are about 500 bytes
  " bufleave but not bufwinleave captures closing 2nd tab
  " nested is needed by bufwrite* (if triggered via other autocmd)
  " BufHidden for compatibility with `set hidden`
  autocmd BufWinLeave,BufLeave,BufWritePost,BufHidden,QuitPre ?* nested silent! mkview!
  autocmd BufWinEnter ?* silent! loadview
augroup END
]])


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

vim.api.nvim_create_user_command('OpenView', OpenView, {})
vim.api.nvim_create_user_command('PrintViewPath', PrintViewPath, {})
vim.api.nvim_create_user_command('ResetView', ResetView, {})
vim.api.nvim_create_user_command('DeleteView', DeleteView, {})
