local M = {}

local rplugin_vim_contents_template = [[
" perl plugins


" node plugins


" python3 plugins
call remote#host#RegisterPlugin('python3', '%s', [
      \ {'sync': v:true, 'name': 'MoltenDeinit', 'type': 'command', 'opts': {}},
      \ {'sync': v:true, 'name': 'MoltenDelete', 'type': 'command', 'opts': {'bang':''}},
      \ {'sync': v:true, 'name': 'MoltenEnterOutput', 'type': 'command', 'opts': {}},
      \ {'sync': v:true, 'name': 'MoltenReevaluateCell', 'type': 'command', 'opts': {}},
      \ {'sync': v:true, 'name': 'MoltenEvaluateLine', 'type': 'command', 'opts': {'nargs': '*'}},
      \ {'sync': v:true, 'name': 'MoltenEvaluateOperator', 'type': 'command', 'opts': {}},
      \ {'sync': v:true, 'name': 'MoltenEvaluateVisual', 'type': 'command', 'opts': {'nargs': '*'}},
      \ {'sync': v:true, 'name': 'MoltenExportOutput', 'type': 'command', 'opts': {'bang': '', 'nargs': '*'}},
      \ {'sync': v:true, 'name': 'MoltenGoto', 'type': 'command', 'opts': {'nargs': '*'}},
      \ {'sync': v:true, 'name': 'MoltenHideOutput', 'type': 'command', 'opts': {}},
      \ {'sync': v:true, 'name': 'MoltenImagePopup', 'type': 'command', 'opts': {}},
      \ {'sync': v:true, 'name': 'MoltenImportOutput', 'type': 'command', 'opts': {'nargs': '*'}},
      \ {'sync': v:true, 'name': 'MoltenInfo', 'type': 'command', 'opts': {}},
      \ {'sync': v:true, 'name': 'MoltenInit', 'type': 'command', 'opts': {'complete': 'file', 'nargs': '*'}},
      \ {'sync': v:true, 'name': 'MoltenInterrupt', 'type': 'command', 'opts': {'nargs': '*'}},
      \ {'sync': v:true, 'name': 'MoltenLoad', 'type': 'command', 'opts': {'nargs': '*'}},
      \ {'sync': v:true, 'name': 'MoltenNext', 'type': 'command', 'opts': {'nargs': '*'}},
      \ {'sync': v:true, 'name': 'MoltenOpenInBrowser', 'type': 'command', 'opts': {}},
      \ {'sync': v:true, 'name': 'MoltenPrev', 'type': 'command', 'opts': {'nargs': '*'}},
      \ {'sync': v:true, 'name': 'MoltenReevaluateAll', 'type': 'command', 'opts': {}},
      \ {'sync': v:true, 'name': 'MoltenRestart', 'type': 'command', 'opts': {'bang': '', 'nargs': '*'}},
      \ {'sync': v:true, 'name': 'MoltenSave', 'type': 'command', 'opts': {'nargs': '*'}},
      \ {'sync': v:true, 'name': 'MoltenShowOutput', 'type': 'command', 'opts': {}},
      \ {'sync': v:true, 'name': 'MoltenEvaluateArgument', 'type': 'command', 'opts': {'nargs': '*'}},
      \ {'sync': v:true, 'name': 'MoltenEvaluateRange', 'type': 'function', 'opts': {}},
      \ {'sync': v:true, 'name': 'MoltenAvailableKernels', 'type': 'function', 'opts': {}},
      \ {'sync': v:true, 'name': 'MoltenBufLeave', 'type': 'function', 'opts': {}},
      \ {'sync': v:true, 'name': 'MoltenRunningKernels', 'type': 'function', 'opts': {}},
      \ {'sync': v:true, 'name': 'MoltenDefineCell', 'type': 'function', 'opts': {}},
      \ {'sync': v:true, 'name': 'MoltenOperatorfunc', 'type': 'function', 'opts': {}},
      \ {'sync': v:false, 'name': 'MoltenSendStdin', 'type': 'function', 'opts': {}},
      \ {'sync': v:true, 'name': 'MoltenTick', 'type': 'function', 'opts': {}},
      \ {'sync': v:false, 'name': 'MoltenTickInput', 'type': 'function', 'opts': {}},
      \ {'sync': v:true, 'name': 'MoltenOnBufferUnload', 'type': 'function', 'opts': {}},
      \ {'sync': v:true, 'name': 'MoltenOnCursorMoved', 'type': 'function', 'opts': {}},
      \ {'sync': v:true, 'name': 'MoltenOnExitPre', 'type': 'function', 'opts': {}},
      \ {'sync': v:true, 'name': 'MoltenOnWinScrolled', 'type': 'function', 'opts': {}},
      \ {'sync': v:true, 'name': 'MoltenStatusLineInit', 'type': 'function', 'opts': {}},
      \ {'sync': v:true, 'name': 'MoltenStatusLineKernels', 'type': 'function', 'opts': {}},
      \ {'sync': v:true, 'name': 'MoltenUpdateInterface', 'type': 'function', 'opts': {}},
      \ {'sync': v:true, 'name': 'MoltenUpdateOption', 'type': 'function', 'opts': {}},
     \ ])


" ruby plugins


]]

local function find_venv_python_executable(venv_dir)
    local candidates = {
        vim.fn.has('unix') == 1 and vim.fs.joinpath(venv_dir, 'bin', 'python'),
        -- MSYS2
        vim.fn.has('win32') == 1
            and vim.fs.joinpath(venv_dir, 'bin', 'python.exe'),
        -- Stock Windows
        vim.fn.has('win32') == 1
            and vim.fs.joinpath(venv_dir, 'Scripts', 'python.exe'),
    }

    for _, candidate in ipairs(candidates) do
        if
            candidate
            and vim.fn.executable(vim.fs.normalize(candidate)) == 1
        then
            return candidate
        end
    end
    return nil
