# Artifact for Soundly Handling Linearity

This is the artifact for the paper:

*Wenhao Tang, Daniel Hillerström, Sam Lindley, J. Garrett Morris, "Soundly Handling Linearity"*

The artifact contains the implementation of control-flow linearity
(CFL) extension in Links as described in Section 4 of the paper, based
on the core calculus $\mathrm{F}_{\mathrm{eff}}^\circ$ formalised in
Section 3. This implementation soundly combine the linear types
(session types) and multi-shot effect handlers of Links, solving a
long-standing soundness bug (see issue
[#544](https://github.com/links-lang/links/issues/544)).

## Overview of the Artifact

The artifact is structured as follows

1. The section [Getting Started Guide](#getting-started-guide) shows
   how to install the artifact and run Links.
2. The section [Evaluation Instructions](#evaluation-instructions) is
   a detailed guide on how to run the examples in the paper as well as
   other test examples we provide.
3. The section [Quick Guide to Links](#quick-guide-to-links) and
   [Quick Guide to CFL in Links](#quick-guide-to-cfl-in-links) provide
   a quick introduction to the effect handlers, linear types (session
   types), and control-flow linearity in Links in order to add
   customised examples.
4. The section [Inspecting the Source Files](#inspecting-the-source-files)
   highlights some relevant source files with our CFL extension.

The directory structure of the artifact is as follows

* `links` contains the full source code of Links extended with
  control-flow linearity, which is used for the Docker image.
* `tests` contains the test files for the examples from the paper, the
  original test suite of Links, and more examples about CFL.
* `run-tests.py` is a script to run the test files.


## Getting Started Guide

To run the artifact you will need to build the Links language in
`/links`. For your convenience, we provide a
[Docker](https://www.docker.com/) image as well as its building
instructions. Please consult [the official Docker
documentation](https://docs.docker.com/engine/install/) for
instructions on to install and configure Docker for your operating
system. We also provide a virtual machine which runs the docker
container of the image.

<!-- ### Installing Links Directly

We strongly recommend using the [Docker image](#using-docker) or
[virtual machine](#using-virtual-machine). If you do not wish to use
Docker however, you can install Links from source using. -->

### Using Docker

The provided Docker image is compatible with x86_64 architectures. For
other architectures (like Apple M1), you can either build the image
from scratch using [Dockerfile](./Dockerfile) or use the [virtual
machine](#using-virtual-machine).

TODO:


### Using Virtual Machine

TODO:


### Sanity Check

Enter `linx`


<!-- ## List of Claims in the Paper -->



## Evaluation Instructions

TODO:

### Testing Examples from the Paper

We provide all Links examples in Section 1 and Section 4, as well as
the Links version of all Feffpop examples in Section 2.

```
/artifact$ ./run-tests.py tests/paper.tests
```

### Testing the Test Suite of Links

```
/artifact$ ./run-tests.py tests/handlers.tests
```

### Testing More Examples of CFL

```
/artifact$ ./run-tests.py tests/more-cfl.tests
```

### Creating Your Own Examples

```
/artifact$ linx --control-flow-linearity tests/custom/your_own_example.links
```


## Quick Guide to Links

An out-dated documentation of Links can be found in this
[link](https://links-lang.org/quick-help.html). However, it lacks a
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

- Invoke an operation `Print`:
  ```
  links> fun f1() {do Print("Hello World"); 42};
  f1 = fun : () {Print:(String) => ()|_}-> Int
  ```
  The operation signature `Print:(String) => ()` shows that `Print`
  takes a string and returns a unit. The effect type is parameterised
  by an anonymous effect row variable `_`.

- Invoke an operation `Choose` with no parameter:
  ```
  links> fun f2() {if (do Choose) 42 else 84};
  f2 = fun : () {Choose:() => Bool|_}-> Int
  ```

- Handle the `Print` operation:
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

- Handle the `Choose` operation with an explicit return clause:
  ```
  links> handle (f1()) {
           case x -> [x]
           case <Choose => r> -> r(true) ++ r(false)
         };
  [42, 84] : [Int]
  ```
  The return clause `case x -> [x]` binds the return value to `x`. By
  default, the return clause is `case x -> x`.

- Compose the `Print` and `Choose` operations:
  ```
  links> fun f3() {if (do Choose) do Print("42") else do Print ("84")};
  f3 = fun : () {Choose:() => Bool,Print:(String) => a|_}-> a
  ```
  Note that this time `Print` is polymorphic over its return type.

- Compose the handlers of `Print` and `Choose`:
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
examples about linear types in [Quick Guide to CFL in Links](#quick-guide-to-control-flow-linearity-in-links).

## Quick Guide to CFL in Links

This section gives a quick introduction to the CFL extension of Links,
the main contribution of our artifact. The extension is enabled by
passing the flag `--track-control-flow-linearity`. It is usually used
together with `--enabled-handlers`. Some explanation of the CFL
extension can also be found in Section 4 of the paper.

### New Constructs

The CFL extension introduces the following new constructs:
* Type syntax `A =@ B` represents signatures for control-flow-linear
  operations (`A => B` for control-flow-unlimited operations)
* Kind syntax `Lin` represents kinds for control-flow-linear effect
  variables (`Any` for effect variables with no linearity restriction)
* Term syntax `lindo L` invokes control-flow-linear operations (`do U`
  for control-flow-unlimtied operations)
* Term syntax `case <L =@ r> -> M` handles control-flow-linear
  operations `L` (`case <U => r> -> M` for control-flow-unlimited
  operations)
* Term syntax `xlin` switches the current control-flow linearity to
  linear (by default, the control-flow linearity is unlimited)

### Understanding CFL in Links

To understand what CFL exactly means in Links, we need to know how the
effect system of Links works. Links adopts a Row-based effect system
similar to that of $\mathrm{F}_{\mathrm{eff}}^\circ$ in Section 3 of
the paper and supports ML-style type inference of it. As a result, the
effect types of sequenced computations are unified. We introduce the
concept *effect scope* to mean the scope where computations share
effects (i.e., have the same effect types). There are only two cases
that new effect scopes are created:
* Function bodies (closures) hold their own effect scopes.
* Computations being handled (the `M` in `handle M {...}`) have their
  own effect scopes, but also share those unhandled effects with
  computations outside the handler.

All operations invoked in the same effect scope have the same
control-flow linearity. By default, the control-flow linearity of
every effect scope is unlimited. We are allowed to use both
control-flow-linear and control-flow-unlimited operations, but only
unlimited value variables. We can switch the control-flow linearity of
the current effect scope to linear by `xlin`. Then, we are allowed to
use both unlimited and linear value variables, but only
control-flow-linear operations. Note that switching the control-flow
linearity to linear is irreversible since control-flow-linear effect
row variables can never be made unlimited. All invocations of
unlimited operations in a control-flow-linear effect scope (even
before `xlin`) would cause type errors.

Though `xlin` can be written anywhere in an effect scope, for good
coding practice, we recommand writing `xlin` at the beginning. We have
the following syntactic sugar
```
xl{ ... } ≣ { xlin; ... } or
@{ ... } ≣ { xlin; ... }
```
(TODO: do we really want this syntactic sugar? It would be good if it
is considered to be valid block syntax. But this may require
non-trivial changes.)

### Examples

Again, we enter REPL with both effect handlers and control-flow
linearity enabled:
```
> linx --enable-handlers --track-control-flow-linearity
```

- Invoke a control-flow-linear operation `Choose` in a
  control-flow-linear context:
  ```
  links> fun g1() {xlin; if (lindo Choose) 42 else 84};
  g1 = fun : () {Choose:() =@ Bool|_::Lin}-> Int
  ```
  We use `xlin` to switch the current control-flow linearity to
  linear. The anonymous effect row variable `_` has kind `Lin` which
  can only be unified with control-flow-linear operations.

- Invoke a control-flow-linear operation `Choose` in a
  control-flow-unlimited context:
  ```
  links> fun g2() {if (lindo Choose) 42 else 84};
  g2 = fun : () {Choose:() =@ Bool|_}-> Int
  ```
  It is sound to invoke control-flow-linear operations in
  control-flow-unlimited contexts. Without kind annotation, the
  anonymous effect row variable `_` has kind `Any` by default which
  can be unified with any operations.

- Mix control-flow-linear and control-flow-unlimited operations in a
  control-flow-unlimited context:
  ```
  links> fun g3() {if (lindo Choose) do Print("42") else do Print ("84")};
  g3 = fun : () {Choose:() =@ Bool,Print:(String) => a|_}-> a
  ```

- Handle control-flow-linear operations:
  ```
  links> handle (g1()) {case <Choose =@ r> -> xlin; r(true)};
  42 : Int
  links> handle (g2()) {case <Choose =@ r> -> xlin; r(true)};
  42 : Int
  links> handle (handle (g3()) {case <Print(s) => r> -> println(s); r(())})
         {case <Choose =@ r> -> xlin; r(true)}
  42
  () : ()
  ```
  We write `case <Choose =@ r> -> ...` for the handler clauses of the
  control-flow-linear operation `Choose`. The operation clauses must
  match the control-flow linearity of operations. Otherwise, we get a
  type error:
  ```
  links> handle (g1()) {case <Choose => r> -> r(true) + r(false)};
  <stdin>:1: Type error: The effect type of an input to a handle should match the type of its computation patterns, but the expression
      `g1()'
  has effect type
      `{Choose:() =@ Bool|a}'
  while the handler handles effects
      `{Choose:() => Bool,wild:()|b::Any}'
  In expression: handle (g1()) {case <Choose => r> -> r(true) + r(false)}.
  ```
  The continuation function `r` bound by `Choose =@ r` is given a
  linear function type and must be used exactly once in a
  control-flow-linear context (enabled by `xlin`). Otherwise, we get
  type errors:
  ```
  links> handle (g1()) {case <Choose =@ r> -> r(true) + r(false)};
  <stdin>:1: Type error: Variable r has linear type
      `(Bool) {}~@ Int'
  but is used 2 times.
  In expression: handle (g1()) {case <Choose =@ r> -> r(true) + r(false)}.
  ```

- Use linear resources in a control-flow-linear context:
  ```
  links> fun(ch) {xlin; var x = if (lindo Choose) 42 else 84; close(send(x,ch))};
  fun : (!(Int).End) {Choose:() =@ Bool|_::Lin}~> ()
  ```
  The linear channel `ch` must be used in control-flow-linear
  contexts. Otherwise, we get a type error complaining that the
  variable `ch` has an unlimited type which cannot be unified with a
  session type:
  ```
  links> fun(ch) {var x = if (lindo Choose) 42 else 84; close(send(x,ch))};
  <stdin>:1: Type error: The function
      `send'
  has type
      `(Int, !(Int).a::Session) ~b~> a::Session'
  while the arguments passed to it have types
      `Int'
  and
      `c::(Unl,Mono)'
  ...
  ```

- Handle control-flow-unlimited operations fully before entering
  control-flow-linear contexts:
  ```
  links> fun(ch) { xlin;
                   var x = handle ({if (do Choose) 42 else 84})
                           {case <Choose => r> -> r(true) + r(false)};
                   close(send(x,ch)) };
  fun : (!(Int).End) {Choose{_::Lin}|_::Lin}~> ()
  ```
  Note that after handling, the presence variable of `Choose` and row
  variable are both control-flow-linear because the handler is in a
  control-flow-linear context.

- Explicit quantifiers for effect row variables with control-flow
  linearity:
  ```
  links> sig f:forall e::Row(Any). () {Get:() => Int|e}-> Int fun f() {do Get}
  f = fun : () {Get:() => Int|_}-> Int
  ```
  When writing explicit quantifiers, we should explicitly annotate the
  control-flow linearity of effect row variables in their kinds using
  `e::Row(Lin)` or `e::Row(Any)`. If the subkind is not specified, it
  means `Lin` instead of `Any` for backwards compatibility (because
  row variables are used by both effect types and variant / record
  types in Links). It is meaningful future work to explicitly separate
  value row variables and effect row variables in Links.

### Relationship between Feffpop and Links with CFL

## Inspecting the Source Files

The source can be found in the `links` directory. Relevant source
files you might wish to look at:

* `links/core/sugarTypes.ml` -- syntax for the surface language
* `links/core/typeSugar.ml` -- type inference
* `links/core/desugarEffects.ml` -- desugaring of effect types

TODO: