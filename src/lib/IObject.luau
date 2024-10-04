--!strict
local Types = require(script.Parent.Types)
local StateWatcher = require(script.Parent.StateWatcher)

local ObjectBindings: {[Types.IObject]: Types.ObjectInternal} = {}

local function getPrivate(o: Types.IObject): Types.ObjectInternal
	return ObjectBindings[o] or error("The object was destroyed")
end

local function killThisThread(t: thread)
	local co = coroutine.running()
	if co == t then
		task.defer(coroutine.close, t)
	else
		coroutine.close(t)
	end
end


local function makeInternal()
	local private = {} :: Types.ObjectInternal
	private.Weak = setmetatable({}, {__mode = "k"})
	private.State = StateWatcher()

	function private.ClearMemoryState(self: Types.ObjectInternal)
		for key in self.Weak do
			if type(key) == "thread" then
				killThisThread(key)
			else
				key:Disconnect()
			end
		end
	end

	return private
end

local IObject = {}
IObject.Bindings = ObjectBindings

function IObject.new(): Types.IObject
	-- returns an empty IObject
	local IObject = {} :: Types.IObject

	function IObject.GetState(self: Types.IObject, name: string): unknown
		local private = getPrivate(self)
		return (private.State.Keys[name] and private.State.Keys[name].NewValue) or nil
	end

	function IObject.GetAllState(self: Types.IObject): {[string]: unknown}
		local private = getPrivate(self)
		local state = {}
	
		for key, stateVal in private.State.Keys do
			state[key] = stateVal.NewValue
		end
	
		return state
	end

	function IObject.SetState(self: Types.IObject, name: string, val: unknown)
		local private = getPrivate(self)
		private.State:DeferNewValue(name, val)
		local co = private.State.DeferSetThread
	
		if co then self:WatchThread(co) end
	end

	function IObject.SetStateChangedSignal(self: Types.IObject, name: string, func: (Types.IObject, name: string, newValue: unknown, oldValue: unknown) -> ())
		local private = getPrivate(self)
		private.State:SetChangeSignal(name, function(key, newValue, oldValue)
			self:WatchThread(coroutine.running())
			func(self, key, newValue, oldValue)
		end)
	end

	function IObject.WatchThread(self: Types.IObject, thread: thread)
		local private = getPrivate(self)
		private.Weak[thread] = true
	end
	
	function IObject.WatchEvent<T>(self: Types.IObject, sender: T, event: RBXScriptSignal, func: (Types.IObject, Types.EventObject<T>, ...any) -> ()): RBXScriptConnection
		local params = {} :: Types.EventObject<T>
		local private = getPrivate(self)

		params.Sender = sender
		params.Connection = event:Connect(function(...)
			self:WatchThread(coroutine.running())
			func(self, params, ...)
		end)

		private.Weak[params.Connection] = true
		return params.Connection
	end

	ObjectBindings[IObject] = makeInternal()
	return IObject
end

return IObject