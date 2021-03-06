#!/bin/bash
############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "Script to attach and detach usbip devices with systemd service"
   echo
   echo "options:"
   echo "h     Print this Help."
   echo "s     Set Server address"
   echo "u     Set USB ID xxx:xxxx"
   echo "a     Action to perform ATTACH|DETACH"
   echo
}

############################################################
# Main program                                             #
############################################################
############################################################
# Process the input options. Add options as needed.        #
############################################################
# Get the options
while getopts "h:s:u:a:" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      s) # set server address
         ServerAddress=$OPTARG;;
      u) # set USB device id xxxx:xxxx
         USBId=$OPTARG;;
      a) # select action
         Action=$OPTARG;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

# find the usbip path
usbippath=$(which usbip)
echo "action: $Action"

case $Action in
     ATTACH)
        retBusId=$(/usr/lib/linux-tools/$(uname -r)/usbip list -r $ServerAddress | grep $USBId | cut -d: -f1 | xargs)
        echo "Requesting attach to: $USBId \t Returned BusId: $retBusId";
        /bin/bash -c "$usbippath attach -r $ServerAddress -b $retBusId";;
     DETACH)
        port=$(/usr/lib/linux-tools/$(uname -r)/usbip port | sed -rn "/$USBId/{x;p;d;}; x" | grep '<Port in Use>' | sed -E 's/^Port ([0-9][0-9]).*/\1/' | xargs);
        echo "Requested device detach: $USBId \t Returned port: $port";
        /bin/bash -c "$usbippath detach --port=$port";;
     \?)  # Invalid option
        echo "Error: Invalid Action $Action. Valid options are ATTACH | DETACH"
        exit;;
esac
