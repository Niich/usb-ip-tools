Scripts and notes for setting up usbip and auto mounting devices on boot

Referances 
https://sleeplessbeastie.eu/2022/03/14/how-to-share-usb-device-over-network/
https://derushadigital.com/other%20projects/2019/02/19/RPi-USBIP-ZWave.html

Install usbip

`sudo apt install linux-tools-common`

or

`sudo apt install usbip`

install dependancies if needed

`sudo apt install linux-tools-generic linux-cloud-tools-generic`

add Kernal moduals

```
cat <<EOF | sudo tee /etc/modules-load.d/usbip.conf
usbip_core
usbip_host
vhci_hcd
EOF
```

reload moduals

`sudo systemctl restart systemd-modules-load.service`

add the service unit files to /etc/systemd/system/

register the services

`sudo systemctl daemon-reload`

find usb device id that you want to use.

`lsusb`

enable host services

`sudo systemctl enable --now usbipd.service`

`sudo systemctl enable --now usbip-bind@<usb device id>.service

note: you need to register a usbip-bind service for each device you want to make available

enable client services




