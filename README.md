# Thrift

Inspired by: "THRee Instruction ForTh".

**Thrift** is a 2 instruction "Forth", the oly two instrucitons are:

* Quote: pushes a byte to the working stack, functionally equivalent to `[ LIT $1 ]`.
* Unquote: evaluates the byte at the top of the stack as an opcode, `[ #00 STR $1 ]`.

All the thrift API is prepended with colon `:` to indicate that this is either a
macro to create remote commands or a routine that is evaluated in the remote uxn
computer, routines may take arguments from the main or the remote computer, i.e.:

```uxntal
@:foo ( :a :b -- :c )

@:bar ( a b -- :c)
``` 

`:foo` is a routine that takes it's arugments from the remote uxn working stack,
while `:bar` takes it's arguments from the main uxn working stack, but leaves a
`:c` byte in the remote computer working stack.

## Macros



## Remote Pseudo Opcodes

## Routines

## Examples

```uxntal
@command ( -- )
    ;/start ;/end send
    JMP2r

    &start [ 
        :0a :03 :divk :mul :sub    ( :01 ) 
    ] &end
```

Is the same as doing:

```uxntal
#0a03 DIVk MUL SUB    ( 01 )
```
