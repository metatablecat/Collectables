--!strict

local Types = require(script.Parent.Parent.Types)
local PathResolver = require(script.Parent.Parent.PathResolver)

return function(name: string, path: Instance|string?)
	local key = {}

	key.Name = name
	key.Path = path -- resolved on the resolve call, leave as is for now

	function key:Attach(o: Types.IObject, pathResolverDescendants, val)
		local path = PathResolver.getRelativeInstance(o, self.Path, pathResolverDescendants)
		local signal = path:GetAttributeChangedSignal(self.Name)
		o:WatchEvent(path, signal, val)
	end

	table.freeze(key)
	return key
end