--!strict
-- Provides the API for generating or fetching a path string
local Types = require(script.Parent.Types)
local PathResolver = {}

function PathResolver.generateDescendantTree(i: Instance, prefix: string, treePipe: {[string]: Instance}?): {[string]: Instance}
	prefix = prefix or ""
	local tree = treePipe or {}::{[string]: Instance}
	
	for _, v in i:GetChildren() do
		local name = prefix .. v.Name
		tree[name] = v
		PathResolver.generateDescendantTree(v, name .. ".", tree)
	end
	
	return tree
end

function PathResolver.getRelativeInstance(o: Types.IObject, path: Instance|string?, pathRelative: {[string]: Instance}): Instance
	if typeof(path) == "Instance" then return path end
	if o.__typeof == "StateObject" then error("When using a StateObject, the path must be an Instance") end

	if not path then return o.Instance :: Instance end
	return pathRelative[path] or error(`Path {path} not present within this tree.`)
end

return PathResolver