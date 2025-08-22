---Based on https://github.com/nvim-telescope/telescope-media-files.nvim

local filetypes = { 'png', 'jpg', 'gif', 'mp4', 'webm', 'pdf' }

---Get file extension from path
---@param url string file path or url
---@return string
local function get_file_extension(url)
    local extension_match = url:match('^.+(%..+)$')
    if type(extension_match) == 'string' then
        local extension, _ = string.gsub(extension_match, '%.', '')
        return extension
    else
        return ''
    end
end

---@class PreviewDrawerOptions
---@field path string
---@field preview_width number
---@field preview_height number

---Creates the image preview command
---@param opts PreviewDrawerOptions
---@return string[] | nil command and arguments or nil if error
---@return string? error
local function image_preview(opts)
    local chafa_cmd_name = 'chafa'
    if vim.fn.executable(chafa_cmd_name) == 0 then
        return nil,
            'Warning: Image preview requires chafa. Install it first to view preview.'
    end
    return {
        chafa_cmd_name,
        vim.fs.abspath(vim.fs.normalize(opts.path)),
        '--format=symbols',
        '--clear',
        '--size',
        string.format('%sx%s', opts.preview_width, opts.preview_height),
    },
        nil
end

---@param opts PreviewDrawerOptions
---@return string[] | nil command and arguments or nil if error
---@return string? error
local function gif_preview(opts)
    local chafa_cmd_name = 'chafa'
    if vim.fn.executable(chafa_cmd_name) == 0 then
        return nil,
            'Warning: Image preview requires chafa. Install it first to view preview.'
    end
    return {
        chafa_cmd_name,
        vim.fs.abspath(vim.fs.normalize(opts.path)),
        '--format=symbols',
        '--clear',
        '--size',
        string.format('%sx%s', opts.preview_width, opts.preview_height),
    },
        nil
end

---@param _opts PreviewDrawerOptions
---@return string[] | nil command and arguments or nil if error
---@return string? error
local function video_preview(_opts)
    -- TODO
    return nil, 'unimplemented video preview'
    -- if ! command -v viu &> /dev/null; then
    --   echo "ffmpegthumbnailer could not be found in your path,\nplease install it to display video previews"
    --   exit
    -- fi
    -- path="${2##*/}"
    -- echo -e "Loading preview..\nFile: $path"
    -- ffmpegthumbnailer -i "$2" -o "${TMP_FOLDER}/${path}.png" -s 0 -q 10
    -- clear
    -- render_at_size "${5}" "${6}" "${TMP_FOLDER}/${path}.png" "${7}"

    -- return get_render_at_size_command(opts.path, opts.preview_width, opts.preview_height)
end

---@param _opts PreviewDrawerOptions
---@return string[] | nil command and arguments or nil if error
---@return string? error
local function pdf_preview(_opts)
    return nil, 'unimplemented pdf preview'
    -- path="${2##*/}"
    --   echo -e "Loading preview..\nFile: $path"
    --   [[ ! -f "${TMP_FOLDER}/${path}.png" ]] && pdftoppm -png -singlefile "$2" "${TMP_FOLDER}/${path}.png"
    --   clear
    --   render_at_size "${5}" "${6}" "${TMP_FOLDER}/${path}.png" "${7}"

    -- return get_render_at_size_command(opts.path, opts.preview_width, opts.preview_height)
end

local draw_matcher = {
    ['jpg'] = image_preview,
    ['png'] = image_preview,
    ['jpeg'] = image_preview,
    ['webp'] = image_preview,
    ['svg'] = image_preview,
    ['gif'] = gif_preview,
    ['avi'] = video_preview,
    ['mp4'] = video_preview,
    ['wmv'] = video_preview,
    ['dat'] = video_preview,
    ['3gp'] = video_preview,
    ['ogv'] = video_preview,
    ['mkv'] = video_preview,
    ['mpg'] = video_preview,
    ['mpeg'] = video_preview,
    ['vob'] = video_preview,
    ['m2v'] = video_preview,
    ['mov'] = video_preview,
    ['webm'] = video_preview,
    ['mts'] = video_preview,
    ['m4v'] = video_preview,
    ['rm'] = video_preview,
    ['qt'] = video_preview,
    ['divx'] = video_preview,
    ['pdf'] = pdf_preview,
    ['epub'] = pdf_preview,
}

local function get_command(opts, entry, status)
    local preview_winid = status.layout.preview and status.layout.preview.winid
    local preview_width = vim.api.nvim_win_get_width(preview_winid)
    local preview_height = vim.api.nvim_win_get_height(preview_winid)

    local tmp_table = vim.split(entry.value, '\t')

    opts.cwd = opts.cwd and vim.fn.expand(opts.cwd) or vim.uv.cwd()

    if vim.tbl_isempty(tmp_table) then
        return nil, 'Hello from empty temp_table'
    end

    local path = string.format([[%s/%s]], opts.cwd, tmp_table[1])
    local extension = get_file_extension(path)

    local preview_drawer = draw_matcher[extension]
    if preview_drawer then
        return preview_drawer({
            path = path,
            preview_width = preview_width,
            preview_height = preview_height,
        })
    else
        return nil, 'Invalid file type'
    end
