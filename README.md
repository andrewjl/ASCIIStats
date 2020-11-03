## ASCII Stats

The only thing better than visualizing probability and statistics... is visualizing it in ASCII! Non-ASCII characters may be used as well.

Visualizations inspired by the excellent [Seeing Theory](https://seeing-theory.brown.edu) online book.

This project is a showcase of my exploration of use of reactive architecture on iOS and Swift and bypassing major reactive frameworks. The purpose is to develop deeper understanding of how reactive systems work and best practices for building out large, complex ones.

In the future additional visualizations inspired by Seeing Theory will be added, hopefully along with lots of ASCII.

#### Project Architecture

##### Tree-based representation

This project is a showcase of a lightweight reactive architecture inspired by the [form library series](https://talk.objc.io/collections/building-a-form-library) on Swift Talk.

Similar to SwiftUI and other reactive UI frameworks, the UI is represented as a hierchical tree. Updates are uni-directional and propogated downward.

Challenges with this architecture included the need to couple behavior of sibling nodes in the tree. In the randomness example, the button needed to add the display link into the main run loop. This was accomplished by routing the change via the model layer but the result is not clean. The model layer is now indirectly coupled to the implementation of the UI.

An alternative solution can be message-passing between nodes similar to the [Elm](https://elm-lang.org) language. SwiftUI also introduced several data flow techniques.

##### Lightweight Reactivity 

 Using Swift keypaths to track and update UI state is similar to [use of the lens pattern](https://medium.com/@dtipson/functional-lenses-d1aba9e52254) in functional programming.

An important performance optimization made possible by Swift key paths is reducing the need for allocations when using value semantics. In  functional programming, data types are immutable so lenses behave have the effective type signature as follows:

`Get: (Instance) -> (Value)`

`Set: (Instance, Value) -> (Instance)`

When using Swift key paths and value types, the signatures become:

`Get: (Instance) -> (Value)`

`Set: (inout Instance, Value) -> ()`

The set lens can now assume ownership of the instance and modify the value directly, without needing to reconstruct a new instance and dispose of the out-of-date instance. The use of `inout` prevents concurrent conflicting changes to the memory. It restricts mutability to small isolated pockets of the system.