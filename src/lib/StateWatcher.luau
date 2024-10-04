--!strict

local Types = require(script.Parent.Types)

local function SUMMON_CHANGE_THREAD(watcher: Types.StateWatcher)
	-- We just spawn it even if the table is empty
	--if watcher.DeferSetThread then return end

	watcher.DeferSetThread = task.defer(function(self: Types.StateWatcher)
		for key in self.UpdatedState do
			local ref = self.Keys[key]

			local ov, nv, change = ref.CurrentValue, ref.NewValue, ref.Change

			if nv == nil and not change then
				self.Keys[key] = nil
			end

			ref.CurrentValue = nv
			if change then task.spawn(change, key, nv, ov) end
		end
		
		table.clear(self.UpdatedState)
		self.DeferSetThread = nil
	end, watcher)
end

local function allocDefaultKey(self: Types.StateWatcher, name: string): Types.StateKey
	local defKey = {
		CurrentValue = nil,
		NewValue = nil
	}::Types.StateKey

	self.Keys[name] = defKey
	return defKey
end

return function(): Types.StateWatcher
	local stateWatcher = {} :: Types.StateWatcher
	stateWatcher.Keys = {}
	stateWatcher.UpdatedState = {}

	function stateWatcher.DeferNewValue(self: Types.StateWatcher, name: string, newValue: unknown)
		local keyWrite = self.Keys[name] or allocDefaultKey(self, name)
		local keyChanged = type(newValue) == "table" or keyWrite.CurrentValue ~= newValue
		self.UpdatedState[name] = if keyChanged then true else nil

		if keyChanged then
			keyWrite.NewValue = newValue
			SUMMON_CHANGE_THREAD(self)
		end
	end

	function stateWatcher.SetChangeSignal(self: Types.StateWatcher, name: string, changeSignal: (key: string, newValue: unknown, oldValue: unknown) -> ())
		local keyWrite = self.Keys[name] or allocDefaultKey(self, name)
		if keyWrite.Change then
			error(`State key {name} already has an assigned change signal`)
		end
	
		keyWrite.Change = changeSignal
	end

	return stateWatcher
end