end

function M.setup_python_remote_plugin()
    local Path = require('myconfig.utils.path')

    local config_env = os.getenv('XDG_CONFIG_HOME')
    if config_env == nil then
        error('cannot find XDG_CONFIG_HOME environment variable')
    end
    local config_path = vim.fn.expand(config_env)

    local venv_directory = vim.fs.joinpath(
        config_path,
        'cli-tools',
        'neovim_remote_plugin_python_venv',
        'venv'
    )

    if not Path.is_directory(venv_directory) then
        vim.notify(
            string.format(
                'The virtual environment for neovim remote plugin is not setup at %s. Run the setup_venv.ps1 script to set it up',
                venv_directory
            ),
            vim.log.levels.ERROR
        )
        return
    end

    local venv_python = find_venv_python_executable(venv_directory)
    if venv_python == nil or not Path.is_file(venv_python) then
        vim.notify(
            string.format(
                'Missing python plugin virtual environment at path %s. vim.g.python3_host_prog could not be configured',
                venv_python
            ),
            vim.log.levels.ERROR
        )
        return
    else
        vim.g.python3_host_prog = venv_python
    end
end

function M.my_update_remote_plugins()
    local Path = require('myconfig.utils.path')
    vim.cmd([[UpdateRemotePlugins]])
    local data_dir = vim.fn.stdpath('data')
    if type(data_dir) ~= 'string' then error('Invalid data directory') end
    local rplugin_filepath = vim.fs.joinpath(data_dir, 'rplugin.vim')
    Path.ensure_file_exists(rplugin_filepath)
    local rplugin_file = io.open(rplugin_filepath, 'w')
    if rplugin_file == nil then
        vim.notify(
            string.format('Could not open file %s', rplugin_filepath),
            vim.log.levels.ERROR
        )
        return
    end
    local molten_path = vim.fs.joinpath(
        data_dir,
        'lazy',
        'molten-nvim',
        'rplugin',
        'python3',
        'molten'
    )
    local content_to_save =
        string.format(rplugin_vim_contents_template, molten_path)
    rplugin_file:write(content_to_save)

    -- Close the file
    rplugin_file:close()
    vim.notify(
        string.format(
            'Updated %s with the remote plugin configuration setting molten path to %s',
            rplugin_filepath,
            molten_path
        ),
        vim.log.levels.INFO
    )
end

function M.setup_keymaps()
    vim.keymap.set('n', '<leader>ip', function()
        --TODO if the the venv isn't setup then
        --set it up with the step
        --  venv project_name # activate the project venv
        --  pip install ipykernel
        --  python -m ipykernel install --user --name project_names:

        vim.cmd('MoltenInit project_name')
        -- local venv = os.getenv('VIRTUAL_ENV')
        --     or os.getenv('CONDA_PREFIX')
        -- vim.print(venv)
        -- if venv ~= nil then
        --     vim.print('hi')
        --     -- in the form of /home/benlubas/.virtualenvs/VENV_NAME
        --     venv = string.match(venv, '/.+/(.+)')
        --     venv =
        --         [[C:\Users\crweb\Documents\poc\molten-test\venv\Scripts\python.exe]]
        --     vim.cmd(('MoltenInit %s'):format(venv))
        -- else
        --     vim.print('bye')
        --     vim.cmd('MoltenInit python3')
        -- end
    end, { desc = 'Initialize Molten for python3', silent = true })

    vim.keymap.set(
        'n',
        '<leader>ie',
        ':MoltenEvaluateOperator<CR>',
        { desc = 'evaluate operator', silent = true }
    )
    vim.keymap.set(
        'n',
        '<leader>ios',
        ':noautocmd MoltenEnterOutput<CR>',
        { desc = 'open output window', silent = true }
    )
    vim.keymap.set(
        'n',
        '<leader>irr',
        ':MoltenReevaluateCell<CR>',
        { desc = 're-eval cell', silent = true }
    )
    vim.keymap.set(
        'v',
        '<leader>ir',
        ':<C-u>MoltenEvaluateVisual<CR>gv',
        { desc = 'execute visual selection', silent = true }
    )
    vim.keymap.set(
        'n',
        '<leader>ioh',
        ':MoltenHideOutput<CR>',
        { desc = 'close output window', silent = true }
    )
    vim.keymap.set(
        'n',
        '<leader>imd',
        ':MoltenDelete<CR>',
        { desc = 'delete Molten cell', silent = true }
    )
    vim.keymap.set(
        'n',
        '<leader>imx',
        ':MoltenOpenInBrowser<CR>',
        { desc = 'open output in browser', silent = true }
    )

    vim.keymap.set(
        'n',
        '<leader>irc',
        function() require('quarto.runner').run_cell() end,
        { desc = 'run cell', silent = true }
    )
    vim.keymap.set(
        'n',
        '<leader>ira',
        function() require('quarto.runner').run_above() end,
        { desc = 'run cell and above', silent = true }
    )
    vim.keymap.set(
        'n',
        '<leader>irA',
        function() require('quarto.runner').run_all() end,
        { desc = 'run all cells', silent = true }
    )
    vim.keymap.set(
        'n',
        '<leader>irl',
        function() require('quarto.runner').run_line() end,
        { desc = 'run line', silent = true }
    )
    vim.keymap.set(
        'v',
        '<leader>ir',
        function() require('quarto.runner').run_range() end,
        { desc = 'run visual range', silent = true }
    )
    vim.keymap.set(
        'n',
        '<leader>iRA',
        function() require('quarto.runner').run_all(true) end,
        { desc = 'run all cells of all languages', silent = true }
    )
end
return M
