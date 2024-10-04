--!strict

export type AttributeValue = unknown -- TODO

-- // StateWatcher

export type StateKey = {
	CurrentValue: unknown,
	NewValue: unknown,
	Change: (name: string, newValue: unknown, currentValue: unknown) -> ()?
}

export type StateWatcher = {
	DeferSetThread: thread?,
	Keys: {
		[string]: StateKey
	},
	UpdatedState: {[string]: true},
	DeferNewValue: (StateWatcher, name: string, newValue: unknown) -> (),
	SetChangeSignal: (StateWatcher, name: string, changeSignal: (key: string, newValue: unknown, oldValue: unknown) -> ()) -> ()
}

-- // IObject
export type EventObject<T> = {
	Sender: T,
	Connection: RBXScriptConnection
}

export type IObject<I = {[string]: any}> = {
	GetState: (IObject<I>, name: string) -> unknown,
	GetAllState: (IObject<I>) -> {[string]: unknown},
	SetState: (IObject<I>, name: string, val: unknown) -> (),
	SetStateChangedSignal: (IObject<I>, name: string, func: (IObject<I>, name: string, newValue: unknown, oldValue: unknown) -> ()) -> (),
	WatchThread: (IObject<I>, thread: thread) -> (),
	WatchEvent: <T>(IObject<I>, sender: T, event: RBXScriptSignal, func: (Object: EventObject<T>, ...any) -> ()) -> RBXScriptConnection
} & I

export type ObjectInternal = {
	Weak: typeof(setmetatable({}::{[thread|RBXScriptConnection]: true}, {__mode = "k"})),
	State: StateWatcher,
	ClearMemoryState: (ObjectInternal) -> ()
}

--// Object Implementors

export type StateObject = IObject<{
	Destroy: (StateObject) -> (),
}>

export type StateImplementor = {
	Init: (StateObject) -> (),
	Destroying: (StateObject) -> ()?,
	Build: (StateImplementor) -> StateObject
}

export type InstanceObject = IObject<{
	Tag: string,
	Instance: Instance?,
	Component: BindableEvent?,
	GetAttribute: (InstanceObject, name: string) -> AttributeValue,
	GetAttributes: (InstanceObject) -> {[string]: AttributeValue},
	SetAttribute: (InstanceObject, name: string, val: AttributeValue) -> (),
	Destroy: (InstanceObject) -> ()
}>

export type InstanceImplementor = {
	Tag: string,
	AsComponent: boolean,
	Init: (InstanceObject) -> (),
	Destroying: (InstanceObject) -> ()?,
	ComponentMoved: (InstanceObject, oldInstance: Instance?) -> ()?,
	Objects: {[Instance]: InstanceObject},
	Build: (InstanceImplementor, i: Instance) -> InstanceObject
}

return nil