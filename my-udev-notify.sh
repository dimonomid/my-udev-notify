#!/bin/bash

# thanks:
#     - to guys from linux.org.ru;
#     - to 'iptable' user from ##linux at irc.freenode.net.

# test command: 
#     sudo /bin/bash my-udev-notify -a add -p 'test_path' -b '555' -d '777'

# get path to this script
DIR="$(dirname $(readlink -f "$0"))"

# set default options {{{

# file for storing list of currently plugged devices
devlist_file="/var/tmp/udev-notify-devices"

show_notifications=true
notification_icons=true

play_sounds=true
use_espeak=false

plug_sound_path="$DIR/sounds/plug_sound.wav"
unplug_sound_path="$DIR/sounds/unplug_sound.wav"
# }}}

# read config file {{{
{
   if [ -r /etc/my-udev-notify.conf ]; then
      . /etc/my-udev-notify.conf
   fi
   #if [ -r ~/.my-udev-notify.conf ]; then
      #. ~/.my-udev-notify.conf
   #fi
}
# }}}

# retrieve options from command line {{{

# action: "add" or "remove"
action=

# dev_path: path like /devices/pci0000:00/0000:00:1d.0/usb5/5-1
dev_path=

# bus number and device number:
# they are needed since device is also stored at /dev/bus/usb/<bus_num>/<dev_num>
bus_num=
dev_num=

while getopts a:p:b:d: opt; do
  case $opt in
  a)
      action=$OPTARG
      ;;
  p)
      dev_path=$OPTARG
      ;;
  b)
      bus_num=$OPTARG
      ;;
  d)
      dev_num=$OPTARG
      ;;
  esac
done

shift $((OPTIND - 1))
# }}}

get_device_icon()
{
   local dev_data=`echo "$1" | sed 's/###/\n/g' | grep -e 'bInterfaceClass' -A 2 -m 1 | cut -d ' ' -f 2,3,4,5,6,7,8,9 | tr -s ' ' '_'`
   
   OLD_IFS=$IFS
   IFS="
"
   local dev_array=($dev_data)
   IFS=$OLD_IFS
   
   local    class=${dev_array[0]}
   local subclass=${dev_array[1]}
   local protocol=${dev_array[2]}
   
   case "$class:$subclass:$protocol" in
      Audio:* )
         dev_icon="audio-card"
      ;;
      
      Communications:Abstract* )
         dev_icon="modem"
      ;;
      
      Communications:Ethernet* )
         dev_icon="network-wired"
      ;;
   
      Human_Interface_Device:*:Keyboard )
         dev_icon="input-keyboard"
      ;;
      
      Human_Interface_Device:*:Mouse )
         dev_icon="input-mouse"
      ;;
      
      Mass_Storage:RBC:* )
         dev_icon="media-removable"
      ;;
      
      Mass_Storage:Floppy:* )
         dev_icon="media-floppy"
      ;;
      
      Mass_Storage:SCSI:* )
         dev_icon="media-removable"
      ;;
      
      Printer:* )
         dev_icon="printer"
      ;;
      
      Hub:* )
         dev_icon="emblem-shared"
      ;;
      
      Video:* )
         dev_icon="camera-web"
      ;;
      
      Xbox:Controller:* )
         dev_icon="input-gaming"
      ;;
      
      Wireless:Radio_Frequency:Bluetooth )
         dev_icon="bluetooth"
      ;;
      
      *)
         dev_icon="dialog-information"
      ;;
   esac
}

