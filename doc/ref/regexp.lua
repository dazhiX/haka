-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

local rem = require('regexp/pcre')

local re = rem.re:compile("foo")
local sink = re:get_sink()

local ret = sink:feed("some fo")
ret = sink:feed("o over two string")

print(ret)
