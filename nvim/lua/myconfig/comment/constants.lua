local C = {}

---@class MyCommentMode
---@field comment integer Comment action
---@field uncomment integer Uncomment action

---An object containing comment modes
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
---@type MyCommentType
C.ctype = {
    linewise = 1,
    blockwise = 2,
}

return C
