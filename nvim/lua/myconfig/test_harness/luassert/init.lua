local assert = require('myconfig.test_harness.luassert.assert')

assert._COPYRIGHT = 'Copyright (c) 2018 Olivine Labs, LLC.'
assert._DESCRIPTION =
    "Extends Lua's built-in assertions to provide additional tests and the ability to create your own."
assert._VERSION = 'Luassert 1.8.0'

-- load basic asserts
require('myconfig.test_harness.luassert.assertions')
require('myconfig.test_harness.luassert.modifiers')
require('myconfig.test_harness.luassert.array')
require('myconfig.test_harness.luassert.matchers')
require('myconfig.test_harness.luassert.formatters')

-- load default language
require('myconfig.test_harness.luassert.languages.en')

return assert
