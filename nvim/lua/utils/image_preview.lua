local M = {}

local function get_file_extension(url) return url:match('^.+(%..+)$') end

local function is_image(url)
    local extension = get_file_extension(url)

    if extension == '.bmp' then
        return true
    elseif extension == '.jpg' or extension == '.jpeg' then
        return true
    elseif extension == '.png' then
        return true
    elseif extension == '.gif' then
        return true
    end

    return false
end

-- Based on plugin https://github.com/adelarsq/image_preview.nvim
function M.preview_image(absolutePath)
    if is_image(absolutePath) then
        local command = ''

        if vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1 then
            command =
                'silent !wezterm cli split-pane -- powershell wezterm imgcat '
            command = command .. "'" .. absolutePath .. "'"
            command = command .. ' ; pause'
        else
            command =
                "silent !wezterm cli split-pane -- bash -c 'wezterm imgcat "
            command = command .. absolutePath
            command = command .. " ; read'"
        end

        vim.api.nvim_command(command)
    else
        print('No preview for file ' .. absolutePath)
    end
end

return M
