# ISSISP 2018 Workshop Materials

This repository contains files used in the ISSISP 2018 workshop describing binary lifting using McSema.

## Authentication bypass

[authenticate.c](authenticate.c) contains a simple password-based authentication program.
The program prompts the user to type in their password, and this password is read by the 
`verify_pin` function using the unsafe `gets` C library function, which writes the read pin
into a fixed-size stack buffer.

The `verify_pin` function is vulnerable to a stack-based buffer overflow, which would normally
permit authentication bypass by at least two mechanisms.

### Exploit scenario 1: Overwriting the return address

The return address of `verify_pin` can be modified to return to the `admin_control` function, thus
ignoring the actual validation of the PIN itself, and providing the user with administrative
privileges.

#### Mitigation

A program lifted with McSema operates on two stacks. The compiled form of the lifted program executes
off of the "shadow stack", also referred to as the McSema stack. The lifted program emulates the operations
performed by the original program on the original program's stack, called the native stack.

When the original program makes a function call, a return address is pushed onto the native stack. When
the called function returns, it pops the stored return address, and redirects execution to that address.
When the lifted program emulates a function call, it emulates the push of the return address onto the
native stack, and it calls the lifted target function, which pushes a return address onto the lifted stack.
When the called lifted function returns, it emulates a pop of the return address off of the native stack,
but ignores this value. It pops the return address off of the lifted stack and jumps to that location.

The return address overwrite exploit is therefore mitigated by lifted code because although lifted code
emulates most return address-related operations, it ignores the value of the return address when performing
returns between lifted functions, and trusts whats on the lifted stack.

### Exploit scenario 2: Overwriting `is_admin` in the caller

This exploit scenario is more contrived in the normal unlifted case, but demonstrates how
the ROP mitigation that comes "for free" with lifting means that an attacker just needs to shift their
focus further up the call stack.

The `verify_pin` function updates `*is_admin = true;` when the PIN is correct. `is_admin` is a local
variable in the stack frame of `verify_pin`s caller, `main`. Thus, with a large enough buffer overrun
to the `gets` function, a user can overwrite the return address (which will be ignored by lifted code)
and target `is_admin` for overwriting, storing any non-zero value to that byte.

#### Mitigation

McSema can optionally lift local variables so that they will be "backed" by the lifted stack, and not
the emulated native stack. This mitigates this vulnerability, at the expense of exposing the lifted 
bitcode itself to ROP.

Lifted bitcode can be optionally compiled with a stack protector/guard that will try to detect such
ROP, and it can also be instrumented so that lifted functions can detect ROP on the emulated native
stack.
