--!strict
local CollectionService: CollectionService = game:GetService("CollectionService")
local StateObject = require(script.Parent.lib.StateObject)
local InstanceObject = require(script.Parent.lib.InstanceObject)
local Types = require(script.Parent.lib.Types)

export type StateObject = Types.StateObject
export type StateImplementor = Types.StateImplementor
export type InstanceObject = Types.InstanceObject
export type InstanceImplementor = Types.InstanceImplementor

local tags: {[string]: InstanceImplementor} = {}
local API = {}

local function buildObject(i: Instance, impl: InstanceImplementor)
	return impl:Build(i)
end

local function setupCollectionService(tag: string, impl: InstanceImplementor)
	CollectionService:GetInstanceAddedSignal(tag):Connect(function(i)
		buildObject(i, impl)
	end)

	CollectionService:GetInstanceRemovedSignal(tag):Connect(function(i)
		-- find object binding
		local binding = impl.Objects[i]
		if not binding then return end
		binding:Destroy()
	end)

	for _, v in CollectionService:GetTagged(tag) do
		buildObject(v, impl)
	end
end

function API.StateObject(init: (StateObject) -> ()): StateImplementor
	return StateObject(init)
end

function API.InstanceObject(tag: string, asComponent: boolean, init: (InstanceObject) -> ()): InstanceImplementor
	if tags[tag] then
		error(`Duplicate tag definition {tag}`)
	end

	local implementor = InstanceObject(tag, asComponent, init)
	tags[tag] = implementor

	setupCollectionService(tag, implementor)
	return implementor
end

function API:AddComponent(i: Instance, componentName: string)
	local component = Instance.new("BindableEvent")
	component.Name = componentName
	component.Parent = i

	component:AddTag(componentName)
end

table.freeze(API)
return API