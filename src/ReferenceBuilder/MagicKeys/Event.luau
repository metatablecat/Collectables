--!strict

local Types = require(script.Parent.Parent.Types)
local PathResolver = require(script.Parent.Parent.PathResolver)

return function(name: RBXScriptSignal|string, path: Instance|string?)
	local key = {}

	key.Name = name
	key.Path = path -- resolved on the resolve call, leave as is for now
	
	function key:Attach(o: Types.IObject, pathResolverDescendants, val)
		local path = PathResolver.getRelativeInstance(o, self.Path, pathResolverDescendants)
		local e = self.Name

		if type(e) == "string" then
			e = path[e]
			if typeof(e) ~= "RBXScriptSignal" then error(`Cannot connect to non-event object {e}`) end
		end

		o:WatchEvent(path, e, val)
		return
	end

	table.freeze(key)
	return key
end