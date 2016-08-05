My Udev Notify
==============

Show notifications when **any** USB device is plugged/unplugged.

![notification](http://i.stack.imgur.com/UQogN.png)

Honestly, I don't quite understand why this essential feature is not
implemented in major Linux distributions by default. There are notifications
about removable media, but not much more than that: e.g. no notifications about
usb-to-com converters, etc. I really want to know when my devices get
recognized by the system, or disconnected for whatever reason (be it a bad USB
cable connection, or whatever).

Installation
------------

 - Clone the project somewhere;
 - Copy file `./stuff/my-udev-notify.rules` to `/etc/udev/rules.d`;
 - Modify paths in it: change `"/path/to/my-udev-notify/my-udev-notify.sh"` to
   the real path to `my-udev-notify.sh` script (where you cloned it).

After this, it should work for newly attached devices. That is, if you unplug
some device, you won't get notification. But when you plug it back, you will
(yes, for me it works without any udev restarting. If it doesn't for you, try
rebooting).

To make it work for all devices, just reboot your system. Note that there will
be many notifications during the first boot (see known issues below). On the
second boot, there will be no notifications (unless you plug a new device while
the system is off)


Customization
-------------

   There is an example configuration file:
      ./stuff/config_example/my-udev-notify.conf 

   Which you can copy as `/etc/my-udev-notify.conf` and edit as necessary.

Known issues
------------

 - There are notifications during the first boot, and later if user plugs a
   device when the system is off. If anyone knows how can I check in bash
   script if the system is booted already, let me know please.

