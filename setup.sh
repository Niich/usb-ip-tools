apt install linux-tools-generic linux-cloud-tools-generic linux-tools-common -y

cat <<EOF | sudo tee /etc/modules-load.d/usbip.conf
usbip_core
usbip_host
vhci_hcd
EOF

systemctl restart systemd-modules-load.service

cp ./*.service /etc/systemd/system/

systemctl daemon-reload

systemctl enable --now usbipd.service
