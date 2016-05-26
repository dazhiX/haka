/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

%module raw

%include "haka/lua/swig.si"
%include "haka/lua/packet.si"
%include "haka/lua/object.si"

%{
#include <haka/packet.h>
#include <haka/packet_module.h>
#include <haka/error.h>
%}

%nodefaultctor;
%nodefaultdtor;

const char *packet_dissector(struct packet *pkt);

%luacode{
	local this = unpack({...})

	local raw_dissector = haka.dissector.new{
		type = haka.helper.PacketDissector,
		name = 'raw'
	}

	local dissectors = {}

	function this.register(name, dissector)
		dissectors[name] = dissector
	end

	raw_dissector.policies.unknown_dissector = haka.policy.new('unknown dissector')

	haka.policy {
		on = raw_dissector.policies.unknown_dissector,
		name = "default action",
		action = function (policy, ctx, values, desc)
			haka.alert{
				description = string.format("dropping unknown dissector '%s'", values.name)
			}
			return ctx:drop()
		end
	}

	function raw_dissector.method:receive()
		haka.context:signal(self, raw_dissector.events.receive_packet)

		local dissector = this.packet_dissector(self)
		if dissector then
			local next_dissector = dissectors[dissector]
			if next_dissector then
				return next_dissector:new(self):preceive()
			else
				raw_dissector.policies.unknown_dissector:apply{
					ctx = self,
					values = {
						name = dissector
					}
				}
				if self:can_continue() then
					return self:send()
				end
			end
		else
			return self:send()
		end
	end

	function raw_dissector:new(pkt)
		return pkt
	end

	function raw_dissector:create(size)
		return haka.packet(size or 0)
	end

	local packet_send = swig.getclassmetatable('packet')['.fn'].send

	function raw_dissector.method:send()
		haka.context:signal(self, raw_dissector.events.send_packet)
		return packet_send(self)
	end

	function raw_dissector.method:can_continue()
		return self:issent()
	end

	swig.getclassmetatable('packet')['.fn'].send = raw_dissector.method.send
	swig.getclassmetatable('packet')['.fn'].receive = raw_dissector.method.receive
	swig.getclassmetatable('packet')['.fn'].continue = haka.helper.Dissector.method.continue
	swig.getclassmetatable('packet')['.fn'].can_continue = raw_dissector.method.can_continue
	swig.getclassmetatable('packet')['.fn'].error = swig.getclassmetatable('packet')['.fn'].drop

	function haka.filter(pkt)
		pkt:receive()
	end

	function this.create(size)
		return raw_dissector:create(size)
	end
}
