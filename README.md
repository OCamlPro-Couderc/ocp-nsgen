# ocp-nsgen

## Automatic aliases wrapper generator

This simple tool allows one to generate automatically wrappers to simulate
namespaces from libraries objetcs (cma or cmxa). In other words, take for
example an object "foo.cma" that contains two compilation units "Bar" and "Baz".
It will generate (on the standard output) the following module rebinding:
```ocaml
module Bar = Bar
module Baz = Baz
```
As a result, those modules can be used as ```Foo.Bar``` and ```Foo.Baz```.

An other possiblity is to give a prefix to remove in the alias, in order to make
wrappers to look more "namespace". Assume "foo.cma" that contains "Foo_bar" and
"Foo_baz":
```ocaml
module Bar = Foo_bar
module Baz = Foo_baz
```

It can be called on multiple files, each time aliased using the last prefix
declared.

## Installation

ocp-nsgen is only compatible with OCaml >= 4.02.0, due to changes in the
Parsetree. Since it is designed to be used specifically with aliases and the
```-no-alias-deps``` option, it is not that relevant to use it for earlier
versions.

Using ```opam```:
```
opam pin add ocp-nsgen git@github.com:OCamlPro-Couderc/ocp-nsgen.git
```

Otherwise, it needs ```ocp-build``` (and obviously OCaml, with ```compiler-libs```):
```
ocp-build ocp-nsgen
// to install
cp _obuild/ocp-nsgen.<byte|asm> <destination accessible from PATH>
```
