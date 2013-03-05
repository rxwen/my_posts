The raspberrypi has two usb ports, so I bought a usb wifi dongle to get rid of network cable.

![fast_fw150us](http://farm9.staticflickr.com/8092/8530353671_eda125f75e_q.jpg)

This dongle uses RTL8188CUS chipset, which has built-in support on the raspberrypi linux kernel. So it just worked after I plugged it to raspberrypi.

The next step is to configure the dongle so that it can connect to my wifi router. There is GUI based connection manager if you're using raspbian system image. But in my case, I use a small system image built with built from [builtroot](https://github.com/rxwen/RaspberryPi-BuildRoot/) with only command line interface, I have to setup manually.

I need to enable wireless tools in [buildroot config](https://github.com/rxwen/RaspberryPi-BuildRoot/blob/master/configs/raspberrypi_simple_defconfig), which provides tools such as iwlist, iwconfig. My wifi router, which is configured with dhcp server enabled, doesn't required password to connect. So I can setup the network with commands below:

    ifconfig wlan0 up
    iwconfig wlan0 essid WIFI_ESSID
    udhcpc -i wlan0

Having tested the network run ok, I updated the /etc/network/interfaces file so that network would be setup automatically.

    auto lo
    iface lo inet loopback

    auto eth0
    iface eth0 inet dhcp

    auto wlan0
    iface wlan0 inet dhcp
        pre-up ifconfig $IFACE up
        pre-up iwconfig $IFACE essid WIFI_ESSID
        down ifconfig $IFACE down

