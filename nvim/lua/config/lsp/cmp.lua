local M = {}

local base_setup = false

function M.apply_base()
    if base_setup then return end

    base_setup = true

    if package.loaded['cmp'] == nil then
        require('cmp').setup(M.base_config())
        return
    end

    local cmp = require('cmp')
    local cmp_config = cmp.get_config()
    local base_config = M.base_config()
    local new_config = {}

    if vim.tbl_isempty(cmp_config.sources) then
        new_config.sources = base_config.sources
    end

    if vim.tbl_isempty(cmp_config.mapping) then
        new_config.mapping = base_config.mapping
    end

    local current = cmp_config.snippet.expand
    local lsp_expand = base_config.snippet.expand

    new_config.snippet = {
        expand = function(args)
            local ok = pcall(current, args)
            if not ok then
                current = lsp_expand
                current(args)
            end
        end,
    }

    cmp.setup(new_config)
end

function M.base_config()
    return {
        mapping = M.basic_mappings(),
        sources = { { name = 'nvim_lsp' } },
        snippet = {
            expand = function(args) require('luasnip').lsp_expand(args.body) end,
        },
    }
end

function M.basic_mappings()
    local cmp = require('cmp')

    return {
        ['<C-y>'] = cmp.mapping.confirm({ select = false }),
        ['<C-e>'] = cmp.mapping.abort(),
        ['<Up>'] = cmp.mapping.select_prev_item({ behavior = 'select' }),
        ['<Down>'] = cmp.mapping.select_next_item({ behavior = 'select' }),
        ['<C-p>'] = cmp.mapping(function()
            if cmp.visible() then
                cmp.select_prev_item({ behavior = 'insert' })
            else
                cmp.complete()
            end
        end),
        ['<C-n>'] = cmp.mapping(function()
            if cmp.visible() then
                cmp.select_next_item({ behavior = 'insert' })
            else
                cmp.complete()
            end
        end),
    }
end

return M
