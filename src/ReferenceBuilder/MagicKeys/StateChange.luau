--!strict

local Types = require(script.Parent.Parent.Types)

return function(name: string)
	local key = {}
	key.Name = name

	function key:Attach(o: Types.IObject, pathResolverDescendants, val)
		o:SetStateChangedSignal(self.Name, val)
	end

	table.freeze(key)
	return key
end