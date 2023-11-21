local M = {}
function M.trim(s)
    --Trim leading and ending whitespace from string
    return s:match('^()%s*$') and '' or s:match('^%s*(.*%S)')
end

function M.getBufferViewPath(viewNumber)
    local path = vim.fn.fnamemodify(vim.fn.bufname('%'), ':p')
    if path == nil then error('path to buffer is unexpectedly nil') end
    -- vim's odd =~ escaping for /
    path = vim.fn.substitute(path, '=', '==', 'g') or ''
    if vim.fn.has_key(vim.fn.environ(), 'HOME') then
        path = vim.fn.substitute(path, '^' .. os.getenv('HOME'), '\\~', '')
            or ''
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

function M.getBufferViewFileNumber()
    if
        vim.api.nvim_get_option_value('foldmethod', {}) == 'expr'
        and vim.api.nvim_get_option_value('foldexpr', {})
            == 'v:lua.vim.treesitter.foldexpr()'
    then
        return TREESITTER_FOLDING_VIEW_FILE_NUMBER
    elseif vim.api.nvim_get_option_value('foldmethod', {}) == 'expr' then
        return OTHER_FOLDING_VIEW_FILE_NUMBER -- In case, I manually set the folding expr to something else
    elseif vim.api.nvim_get_option_value('diff', {}) then
        return DIFF_FOLDING_VIEW_FILE_NUMBER
    else
        return OTHER_FOLDING_VIEW_FILE_NUMBER
    end
end

-- If my folds get screwed up the following function can be used to delete
-- the view file. I think this should fix my folds but need to test it
function M.deleteView(viewNumber)
    local path = M.getBufferViewPath(viewNumber)
    vim.fn.delete(path)
    print('Deleted: ' .. path)
end

function M.openView(viewNumber)
    local path = M.getBufferViewPath(viewNumber)
    vim.cmd('e ' .. path)
end

function M.printViewPath(viewNumber)
    local path = M.getBufferViewPath(viewNumber)
    print(path)
end

function M.resetView(viewNumber)
    vim.cmd([[
        augroup remember_folds
           autocmd!
        augroup END
    ]])
    M.deleteView(viewNumber)
    print('Close and reopen nvim for to finish reseting the view file')
end

function M.saveView()
    -- view files are about 500 bytes
    local viewFileNumber = M.getBufferViewFileNumber()
    vim.cmd('silent! mkview!' .. viewFileNumber)
end

function M.loadView()
    local viewFileNumber = M.getBufferViewFileNumber()
    vim.cmd('silent! loadview ' .. viewFileNumber)
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

return M
