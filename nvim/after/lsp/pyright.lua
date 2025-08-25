return {
    settings = {
        python = {
            -- Note autoImportCompletions only shows imports that have been used in other files that have already been opened
            -- See https://github.com/hrsh7th/nvim-cmp/issues/426#issuecomment-1185144017
            -- TODO see if there is a way to get it to at least suggest imports without having to open all workspace files
            autoImportCompletions = true,
        },
    },
}
