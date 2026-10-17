local M = {}

---@alias MyCommentStringType 'line'|'block'

---Common commentstring shared b/w multiple languages
---Based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/ft.lua#L16
local S = {
    cxx_l = '//%s',
    cxx_b = '/*%s*/',
    dbl_hash = '##%s',
    dash = '--%s',
    dash_bracket = '--[[%s]]',
    handlebars = '{{!--%s--}}',
    hash = '#%s',
    hash_bracket = '#[[%s]]',
    hash_angle_bracket = '<#%s#>',
    haskell_b = '{-%s-}',
    fsharp_b = '(*%s*)',
    html = '<!--%s-->',
    latex = '%%s',
    semicolon = ';%s',
    lisp_l = ';;%s',
    lisp_b = '#|%s|#',
    twig = '{#%s#}',
    vim = '"%s',
    lean_b = '/-%s-/',
    ruby_block = '=begin%s=end',
    ini_alternate_line = ';%s', --currently I have it configured to use hash(#) instead of ; but semicolon is popular
}

local filetypes_notified_of_no_configuration = {}

---Lang table that contains commentstring (line/block) for multiple filetypes
---Structure = { filetype = { line, block } }
---
---Based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/ft.lua#L41
---@type table<string,string[]>
local L = setmetatable({
    arduino = { S.cxx_l, S.cxx_b },
    applescript = { S.hash },
    asm = { S.hash },
    astro = { S.html },
    autohotkey = { S.semicolon, S.cxx_b },
    bash = { S.hash },
    beancount = { S.semicolon },
    bib = { S.latex },
    blueprint = { S.cxx_l }, -- Blueprint doesn't have block comments
    c = { S.cxx_l, S.cxx_b },
    cabal = { S.dash },
    cairo = { S.cxx_l },
    cmake = { S.hash, S.hash_bracket },
    conf = { S.hash },
    conkyrc = { S.dash, S.dash_bracket },
    coq = { S.fsharp_b, S.fsharp_b },
    cpp = { S.cxx_l, S.cxx_b },
    cs = { S.cxx_l, S.cxx_b },
    css = { S.cxx_b, S.cxx_b },
    cuda = { S.cxx_l, S.cxx_b },
    cue = { S.cxx_l },
    dart = { S.cxx_l, S.cxx_b },
    dhall = { S.dash, S.haskell_b },
    dnsmasq = { S.hash },
    dosbatch = { 'REM%s' },
    dot = { S.cxx_l, S.cxx_b },
    dts = { S.cxx_l, S.cxx_b },
    editorconfig = { S.hash },
    eelixir = { S.html, S.html },
    elixir = { S.hash },
    elm = { S.dash, S.haskell_b },
    elvish = { S.hash },
    faust = { S.cxx_l, S.cxx_b },
    fennel = { S.semicolon },
    fish = { S.hash },
    func = { S.lisp_l },
    fsharp = { S.cxx_l, S.fsharp_b },
    gdb = { S.hash },
    gdscript = { S.hash },
    gdshader = { S.cxx_l, S.cxx_b },
    gitconfig = { S.ini_alternate_line },
    gitignore = { S.hash },
    gleam = { S.cxx_l },
    glsl = { S.cxx_l, S.cxx_b },
    gnuplot = { S.hash, S.hash_bracket },
    go = { S.cxx_l, S.cxx_b },
    gomod = { S.cxx_l },
    graphql = { S.hash },
    groovy = { S.cxx_l, S.cxx_b },
    handlebars = { S.handlebars, S.handlebars },
    haskell = { S.dash, S.haskell_b },
    haxe = { S.cxx_l, S.cxx_b },
    hcl = { S.hash, S.cxx_b },
    heex = { S.html, S.html },
    html = { S.html, S.html },
    htmldjango = { S.html, S.html },
    hyprlang = { S.hash },
    idris = { S.dash, S.haskell_b },
    idris2 = { S.dash, S.haskell_b },
    ini = { S.hash },
    jai = { S.cxx_l, S.cxx_b },
    java = { S.cxx_l, S.cxx_b },
    javascript = { S.cxx_l, S.cxx_b },
    javascriptreact = { S.cxx_l, S.cxx_b },
    jq = { S.hash },
    jsonc = { S.cxx_l },
    jsonnet = { S.cxx_l, S.cxx_b },
    julia = { S.hash, '#=%s=#' },
    kdl = { S.cxx_l, S.cxx_b },
    kotlin = { S.cxx_l, S.cxx_b },
    lean = { S.dash, S.lean_b },
    lean3 = { S.dash, S.lean_b },
    lidris = { S.dash, S.haskell_b },
    lilypond = { S.latex, '%{%s%}' },
    lisp = { S.lisp_l, S.lisp_b },
    lua = { S.dash, S.dash_bracket },
    metalua = { S.dash, S.dash_bracket },
    luau = { S.dash, S.dash_bracket },
    markdown = { S.html, S.html },
    make = { S.hash },
    mbsyncrc = { S.dbl_hash },
    mermaid = { '%%%s' },
    meson = { S.hash },
    mojo = { S.hash },
    nextflow = { S.cxx_l, S.cxx_b },
    nim = { S.hash, '#[%s]#' },
    nix = { S.hash, S.cxx_b },
    nu = { S.hash },
    objc = { S.cxx_l, S.cxx_b },
    objcpp = { S.cxx_l, S.cxx_b },
    ocaml = { S.fsharp_b, S.fsharp_b },
    odin = { S.cxx_l, S.cxx_b },
    openscad = { S.cxx_l, S.cxx_b },
    plantuml = { "'%s", "/'%s'/" },
    purescript = { S.dash, S.haskell_b },
    puppet = { S.hash },
    python = { S.hash }, -- Python doesn't have block comments
    php = { S.cxx_l, S.cxx_b },
    prisma = { S.cxx_l },
    proto = { S.cxx_l, S.cxx_b },
    ps1 = { S.hash, S.hash_angle_bracket },
    quarto = { S.html, S.html },
    r = { S.hash }, -- R doesn't have block comments
    racket = { S.lisp_l, S.lisp_b },
    rasi = { S.cxx_l, S.cxx_b },
    readline = { S.hash },
    reason = { S.cxx_l, S.cxx_b },
    rego = { S.hash },
    remind = { S.hash },
    rescript = { S.cxx_l, S.cxx_b },
    robot = { S.hash }, -- Robotframework doesn't have block comments
    ron = { S.cxx_l, S.cxx_b },
    ruby = { S.hash, S.ruby_block },
    rust = { S.cxx_l, S.cxx_b },
    sbt = { S.cxx_l, S.cxx_b },
    scala = { S.cxx_l, S.cxx_b },
    scss = { S.cxx_b, S.cxx_b },
    scheme = { S.lisp_l, S.lisp_b },
    sh = { S.hash },
    solidity = { S.cxx_l, S.cxx_b },
    supercollider = { S.cxx_l, S.cxx_b },
    sql = { S.dash, S.cxx_b },
    stata = { S.cxx_l, S.cxx_b },
    svelte = { S.html, S.html },
    swift = { S.cxx_l, S.cxx_b },
    sxhkdrc = { S.hash },
    systemverilog = { S.cxx_l, S.cxx_b },
    tablegen = { S.cxx_l, S.cxx_b },
    teal = { S.dash, S.dash_bracket },
    terraform = { S.hash, S.cxx_b },
    tex = { S.latex },
    template = { S.dbl_hash },
    tidal = { S.dash, S.haskell_b },
    tmux = { S.hash },
    toml = { S.hash },
    twig = { S.twig, S.twig },
    typescript = { S.cxx_l, S.cxx_b },
    typescriptreact = { S.cxx_l, S.cxx_b },
    typst = { S.cxx_l, S.cxx_b },
    v = { S.cxx_l, S.cxx_b },
    vala = { S.cxx_l, S.cxx_b },
    verilog = { S.cxx_l },
    vhdl = { S.dash },
    vim = { S.vim },
    vifm = { S.vim },
    vue = { S.html, S.html },
    wgsl = { S.cxx_l, S.cxx_b },
    xdefaults = { '!%s' },
    xml = { S.html, S.html },
    xonsh = { S.hash }, -- Xonsh doesn't have block comments
    yaml = { S.hash },
    yuck = { S.lisp_l },
    zig = { S.cxx_l }, -- Zig doesn't have block comments
}, {
    -- Support for compound filetype i.e. 'ios.swift', 'ansible.yaml' etc.
    __index = function(this, filetype)
        local base, fallback = string.match(filetype, '^(.-)%.(.*)')
        if not (base or fallback) then return nil end
        return this[base] or this[fallback]
    end,
})

---gets the fallback commentstring
---@param filetype string
---@param comment_string_type MyCommentStringType
---@return string? commentstring
local function get_fallback_commentstring(filetype, comment_string_type)
    if comment_string_type == 'block' then
        return nil -- No fallback for block comments for now TODO maybe add a default
    end
    if vim.bo.commentstring ~= '' then
        if not filetypes_notified_of_no_configuration[filetype] then
            vim.notify(
                string.format(
                    'commentstring not configured for filetype `%s` so will fallback to vim.bo.commentstring of `%s`',
                    filetype,
                    vim.bo.commentstring
                ),
                vim.log.levels.WARN
            )
            filetypes_notified_of_no_configuration[filetype] = true
        end
        return vim.bo.commentstring
    end
    return nil
end

---Get line/block/both commentstring(s) for a given filetype
---
---Based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/ft.lua#L250
---@param lang string Filetype/Language of the buffer
---@param comment_string_type MyCommentStringType
---@return string? #Returns stored commentstring
function M.get(lang, comment_string_type)
    local tuple = L[lang]
    if not tuple then return nil end
    if comment_string_type == 'line' then
        return tuple[1]
    elseif comment_string_type == 'block' then
        return tuple[2]
    else
        error('invalid comment_string_type')
    end
end

---Get a language tree for a given range by walking the parse tree recursively.
---This uses 'lua-treesitter' API under the hood. This can be used to calculate
---language of a particular region which embedded multiple filetypes like html,
---vue, markdown etc.
---
---NOTE: This ignores `tree-sitter-comment` parser, if installed.
---
---Based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/ft.lua#L279
---@param tree vim.treesitter.LanguageTree Parse tree to be walked
---@param range integer[] Range to check
---{start_row, start_col, end_row, end_col}
---@return vim.treesitter.LanguageTree
local function contains(tree, range)
    for lang, child in pairs(tree:children()) do
        if lang ~= 'comment' and child:contains(range) then
            return contains(child, range)
        end
    end

    return tree
end

---Calculate commentstring with the power of treesitter
---
---Based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/ft.lua#L293
---with the logic for treesitter injected trees fixed
---@param range My01IndexedBufferRange
---@param comment_string_type MyCommentStringType
---@return nil|string commentstring
local function calculate(range, comment_string_type)
    local parser, err =
        vim.treesitter.get_parser(vim.api.nvim_get_current_buf())
    if parser == nil or err then
        local commentstring = M.get(vim.bo.filetype, comment_string_type)
            or get_fallback_commentstring(vim.bo.filetype, comment_string_type)

        return commentstring
    end

    local lang = contains(parser, {
        range.start_row - 1,
        range.start_col,
        range.end_row - 1,
        range.end_col,
    }):lang()

    local filetypes = vim.treesitter.language.get_filetypes(lang)

    for _, ft in ipairs(filetypes) do
        local commentstring = M.get(ft, comment_string_type)
        if commentstring ~= nil then return commentstring end
    end
    return M.get(vim.bo.filetype, comment_string_type)
        or get_fallback_commentstring(vim.bo.filetype, comment_string_type)
end

---Determines the left and right side of the comment string for the given type
---based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/utils.lua#L173
---
---TODO this could use some refactoring and should use the bufnr as a param
---@param range My01IndexedBufferRange
---@param comment_string_type MyCommentStringType
---@return string string Left side of the commentstring
---@return string string Right side of the commentstring
function M.parse_cstr(range, comment_string_type)
    local inbuilt = calculate(range, comment_string_type)

    assert(
        inbuilt or (comment_string_type ~= 'block'),
        vim.bo.filetype .. " doesn't support block comments!"
    )

    local cstr = inbuilt or vim.bo.commentstring
    local left, right = string.match(cstr, '(.*)%%s(.*)')

    assert((left or right), {
        msg = string.format(
            'Invalid commentstring for %s! Read `:h commentstring` for help.',
            vim.bo.filetype
        ),
    })

    return vim.trim(left), vim.trim(right)
end

return M
