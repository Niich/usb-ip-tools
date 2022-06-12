apt-get update
apt-get install linux-tools-generic linux-cloud-tools-generic linux-tools-common -y

cat <<EOF | sudo tee /etc/modules-load.d/usbip.conf
usbip_core
usbip_host
vhci_hcd
EOF

systemctl restart systemd-modules-load.service

cp -v ./*.service /etc/systemd/system/
cp -v ./usbip-service-helper.sh /var/local/

chmod +x /var/local/usbip-service-helper.sh

systemctl daemon-reload

systemctl enable --now usbipd.service
