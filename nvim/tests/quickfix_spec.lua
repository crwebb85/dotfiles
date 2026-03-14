---Run with :PlenaryBustedFile %
---TODO fix tests

describe('Quickfix', function()
    it('set_list with nil window sets the quickfix list', function()
        require('myconfig.quickfix').set_list(nil, ' ', {
            items = {
                { text = 'helloworld1', valid = 0 },
                { text = 'helloworld2', valid = 0 },
            },
        })
        local list = vim.fn.getqflist()
        assert.is_not_nil(list)
        local expected = {
            {
                bufnr = 0,
                col = 0,
                end_col = 0,
                end_lnum = 0,
                lnum = 0,
                module = '',
                nr = 0,
                pattern = '',
                text = 'helloworld1',
                type = '',
                valid = 0,
                vcol = 0,
            },
            {
                bufnr = 0,
                col = 0,
                end_col = 0,
                end_lnum = 0,
                lnum = 0,
                module = '',
                nr = 0,
                pattern = '',
                text = 'helloworld2',
                type = '',
                valid = 0,
                vcol = 0,
            },
        }
        assert.are.same(expected, list)
    end)

    it(
        'set_list with win=0 sets the location list for the current window',
        function()
            require('myconfig.quickfix').set_list(0, ' ', {
                items = {
                    { text = 'helloworld win=0', valid = 0 },
                    { text = 'helloworld2', valid = 0 },
                },
            })
            local list = vim.fn.getloclist(0)
            assert.is_not_nil(list)
            local expected = {
                {
                    bufnr = 0,
                    col = 0,
                    end_col = 0,
                    end_lnum = 0,
                    lnum = 0,
                    module = '',
                    nr = 0,
                    pattern = '',
                    text = 'helloworld win=0',
                    type = '',
                    valid = 0,
                    vcol = 0,
                },
                {
                    bufnr = 0,
                    col = 0,
                    end_col = 0,
                    end_lnum = 0,
                    lnum = 0,
                    module = '',
                    nr = 0,
                    pattern = '',
                    text = 'helloworld2',
                    type = '',
                    valid = 0,
                    vcol = 0,
                },
            }
            assert.are.same(expected, list)
        end
    )

    it('set_list with win=1 sets the location list for window 1', function()
        require('myconfig.quickfix').set_list(0, ' ', {
            items = {
                { text = 'helloworld set win=1', valid = 0 },
                { text = 'helloworld2', valid = 0 },
            },
        })
        local list = vim.fn.getloclist(0)
        assert.is_not_nil(list)
        local expected = {
            {
                bufnr = 0,
                col = 0,
                end_col = 0,
                end_lnum = 0,
                lnum = 0,
                module = '',
                nr = 0,
                pattern = '',
                text = 'helloworld set win=1',
                type = '',
                valid = 0,
                vcol = 0,
            },
            {
                bufnr = 0,
                col = 0,
                end_col = 0,
                end_lnum = 0,
                lnum = 0,
                module = '',
                nr = 0,
                pattern = '',
                text = 'helloworld2',
                type = '',
                valid = 0,
                vcol = 0,
            },
        }
        assert.are.same(expected, list)
    end)
end)
