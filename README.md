# Artifact for Soundly Handling Linearity

This is the artifact for the paper:

*Wenhao Tang, Daniel Hillerström, Sam Lindley, J. Garrett Morris, "Soundly Handling Linearity", Proc. ACM Program. Lang. 8(POPL), 2024.*

The artifact contains the implementation of control-flow linearity
(CFL) extension in Links as described in Section 4 of the paper, based
on the core calculus $\mathrm{F}_{\mathrm{eff}}^\circ$ formalised in
Section 3. This implementation soundly combine the linear types
(session types) and multi-shot effect handlers of Links, solving a
long-standing soundness bug (see issue
[#544](https://github.com/links-lang/links/issues/544)).

This document is best viewed in a markdown editor or on
[GitHub](https://github.com/thwfhk/shl-popl24-artifact).

## Overview of the Artifact

The artifact is structured as follows

1. The section [Getting Started Guide](#getting-started-guide) shows
   how to install the artifact and enter the Links REPL.
2. The section [Evaluation Instructions](#evaluation-instructions) is
   a detailed guide on how to run the examples in the paper as well as
   other test examples we provide.
3. The section [Quick Guide to Links](#quick-guide-to-links) and
   [Quick Guide to CFL in Links](#quick-guide-to-cfl-in-links) provide
   a quick introduction to the effect handlers, linear types (session
   types), and control-flow linearity in Links in order to add
   customised examples.
4. The section [Relevant Source Files](#relevant-source-files)
   highlights some relevant source files with our CFL extension.

The directory structure of the artifact is as follows

* `links` contains our fork of Links which is extended with
  control-flow linearity.
* `tests` contains the test files for the examples from the paper, the
  original test suite of Links, and more examples about CFL.
* `cfl.patch` contains the changesets for our fork of Links
* `run-tests.py` is a script to run the test files.


## Getting Started Guide

To evaluate the artifact you will need to build the Links language in
`/links`. For your convenience, we provide a
[Docker](https://www.docker.com/) image as well as its building
instructions. Please consult [the official Docker
documentation](https://docs.docker.com/engine/install/) for
instructions on to install and configure Docker for your operating
system.

### Download the artifact

Check it out from the git repository
```
> git clone https://github.com/thwfhk/shl-popl24-artifact paper-261
```
You should now have the following files on your machine
```
> cd paper-261 && ls -m
Dockerfile, README.md, cfl.patch, links, run-tests.py, tests
```

Then you can either [build Links](#a-install-links-directly) on your
machine or [use Docker](#b-use-docker).

### A. Install Links Directly

We strongly recommend using the [Docker image](#b-use-docker). If you
do not wish to use it however, you can install Links from source
following the instructions in the [Dockerfile](./Dockerfile). Then,
jump to the step 3 Soundness check of [Using Docker](#b-use-docker).


### B. Use Docker

The provided Docker image is compatible with x86_64 architectures. For
other architectures (like Apple M1), you can build the image from
scratch using [Dockerfile](./Dockerfile).

1. Obtain the Docker image \
   You can either download a prepared image or build it yourself.
   *  Downloading the image \
      You can download the prepared image (built for x86_64
      architectures) by issuing the following command
      ```
      > docker pull thwfhk/shl-popl24-artifact:latest
      > docker tag thwfhk/shl-popl24-artifact shl-popl24-artifact
      ```
      The last command creates an alias for the image, which we will
      use exclusively throughout this guide.
   *  Building from source \
      To build the image from scratch you may use provided
      [Dockerfile](./Dockerfile) build script. Depending on your
      hardware the build process may take upwards an hour, though, any
      reasonable modern workstation ought to be able to finish the
      process within 5 minutes. If you are using an x86_64 machine,
      then you may build the image by issuing the following command
      ```
      $ docker build -t shl-popl24-artifact .
      ```
      If you are on an Arm-powered machine, then you may try to cross build
      the image
      ```
      $ docker buildx build --platform linux/amd64 -t shl-popl24-artifact .
      ```

2. Launch the image inside a container \
   If you are on an x86_64 machine, then invoke the following command
   to launch the image inside a container and drop you into an
   interactive shell
   ```
   > docker run -it shl-popl24-artifact
   ```
   If you are on an Arm-powered device then you may try to use the
   emulation layer, e.g.
   ```
   > docker run --platform linux/amd64 -it shl-popl24-artifact
   ```
   Nonetheless, once the shell has been launched you should be
   directed to `/artifact` directory with the following files
   ```
   /artifact$ ls
   README.md  cfl.patch  links  run-tests.py  tests
   ```
   To exit the container, simply type
   ```
   > exit
   ```

3. Soundness check \
   To ensure that Links is successfully built in the directory
   `/artifact/links`, enter the Links REPL with CFL enabled by the
   following command
   ```
   /artifact$ ./links/links --control-flow-linearity
    _     _ __   _ _  __  ___
   / |   | |  \ | | |/ / / ._\
   | |   | | , \| |   /  \  \
   | |___| | |\ \ | |\ \ _\  \
   |_____|_|_| \__|_| \_|____/
   Welcome to Links version 0.9.8 (Burghmuirhead)
   links>
   ```
   The global command `linx` is linked to Links. So the following
   command should also work
   ```
   /artifact$ linx --control-flow-linearity
    _     _ __   _ _  __  ___
   / |   | |  \ | | |/ / / ._\
   | |   | | , \| |   /  \  \
   | |___| | |\ \ | |\ \ _\  \
   |_____|_|_| \__|_| \_|____/
   Welcome to Links version 0.9.8 (Burghmuirhead)
   links>
   ```
   To exit Links REPL, enter `ctrl+D`.

## Evaluation Instructions

To simplify the evaluation, we wrap all examples and their expected
results into test files with suffix `.tests`. Three test files
`paper.tests`, `handlers.tests`, and `more-cfl.tests` as well as
directories containing their auxiliary Links programs are provided in
the `tests` directory. The configuration file
`tests/control_flow_linearity.config` is just used to enable the CFL
flag. The `tests/custom` directory is used to add your own examples.
```
/artifact$ ls tests
control_flow_linearity.config  handlers        more-cfl        paper.tests
custom			       handlers.tests  more-cfl.tests  popl24
```

The script `run-tests.py` parses the test files and run the test cases
in them. Notice that the default timeout for each test case is 60
seconds. This is usually enough. If you accidentally get timeout
errors, please try to set the `TIMEOUT` on line 11 of `run-tests.py`
to a larger number.

### Format of Test Files

You can use `vi` or install your favourite text editor to read the
test files. For example,
```
/artifact$ vi tests/paper.tests
```

The first three lines of test files make sure that the CFL extension
is enabled for all tests. Comments start with `#`.

The main part of test files consists of several blocks of consecutive
lines, separated by empty lines. Each such block represents one test
case, including its description, Links code, expected result, and
other optional arguments.

The first line of each block contains a description.

The second line usually contains the actual Links code.
Alternatively, in some cases, the second line contains a path to a
`.links` file containing the actual code.

Finally, the lines from the third onward give extra information about the
expected output of the program.  This includes:
  * The messages printed  (`stdout :` and `stderr :`)
  * The exit code, if non-zero ( `exit :`)
  * Flag to read a program from a file (`filemode :`)

For example, the first test case in `tests/paper.tests` is
```
S1 The original introduction program
tests/popl24/intro.links
filemode : true
exit : 1
stderr : @.*Type error.*
```
It uses the file in `tests/popl24/intro.links`, which contains the
motivation example we showed in Section 1 of the paper. This program
is expected to exit with code 1 and throw a type error.

### Testing Examples from the Paper

We provide all Links examples in Section 1 and Section 4, as well as
the Links version of all $\mathrm{F}_{\mathrm{eff}}^\circ$ examples in
Section 2 in the test file `tests/paper.tests` and the directory
`tests/popl24`. You can find the correspondence in the description of
each test case.

To test them, run
```
/artifact$ ./run-tests.py tests/paper.tests
```
If all tests are passed, the last two lines of the output should be
```
0 failures (+0 ignored)
31 successes
```

### Testing the Test Suite of Links

We provide all examples from the original test suite of Links that use
effect handlers in the test file `tests/handlers.tests` and the
directory `tests/handlers`. This test shows that our CFL extension is
backward compatible with the handler feature of Links.

To test them, run
```
/artifact$ ./run-tests.py tests/handlers.tests
```
If all tests are passed, the last two lines of the output should be
```
0 failures (+0 ignored)
124 successes
```

### Testing More Examples of CFL

We provide more examples to test the behaviour of the CFL extension in
the test file `tests/more-cfl.tests` and the directory
`tests/more-cfl`. A brief description can be found in the first line
of each test case.

To test them, run
```
/artifact$ ./run-tests.py tests/more-cfl.tests
```
If all tests are passed, the last two lines of the output should be
```
0 failures (+0 ignored)
33 successes
```

### Creating Your Own Examples

We provide two guides, [Quick Guide to Links](#quick-guide-to-links)
and [Quick Guide to CFL in Links](#quick-guide-to-cfl-in-links), to
help you get familiar with Links in order to create your own examples.
You can test the examples in the guide in the REPL and write your own
examples in either REPL or standalone files.

To enter the Links REPL with CFL enabled, run
```
/artifact$ linx --control-flow-linearity
```

To execute a program file, run
```
/artifact$ linx --control-flow-linearity tests/custom/your_own_example.links
```

Alternatively, you can first enter the REPL and then load the file
```
/artifact$ linx --control-flow-linearity
 _     _ __   _ _  __  ___
/ |   | |  \ | | |/ / / ._\
| |   | | , \| |   /  \  \
| |___| | |\ \ | |\ \ _\  \
|_____|_|_| \__|_| \_|____/
Welcome to Links version 0.9.8 (Burghmuirhead)
links> @load "tests/custom/your_own_example.links"
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
> linx --control-flow-linearity
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
  links> handle (f2()) {
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
         {case <Choose => r> -> r(true); r(false)};
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

Note that the flag `--control-flow-linearity` influences the default
behaviour of linear resources in Links. We will show more examples
about linear types in [Quick Guide to CFL in
Links](#quick-guide-to-control-flow-linearity-in-links).

## Quick Guide to CFL in Links

This section gives a quick introduction to the CFL extension of Links,
the main contribution of our artifact. The extension is enabled by
passing the flag `--control-flow-linearity`, which automatically
enables the flag `--enable-handlers`. Some explanation of the CFL
extension in Links and its relation to
$\mathrm{F}_{\mathrm{eff}}^\circ$ can also be found in Section 4 of
the paper.

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
coding practice, we recommand writing `xlin` at the beginning of
scopes.

### Examples

Again, we enter REPL with CFL enabled:
```
> linx --control-flow-linearity
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
         {case <Choose =@ r> -> xlin; r(true)};
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
  links> sig f:forall e::Row(Any). () {Get:() => Int|e}-> Int fun f() {do Get};
  f = fun : () {Get:() => Int|_}-> Int
  ```
  When writing explicit quantifiers, we should explicitly annotate the
  control-flow linearity of effect row variables in their kinds using
  `e::Row(Lin)` or `e::Row(Any)`. If the subkind is not specified, it
  means `Lin` instead of `Any` for backwards compatibility (because
  row variables are used by both effect types and variant / record
  types in Links). It is meaningful future work to explicitly separate
  value row variables and effect row variables in Links.


## Relevant Source Files

This artifact contains the full source code and test suite of our fork
of Links in the `links` directory. To emphasise which part is crucial
to the CFL extension, we include our changesets to the Links source
code (i.e., the `links/core` directory) in the file `cfl.patch`. These
changesets were obtained by running `git diff` of our fork against the
upstream master branch (before our PR is merged).

The following list highlights the most relevant source files in the
`links/core` directory:

* `links/core/typeSugar.ml` : type inference. This file contains the
  main mechanism of tracking control-flow linearity.
* `links/core/sugarTypes.ml` : syntax for the surface language
* `links/core/types.ml` : semantic types
* `links/core/desugarTypeVariables.ml` : desugaring of type variables
* `links/core/desugarEffects.ml` : desugaring of anonymous effect variables
* `links/core/parser.mly` : parser