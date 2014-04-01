My Udev Notify
==============
Show notifications when **any** USB device is plugged/unplugged.

[!notification](http://i.stack.imgur.com/UQogN.png)

It is tested on Linux Mint 13, Ubuntu 12.04, Ubuntu 13.04.
I believe it will work on any systems with udev.


Installation
------------

 - unpack archive somewhere in your system
 - copy file ./stuff/my-udev-notify.rules  to  /etc/udev/rules.d
 - modify paths in it: change "/path/to/my-udev-notify/my-udev-notify.sh" to
   real path to the my-udev-notify.sh script (where you unpacked it).

After this, it should work for newly attached devices. That is, if you unplug
some device, you won't get notification. But when you plug it back, you will.
(yes, for me it works without any udev restarting. If it doesn't for you, try
rebooting)

To make it work for all devices, just reboot your system. NOTE that there will
be many notifications during first boot (see known issues below). On second
boot, there will be no notifications (unless you plug in new device when
system is off)


Customization
-------------

   There is example configuration file:
      ./stuff/config_example/my-udev-notify.conf 

   Valid locations are:
      /etc/my-udev-notify.conf   (system-wide)
      ~/.my-udev-notify.conf     (per-user)

   So you can copy it to some of these locations and modify for your needs.

Known issues
------------

 - There are notifications during first boot, and later if user plugs
   device when system is off. If anyone knows how can I check in
   bash script if system is booted already, let me know.