show_visual_notification()
{
   # TODO: wait for 'iptable' user from ##linux to say how to do it better
   #       or, at least it's better to use 'who' command instead of 'w', 
   #       because 'who' echoes display number like (:0), and echoes nothing if no display,
   #       which is more convenient to parse.

   local header=$1
   local text=$2

   if [[ notification_icons == true ]]; then
      get_device_icon "$text"
   else
      dev_icon=''
   fi
   
   text=`echo "$text" | sed 's/###/\n/g'`

   declare -a logged_users=(` who | grep "(.*)" | sed 's/^\s*\(\S\+\).*(\(.*\))/\1 \2/g' | uniq | sort`)

   if [[ ${#logged_users[@]} == 0 ]]; then
      # it seems 'who' doesn't echo displays, so let's assume :0 (better than nothing)
      declare -a logged_users=(`who | awk '{print $1" :0"}' | uniq | sort`)
   fi

   for (( i=0; i<${#logged_users[@]}; i=($i + 2) )); do
      cur_user=${logged_users[$i + 0]}
      cur_display=${logged_users[$i + 1]}

      export DISPLAY=$cur_display
      su $cur_user -c "notify-send -i '$dev_icon' '$header' '$text'"
   done
}

sound_or_speak()
{
   local soundfile=$1
   local speaktext=$2
   
   
   if [[ $use_espeak == true ]]; then
      if [[ "$speaktext" != "" ]]; then
         /usr/bin/espeak "$speaktext" &
      fi
   else
      if [[ -r "$soundfile" ]]; then
         /usr/bin/play -q "$soundfile" &
      fi
   fi
}

# notification for plugged device {{{
notify_plugged()
{
   local dev_title=$1
   local dev_name=$2

   if [[ $show_notifications == true ]]; then
      #notify-send "device plugged" "$dev_title" &
      show_visual_notification "device plugged" "$dev_title"
   fi
   
   if [[ $play_sounds == true ]]; then
      sound_or_speak "$plug_sound_path" "Device plugged: $dev_name"
   fi
}
# }}}

# notification for unplugged device {{{
notify_unplugged()
{
   local dev_title=$1
   local dev_name=$2

   if [[ $show_notifications == true ]]; then
      #notify-send "device unplugged" "$dev_title" &
      show_visual_notification "device unplugged" "$dev_title"
   fi
   
   if [[ $play_sounds == true ]]; then
      sound_or_speak "$unplug_sound_path" "Device unplugged: $dev_name"
   fi
}
# }}}

{
   # we need for lock our $devlist_file
   exec 200>/var/lock/.udev-notify-devices.exclusivelock
   flock -x -w 10 200 || exit 1
   case $action in

      "reboot" )
         rm $devlist_file
         ;;

      "add" )
         # ------------------- PLUG -------------------

         if [[ "$bus_num" != "" && "$dev_num" != "" ]]; then

            # Retrieve device title. Currently it's done just by lsusb and grep.
            # Not so good: if one day lsusb change its output format, this script
            # might stop working.
            dev_title="$(lsusb -v -s $bus_num:$dev_num | awk '/ Device /{if($1=="Bus")print ":<b>" substr($0, index($0,$5)) "</b>"}; /bInterfaceClass|bInterfaceProtocol/{print "<b>" $1 ":</b> " substr($0, index($0,$3)) }' ORS='###')"
            dev_name="$(lsusb -v -s $bus_num:$dev_num |  grep -Po "(?<=idProduct\ {10}0x\S{4} ).*")"

            # Sometimes we might have the same device attached to different bus_num or dev_num:
            # in this case, we just modify bus_num and dev_num to the current ones.
            # At least, it often happens on reboot: during previous session, user plugged/unplugged
            # devices, and dev_num is increased every time. But after reboot numbers are reset,
            # so with this substitution we won't have duplicates in our devlist.
            escaped_dev_path=`echo "$dev_path" | sed 's/[\/&*.^$]/\\\&/g'`
            sed -i "s#^\([0-9]\{3\}:\)\{2\}\($escaped_dev_path\)#$bus_num:$dev_num:$dev_path#" $devlist_file

            # udev often generates many events for the same device
            # (I still don't know how to write udev rule to prevent it)
            # so we need to check if this device is already stored in our devlist file
            existing_dev_on_bus_cnt=`cat $devlist_file | grep "^$bus_num:$dev_num:" | awk 'END {print NR}'`

            if [[ $existing_dev_on_bus_cnt == 0 ]]; then
               # this device isn't stored yet in the devlist, so let's write it there.
               echo "$bus_num:$dev_num:$dev_path title=\"$dev_title\"" >> $devlist_file
               echo "$bus_num:$dev_num:$dev_path name=\"$dev_name\"" >> $devlist_file

               # and, finally, notify the user.
               notify_plugged "$dev_title" "$dev_name"
            fi
         fi
         ;;

      "remove" )
         # ------------------- UNPLUG -------------------

         # Unfortunately, udev doesn't emit bus_num and dev_num for "remove" events,
         # and there's even no vendor_id and product_id.
         # But it emits dev_path. So we have to maintain our own plugged devices list.
         # Now we retrieve stored device title from our devlist by its dev_path.
         dev_title=`cat $devlist_file | grep "$dev_path " | grep 'title="' | sed 's/.*title=\"\(.*\)\".*/\1/g'`
         dev_name=`cat $devlist_file | grep "$dev_path " | grep 'name="' | sed 's/.*name=\"\(.*\)\".*/\1/g'`

         # remove that device from list (since it was just unplugged)
         cat $devlist_file | grep -v "$dev_path " > ${devlist_file}_tmp
         mv ${devlist_file}_tmp $devlist_file

         # if we have found title, then notify user, after all.
         if [[ "$dev_title" != "" ]]; then
            notify_unplugged "$dev_title" "$dev_name"
         fi
         ;;

   esac

   #unlock $devlist_file
   flock -u 200
}



