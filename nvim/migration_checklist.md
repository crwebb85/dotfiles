- [x] replace ipc_tools
- [ ] implement sort_json in command_handlers.lua
- [x] create Invoke-Delete-DotGit
- [x] add error handling for Invoke-Delete-DotGit
- remove Invoke-OldNvim
- add a sort QF/loc list command
- add a dd QF/loc list keymap
- setup luarc.json
- [x] fix bug where the character at the cursor is getting pasted into telescope
- [x] refactor to first download all plugins and then only load the ones I want to load
- load profile.nvim when using it's keymap
- My quickfix commands don't open the quickfix menu so that I can chain them together but
  I should still notify how many items got added/set
- vim.diagnostic.setqflist has a bug where it clears the quickfix list history
- create user commands like `vim.pack.update(nil, { target = 'lockfile' })`
- what is the following mean in the vim.pack.add description `For each plugin execute |:packadd| (or customizable 'load' function) making it reachable by Nvim.`
- the old EditorToolsCLI shows how to use a pyproject.toml switch to using it
- my quickfix commands should notify changes if list closed or if nothing changed
- my gd keymap should us 'u' to update the quickfix when I gd the same item since
  I don't want to keep poluting my quickfix history with lists that have the exact
  same entries
- replace conform.nvim with an lsp that converts formatters to an lsp
- move lsp's and formatters from mason to cli-tool/ folder
  - powershell_es To install, download and extract PowerShellEditorServices.zip from the [releases](https://github.com/PowerShell/PowerShellEditorServices/releases). To configure the language server, set the property `bundle_path` to the root of the extracted PowerShellEditorServices.zip.
  - prettier just use the one I am already using
- `tree-sitter --init-config`

```
  c = {
    install_info = {
      revision = 'ae19b676b13bdcc13b7665397e6d9b14975473dd',
      url = 'https://github.com/tree-sitter/tree-sitter-c',
    },
    maintainers = { '@amaanq' },
    tier = 2,
  },
  lua = {
    install_info = {
      revision = '10fe0054734eec83049514ea2e718b2a56acd0c9',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-lua',
    },
    maintainers = { '@muniftanjim' },
    tier = 2,
  },

  luadoc = {
    install_info = {
      revision = '873612aadd3f684dd4e631bdf42ea8990c57634e',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-luadoc',
    },
    maintainers = { '@amaanq' },
    tier = 2,
  },
  vim = {
    install_info = {
      revision = '3092fcd99eb87bbd0fc434aa03650ba58bd5b43b',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-vim',
    },
    maintainers = { '@clason' },
    tier = 2,
  },
  vimdoc = {
    install_info = {
      revision = 'f061895a0eff1d5b90e4fb60d21d87be3267031a',
      url = 'https://github.com/neovim/tree-sitter-vimdoc',
    },
    maintainers = { '@clason' },
    tier = 2,
  },
  markdown = {
    install_info = {
      location = 'tree-sitter-markdown',
      revision = 'f969cd3ae3f9fbd4e43205431d0ae286014c05b5',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-markdown',
    },
    maintainers = { '@MDeiml' },
    readme_note = 'basic highlighting',
    requires = { 'markdown_inline' },
    tier = 2,
  },
  markdown_inline = {
    install_info = {
      location = 'tree-sitter-markdown-inline',
      revision = 'f969cd3ae3f9fbd4e43205431d0ae286014c05b5',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-markdown',
    },
    maintainers = { '@MDeiml' },
    readme_note = 'needed for full highlighting',
    tier = 2,
  },
  diff = {
    install_info = {
      revision = '2520c3f934b3179bb540d23e0ef45f75304b5fed',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-diff',
    },
    maintainers = { '@gbprod' },
    tier = 2,
  },

  editorconfig = {
    install_info = {
      revision = 'v2.0.0',
      url = 'https://github.com/ValdezFOmar/tree-sitter-editorconfig',
    },
    maintainers = { '@ValdezFOmar' },
    tier = 1,
  },
javascript = {
  install_info = {
    revision = '58404d8cf191d69f2674a8fd507bd5776f46cb11',
    url = 'https://github.com/tree-sitter/tree-sitter-javascript',
  },
  maintainers = { '@steelsojka' },
  requires = { 'ecma', 'jsx' },
  tier = 2,
},

  powershell = {
    filetype = 'ps1',
    install_info = {
      revision = '73800ecc8bddeee8f1079a5a2e0c13c3d00269bb',
      url = 'https://github.com/airbus-cert/tree-sitter-powershell',
    },
    maintainers = { '@L2jLiga' },
    tier = 2,
  },
  tsx = {
    install_info = {
      location = 'tsx',
      revision = '75b3874edb2dc714fb1fd77a32013d0f8699989f',
      url = 'https://github.com/tree-sitter/tree-sitter-typescript',
    },
    maintainers = { '@steelsojka' },
    requires = { 'ecma', 'jsx', 'typescript' },
    tier = 2,
  },

  jsx = {
    maintainers = { '@steelsojka' },
    readme_note = 'queries required by javascript, tsx',
    tier = 2,
  },
  typescript = {
    install_info = {
      location = 'typescript',
      revision = '75b3874edb2dc714fb1fd77a32013d0f8699989f',
      url = 'https://github.com/tree-sitter/tree-sitter-typescript',
    },
    maintainers = { '@steelsojka' },
    requires = { 'ecma' },
    tier = 2,
  },

  cpp = {
    install_info = {
      revision = '8b5b49eb196bec7040441bee33b2c9a4838d6967',
      url = 'https://github.com/tree-sitter/tree-sitter-cpp',
    },
    maintainers = { '@theHamsta' },
    requires = { 'c' },
    tier = 2,
  },
  css = {
    install_info = {
      revision = 'dda5cfc5722c429eaba1c910ca32c2c0c5bb1a3f',
      url = 'https://github.com/tree-sitter/tree-sitter-css',
    },
    maintainers = { '@TravonteD' },
    tier = 2,
  },
  csv = {
    install_info = {
      location = 'csv',
      revision = 'f6bf6e35eb0b95fbadea4bb39cb9709507fcb181',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-csv',
    },
    maintainers = { '@amaanq' },
    requires = { 'tsv' },
    tier = 2,
  },
json = {
  install_info = {
    revision = '001c28d7a29832b06b0e831ec77845553c89b56d',
    url = 'https://github.com/tree-sitter/tree-sitter-json',
  },
  maintainers = { '@steelsojka' },
  tier = 2,
},
json5 = {
  install_info = {
    revision = 'aa630ef48903ab99e406a8acd2e2933077cc34e1',
    url = 'https://github.com/Joakker/tree-sitter-json5',
  },
  maintainers = { '@Joakker' },
  tier = 2,
},

  apex = {
    install_info = {
      location = 'apex',
      revision = '3597575a429766dd7ecce9f5bb97f6fec4419d5d',
      url = 'https://github.com/aheber/tree-sitter-sfapex',
    },
    maintainers = { '@aheber', '@xixiafinland' },
    tier = 2,
  },

  ecma = {
    maintainers = { '@steelsojka' },
    readme_note = 'queries required by javascript, typescript, tsx, qmljs',
    tier = 2,
  },

  xml = {
    install_info = {
      location = 'xml',
      revision = '5000ae8f22d11fbe93939b05c1e37cf21117162d',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-xml',
    },
    maintainers = { '@ObserverOfTime' },
    requires = { 'dtd' },
    tier = 2,
  },

  yaml = {
    install_info = {
      revision = '4463985dfccc640f3d6991e3396a2047610cf5f8',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-yaml',
    },
    maintainers = { '@amaanq' },
    tier = 2,
  },
  dtd = {
    install_info = {
      location = 'dtd',
      revision = '5000ae8f22d11fbe93939b05c1e37cf21117162d',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-xml',
    },
    maintainers = { '@ObserverOfTime' },
    tier = 2,
  },

  yaml = {
    install_info = {
      revision = '4463985dfccc640f3d6991e3396a2047610cf5f8',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-yaml',
    },
    maintainers = { '@amaanq' },
    tier = 2,
  },

  rust = {
    install_info = {
      revision = '77a3747266f4d621d0757825e6b11edcbf991ca5',
      url = 'https://github.com/tree-sitter/tree-sitter-rust',
    },
    maintainers = { '@amaanq' },
    tier = 2,
  },

  query = {
    install_info = {
      revision = 'fc5409c6820dd5e02b0b0a309d3da2bfcde2db17',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-query',
    },
    maintainers = { '@steelsojka' },
    readme_note = 'Tree-sitter query language',
    tier = 2,
  },
toml = {
  install_info = {
    revision = '64b56832c2cffe41758f28e05c756a3a98d16f41',
    url = 'https://github.com/tree-sitter-grammars/tree-sitter-toml',
  },
  maintainers = { '@tk-shirasaka' },
  tier = 2,
},
tsv = {
  install_info = {
    location = 'tsv',
    revision = 'f6bf6e35eb0b95fbadea4bb39cb9709507fcb181',
    url = 'https://github.com/tree-sitter-grammars/tree-sitter-csv',
  },
  maintainers = { '@amaanq' },
  tier = 2,
},
  razor = {
    install_info = {
      revision = 'fe46ce5ea7d844e53d59bc96f2175d33691c61c5',
      url = 'https://github.com/tris203/tree-sitter-razor',
    },
    maintainers = { '@tris203' },
    tier = 2,
  },

  http = {
    install_info = {
      revision = 'db8b4398de90b6d0b6c780aba96aaa2cd8e9202c',
      url = 'https://github.com/rest-nvim/tree-sitter-http',
    },
    maintainers = { '@amaanq', '@NTBBloodbath' },
    tier = 2,
  },
  hurl = {
    install_info = {
      revision = '597efbd7ce9a814bb058f48eabd055b1d1e12145',
      url = 'https://github.com/pfeiferj/tree-sitter-hurl',
    },
    maintainers = { '@pfeiferj' },
    tier = 2,
  },

  ini = {
    install_info = {
      revision = 'e4018b5176132b4f3c5d6e61cea383f42288d0f5',
      url = 'https://github.com/justinmk/tree-sitter-ini',
    },
    maintainers = { '@theHamsta' },
    tier = 2,
  },

  git_config = {
    install_info = {
      revision = '0fbc9f99d5a28865f9de8427fb0672d66f9d83a5',
      url = 'https://github.com/the-mikedavis/tree-sitter-git-config',
    },
    maintainers = { '@amaanq' },
    tier = 2,
  },
  git_rebase = {
    install_info = {
      revision = '760ba8e34e7a68294ffb9c495e1388e030366188',
      url = 'https://github.com/the-mikedavis/tree-sitter-git-rebase',
    },
    maintainers = { '@gbprod' },
    tier = 2,
  },
  gitattributes = {
    install_info = {
      revision = '1b7af09d45b579f9f288453b95ad555f1f431645',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-gitattributes',
    },
    maintainers = { '@ObserverOfTime' },
    tier = 2,
  },
  gitcommit = {
    install_info = {
      revision = '33fe8548abcc6e374feaac5724b5a2364bf23090',
      url = 'https://github.com/gbprod/tree-sitter-gitcommit',
    },
    maintainers = { '@gbprod' },
    tier = 2,
  },
  gitignore = {
    install_info = {
      revision = 'f4685bf11ac466dd278449bcfe5fd014e94aa504',
      url = 'https://github.com/shunsambongi/tree-sitter-gitignore',
    },
    maintainers = { '@theHamsta' },
    tier = 2,
  },

  angular = {
    install_info = {
      revision = 'f0d0685701b70883fa2dfe94ee7dc27965cab841',
      url = 'https://github.com/dlvandenberg/tree-sitter-angular',
    },
    maintainers = { '@dlvandenberg' },
    requires = { 'html', 'html_tags' },
    tier = 2,
  },

  html_tags = {
    maintainers = { '@TravonteD' },
    readme_note = 'queries required by html, astro, vue, svelte',
    tier = 2,
  },
  awk = {
    install_info = {
      revision = '34bbdc7cce8e803096f47b625979e34c1be38127',
      url = 'https://github.com/Beaglefoot/tree-sitter-awk',
    },
    tier = 2,
  },
  bash = {
    install_info = {
      revision = 'a06c2e4415e9bc0346c6b86d401879ffb44058f7',
      url = 'https://github.com/tree-sitter/tree-sitter-bash',
    },
    maintainers = { '@TravonteD' },
    tier = 2,
  },

  c_sharp = {
    install_info = {
      revision = '88366631d598ce6595ec655ce1591b315cffb14c',
      url = 'https://github.com/tree-sitter/tree-sitter-c-sharp',
    },
    maintainers = { '@amaanq' },
    tier = 2,
  },

  cmake = {
    install_info = {
      revision = 'c7b2a71e7f8ecb167fad4c97227c838439280175',
      url = 'https://github.com/uyha/tree-sitter-cmake',
    },
    maintainers = { '@uyha' },
    tier = 2,
  },

  make = {
    install_info = {
      revision = '70613f3d812cbabbd7f38d104d60a409c4008b43',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-make',
    },
    maintainers = { '@lewis6991' },
    tier = 2,
  },

  mermaid = {
    install_info = {
      revision = '90ae195b31933ceb9d079abfa8a3ad0a36fee4cc',
      url = 'https://github.com/monaqa/tree-sitter-mermaid',
    },
    tier = 2,
  },
comment = {
  install_info = {
    revision = '66272d2b6c73fb61157541b69dd0a7ce7b42a5ad',
    url = 'https://github.com/stsewd/tree-sitter-comment',
  },
  maintainers = { '@stsewd' },
  tier = 2,
},

  dockerfile = {
    install_info = {
      revision = '971acdd908568b4531b0ba28a445bf0bb720aba5',
      url = 'https://github.com/camdencheek/tree-sitter-dockerfile',
    },
    maintainers = { '@camdencheek' },
    tier = 2,
  },

  go = {
    install_info = {
      revision = '2346a3ab1bb3857b48b29d779a1ef9799a248cd7',
      url = 'https://github.com/tree-sitter/tree-sitter-go',
    },
    maintainers = { '@theHamsta', '@WinWisely268' },
    tier = 2,
  },
graphql = {
  install_info = {
    revision = '5e66e961eee421786bdda8495ed1db045e06b5fe',
    url = 'https://github.com/bkegley/tree-sitter-graphql',
  },
  maintainers = { '@bkegley' },
  tier = 2,
},

  java = {
    install_info = {
      revision = 'e10607b45ff745f5f876bfa3e94fbcc6b44bdc11',
      url = 'https://github.com/tree-sitter/tree-sitter-java',
    },
    maintainers = { '@p00f' },
    tier = 2,
  },
  javadoc = {
    install_info = {
      revision = 'e2f56b4d0df08f6ed5df8bae266f9e75b340a9ab',
      url = 'https://github.com/rmuir/tree-sitter-javadoc',
    },
    maintainers = { '@rmuir' },
    tier = 2,
  },

  jinja = {
    install_info = {
      location = 'tree-sitter-jinja',
      revision = '413dba9fea354b62f6adada1815b2f504e32ffb5',
      url = 'https://github.com/cathaysia/tree-sitter-jinja',
    },
    maintainers = { '@cathaysia' },
    readme_note = 'basic highlighting',
    requires = { 'jinja_inline' },
    tier = 2,
  },
  jinja_inline = {
    install_info = {
      location = 'tree-sitter-jinja_inline',
      revision = '413dba9fea354b62f6adada1815b2f504e32ffb5',
      url = 'https://github.com/cathaysia/tree-sitter-jinja',
    },
    maintainers = { '@cathaysia' },
    readme_note = 'needed for full highlighting',
    tier = 2,
  },

  jsdoc = {
    install_info = {
      revision = '658d18dcdddb75c760363faa4963427a7c6b52db',
      url = 'https://github.com/tree-sitter/tree-sitter-jsdoc',
    },
    maintainers = { '@steelsojka' },
    tier = 2,
  },

  psv = {
    install_info = {
      location = 'psv',
      revision = 'f6bf6e35eb0b95fbadea4bb39cb9709507fcb181',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-csv',
    },
    maintainers = { '@amaanq' },
    requires = { 'tsv' },
    tier = 2,
  },

  python = {
    install_info = {
      revision = 'v0.25.0',
      url = 'https://github.com/tree-sitter/tree-sitter-python',
    },
    maintainers = { '@stsewd', '@theHamsta' },
    tier = 1,
  },

  regex = {
    install_info = {
      revision = 'b2ac15e27fce703d2f37a79ccd94a5c0cbe9720b',
      url = 'https://github.com/tree-sitter/tree-sitter-regex',
    },
    maintainers = { '@theHamsta' },
    tier = 2,
  },
requirements = {
  install_info = {
    revision = 'caeb2ba854dea55931f76034978de1fd79362939',
    url = 'https://github.com/tree-sitter-grammars/tree-sitter-requirements',
  },
  maintainers = { '@ObserverOfTime' },
  readme_name = 'pip requirements',
  tier = 2,
},

  sflog = {
    install_info = {
      location = 'sflog',
      revision = '3597575a429766dd7ecce9f5bb97f6fec4419d5d',
      url = 'https://github.com/aheber/tree-sitter-sfapex',
    },
    maintainers = { '@aheber', '@xixiaofinland' },
    readme_note = 'Salesforce debug log',
    tier = 2,
  },

  soql = {
    install_info = {
      location = 'soql',
      revision = '3597575a429766dd7ecce9f5bb97f6fec4419d5d',
      url = 'https://github.com/aheber/tree-sitter-sfapex',
    },
    maintainers = { '@aheber', '@xixiafinland' },
    tier = 2,
  },
  sosl = {
    install_info = {
      location = 'sosl',
      revision = '3597575a429766dd7ecce9f5bb97f6fec4419d5d',
      url = 'https://github.com/aheber/tree-sitter-sfapex',
    },
    maintainers = { '@aheber', '@xixiafinland' },
    tier = 2,
  },

  sql = {
    install_info = {
      branch = 'gh-pages',
      revision = '851e9cb257ba7c66cc8c14214a31c44d2f1e954e',
      url = 'https://github.com/derekstride/tree-sitter-sql',
    },
    maintainers = { '@derekstride' },
    tier = 2,
  },

  ssh_config = {
    install_info = {
      revision = '71d2693deadaca8cdc09e38ba41d2f6042da1616',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-ssh-config',
    },
    maintainers = { '@ObserverOfTime' },
    tier = 2,
  },

  strace = {
    install_info = {
      revision = 'ac874ddfcc08d689fee1f4533789e06d88388f29',
      url = 'https://github.com/sigmaSd/tree-sitter-strace',
    },
    maintainers = { '@amaanq' },
    tier = 2,
  },

  ssh_config = {
    install_info = {
      revision = '71d2693deadaca8cdc09e38ba41d2f6042da1616',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-ssh-config',
    },
    maintainers = { '@ObserverOfTime' },
    tier = 2,
  },

  terraform = {
    install_info = {
      location = 'dialects/terraform',
      revision = '64ad62785d442eb4d45df3a1764962dafd5bc98b',
      url = 'https://github.com/MichaHoffmann/tree-sitter-hcl',
    },
    maintainers = { '@MichaHoffmann' },
    requires = { 'hcl' },
    tier = 2,
  },

  vue = {
    install_info = {
      revision = 'ce8011a414fdf8091f4e4071752efc376f4afb08',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-vue',
    },
    maintainers = { '@WhyNotHugo', '@lucario387' },
    requires = { 'html_tags' },
    tier = 2,
  },

  zig = {
    install_info = {
      revision = '6479aa13f32f701c383083d8b28360ebd682fb7d',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-zig',
    },
    maintainers = { '@amaanq' },
    tier = 2,
  },

```

```
  {
      lang = { 'c' },
    install_info = {
      revision = 'ae19b676b13bdcc13b7665397e6d9b14975473dd',
      url = 'https://github.com/tree-sitter/tree-sitter-c',
    },
    tier = 2,
  },
  {
      lang = { 'lua' },
    install_info = {
      revision = '10fe0054734eec83049514ea2e718b2a56acd0c9',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-lua',
    },
    tier = 2,
  },

  {
      lang = { 'luadoc' },
    install_info = {
      revision = '873612aadd3f684dd4e631bdf42ea8990c57634e',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-luadoc',
    },
    tier = 2,
  },
  {
      lang = { 'vim' },
    install_info = {
      revision = '3092fcd99eb87bbd0fc434aa03650ba58bd5b43b',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-vim',
    },
    tier = 2,
  },
  {
      lang = { 'vimdoc' },
    install_info = {
      revision = 'f061895a0eff1d5b90e4fb60d21d87be3267031a',
      url = 'https://github.com/neovim/tree-sitter-vimdoc',
    },
    tier = 2,
  },
  {
      lang = { 'markdown' },
    install_info = {
      location = 'tree-sitter-markdown',
      revision = 'f969cd3ae3f9fbd4e43205431d0ae286014c05b5',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-markdown',
    },
    readme_note = 'basic highlighting',
    requires = { 'markdown_inline' },
    tier = 2,
  },
  {
      lang = { 'markdown_inline' },
    install_info = {
      location = 'tree-sitter-markdown-inline',
      revision = 'f969cd3ae3f9fbd4e43205431d0ae286014c05b5',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-markdown',
    },
    readme_note = 'needed for full highlighting',
    tier = 2,
  },
  {
      lang = { 'diff' },
    install_info = {
      revision = '2520c3f934b3179bb540d23e0ef45f75304b5fed',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-diff',
    },
    tier = 2,
  },

  {
      lang = { 'editorconfig' },
    install_info = {
      revision = 'v2.0.0',
      url = 'https://github.com/ValdezFOmar/tree-sitter-editorconfig',
    },
    tier = 1,
  },
{
    lang = { 'javascript' },
  install_info = {
    revision = '58404d8cf191d69f2674a8fd507bd5776f46cb11',
    url = 'https://github.com/tree-sitter/tree-sitter-javascript',
  },
  requires = { 'ecma', 'jsx' },
  tier = 2,
},

  {
      lang = { 'powershell' },
    filetype = 'ps1',
    install_info = {
      revision = '73800ecc8bddeee8f1079a5a2e0c13c3d00269bb',
      url = 'https://github.com/airbus-cert/tree-sitter-powershell',
    },
    tier = 2,
  },
  {
      lang = { 'tsx' },
    install_info = {
      location = 'tsx',
      revision = '75b3874edb2dc714fb1fd77a32013d0f8699989f',
      url = 'https://github.com/tree-sitter/tree-sitter-typescript',
    },
    requires = { 'ecma', 'jsx', 'typescript' },
    tier = 2,
  },

  {
      lang = { 'jsx' },
    readme_note = 'queries required by javascript, tsx',
    tier = 2,
  },
  {
      lang = { 'typescript' },
    install_info = {
      location = 'typescript',
      revision = '75b3874edb2dc714fb1fd77a32013d0f8699989f',
      url = 'https://github.com/tree-sitter/tree-sitter-typescript',
    },
    requires = { 'ecma' },
    tier = 2,
  },

  {
      lang = { 'cpp' },
    install_info = {
      revision = '8b5b49eb196bec7040441bee33b2c9a4838d6967',
      url = 'https://github.com/tree-sitter/tree-sitter-cpp',
    },
    requires = { 'c' },
    tier = 2,
  },
  {
      lang = { 'css' },
    install_info = {
      revision = 'dda5cfc5722c429eaba1c910ca32c2c0c5bb1a3f',
      url = 'https://github.com/tree-sitter/tree-sitter-css',
    },
    tier = 2,
  },
  {
      lang = { 'csv' },
    install_info = {
      location = 'csv',
      revision = 'f6bf6e35eb0b95fbadea4bb39cb9709507fcb181',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-csv',
    },
    requires = { 'tsv' },
    tier = 2,
  },
{
    lang = { 'json' },
  install_info = {
    revision = '001c28d7a29832b06b0e831ec77845553c89b56d',
    url = 'https://github.com/tree-sitter/tree-sitter-json',
  },
  tier = 2,
},
{
    lang = { 'json5' },
  install_info = {
    revision = 'aa630ef48903ab99e406a8acd2e2933077cc34e1',
    url = 'https://github.com/Joakker/tree-sitter-json5',
  },
  tier = 2,
},

  {
      lang = { 'apex' },
    install_info = {
      location = 'apex',
      revision = '3597575a429766dd7ecce9f5bb97f6fec4419d5d',
      url = 'https://github.com/aheber/tree-sitter-sfapex',
    },
    tier = 2,
  },

  {
      lang = { 'ecma' },
    readme_note = 'queries required by javascript, typescript, tsx, qmljs',
    tier = 2,
  },

  {
      lang = { 'xml' },
    install_info = {
      location = 'xml',
      revision = '5000ae8f22d11fbe93939b05c1e37cf21117162d',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-xml',
    },
    requires = { 'dtd' },
    tier = 2,
  },

  {
      lang = { 'yaml' },
    install_info = {
      revision = '4463985dfccc640f3d6991e3396a2047610cf5f8',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-yaml',
    },
    tier = 2,
  },
  {
      lang = { 'dtd' },
    install_info = {
      location = 'dtd',
      revision = '5000ae8f22d11fbe93939b05c1e37cf21117162d',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-xml',
    },
    tier = 2,
  },

  {
      lang = { 'yaml' },
    install_info = {
      revision = '4463985dfccc640f3d6991e3396a2047610cf5f8',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-yaml',
    },
    tier = 2,
  },

  {
      lang = { 'rust' },
    install_info = {
      revision = '77a3747266f4d621d0757825e6b11edcbf991ca5',
      url = 'https://github.com/tree-sitter/tree-sitter-rust',
    },
    tier = 2,
  },

  {
      lang = { 'query' },
    install_info = {
      revision = 'fc5409c6820dd5e02b0b0a309d3da2bfcde2db17',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-query',
    },
    readme_note = 'Tree-sitter query language',
    tier = 2,
  },
{
    lang = { 'toml' },
  install_info = {
    revision = '64b56832c2cffe41758f28e05c756a3a98d16f41',
    url = 'https://github.com/tree-sitter-grammars/tree-sitter-toml',
  },
  tier = 2,
},
{
    lang = { 'tsv' },
  install_info = {
    location = 'tsv',
    revision = 'f6bf6e35eb0b95fbadea4bb39cb9709507fcb181',
    url = 'https://github.com/tree-sitter-grammars/tree-sitter-csv',
  },
  tier = 2,
},
  {
      lang = { 'razor' },
    install_info = {
      revision = 'fe46ce5ea7d844e53d59bc96f2175d33691c61c5',
      url = 'https://github.com/tris203/tree-sitter-razor',
    },
    tier = 2,
  },

  {
      lang = { 'http' },
    install_info = {
      revision = 'db8b4398de90b6d0b6c780aba96aaa2cd8e9202c',
      url = 'https://github.com/rest-nvim/tree-sitter-http',
    },
    tier = 2,
  },
  {
      lang = { 'hurl' },
    install_info = {
      revision = '597efbd7ce9a814bb058f48eabd055b1d1e12145',
      url = 'https://github.com/pfeiferj/tree-sitter-hurl',
    },
    tier = 2,
  },

  {
      lang = { 'ini' },
    install_info = {
      revision = 'e4018b5176132b4f3c5d6e61cea383f42288d0f5',
      url = 'https://github.com/justinmk/tree-sitter-ini',
    },
    tier = 2,
  },

  {
      lang = { 'git_config' },
    install_info = {
      revision = '0fbc9f99d5a28865f9de8427fb0672d66f9d83a5',
      url = 'https://github.com/the-mikedavis/tree-sitter-git-config',
    },
    tier = 2,
  },
  {
      lang = { 'git_rebase' },
    install_info = {
      revision = '760ba8e34e7a68294ffb9c495e1388e030366188',
      url = 'https://github.com/the-mikedavis/tree-sitter-git-rebase',
    },
    tier = 2,
  },
  {
      lang = { 'gitattributes' },
    install_info = {
      revision = '1b7af09d45b579f9f288453b95ad555f1f431645',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-gitattributes',
    },
    tier = 2,
  },
  {
      lang = { 'gitcommit' },
    install_info = {
      revision = '33fe8548abcc6e374feaac5724b5a2364bf23090',
      url = 'https://github.com/gbprod/tree-sitter-gitcommit',
    },
    tier = 2,
  },
  {
      lang = { 'gitignore' },
    install_info = {
      revision = 'f4685bf11ac466dd278449bcfe5fd014e94aa504',
      url = 'https://github.com/shunsambongi/tree-sitter-gitignore',
    },
    tier = 2,
  },

  {
      lang = { 'angular' },
    install_info = {
      revision = 'f0d0685701b70883fa2dfe94ee7dc27965cab841',
      url = 'https://github.com/dlvandenberg/tree-sitter-angular',
    },
    requires = { 'html', 'html_tags' },
    tier = 2,
  },

  {
      lang = { 'html_tags' },
    readme_note = 'queries required by html, astro, vue, svelte',
    tier = 2,
  },
  {
      lang = { 'awk' },
    install_info = {
      revision = '34bbdc7cce8e803096f47b625979e34c1be38127',
      url = 'https://github.com/Beaglefoot/tree-sitter-awk',
    },
    tier = 2,
  },
  {
      lang = { 'bash' },
    install_info = {
      revision = 'a06c2e4415e9bc0346c6b86d401879ffb44058f7',
      url = 'https://github.com/tree-sitter/tree-sitter-bash',
    },
    tier = 2,
  },

  {
      lang = { 'c_sharp' },
    install_info = {
      revision = '88366631d598ce6595ec655ce1591b315cffb14c',
      url = 'https://github.com/tree-sitter/tree-sitter-c-sharp',
    },
    tier = 2,
  },

  {
      lang = { 'cmake' },
    install_info = {
      revision = 'c7b2a71e7f8ecb167fad4c97227c838439280175',
      url = 'https://github.com/uyha/tree-sitter-cmake',
    },
    tier = 2,
  },

  {
      lang = { 'make' },
    install_info = {
      revision = '70613f3d812cbabbd7f38d104d60a409c4008b43',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-make',
    },
    tier = 2,
  },

  {
      lang = { 'mermaid' },
    install_info = {
      revision = '90ae195b31933ceb9d079abfa8a3ad0a36fee4cc',
      url = 'https://github.com/monaqa/tree-sitter-mermaid',
    },
    tier = 2,
  },
{
    lang = { 'comment' },
  install_info = {
    revision = '66272d2b6c73fb61157541b69dd0a7ce7b42a5ad',
    url = 'https://github.com/stsewd/tree-sitter-comment',
  },
  tier = 2,
},

  {
      lang = { 'dockerfile' },
    install_info = {
      revision = '971acdd908568b4531b0ba28a445bf0bb720aba5',
      url = 'https://github.com/camdencheek/tree-sitter-dockerfile',
    },
    tier = 2,
  },

  {
      lang = { 'go' },
    install_info = {
      revision = '2346a3ab1bb3857b48b29d779a1ef9799a248cd7',
      url = 'https://github.com/tree-sitter/tree-sitter-go',
    },
    tier = 2,
  },
{
    lang = { 'graphql' },
  install_info = {
    revision = '5e66e961eee421786bdda8495ed1db045e06b5fe',
    url = 'https://github.com/bkegley/tree-sitter-graphql',
  },
  tier = 2,
},

  {
      lang = { 'java' },
    install_info = {
      revision = 'e10607b45ff745f5f876bfa3e94fbcc6b44bdc11',
      url = 'https://github.com/tree-sitter/tree-sitter-java',
    },
    tier = 2,
  },
  {
      lang = { 'javadoc' },
    install_info = {
      revision = 'e2f56b4d0df08f6ed5df8bae266f9e75b340a9ab',
      url = 'https://github.com/rmuir/tree-sitter-javadoc',
    },
    tier = 2,
  },

  {
      lang = { 'jinja' },
    install_info = {
      location = 'tree-sitter-jinja',
      revision = '413dba9fea354b62f6adada1815b2f504e32ffb5',
      url = 'https://github.com/cathaysia/tree-sitter-jinja',
    },
    readme_note = 'basic highlighting',
    requires = { 'jinja_inline' },
    tier = 2,
  },
  {
      lang = { 'jinja_inline' },
    install_info = {
      location = 'tree-sitter-jinja_inline',
      revision = '413dba9fea354b62f6adada1815b2f504e32ffb5',
      url = 'https://github.com/cathaysia/tree-sitter-jinja',
    },
    readme_note = 'needed for full highlighting',
    tier = 2,
  },

  {
      lang = { 'jsdoc' },
    install_info = {
      revision = '658d18dcdddb75c760363faa4963427a7c6b52db',
      url = 'https://github.com/tree-sitter/tree-sitter-jsdoc',
    },
    tier = 2,
  },

  {
      lang = { 'psv' },
    install_info = {
      location = 'psv',
      revision = 'f6bf6e35eb0b95fbadea4bb39cb9709507fcb181',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-csv',
    },
    requires = { 'tsv' },
    tier = 2,
  },

  {
      lang = { 'python' },
    install_info = {
      revision = 'v0.25.0',
      url = 'https://github.com/tree-sitter/tree-sitter-python',
    },
    tier = 1,
  },

  {
      lang = { 'regex' },
    install_info = {
      revision = 'b2ac15e27fce703d2f37a79ccd94a5c0cbe9720b',
      url = 'https://github.com/tree-sitter/tree-sitter-regex',
    },
    tier = 2,
  },
{
    lang = { 'requirements' },
  install_info = {
    revision = 'caeb2ba854dea55931f76034978de1fd79362939',
    url = 'https://github.com/tree-sitter-grammars/tree-sitter-requirements',
  },
  readme_name = 'pip requirements',
  tier = 2,
},

  {
      lang = { 'sflog' },
    install_info = {
      location = 'sflog',
      revision = '3597575a429766dd7ecce9f5bb97f6fec4419d5d',
      url = 'https://github.com/aheber/tree-sitter-sfapex',
    },
    readme_note = 'Salesforce debug log',
    tier = 2,
  },

  {
      lang = { 'soql' },
    install_info = {
      location = 'soql',
      revision = '3597575a429766dd7ecce9f5bb97f6fec4419d5d',
      url = 'https://github.com/aheber/tree-sitter-sfapex',
    },
    tier = 2,
  },
  {
      lang = { 'sosl' },
    install_info = {
      location = 'sosl',
      revision = '3597575a429766dd7ecce9f5bb97f6fec4419d5d',
      url = 'https://github.com/aheber/tree-sitter-sfapex',
    },
    tier = 2,
  },

  {
      lang = { 'sql' },
    install_info = {
      branch = 'gh-pages',
      revision = '851e9cb257ba7c66cc8c14214a31c44d2f1e954e',
      url = 'https://github.com/derekstride/tree-sitter-sql',
    },
    tier = 2,
  },

  {
      lang = { 'ssh_config' },
    install_info = {
      revision = '71d2693deadaca8cdc09e38ba41d2f6042da1616',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-ssh-config',
    },
    tier = 2,
  },

  {
      lang = { 'strace' },
    install_info = {
      revision = 'ac874ddfcc08d689fee1f4533789e06d88388f29',
      url = 'https://github.com/sigmaSd/tree-sitter-strace',
    },
    tier = 2,
  },

  {
      lang = { 'ssh_config' },
    install_info = {
      revision = '71d2693deadaca8cdc09e38ba41d2f6042da1616',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-ssh-config',
    },
    tier = 2,
  },

  {
      lang = { 'terraform' },
    install_info = {
      location = 'dialects/terraform',
      revision = '64ad62785d442eb4d45df3a1764962dafd5bc98b',
      url = 'https://github.com/MichaHoffmann/tree-sitter-hcl',
    },
    requires = { 'hcl' },
    tier = 2,
  },

  {
      lang = { 'vue' },
    install_info = {
      revision = 'ce8011a414fdf8091f4e4071752efc376f4afb08',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-vue',
    },
    requires = { 'html_tags' },
    tier = 2,
  },

  {
      lang = { 'zig' },
    install_info = {
      revision = '6479aa13f32f701c383083d8b28360ebd682fb7d',
      url = 'https://github.com/tree-sitter-grammars/tree-sitter-zig',
    },
    tier = 2,
  },
```

```lua
local M = {
    {
        src = 'https://github.com/dlvandenberg/tree-sitter-angular',
        version = 'f0d0685701b70883fa2dfe94ee7dc27965cab841',
        data = {
            load = false,
            runtimepath = false,
            treesitter = {
                angular = {
                    requires = { 'html', 'html_tags' },
                    versioning_type = 'HEAD',
                    filetypes = { 'htmlangular' },
                },
            },
        },
    },
    {
        src = 'https://github.com/aheber/tree-sitter-sfapex',
        version = '3597575a429766dd7ecce9f5bb97f6fec4419d5d',
        data = {
            load = false,
            runtimepath = false,
            treesitter = {
                apex = { location = 'apex', versioning_type = 'HEAD' },
                sflog = {
                    location = 'sflog',
                    readme_note = 'Salesforce debug log',
                    versioning_type = 'HEAD',
                },
                soql = { location = 'soql', versioning_type = 'HEAD' },
                sosl = { location = 'sosl', versioning_type = 'HEAD' },
            },
        },
    },
    {
        src = 'https://github.com/Beaglefoot/tree-sitter-awk',
        version = '34bbdc7cce8e803096f47b625979e34c1be38127',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { awk = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/tree-sitter/tree-sitter-bash',
        version = 'a06c2e4415e9bc0346c6b86d401879ffb44058f7',
        data = {
            load = false,
            runtimepath = false,
            treesitter = {
                bash = {
                    versioning_type = 'HEAD',
                    filetypes = { 'sh' },
                },
            },
        },
    },
    {
        src = 'https://github.com/tree-sitter/tree-sitter-c',
        version = 'ae19b676b13bdcc13b7665397e6d9b14975473dd',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { c = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/tree-sitter/tree-sitter-c-sharp',
        version = '88366631d598ce6595ec655ce1591b315cffb14c',
        data = {
            load = false,
            runtimepath = false,
            treesitter = {
                c_sharp = {
                    versioning_type = 'HEAD',
                    filetypes = { 'cs', 'csharp' },
                },
            },
        },
    },
    {
        src = 'https://github.com/uyha/tree-sitter-cmake',
        version = 'c7b2a71e7f8ecb167fad4c97227c838439280175',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { cmake = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/stsewd/tree-sitter-comment',
        version = '66272d2b6c73fb61157541b69dd0a7ce7b42a5ad',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { comment = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/tree-sitter/tree-sitter-cpp',
        version = '8b5b49eb196bec7040441bee33b2c9a4838d6967',
        data = {
            load = false,
            runtimepath = false,
            treesitter = {
                cpp = { requires = { 'c' }, versioning_type = 'HEAD' },
            },
        },
    },
    {
        src = 'https://github.com/tree-sitter/tree-sitter-css',
        version = 'dda5cfc5722c429eaba1c910ca32c2c0c5bb1a3f',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { css = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/tree-sitter-grammars/tree-sitter-csv',
        version = 'f6bf6e35eb0b95fbadea4bb39cb9709507fcb181',
        data = {
            load = false,
            runtimepath = false,
            treesitter = {
                csv = {
                    location = 'csv',
                    requires = { 'tsv' },
                    versioning_type = 'HEAD',
                },
                tsv = { location = 'tsv', versioning_type = 'HEAD' },
                psv = {
                    location = 'psv',
                    requires = { 'tsv' },
                    versioning_type = 'HEAD',
                },
            },
        },
    },
    {
        src = 'https://github.com/tree-sitter-grammars/tree-sitter-diff',
        version = '2520c3f934b3179bb540d23e0ef45f75304b5fed',
        data = {
            load = false,
            runtimepath = false,
            treesitter = {
                diff = {
                    versioning_type = 'HEAD',
                    filetypes = { 'gitdiff' },
                },
            },
        },
    },
    {
        src = 'https://github.com/camdencheek/tree-sitter-dockerfile',
        version = '971acdd908568b4531b0ba28a445bf0bb720aba5',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { dockerfile = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/ValdezFOmar/tree-sitter-editorconfig',
        version = 'v2.0.0',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { editorconfig = { versioning_type = 'SEMVER' } },
        },
    },
    {
        src = 'https://github.com/the-mikedavis/tree-sitter-git-config',
        version = '0fbc9f99d5a28865f9de8427fb0672d66f9d83a5',
        data = {
            load = false,
            runtimepath = false,
            treesitter = {
                git_config = {
                    versioning_type = 'HEAD',
                    filetypes = { 'gitconfig' },
                },
            },
        },
    },
    {
        src = 'https://github.com/the-mikedavis/tree-sitter-git-rebase',
        version = '760ba8e34e7a68294ffb9c495e1388e030366188',
        data = {
            load = false,
            runtimepath = false,
            treesitter = {
                git_rebase = {
                    versioning_type = 'HEAD',
                    filetypes = { 'gitrebase' },
                },
            },
        },
    },
    {
        src = 'https://github.com/tree-sitter-grammars/tree-sitter-gitattributes',
        version = '1b7af09d45b579f9f288453b95ad555f1f431645',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { gitattributes = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/gbprod/tree-sitter-gitcommit',
        version = '33fe8548abcc6e374feaac5724b5a2364bf23090',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { gitcommit = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/shunsambongi/tree-sitter-gitignore',
        version = 'f4685bf11ac466dd278449bcfe5fd014e94aa504',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { gitignore = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/tree-sitter/tree-sitter-go',
        version = '2346a3ab1bb3857b48b29d779a1ef9799a248cd7',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { go = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/bkegley/tree-sitter-graphql',
        version = '5e66e961eee421786bdda8495ed1db045e06b5fe',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { graphql = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/rest-nvim/tree-sitter-http',
        version = 'db8b4398de90b6d0b6c780aba96aaa2cd8e9202c',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { http = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/pfeiferj/tree-sitter-hurl',
        version = '597efbd7ce9a814bb058f48eabd055b1d1e12145',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { hurl = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/justinmk/tree-sitter-ini',
        version = 'e4018b5176132b4f3c5d6e61cea383f42288d0f5',
        data = {
            load = false,
            runtimepath = false,
            treesitter = {
                ini = {
                    versioning_type = 'HEAD',
                    filetypes = { 'confini', 'dosini' },
                },
            },
        },
    },
    {
        src = 'https://github.com/tree-sitter/tree-sitter-java',
        version = 'e10607b45ff745f5f876bfa3e94fbcc6b44bdc11',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { java = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/rmuir/tree-sitter-javadoc',
        version = 'e2f56b4d0df08f6ed5df8bae266f9e75b340a9ab',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { javadoc = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/tree-sitter/tree-sitter-javascript',
        version = '58404d8cf191d69f2674a8fd507bd5776f46cb11',
        data = {
            load = false,
            runtimepath = false,
            treesitter = {
                javascript = {
                    requires = { 'ecma', 'jsx' },
                    versioning_type = 'HEAD',
                    filetypes = {
                        'javascriptreact',
                        'ecma',
                        'ecmascript',
                        'jsx',
                        'js',
                    },
                },
            },
        },
    },
    {
        src = 'https://github.com/cathaysia/tree-sitter-jinja',
        version = '413dba9fea354b62f6adada1815b2f504e32ffb5',
        data = {
            load = false,
            runtimepath = false,
            treesitter = {
                jinja = {
                    location = 'tree-sitter-jinja',
                    readme_note = 'basic highlighting',
                    requires = { 'jinja_inline' },
                    versioning_type = 'HEAD',
                },
                jinja_inline = {
                    location = 'tree-sitter-jinja_inline',
                    readme_note = 'needed for full highlighting',
                    versioning_type = 'HEAD',
                },
            },
        },
    },
    {
        src = 'https://github.com/tree-sitter/tree-sitter-jsdoc',
        version = '658d18dcdddb75c760363faa4963427a7c6b52db',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { jsdoc = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/tree-sitter/tree-sitter-json',
        version = '001c28d7a29832b06b0e831ec77845553c89b56d',
        data = {
            load = false,
            runtimepath = false,
            treesitter = {
                json = {
                    versioning_type = 'HEAD',
                    filetypes = { 'jsonc' },
                },
            },
        },
    },
    {
        src = 'https://github.com/Joakker/tree-sitter-json5',
        version = 'aa630ef48903ab99e406a8acd2e2933077cc34e1',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { json5 = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/tree-sitter-grammars/tree-sitter-lua',
        version = '10fe0054734eec83049514ea2e718b2a56acd0c9',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { lua = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/tree-sitter-grammars/tree-sitter-luadoc',
        version = '873612aadd3f684dd4e631bdf42ea8990c57634e',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { luadoc = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/tree-sitter-grammars/tree-sitter-make',
        version = '70613f3d812cbabbd7f38d104d60a409c4008b43',
        data = {
            load = false,
            runtimepath = false,
            treesitter = {
                make = {
                    versioning_type = 'HEAD',
                    filetypes = { 'automake' },
                },
            },
        },
    },
    {
        src = 'https://github.com/tree-sitter-grammars/tree-sitter-markdown',
        version = 'f969cd3ae3f9fbd4e43205431d0ae286014c05b5',
        data = {
            load = false,
            runtimepath = false,
            treesitter = {
                markdown = {
                    location = 'tree-sitter-markdown',
                    readme_note = 'basic highlighting',
                    requires = { 'markdown_inline' },
                    versioning_type = 'HEAD',
                    filetypes = { 'pandoc' },
                },
                markdown_inline = {
                    location = 'tree-sitter-markdown-inline',
                    readme_note = 'needed for full highlighting',
                    versioning_type = 'HEAD',
                },
            },
        },
    },
    {
        src = 'https://github.com/monaqa/tree-sitter-mermaid',
        version = '90ae195b31933ceb9d079abfa8a3ad0a36fee4cc',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { mermaid = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/airbus-cert/tree-sitter-powershell',
        version = '73800ecc8bddeee8f1079a5a2e0c13c3d00269bb',
        data = {
            load = false,
            runtimepath = false,
            treesitter = {
                powershell = { versioning_type = 'HEAD', filetypes = { 'ps1' } },
            },
        },
    },
    {
        src = 'https://github.com/tree-sitter/tree-sitter-python',
        version = 'v0.25.0',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { python = { versioning_type = 'SEMVER' } },
        },
    },
    {
        src = 'https://github.com/tree-sitter-grammars/tree-sitter-query',
        version = 'fc5409c6820dd5e02b0b0a309d3da2bfcde2db17',
        data = {
            load = false,
            runtimepath = false,
            treesitter = {
                query = {
                    readme_note = 'Tree-sitter query language',
                    versioning_type = 'HEAD',
                },
            },
        },
    },
    {
        src = 'https://github.com/tris203/tree-sitter-razor',
        version = 'fe46ce5ea7d844e53d59bc96f2175d33691c61c5',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { razor = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/tree-sitter/tree-sitter-regex',
        version = 'b2ac15e27fce703d2f37a79ccd94a5c0cbe9720b',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { regex = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/tree-sitter-grammars/tree-sitter-requirements',
        version = 'caeb2ba854dea55931f76034978de1fd79362939',
        data = {
            load = false,
            runtimepath = false,
            treesitter = {
                requirements = {
                    readme_name = 'pip requirements',
                    versioning_type = 'HEAD',
                },
            },
        },
    },
    {
        src = 'https://github.com/tree-sitter/tree-sitter-rust',
        version = '77a3747266f4d621d0757825e6b11edcbf991ca5',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { rust = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/derekstride/tree-sitter-sql',
        version = '851e9cb257ba7c66cc8c14214a31c44d2f1e954e',
        -- branch = 'gh-pages',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { sql = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/tree-sitter-grammars/tree-sitter-ssh-config',
        version = '71d2693deadaca8cdc09e38ba41d2f6042da1616',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { ssh_config = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/tree-sitter-grammars/tree-sitter-ssh-config',
        version = '71d2693deadaca8cdc09e38ba41d2f6042da1616',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { ssh_config = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/sigmaSd/tree-sitter-strace',
        version = 'ac874ddfcc08d689fee1f4533789e06d88388f29',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { strace = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/tree-sitter-grammars/tree-sitter-hcl',
        version = '64ad62785d442eb4d45df3a1764962dafd5bc98b',
        data = {
            load = false,
            runtimepath = false,
            treesitter = {
                terraform = {
                    location = 'dialects/terraform',
                    requires = { 'hcl' },
                    versioning_type = 'HEAD',
                },
                hcl = { location = nil, versioning_type = 'HEAD' },
            },
        },
    },
    {
        src = 'https://github.com/tree-sitter-grammars/tree-sitter-toml',
        version = '64b56832c2cffe41758f28e05c756a3a98d16f41',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { toml = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/tree-sitter/tree-sitter-typescript',
        version = '75b3874edb2dc714fb1fd77a32013d0f8699989f',
        data = {
            load = false,
            runtimepath = false,
            treesitter = {
                tsx = {
                    location = 'tsx',
                    requires = { 'ecma', 'jsx', 'typescript' },
                    versioning_type = 'HEAD',
                },
                typescript = {
                    location = 'typescript',
                    requires = { 'ecma' },
                    versioning_type = 'HEAD',
                },
            },
        },
    },
    {
        src = 'https://github.com/tree-sitter-grammars/tree-sitter-vim',
        version = '3092fcd99eb87bbd0fc434aa03650ba58bd5b43b',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { vim = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/neovim/tree-sitter-vimdoc',
        version = 'f061895a0eff1d5b90e4fb60d21d87be3267031a',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { vimdoc = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/tree-sitter-grammars/tree-sitter-vue',
        version = 'ce8011a414fdf8091f4e4071752efc376f4afb08',
        data = {
            load = false,
            runtimepath = false,
            treesitter = {
                vue = { requires = { 'html_tags' }, versioning_type = 'HEAD' },
            },
        },
    },
    {
        src = 'https://github.com/tree-sitter-grammars/tree-sitter-xml',
        version = '5000ae8f22d11fbe93939b05c1e37cf21117162d',
        data = {
            load = false,
            runtimepath = false,
            treesitter = {
                xml = {
                    location = 'xml',
                    requires = { 'dtd' },
                    versioning_type = 'HEAD',
                },
                dtd = { location = 'dtd', versioning_type = 'HEAD' },
            },
        },
    },
    {
        src = 'https://github.com/tree-sitter-grammars/tree-sitter-yaml',
        version = '4463985dfccc640f3d6991e3396a2047610cf5f8',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { yaml = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/tree-sitter-grammars/tree-sitter-yaml',
        version = '4463985dfccc640f3d6991e3396a2047610cf5f8',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { yaml = { versioning_type = 'HEAD' } },
        },
    },
    {
        src = 'https://github.com/tree-sitter-grammars/tree-sitter-zig',
        version = '6479aa13f32f701c383083d8b28360ebd682fb7d',
        data = {
            load = false,
            runtimepath = false,
            treesitter = { zig = { versioning_type = 'HEAD' } },
        },
    },

    {
        lang = { 'ecma' },
        readme_note = 'queries required by javascript, typescript, tsx, qmljs',
        versioning_type = 'HEAD',
    },
    {
        lang = { 'jsx' },
        readme_note = 'queries required by javascript, tsx',
        versioning_type = 'HEAD',
    },
    {
        lang = { 'html_tags' },
        readme_note = 'queries required by html, astro, vue, svelte',
        versioning_type = 'HEAD',
    },

    {
        src = 'https://github.com/tree-sitter-grammars/tree-sitter-luap',
        version = 'c134aaec6acf4fa95fe4aa0dc9aba3eacdbbe55a',
        data = {
            load = false,
            runtimepath = false,
            treesitter = {
                luap = {
                    versioning_type = 'HEAD',
                    readme_note = 'Lua patterns',
                },
            },
        },
    },
    {
        src = 'https://github.com/tree-sitter-grammars/tree-sitter-luau',
        version = 'a8914d6c1fc5131f8e1c13f769fa704c9f5eb02f',
        data = {
            load = false,
            runtimepath = false,
            treesitter = {
                luau = {
                    versioning_type = 'HEAD',
                    requires = { 'lua' },
                },
            },
        },
    },
}

--- maybe add
---
-- properties = { 'jproperties' },
-- perl = { 'pl' },
```
