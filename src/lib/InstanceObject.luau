--!strict

local IObject = require(script.Parent.IObject)
local Types = require(script.Parent.Types)

local Implementors: {[Types.InstanceObject]: Types.InstanceImplementor} = {}
local ObjectBindings = IObject.Bindings :: {[Types.InstanceObject]: Types.ObjectInternal}
local InstanceBindings: {[Instance]: Types.InstanceObject} = {}

local function destroySafe(i: Instance)
	i:Destroy()
	-- defer call this
end

local function newObject(tag: string, instance: any, componentMode: boolean): Types.InstanceObject
	local object = IObject.new() :: Types.InstanceObject
	object.Tag = tag
	if componentMode then
		object.Instance = instance.Parent
		object.Component = instance
	else
		object.Instance = instance
	end

	function object.GetAttribute(self: Types.InstanceObject, name: string): Types.AttributeValue
		if not self.Instance then error("Object has no active instance binding") end
		return self.Instance:GetAttribute(name)
	end
	
	function object.GetAttributes(self: Types.InstanceObject): {[string]: Types.AttributeValue}
		if not self.Instance then error("Object has no active instance binding") end
		return self.Instance:GetAttributes()
	end
	
	function object.SetAttribute(self: Types.InstanceObject, name: string, val: Types.AttributeValue)
		if not self.Instance then error("Object has no active instance binding") end
		self.Instance:SetAttribute(name, val)
	end

	function object.Destroy(self: Types.InstanceObject)
		local private = ObjectBindings[self]
		local inst = self.Instance::Instance
		if not private or not inst then return end
		local impl = Implementors[self]
	
		Implementors[self] = nil
		impl.Objects[inst] = nil
		ObjectBindings[self] = nil
		InstanceBindings[inst] = nil
	
		if self.Component then
			task.defer(destroySafe, self.Component)
		end
	
		private:ClearMemoryState()
		if impl.Destroying then impl.Destroying(self) end
		private:ClearMemoryState()
	end

	return object
end

local function realloc(self: Types.InstanceObject, nextInstance: Instance?)
	-- clears memory state and unassociated instance
	-- not the same as destroy
	local private = ObjectBindings[self]
	if not private then return end -- probably destroyed, moving instances triggers this

	local impl = Implementors[self]
	local oldInstance = self.Instance
	if oldInstance then
		impl.Objects[oldInstance] = nil
		InstanceBindings[oldInstance] = nil
	end

	private:ClearMemoryState()

	self.Instance = nextInstance
	if nextInstance then
		impl.Objects[nextInstance] = self
		InstanceBindings[nextInstance] = self
	end

	if impl.ComponentMoved then impl.ComponentMoved(self, oldInstance) end
end

local function spinUp(object: Types.InstanceObject, func)
	local initSpawn = coroutine.create(func)
	object:WatchThread(initSpawn)
	task.spawn(initSpawn, object)
end

return function(tag: string, asComponent: boolean, init: (Types.InstanceObject) -> ()): Types.InstanceImplementor
	local implementor = {} :: Types.InstanceImplementor
	implementor.Tag = tag
	implementor.AsComponent = asComponent
	implementor.Init = init
	implementor.Objects = {}

	function implementor.Build(self: Types.InstanceImplementor, i: Instance): Types.InstanceObject
		local object = newObject(self.Tag, i, self.AsComponent)
	
		if self.AsComponent then
			if not i:IsA("BindableEvent") then error("In component mode, assigned instance should be a BindableEvent") end
	
			i.AncestryChanged:Connect(function(_, p)
				realloc(object, p)
				if not p then return end
				spinUp(object, self.Init)
			end)
		end
	
		Implementors[object] = self
		self.Objects[i] = object
		InstanceBindings[i] = object
	
		if self.AsComponent and i.Parent == nil then return object end -- objects that are parented to nil are NOT tracked
		spinUp(object, self.Init)
		return object
	end

	return implementor
end