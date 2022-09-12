# Collie

A LISP dialect transpiled to Erlang.

## Setup

- You need to have `asdf` installed.
- Run `asdf install`.

## REPL

In order to use REPL run `mix run repl.exs`

## Compiling and running files

In order to write a program in Collie and compile it to BEAM machine code you need to place your code in `input.cll` and run `compile_and_run.sh`. The output will be saved as transpiled code in `output.erl` as well as BEAM code in `output.beam`.
