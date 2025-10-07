local M = {}

---Gets the property that toggles if quickfix list is in preview mode
---@return boolean
function M.is_qf_preview_mode()
    if vim.g.is_qf_preview_mode == nil then return false end
    return vim.g.is_qf_preview_mode
end

---Sets the property to toggle if quickfix list is in preview mode
---@param is_qf_preview_mode boolean
function M.set_qf_preview_mode(is_qf_preview_mode)
    vim.g.is_qf_preview_mode = is_qf_preview_mode
end

return M
