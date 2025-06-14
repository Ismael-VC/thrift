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

The **Macros** provide a low lewel API used to create commands in the local which
are then sent to the remote to be executed as "expressions":

* `:quot`: quotes a byte (treating it as a literal to be pushed to the :WST).
* `:unqt`: unquotes a byte (treating it as an opcode to executed immediatly).

```uxntal
@main ( -> )
    #0004 ;:#0a03   :asm/send-len   ( :0a :03 )
    ;:mod ;:mod/end :asm/send-blk   ( :01 )
    :DBG
    BRK

    @:#0a030 [ :quot 0a  :quot 03 ]
    @:mod [ ( :quot DIVk :unqt  :quot MUL :unqt  :quot SUB :unqt ] &end
```

## Remote Assembler

* `:asm/setup`: setups a copy of thrift at :ff0e, resets the assembler and jumps to :ff0e.
* `:asm/send-len ( length* start* -- )` sends a number of bytes to be assembled at
  `:asm/pointer_` absolute address.
* `:asm/send-blk ( start* end*  -- )`: sends a block of bytes to be assembled at
  `:asm/pointer_` absolute address.
* `:asm/set ( addr* -- )`: sets `:asm/pointer_` to an absolute address.
* `:asm/reset ( -- )`: resets `:asm/pointer_` to the default value (0100).
* `:asm/get`: gets the current value of `:asm/pointer_`.

Notice that each byte must be quoted independently.

## Remote Pseudo Opcodes

These routines provide a higer level API:

```uxntal
@main ( -> )
    [ :LIT2 0a03 ] :MOD   ( :01 )
    :DBG
    BRK

@:MOD ( :a :b -- :(a%b) ) :DIVk :MUL !:SUB
```
