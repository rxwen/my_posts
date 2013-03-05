I bought a [raspberrypi](http://www.raspberrypi.org/) to try some interseting ideas on. 

![raspberry_pi_image](http://farm9.staticflickr.com/8526/8516031760_b89b6e03bd.jpg)

raspberrypi provides several images for [downloading](http://www.raspberrypi.org/downloads), but they are too large and exceeds my needs. My desired raspberrypi image should meet:

1. fully customizing capabilities on kernel and user applications
1. python support
1. standard c&c++ libiaries
1. serial port communication with peripheral devices

Luckily, [here](https://github.com/nezticle/RaspberryPi-BuildRoot) is a buildroot project customized for raspberrypi. With buildroot, all my requirements can be easily satisfied. So I [forked](https://github.com/rxwen/RaspberryPi-BuildRoot) from the repository and made some changes, to make the targe image minimal.

1. disable Qt5 library
1. disable boost library
1. change kernel to the [official one](https://github.com/raspberrypi/linux) maintained by raspberrypi team

To build the target image, run commands below:

    cp configs/raspberry_simple_defconfig .config
    make

After the build is finished. I just need to copy the output/build/linux-rpi-3.6.y/arch/arm/boot/Image to kernel.img on boot partition on the sd card, and untar output/images/rootfs.tar to root filesystem partition. 

Power on, and now raspberry pi should be running our own system.
