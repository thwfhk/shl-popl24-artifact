# Artifact for Soundly Handling Linearity

This is the artifact for the paper:

*Wenhao Tang, Daniel Hillerström, Sam Lindley, J. Garrett Morris: Soundly Handling Linearity.*

The artifact contains the implementation of tracking control-flow
linearity in Links as described in Section 4, based on the core
calculus $\mathrm{F}_{\mathrm{eff}}^\circ$ formalised in Section 3.
This implementation solves a long-standing soundness bug of Links (see
issue [#544](https://github.com/links-lang/links/issues/544)) with the
interaction between multi-shot effect handlers and session-typed
channels (more generally any linear resource).

## Overview of the Artifact


The artifact is structured as follows

1. The section [Getting Started Guide](#getting-started-guide)
   shows how to install the artifact
2. The section [Step by Step Instructions](#step-by-step-instructions)
   is a detailed guide on how to run the experiments inside a Docker
   container running the provided Docker image.
3. The section [Inspecting the Source
   Files](#inspecting-the-source-files) highlights some relevant
   source files with our WasmFX additions.
4. The section [The WasmFX Toolchains](#the-wasmfx-toolchains)
   describes how our "toolchains" work.
5. The section [Reference Machine
   Specification](#reference-machine-specification) contains some
   detailed information about the reference machine used to conduct
   the experiments.

The directory structure of the artifact is as follows

* `links` contains the source code of Links extended with control-flow
  linearity, which is used for the Docker image.
* `examples` contains the examples
* (TODO: shared folder?)


## Getting Started Guide

To run the artifact you will need to build the Links language in
`/links`. For your convenience, we provide a
[Docker](https://www.docker.com/) image as well as its building
instructions. Please consult [the official Docker
documentation](https://docs.docker.com/engine/install/) for
instructions on to install and configure Docker for your operating
system. We also provide a virtual machine which runs the docker
container of the image.

### Using Docker

The provided Docker image is compatible with x86_64 architectures. For
other architectures (like Apple M1), you can either build the image
from scratch using [Dockerfile](./Dockerfile) or use the (virtual
machine)[#using-virtual-machine].

TODO:
- Install / build
- Run
- Sanity check

### Using Virtual Machine


<!-- ## List of Claims in the Paper -->



## Evaluation Instructions

### Test suites

### Examples from the paper



## Quick Guide to Links

An out-dated documentation of Links can be found on this
[webpage](https://links-lang.org/quick-help.html). However, it lacks a
lot of relatively new features of Links like session types (linear
types) and effect handlers. This section helps you get familiar with
effect handlers and linear types in Links.

To be consistent with other examples in this artifact, we enter REPL
with effect handlers and control-flow linearity enabled:
```
> linx --enable-handlers --track-control-flow-linearity
 _     _ __   _ _  __  ___
/ |   | |  \ | | |/ / / ._\
| |   | | , \| |   /  \  \
| |___| | |\ \ | |\ \ _\  \
|_____|_|_| \__|_| \_|____/
Welcome to Links version 0.9.8 (Burghmuirhead)
links>
```
The following commands are all ran in this REPL. You can type or
copy-paste them to try it yourself.

### Effect Handlers in Links

Links does not require operations to be declared before using;
instead, it infers the signatures for them.

Invoke an operation `Print`:
```
links> fun f1() {do Print("Hello World"); 42};
f1 = fun : () {Print:(String) => ()|_}-> Int
```
The operation signature `Print:(String) => ()` shows that `Print`
takes a string and returns a unit. The effect type is parameterised by
an anonymous effect row variable `_`.

Invoke an operation `Choose` with no parameter:
```
links> fun f2() {if (do Choose) 42 else 84};
f2 = fun : () {Choose:() => Bool|_}-> Int
```

Handle the `Print` operation:
```
links> handle (f1()) {case <Print(s) => r> -> println(s); r(())};
Hello World
42 : Int
```
The operation clause `case <Print(s) => r>` for `Print` binds its
parameter to `s` and continuation to `r`. We can also inline the
function `f1` by wrapping it into a block using `{...}`.
```
links> handle ({do Print("Hello World"); 42})
       {case <Print(s) => r> -> println(s); r(())};
Hello World
42 : Int
```

Handle the `Choose` operation with an explicit return clause:
```
links> handle (f1()) {
         case x -> [x]
         case <Choose => r> -> r(true) ++ r(false)
       };
[42, 84] : [Int]
```
The return clause `case x -> [x]` binds the return value to `x`. By
default, the return clause is `case x -> x`.

Compose the `Print` and `Choose` operations:
```
links> fun f3() {if (do Choose) do Print("42") else do Print ("84")};
f3 = fun : () {Choose:() => Bool,Print:(String) => a|_}-> a
```
Note that this time `Print` is polymorphic over its return type.

Compose the handlers of `Print` and `Choose`:
```
links> handle (handle(f3()) {case <Print(s) => r> -> println(s); r(())})
       {case <Choose => r> -> r(true); r(false)}
42
84
() : ()
```


### Linear Types and Session Types in Links

Links distinguishes between linear functions (defined by keyword
`linfun`) and unlimited functions (defined by keyword `fun`).
```
links> linfun(x) {x};
fun : (a) -@ a
links> fun(x) {x};
fun : (a) -> a
```
Linear function types are denoted by lollipops `-@`, and unlimited
function types are denoted by normal arrows `->`.

There are four type constructors of session types:
- `!A.S` : send a value of type `A`, then continue as `S`
- `?A.S` : receive a value of type `A`, then continue as `S`
- `~S`   : the dual channel of `S`
- `End`  : no communication
Session types are linear. As a result, channels are linear. Links
provides 4 primitive functions for basic channel communication.
```
links> send;
send : (a::Any, !(a::Any).b::Session) ~> b::Session
links> receive;
receive : (?(a::Any).b::Session) ~> (a::Any, b::Session)
links> fork;
fun : ((a::Session) {SessionFail:() =@ [||]}~> ()) ~> ~a::Session
links> close;
close : (End) ~> ()
```
The kind `a::Any` denotes that the type variable `a` can either be
linear or unlimited. Without kind annotation, value type variables has
kind `Unl` by default. The kind `b::Session` denotes that the type
variable `b` is a session type. The `SessionFail` operation and `~>`
curly arrow are irrelevant to this artifact and can be ignored (just
understood as the normal arrow `->`).

Note that the flag `--track-control-flow-linearity` influences the
default behaviour of linear resources in Links. We will show more
examples about linear types in the next
[Section](#quick-guide-to-control-flow-linearity-in-links).

## Quick Guide to Control-Flow Linearity in Links

This section

The extension `--track-control-flow-linearity` introduces the
following new constructs:
* Type syntax `A =@ B` is the signature for control-flow-linear
  operations (`A => B` for control-flow-unlimited operations)
* Kind syntax `Lin` is the kind for control-flow-linear effect variables (`Any`
  for effect variables with no linearity restriction)
* Term syntax `lindo L` invokes the control-flow-linear operation `L`
  (`do U` for control-flow-unlimtied operations)
* Term syntax `case <L =@ r> -> M` handles the control-flow-linear
  operation `L` (`case <U => r> -> M` for control-flow-unlimited
  operations)
* Term syntax `xlin` switches the current control-flow linearity to
  linear (by default, the control-flow linearity is unlimited)


1. We can mix control-flow-linear and control-flow-unlimited
   operations in a control-flow-unlimited effect scope (the default
   case). The anonymous effect variable `_` has kind `Any` by default
   which can be unified with any operations.

    ```
    links> fun() {do U; lindo L};
    fun : () {L:() =@ a,U:() => ()|_}-> a
    ```

2. We can only invoke control-flow-linear operations in a
   control-flow-linear effect scope (in other words, we cannot invoke
   control-flow-unlimited operations in a control-flow-linear effect
   scope). The linear control flow enables the usage of the linear
   channel `ch`. Now the effect variable `_` has kind `Lin`
   explicitly, which can only be unified with linear operations with
   signatures `=@`.

    ```
    links> fun(ch:End) {xlin; lindo L; close(ch)};
    fun : (End) {L:() =@ ()|_::Lin}~> ()
    ```

3. We can only handle control-flow-linear operations using a linear
   handler (indicated by `=@` in the clause) which guarantees the
   continuation is used exactly once.

    ```
    links> handle ({xlin; lindo L + 40}) { case <L =@ r> -> xlin; r(2) };
    42 : Int
    ```

4. We can handle control-flow-unlimited operations before entering a
   control-flow-linear effect scope as long as we guarantee that they
   are all handled. Note that after handling, the presence variable of
   `Choose` and row variable are both linear.

    ```
    links> fun(ch:End) { xlin; close(ch); handle ({if (do Choose) 40 else 2}) {case <Choose => r> -> r(true) + r(false)} };
    fun : (End) {Choose{_::Lin}|_::Lin}~> Int
    ```

5. When writing explicit quantifiers, we must explicitly annotate the
   kinds of row variables using `e::Row(Lin)` or `e::Row(Any)`. If the
   subkind is not specified, it means `Lin` instead of `Any` in order
   to be compatible with variants and records in Links which also use
   row variables. It is meaningful future work to explicitly separate
   value row variables and effect row variables in Links.

    ```
    links> sig f:forall e::Row(Any). () {Get:() => Int|e}-> Int fun f() {do Get}
    f = fun : () {Get:() => Int|_}-> Int
    ```


## Code Structure

