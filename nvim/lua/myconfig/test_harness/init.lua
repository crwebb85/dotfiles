--- Based on https://github.com/nvim-lua/plenary.nvim/blob/74b06c6c75e4eeb3108ec01852001636d85a932b/plugin/plenary.vim
--- but changed from vimscript to lua and changed the command names

vim.api.nvim_create_user_command('BustedFile', function(args)
    local testfile_path = args.fargs[1]
    require('myconfig.test_harness.test_harness').test_file(testfile_path)
end, {
    nargs = 1,
    complete = 'file',
    desc = 'Run the test file with busted',
})

vim.api.nvim_create_user_command('BustedDirectory', function(args)
    local command_args_string = args.args
    local split_string = vim.split(command_args_string, ' ')
    local directory = vim.fn.expand(table.remove(split_string, 1))
    if type(directory) ~= 'string' then
        error('invalid directory: not a string')
    end

    local opts =
        assert(loadstring('return ' .. table.concat(split_string, ' ')))()

    return require('myconfig.test_harness.test_harness').test_directory(
        directory,
        opts
    )
end, {
    nargs = '+',
    complete = 'file',
    desc = 'Run the test files in directories with busted',
})
