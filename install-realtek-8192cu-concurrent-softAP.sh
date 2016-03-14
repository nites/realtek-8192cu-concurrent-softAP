#Make the driver and install via dkms:
echo "--------------------------------------------------------------------------------"
echo "Making the driver with concurrency on and installing via dkms"
echo "--------------------------------------------------------------------------------"
    
cd rtl8192cu-fixes
make
make install
cd ..
dkms add ./rtl8192cu-fixes
dkms install 8192cu/1.10
depmod -a
cp ./rtl8192cu-fixes/blacklist-native-rtl8192.conf /etc/modprobe.d/

#Now build and install a version of hostapd with rtl871xdrv support
echo "--------------------------------------------------------------------------------"
echo "Building and installing a version of hostapd with rtl871xdrv support"
echo "--------------------------------------------------------------------------------"

apt-get -y remove hostapd
tar zxvf hostapd-2.4.tar.gz
cd hostapd-2.4
patch -p1 -i ../hostapd-rtl871xdrv/rtlxdrv.patch
cp ../hostapd-rtl871xdrv/driver_* src/drivers
cd hostapd
cp defconfig .config
echo CONFIG_DRIVER_RTW=y >> .config
echo CONFIG_LIBNL32=y >> .config
make
make install
cd ../..


#Install dhcpd server to provide dhcp on the AP
echo "--------------------------------------------------------------------------------"
echo "Installing isc-dhcp-server to provide dhcp on the AP"
echo "--------------------------------------------------------------------------------"

apt-get install isc-dhcp-server


#Back up any old configs on the system and replace them with the working set:
echo "--------------------------------------------------------------------------------"
echo "Backing up any old configs on the system and replacing them with the working set"
echo "--------------------------------------------------------------------------------"

mv /etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf.bak
mv /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bak
mv /etc/network/interfaces /etc/network/interfaces.bak
mv /etc/default/isc-dhcp-server /etc/default/isc-dhcp-server.bak
mv /etc/default/hostapd /etc/default/hostapd.bak
    
cp ./configs/hostapd.conf /etc/hostapd/hostapd.conf
cp ./configs/dhcpd.conf /etc/dhcp/dhcpd.conf
cp ./configs/interfaces /etc/network/interfaces
cp ./configs/isc-dhcp-server /etc/default/isc-dhcp-server
cp ./configs/hostapd /etc/default/hostapd

echo "--------------------------------------------------------------------------------"
echo "Installation finished - please reboot and then check using iwconfig, dkms"
echo "AP and client can be started by running ./bring-up.sh in project root"
echo "--------------------------------------------------------------------------------"

