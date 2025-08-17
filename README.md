# Thrift

**Thrift** is a 2 instruction "Forth" for Uxn in 24 bytes, inspired by
["THRee Instruction ForTh"](https://pygmy.utoh.org/3ins4th.html),
the olny two instrucitons are `quote` and `unquote`.

> "To quote, or to unquote, that is the question." -- Not William Shakespeare.

```uxntal
@on-reset ( -> )
|0100   40 00 03   ( !/reset )
&quote
|0103   80 12 16   ( .Console/read DEI )
&reset
|0106   a0 01 0d   ( ;on-console )
|0109   80 10 37   ( .Console/vector-hi DEO2 )
|010c   00         ( BRK )

@on-console ( -> )
|010d   80 12 16   ( .Console/read DEI )
|0110   8c         ( JMPk )
&unquote
|0111   13 00 00   ( STR $1 BRK )
&quote
|0114   80 11 17   ( .Console/vector-lo DEO )
|0117   00         ( BRK )
```
When assembled the last trailing null byte is ellided because uxn memory
is zeroed out on reset, leaving us with a 23 bytes rom.

```uxntal
4000 0380 1216 a001  0d80 1037 0080 1216
8c13 0000 8011 17
````

* Quote: pushes a byte to the remote working stack, functionally equivalent to
  `LIT`.
* Unquote: evaluates the byte at the top of the remote working stack as an
  opcode.

Serial communication is emulated via the `Console/write` device ports, used to
send bytes between the local and remote computers.

All the thrift API is prepended with colon `:` to indicate that this is either a
macro to create remote commands or a routine that is evaluated in the remote uxn
computer, routines may take arguments from the main or the remote computer,
i.e.:

```uxntal
@:foo ( :a :b -- :c )
@:bar ( a b -- :c)
```

`:foo` is a routine that takes it's arugments from the remote working stack,
while `:bar` takes it's arguments from the local working stack, but leaves a
byte in the remote working stack.

## Dependencies

* [`uxncli`](https://git.sr.ht/~rabbits/uxn): Uxn/Varvara emulator.
* [`drifblim`](https://git.sr.ht/~rabbits/drifblim): Uxntal assembler.
* [`socat`](http://www.dest-unreach.org/socat/): Emulates serial connection in
   Linux.

## Build

```sh
$ make            # build roms.
$ make install    # copy roms to ~/roms
```

## Testing

```sh
$ make run        # test default example (fizzbuzz)
```

## API

### Device Labels

All the Varavara device labels are defined for convenience.

### Remote Assembler

* `:asm/setup`: setups a copy of thrift at `:ffe9`, resets the assembler to `0100` and
  jumps to `:ffe9`.
* `:asm/set ( addr* -- )`: sets `:asm/pointer_` to an absolute address.
* `:asm/reset ( -- )`: resets `:asm/pointer_` to the default value (`0100`).
* `:asm/get`: gets the current short value of `:asm/pointer_`.
* `:asm/write`: write a byte at `:asm/pointer_` absolute address and increment
  `:asm/pointer_`.

#### Eval


* `:asm/send-len ( length* start* -- )` sends a number of bytes to be evaluated
  as an expression.
* `:asm/send-blk ( start* end*  -- )`: sends a block of bytes to be evaluated as
  an expression.

#### Copy

In order to copy code you have to make sure that absolute addressing is
respected as expected by the code, or that it is patched, it is best to use
relative opcodes to make the code as rellocatable as possible.

* `:asm/copy-len ( length* start* -- )` copies a number of bytes to be assembled
  starting at `:asm/pointer_` absolute address.
* `:asm/copy-blk ( start* end*  -- )`: copies a block of bytes to be assembled
  starting at `:asm/pointer_` absolute address.

## Macros

The **Macros** provide a low lewel API used to create commands in the local
which are then sent to the remote to be executed as "expressions":

* `:quot`: quotes a byte (treating it as a literal to be pushed to the :WST).
* `:unqt`: unquotes a byte (treating it as an opcode to executed immediatly).

```uxntal
@main ( -> )
    #0004 ;:cmd     :asm/send-len   ( :0a :03 )
    ;:mod ;:mod/end :asm/send-blk   ( :01 )
    :DBG
    BRK

@:cmd [ :quot 0a  :quot 03 ]

%:divk { :quot DIVk :unqt }  %:mul { :quot MUL :unqt}  %:sub { :quot SUB :unqt}
@:mod [ :divk :mul :sub ] &end
```

Output:
```
WST 00 00 00 00 00 00 00|01 <01
RST 00 00 00 00 00 00 00 00|<00
```

Originally there were macros like `:divk` for each opcode, but the drifblim
assembler does not support the creation of that many macros.

Notice that each byte must be quoted independently.

## Remote Pseudo Opcodes

These routines provide a higer level API for evaluating expressions on the
remote:

```uxntal
@main ( -> )
    [ :LIT2 0a03 ] :MOD   ( :01 )
    :DBG
    BRK

@:MOD ( :a :b -- :(a%b) ) :DIVk :MUL !:SUB
```

Output:
```
WST 00 00 00 00 00 00 00|01 <01
RST 00 00 00 00 00 00 00 00|<00
```

Remember all remote pseudo opcodes are routines, so you can jump to them at tail
position: `!:SUB` vs `:SUB JMP2r`.

### Unimplemented Remote Pseudo Opcodes

Relative opcodes don't make sense when evaluating using the thrift VM, since
unquoting is done at the same absolute address each time, which is why only
absolute addressing is supported in expressions.

#### Immediate Opcodes

* `:JCI`: use `:JCN2` instead.
* `:JMI`: use `:JMP2` instead.
* `:JSI`: use `:JSR2` instead.

#### Noop Opcodes

Only `:POPk` is implemented, and well, it does nothing as you would expect.

* `:POPkr`:  use `:POPk` instead.
* `:POP2k`:  use `:POPk` instead.
* `:POP2kr`: use `:POPk` instead.
* `:NIPk`:   use `:POPk` instead.
* `:NIP2k`:  use `:POPk` instead.
* `:NIPkr`:  use `:POPk` instead.
* `:NIP2kr`: use `:POPk` instead.

#### Relative Opcodes

* `:JMP`:    use `:JMP2`   instead.
* `:JMPk`:   use `:JMP2k`  instead.
* `:JCN`:    use `:JCN2`   instead.
* `:JCNk`:   use `:JCN2k`  instead.
* `:JSR`:    use `:JSR2`   instead.
* `:JSRk`:   use `:JSR2k`  instead.
* `:LDR`:    use `:LDA`    instead.
* `:LDRk`:   use `:LDAk`   instead.
* `:LDR2r`:  use `:LDA2r`  instead.
* `:LDR2kr`: use `:LDA2kr` instead.
* `:STR`:    use `:STA`    instead.
* `:STRk`:   use `:STAk`   instead.
* `:STR2r`:  use `:STA2r`  instead.
* `:STR2kr`: use `:STA2kr` instead.
