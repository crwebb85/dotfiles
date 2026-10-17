local C = {}

---@class MyCommentMode
---@field comment integer Comment action
---@field uncomment integer Uncomment action

---An object containing comment modes
---
---Based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/utils.lua#L30
---
---TODO refactor out
---@type MyCommentMode
C.cmode = {
    comment = 1,
    uncomment = 2,
}

---Comment types
---@class MyCommentType
---@field linewise integer Use linewise commentstring
---@field blockwise integer Use blockwise commentstring

---An object containing comment types
---
---Based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/utils.lua#L43
---
---TODO refactor out
---@type MyCommentType
C.ctype = {
    linewise = 1,
    blockwise = 2,
}

return C