end

---Based on telescope's new_termopen_previewer
local function media_previewer(opts)
    opts = opts or {}

    assert(not opts.preview_fn, 'preview_fn not allowed')

    local opt_setup = opts.setup
    local opt_teardown = opts.teardown

    local old_bufs = {}
    local bufentry_table = {}
    local term_ids = {}

    local function get_term_id(self)
        if self.state then return self.state.termopen_id end
    end

    local function get_bufnr(self)
        if self.state then return self.state.termopen_bufnr end
    end

    local function set_term_id(self, value)
        if self.state and term_ids[self.state.termopen_bufnr] == nil then
            term_ids[self.state.termopen_bufnr] = value
            self.state.termopen_id = value
        end
    end

    local function set_bufnr(self, value)
        if get_bufnr(self) then table.insert(old_bufs, get_bufnr(self)) end
        if self.state then self.state.termopen_bufnr = value end
    end

    local function get_bufnr_by_bufentry(self, value)
        if self.state then return bufentry_table[value] end
    end

    local function set_bufentry(self, value)
        if self.state and value then bufentry_table[value] = get_bufnr(self) end
    end

    function opts.setup(self)
        local state = {}
        if opt_setup then
            state = vim.tbl_deep_extend('force', state, opt_setup(self))
        end
        return state
    end

    function opts.teardown(self)
        if opt_teardown then opt_teardown(self) end

        set_bufnr(self, nil)
        set_bufentry(self, nil)

        for _, bufnr in ipairs(old_bufs) do
            local term_id = term_ids[bufnr]
            if
                term_id
                and require('telescope.utils').job_is_running(term_id)
            then
                vim.fn.jobstop(term_id)
            end
            require('telescope.utils').buf_delete(bufnr)
        end
        bufentry_table = {}
    end

    function opts.preview_fn(self, entry, status)
        local preview_winid = status.layout.preview
            and status.layout.preview.winid

        if get_bufnr(self) == nil then
            set_bufnr(self, vim.api.nvim_win_get_buf(preview_winid))
        end

        local prev_bufnr = get_bufnr_by_bufentry(self, entry)
        if prev_bufnr then
            set_bufnr(self, prev_bufnr)
            require('telescope.utils').win_set_buf_noautocmd(
                preview_winid,
                self.state.termopen_bufnr
            )
            self.state.termopen_id = term_ids[self.state.termopen_bufnr]
        else
            local bufnr = vim.api.nvim_create_buf(false, true)
            set_bufnr(self, bufnr)
            require('telescope.utils').win_set_buf_noautocmd(
                preview_winid,
                bufnr
            )

            local cmd, err = get_command(opts, entry, status)
            if cmd then
                vim.api.nvim_buf_call(bufnr, function()
                    local term_id = vim.fn.jobstart(cmd, {
                        cwd = opts.cwd or vim.uv.cwd(),
                        env = opts.env
                            or require('telescope.config').values.set_env,
                        term = true,
                    })
                    set_term_id(self, term_id)
                end)
            elseif err ~= nil then
                vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, { err })
            end
            set_bufentry(self, entry)
        end
    end

    if not opts.send_input then
        function opts.send_input(self, input)
            local termcode =
                vim.api.nvim_replace_termcodes(input, true, false, true)

            local term_id = get_term_id(self)
            if term_id then
                if not require('telescope.utils').job_is_running(term_id) then
                    return
                end

                vim.fn.chansend(term_id, termcode)
            end
        end
    end

    if not opts.scroll_fn then
        function opts.scroll_fn(self, direction)
            if not self.state then return end

            local input = direction > 0 and 'd' or 'u'
            local count = math.abs(direction)

            self:send_input(count .. input)
        end
    end

    local Previewer = require('telescope.previewers.previewer')
    return Previewer:new(opts)
end

local media_preview = require('telescope.utils').make_default_callable(
    function(_) return media_previewer({}) end,
    {}
)

local function media_files(opts)
    opts = opts or {}
    opts.attach_mappings = function(prompt_bufnr, _)
        require('telescope.actions').select_default:replace(function()
            local entry =
                require('telescope.actions.state').get_selected_entry()
            require('telescope.actions').close(prompt_bufnr)
            if entry[1] then
                local filename = entry[1]
                vim.fn.setreg(vim.v.register, filename)
                vim.notify('The image path has been copied!')
            end
        end)
        return true
    end
    opts.path_display = { 'shorten' }

    local picker = require('telescope.pickers').new(opts, {
        prompt_title = 'Media Files',
        finder = require('telescope.finders').new_oneshot_job({
            'rg',
            '--files',
            '--glob',
            [[*.{]] .. table.concat(filetypes, ',') .. [[}]],
            '.',
        }, opts),
        previewer = media_preview.new(opts),
        sorter = require('telescope.config').values.file_sorter(opts),
    })

    picker:find()
end

return require('telescope').register_extension({
    setup = function(_) end,
    exports = {
        media_files = media_files,
    },
})
