People often use gdb to debug user mode applications, which is a convenient debugging means. It's also possible to use gdb to debug linux kernel and drivers with the help of kgdb. [This page](http://kernel.org/doc/htmldocs/kgdb.html) is a good tutorial for how to use kgdb.

# Benefits of using gdb to debug kernel
- It helps us understanding linux internals. In linux, it's very common to see structures with a lot of function pointer members being passed around. And it's not easy to find out where and how these function pointers are actually called by reading code. By setting breakpoint on the function, we can easily find how linux call into it.
- It saves the debugging time. If we only debug by printk, we usually have to compile and deploy linux kernel multiple times to fix a minor bug. It's more efficient to debug if we can step through the code and see all variables' value in real time.

# Preparations
As the precedent document illustrates, to enable kgdb for a kernel, we need to:
- Enable kernel config options for kgdb
- Provide a kgdb I/O driver
- Set linux boot argument to instruct linux kernel use our kgdb I/O driver

# How to implement a kgdb I/O driver
To implement a kgdb I/O driver, we need to implemen poll_get_char and poll_put_char callbacks in the UART driver. These callbacks will be called by the kgdb to communicate with gdb. Linux contains a good example for us to follow in [8250.c](http://lxr.free-electrons.com/source/drivers/tty/serial/8250/8250.c#L1836).

# How to debug if there is only one serial port
kgdb is designed to work when there is only one serial port on our board. The serial port can be used as primary console as well as the communication channel with gdb. In this case, we should first connect our serial port client (e.g., [kermit](http://www.columbia.edu/kermit/)) to the console and input 'echo g > /proc/sysrq-trigger' command to break into linux kernel. Now linux should halt and wait for a gdb client to connect. Then we exit the serial port client process and start a gdb client to connect to the linux on the same serial port.  It's time-division multiplexing on the serial port. 
The [agent-proxy](http://git.kernel.org/pub/scm/utils/kernel/kgdb/agent-proxy.git) make the process even easier. agent-proxy is a tty to tcp connection mux that allow us connect more than one client application to a tty. By using it, we can run the serial port client and gdb process simultaneously.

# How to debug linux initialization code

# How to debug module

