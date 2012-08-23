People ofen use gdb to debug user mode applications, which is a convenient debugging means. It's also possible to use gdb to debug linux kernel and drivers with the help of kgdb. [This page](http://kernel.org/doc/htmldocs/kgdb.html) is a good tutorial of how to use kgdb.

# Benefits of using gdb to debug kernel
- It helps us understanding linux internals. In linux, it's very common to see structures with a lot of function pointer members being passed around. And it's not easy to find out where and how these function pointers are actually called by reading code. By setting breakpoint on the function, we can easily find how the linux call into it.
- It saves the debugging time. If we only debug by printk, we usually have to compile and deploy linux kernel multiple times to fix a minor bug. It's more efficient to debug if we can step through the code and see all variables' value in real time.

# Preparations
As the precedent document illustrates, to enable kgdb for a kernel, we need to:
- Enable kernel config options for kgdb
- Provide a kgdb I/O driver
- Set linux boot argument to instruct linux kernel use our kgdb I/O driver


