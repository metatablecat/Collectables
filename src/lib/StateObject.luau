--!strict
local IObject = require(script.Parent.IObject)
local Types = require(script.Parent.Types)

local Implementors: {[Types.StateObject]: Types.StateImplementor} = {}
local ObjectBindings = IObject.Bindings :: {[Types.StateObject]: Types.ObjectInternal}

local function newObject(): Types.StateObject
	local object = IObject.new() :: Types.StateObject
	
	function object.Destroy(self: Types.StateObject)
		local private = ObjectBindings[self]
		if not private then return end

		local impl = Implementors[self]
		Implementors[self] = nil
		ObjectBindings[self] = nil
		private:ClearMemoryState()
		if impl.Destroying then impl.Destroying(self) end
		private:ClearMemoryState()
	end

	return object
end

local function spinUp(object: Types.StateObject, func)
	local initSpawn = coroutine.create(func)
	object:WatchThread(initSpawn)
	task.spawn(initSpawn, object)
end

return function(init: (Types.StateObject) -> ()): Types.StateImplementor
	local implementor = {} :: Types.StateImplementor
	implementor.Init = init

	function implementor.Build(self: Types.StateImplementor)
		local object = newObject()
		Implementors[object] = self
		spinUp(object, self.Init)
		return object
	end

	return implementor
end