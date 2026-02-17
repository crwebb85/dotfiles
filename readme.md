## Requirements:

- [git](https://git-scm.com/)
- [.NET](https://dotnet.microsoft.com/en-us/download/dotnet) used to install
  powershell 7 on Windows. Download the SDK if developing dotnet applications.
  Download the `Hosting Bundle` runtime as well if developing/running dotnet
  applications in IIS.
- [PowerShell 7](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows?view=powershell-7.5)
  (Windows only) Install with `dotnet tool install --global PowerShell`
- [neovim](https://github.com/neovim/neovim) my editor. Use nightly release.
- [ripgrep](https://github.com/BurntSushi/ripgrep) file finder used by pickers like telescope.nvim
- [Treesitter CLI](https://github.com/tree-sitter/tree-sitter) which is now required by nvim-treesitter
- [mingw](https://www.mingw-w64.org/downloads/#mingw-w64-builds) used by nvim-treesitter
  to compile the parsers (can also be installed with `choco install mingw`)
- [fd](https://github.com/sharkdp/fd) file finder used by venv-selector.nvim
- [fzf](https://github.com/junegunn/fzf) fuzzy finder. Used by my powershell profile.
- [node/npm](https://nodejs.org/en) used to run and install some LSPs, formatters,
  and debuggers (using mason.nvim)
- [python/pip/py](https://www.python.org/downloads/) used to run and install some
  LSPs, formatters, and debuggers (using mason.nvim). Note: On windows, only `py`
  is added to the path variables so the default python install location will need
  to be added so that mason.nvim can find it. Also used in [Inlined Config Requirements](#inlined-config-requirements)
- Rust specific tools:
  - [rust/cargo](https://rust-lang.org/tools/install/)
  - [carg-bininstall](https://github.com/cargo-bins/cargo-binstall) used for installing nextest
  - [nextest](https://nexte.st/) the rust test runner that the plugin [neotest-rust](https://github.com/rouge8/neotest-rust)
    requires
- Go specific tools:
  - [go](https://go.dev/dl/)

## Inlined Config Requirements:

- `.\cli-tools\jupytext_venv\venv` installs jupytext cli (via pip) used by my
  config to convert jupyter notebooks to a markdown format for editing and then
  convert them back to json when saving.
- `.\cli-tools\neovim_remote_plugin_python_venv\venv` used for neovim python
  remote plugins (required by molten-nvim)
- `.\cli-tools\prettier\package.json` used to install prettier with the xml plugin.
  This needs to be setup for conform.nvim to format xml

## Optional Requirements:

- [wezterm](https://wezterm.org/)
- [hurl](https://github.com/Orange-OpenSource/hurl)
- [make](https://www.gnu.org/software/make/#download) used to run project makefiles
  (can also be installed with `choco install make`
- [chafa](https://github.com/hpjansson/chafa) converts images to ascii. Used by
  my telescope.nvim picker to preview images. (can also be installed with
  `winget install hpjansson.Chafa`
- [choco](https://chocolatey.org/install) a package manager for programs on Windows
  (optional way to install programs)
- [clang](https://clang.llvm.org/) clang c compiler
- [GitHub CLI](https://cli.github.com/)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- [Azure Devops Extension to Azure CLI](https://learn.microsoft.com/en-us/azure/devops/cli/?view=azure-devops)
- Used to build neovim
  - [cmake](https://cmake.org/download/)
  - [zig version 0.15.2](https://ziglang.org/download/) used by zig build
  - [windows sdk](https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/)
    used by zig build. See [neovim issue #36889](https://github.com/neovim/neovim/issues/36889)

## Add Environment Variables:

- User variables manually added
  - `MY_NOTES=<path to my notes different per machine>` used by notes file picker in neovim
  - `XDG_CONFIG_HOME=%USERPROFILE%\Documents\.config\` the location this repository is checked out
  - `Path=%USERPROFILE%\AppData\Local\nvim-data\mason\bin` for CLI's installed by mason.nvim
  - `Path=%USERPROFILE%\AppData\Local\Programs\Python\Python314` so that mason.nvim can find the default python
  - `Path=%USERPROFILE%\Documents\tools\nvim-win64` for [neovim](https://github.com/neovim/neovim)
  - `Path=%USERPROFILE%\Documents\tools\ripgrep` for [ripgrep](https://github.com/BurntSushi/ripgrep)
  - `Path=%USERPROFILE%\Documents\tools\tree-sitter-windows-x64` for [Treesitter CLI](https://github.com/tree-sitter/tree-sitter)
  - `Path=%USERPROFILE%\Documents\tools\mingw` for [mingw](https://www.mingw-w64.org/downloads/#mingw-w64-builds)
  - `Path=%USERPROFILE%\Documents\tools\fd` for [fd](https://github.com/sharkdp/fd)
  - `Path=%USERPROFILE%\Documents\tools\fzf` for [fzf](https://github.com/junegunn/fzf)
  - `Path=%USERPROFILE%\Documents\tools\hurl` for [hurl](https://github.com/Orange-OpenSource/hurl)
  - `Path=%USERPROFILE%\Documents\tools\make` for [make](https://www.gnu.org/software/make/#download)
  - `Path=%USERPROFILE%\Documents\tools\WezTerm` for [wezterm](https://wezterm.org/)
  - `Path=%USERPROFILE%\Documents\tools\chafa` for [chafa](https://github.com/hpjansson/chafa)
  - `Path=%USERPROFILE%\Documents\tools\clang` for [clang](https://clang.llvm.org/)
  - `Path=%USERPROFILE%\Documents\tools\zig` for [zig version 0.15.2](https://ziglang.org/download/)
- User Variables that should be added by installers
  - `Path=%USERPROFILE%\.cargo\bin` for tools installed by [rust's cargo](https://rust-lang.org/tools/install/)
  - `Path=%USERPROFILE%\AppData\Local\Programs\Python\Launcher\` for [py python version manager](https://www.python.org/downloads/)
  - `Path=%USERPROFILE%\.dotnet\tools` for tools installed by dotnet (If you
    install Powershell 7 using the dotnet CLI, then `pwsh` should be accessible
    on path)
  - `Path=%USERPROFILE%\go\bin` for tools installed by [go](https://go.dev/dl/)
  - `Path=%USERPROFILE%\AppData\Roaming\npm` for tools installed globally by npm
- System Variables manually added
  - None
- System Variables that should be added by installers:
  - `C:\Program Files\Git\cmd`
  - `Path=C:\ProgramData\chocolatey\bin`
  - `Path=C:\Program Files\nodejs`
  - `Path=C:\Program Files\dotnet\`
  - `Path=C:\Program Files\Go\bin`
  - `C:\Program Files\CMake\bin`
  - `C:\Program Files\GitHub CLI\`

# Updating Config

```powershell
# Backup my config file for easier comparison
Copy-Item -Path "$env:XDG_CONFIG_HOME\nvim\lua\myconfig\config.lua" -Destination "$env:XDG_CONFIG_HOME\nvim\lua\myconfig\config.lua.bak"

git checkout -b <YYYY-MM-DD>

# review the changes to my repo
nvim ./ "+DiffviewOpen"

git add --all
git commit --message "Backing up changes"

git checkout main
git pull

# If treesitter.nvim fails to install parsers on some machines, I sometimes edit
# the curl request so I need to stash it before restoring plugins
$treesitterPath = "$env:USERPROFILE\AppData\Local\nvim-data\lazy\nvim-treesitter"
if ($env:XDG_DATA_HOME -ne $null) {
    $treesitterPath = "$env:XDG_DATA_HOME\nvim-data\lazy\nvim-treesitter"
}
git -C "$treesitterPath" stash

# Restore plugins
nvim --headless "+Lazy! restore" +qa

# the first time lazy restore runs it puts the versions
# at HEAD so we need to stash the lock file and rerun
# so it properly sets versions to the lazy lock file
git stash

# Restore plugins a second time to checkout the commits in the lock file
nvim --headless "+Lazy! restore" +qa

# Compare the old config.lua with the new one in use `:diffget` to pull in any changes
nvim --clean -d  $env:XDG_CONFIG_HOME\nvim\lua\myconfig\config.lua $env:XDG_CONFIG_HOME\nvim\lua\myconfig\config.lua.bak

# If treesitter.nvim fails to install parsers on some machines, I sometimes edit
# the curl request so I need pop the changes after restoring plugins
git -C "$treesitterPath" stash pop

# update jupytext_venv
& $env:XDG_CONFIG_HOME\cli-tools\jupytext_venv\venv\Scripts\python.exe -m pip install -r "$env:XDG_CONFIG_HOME\cli-tools\jupytext_venv\requirements.txt"

# update neovim_remote_plugin_python_venv
& $env:XDG_CONFIG_HOME\cli-tools\neovim_remote_plugin_python_venv\venv\Scripts\python.exe -m pip install -r "$env:XDG_CONFIG_HOME\cli-tools\neovim_remote_plugin_python_venv\requirements.txt"

# update prettier xml packages
npm --cwd "$env:XDG_CONFIG_HOME\cli-tools\prettier" install

# Open neovim and update treesitter parsers and mason cli's
nvim ./
```

# Debugging

When having issues with treesitter.nvim try manually deleting the files and reinstalling
