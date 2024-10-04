# ReferenceBuilder

The following document explains the target specification for ReferenceBuilder.

The goal of this is to allow a declarative, event-driven approach to creating
objects.

Currently, two objects can be created within the Object framework:
`StateObject` and `InstanceObject`. Components can also be made, but this is
an extension of the already implemented `InstanceObject`.

# Basic Layout

Each Reference is a table where the keys define MagicKeys (or implementor
callbacks) that then link to a function:

```lua
return ReferenceBuilder.InstanceObject "KillBrick" {
	Touched = function(self, sender, otherPart)

	end
}
```

> Touched here is a fast-path alias for Event<"Touched", "@">, Path syntax does
> not allow @ externally

InstanceObject also allows for constraining a class type, this is not a feature
natively available in the object service.

The type of permitted keys are as follows:
* `"Init"|"Destroying"|"ComponentMoved"` - implementor callbacks, component
  moved only works with Components
* `MagicKey<any>` - Defines a magic key (defined below)
* `string` - Direct event binding to root

```lua
local Reference = ReferenceBuilder.InstanceObject("KillBrick", "BasePart") {
	...
}

Part:AddTag("KillBrick") -- OK!
workspace:AddTag("KillBrick") -- NOT OK! workspace is not a 'BasePart'
```

When working with a Component, this will check the parented object of the
component. ObjectService SHOULD still hook remaining builtin functionality.

We're also investigating a possible "CanImplement" callback on the reference
document to better constrain beyond the class name.

# Path Resolution

The syntax allows for referencing child instances (with Instance mode), which
is identical to Roblox path resolution syntax.

> The root instance is excluded from the resolver

Examples of this syntax are as follows:

```lua
"Touched" --> ROOT.Touched
"Part.Touched" --> ROOT.Part.Touched
```

This is passed as ROOT.(PathSteps).EventName. For components, you should use the
symbol `#` to forcefully set the path origin to the component, otherwise, it uses
the Instance.

# MagicKeys

In the initial spec, there will be the following magic keys, with the defined
logic enclosed:

> Path refers to the path resolution syntax minus the event sector. Change
> signals originates from the Component if path is undefined when applicable.

|Key|Signature|Purpose|
|-|-|-|
|`Change`|`(propName: string, path: string?)`|Binds a property change signal|
|`AttributeChange`|`(attribName: string, path: string?)`|Binds an attribute change signal|
|`StateChange`|`(stateName: string)`|Binds a state change signal|
|`Event`|`(event: RBXScriptSignal\|string, path: Instance\|string)`|Connects to an event, useful for non-direct events. Instance/path is required to derive sender|

Except for `StateChange`, they can all inherit from the same key system. We
should investigate conditional paths, but this is not to be implemented in the
first build.

## Non-Instance Objects

When it comes to Non-Instance objects, all MagicKeys are permitted, but the
path MUST Be defined when they have a `path` command.

# API Reference

The reference builder exports the following objects:

|Export|Signature|Description|
|-|-|-|
|`InstanceObject`|`(tag: string, classRestrict: {string}) -> (ReferenceParams) -> Reference`|Returns a description function to build an InstanceObject|
|`Component`|`(tag: string, classRestrict: {string}) -> (ReferenceParams) -> Reference`|Identical to `InstanceObject`, but enables the `asComponent` option.|
|`Object`|`(tag: string) -> (ReferenceParams) -> Reference`|Returns an unlinked object|
|`Change`|`(propName: string, path: string?) -> ChangeKey`|See MagicKeys|
|`AttributeChange`|`(attribName: string, path: string?) -> AttributeChangeKey`|See MagicKeys|
|`StateChange`|`(stateName: string) -> StateChangeKey`|See MagicKeys|
|`Event`|`(eventName: string, path: Instance\|string?) -> EventKey`|See MagicKeys|

# Construction Workflow

Each step here is either passed to a special Init callback, or hooked into the
implementor. The planned implementation of this is provided below:

```
Init
  Is ClassName implementable?
  	NO -> If component, warn and return, if Instance, error

  Hook events
  Hook internal change signals
  Run init callback
```


### License
(ↄ) metatablecat 2024 - MIT license