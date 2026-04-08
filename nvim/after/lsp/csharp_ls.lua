local util = require('lspconfig.util')

---@type vim.lsp.Config
return {
    cmd = function(dispatchers, config)
        local csharp_ls_exe = vim.fs.joinpath(
            require('myconfig.utils.path').get_mason_base_path(),
            'packages',
            'csharp-language-server',
            'csharp-ls.exe'
        )

        -- csharp-ls attempt to locate sln, slnx or csproj files from root_dir
        -- If cmd_cwd is provide use it instead
        local root_dir = config.cmd_cwd or config.root_dir
        local sln_filename = nil
        local sln_files = vim.fn.glob('*.sln', true, true)
        if #sln_files == 1 then sln_filename = sln_files[1] end
        local cmd = {
            csharp_ls_exe,
            '-f',
            'metadata-uris,razor-support',
        }

        --Setting the solution name was needed when I had gitworktrees since
        --in my cwd since it would detect both the sln in cwd and the sln in the
        --worktree
        if sln_filename ~= nil then
            table.insert(cmd, '--solution')
            table.insert(cmd, sln_filename)
        end

        return vim.lsp.rpc.start(cmd, dispatchers, {
            cwd = root_dir,
            env = config.cmd_env,
            detached = config.detached,
        })
    end,
    root_dir = function(bufnr, on_dir)
        local fname = vim.api.nvim_buf_get_name(bufnr)
        local root = util.root_pattern('*.sln')(fname)
            or util.root_pattern('*.slnx')(fname)
            or util.root_pattern('*.csproj')(fname)
        root = vim.fs.normalize(root)
        on_dir(root)
    end,
    -- filetypes = { 'cs', 'cshtml' },
}
