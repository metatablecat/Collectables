local Object = require(script.Object)

export type InstanceImplementor = Object.InstanceImplementor
export type InstanceObject = Object.InstanceObject
export type StateImplementor = Object.StateImplementor
export type StateObject = Object.StateObject

local export = {
	Object = Object,
	ReferenceBuilder = setmetatable({}::any, {__index = function() error("ReferenceBuilder Syntax is not available yet. Stay tuned!") end})
}

table.freeze(export)
return export