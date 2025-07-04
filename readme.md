# Windows install

[Wezterm config help](https://gilbertsanchez.com/posts/my-terminal-wezterm/)

```ps1
# if pwsh is not a command
winget install --id Microsoft.Powershell --source winget

# Then install
choco install mingw
choco install ripgrep
winget install hpjansson.Chafa
choco install make
choco install hurl
```

Other requirements:

- node
- npm
- python
- pip
- [Treesitter CLI](https://github.com/tree-sitter/tree-sitter) which is now required by nvim-treesitter

Add Environment Variables:

- User variables
  - XDG_CONFIG_HOME=%USERPROFILE%\Documents\.config\
  - Path=%USERPROFILE%\AppData\Local\nvim-data\mason\bin
- System Variables:
  - Path=C:\Program Files\WezTerm
  - Path=C:\nvim-win64\bin
  - Path=C:\tree-sitter-windows-x64
  - Path=C:\Program Files\nodejs
  - Path=C:\ProgramData\chocolatey\bin
  - Path=C:\Program Files\PowerShell\7

Rust specific tools:

- [carg-bininstall](https://github.com/cargo-bins/cargo-binstall) used for installing nextest
- [nextest](https://nexte.st/) the rust test runner that the plugin https://github.com/rouge8/neotest-rust requires

I also had issues with treesitter markdown support `Error in decoration provider treesitter/highlighter.win: Error executing lua: ...im`
I solved it by trying:

```
:TSUninstall markdown
:TSUninstall markdown_inline
```

Those commands failed for some reason but the error message told me the file path they
were downloaded at and I manually deleted them and it fixed the problem
