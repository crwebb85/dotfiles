local M = {}

---Helper to get padding pattern
---
---based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/utils.lua#L86
---@param flag boolean
---@return string string
function M.get_padpat(flag) return flag and '%s?' or '' end

---Helper to get padding character
---
---based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/utils.lua#L78
---@param flag boolean
---@return string string
function M.get_pad(flag) return flag and ' ' or '' end
return M
