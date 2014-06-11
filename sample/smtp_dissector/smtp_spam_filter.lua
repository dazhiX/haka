local smtp = require('smtp')

local rem = require('regexp/pcre')
local email_pattern = rem.re:compile("@.*")

local forbidden_domain = 'packet-level.com'

smtp.install_tcp_rule(25)

haka.rule{
	hook = smtp.events.command,
	eval = function (flow, message)
		local command = message.command:lower()
		if command == 'mail' then
			local param = message.parameter
			local res, startpos, endpos = email_pattern:match(param)
			if not res then
				haka.alert {
					description = "malformed email address",
					severity = 'low'
				}
				flow:drop()
			else

				local mailfrom = param:sub(startpos+2, endpos)
				if mailfrom == "suspicious.org" then
					haka.alert {
						description = "forbidden mail domain",
						severity = 'low'
					}
				end
				flow:drop()
			end
		end
	end
}
