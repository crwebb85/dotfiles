vim.o.shell = vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell"
vim.cmd([[
	   set noshelltemp
	   let &shellcmdflag = '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command '
	   let &shellcmdflag .= '[Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new();'
	   let &shellcmdflag .= '$PSDefaultParameterValues[''Out-File:Encoding'']=''utf8'';'
	   let &shellpipe  = '> %s 2>&1'
	   set shellquote= shellxquote=
    ]])
if vim.fn.executable("pwsh") == 1 then
	vim.cmd([[
            let &shellcmdflag .= '$PSStyle.OutputRendering = ''PlainText'';'
            let $__SuppressAnsiEscapeSequences = 1
        ]])
end
