--!strict

local Flags = require(script.Parent.lib.Flags)
local Object = require(script.Parent.Object)
local ReferenceBuilder = {}



if not Flags.ENABLE_REFERENCE_BUILDER_SYNTAX then
	local t = setmetatable({}, {__index = function(self)
		error("Feature ENABLE_REFERENCE_BUILDER_SYNTAX is not enabled")
	end}) :: typeof(ReferenceBuilder)

	table.freeze(t)
	return t
end

table.freeze(ReferenceBuilder)
return ReferenceBuilder
