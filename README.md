# realtek-8192cu-concurrent-softAP

Some scripts to build and install the Realtek 8192cu driver via dkms, with concurrent mode enabled, allowing simultaneous AP and client mode.  All necessary files including hostapd 2.4 with rtl871xdrv patches and config files for hostapd, dhcpd, /etc/network/interfaces are included.

## Why?

The default firmware-realtek drivers in debian jessie do not support simultaneous AP and client mode.  Similarly, the realtek 8192cu drivers don't support it by default.  So this repository has a (barely) modified verasion of the https://github.com/pvaret/rtl8192cu-fixes driver, and semi-automates the installation of the driver, hostapd, isc-dhcp-server and config files to get a (hopefully) working AP + client combination to save a lot of time and hassle.

The initial directions to enable concurrent mode came from Aid Vllasaliu's excellent blog post here: http://randomstuffidosometimes.blogspot.com/2016/03/rtl8192cu-and-rtl8188cus-in-station-and.html

## Compatibility

Tested under Debian 8.3 Jessie on a Beaglebone Black with 4.1.18 kernel with RTL8192CU chipset.  No guarantees but expected to work on other similar configurations and other hardware such as RPi too. 
Minimum kernel version of 3.11, and dkms support required.

## Pre-requisites

### Ensure you have the necessary prerequisite packages installed:

Note - all commands below generally assume root access is already present.  `sudo su` or login as root before running if not.

Pre-Jessie:

    apt-get update
    apt-get install linux-headers-$(uname -r) build-essential dkms git psmisc libnl-dev

Jessie:

    apt-get update
    apt-get install linux-headers-$(uname -r) build-essential dkms git psmisc libnl-3-dev


### Removal of previous driver modules

If you tried any of the many other excellent repositories which build and install the 8192cu drivers from realtek, there is a good chance you have some other driver modules present, whether they are currently successfully loaded or not.  It is worth checking for these as follows:

First, run `dkms status`.  If any results relating to the 8192cu are present, remove them using the specific package name/version.  Example - if `dkms status` reports: `"8192cu, 1.10: added"` then run `dkms remove 8192cu/1.10 --all`.  Repeat for any other 8192cu related modules.

Secondly, run `find / -name '*8192*.ko'` and delete or back up to another location any 8192cu.ko files which are found.

## Installation

There are two methods of installation.  Option 1 below is recommended.  For those willing to live on the edge, option 2 provides a two statement auto-install which works OK but has no error trapping so is not recommended.

### Installation - Option 1 - recommended

Clone this repository:

    git clone https://github.com/desflynn/realtek-8192cu-concurrent-softAP.git

Make the driver and install via dkms:
    
    cd realtek-8192cu-concurrent-softAP

    #   Note if you prefer to pull the sources from git clone pvaret/rtl8192cu-fixes then run the following lines now (note any version changes, based on 1.10)
    #      rm -rf rtl8192cu-fixes 
    #      git clone https://github.com/pvaret/rtl8192cu-fixes.git

    cd rtl8192cu-fixes
    make
    make install
    cd ..
    dkms add ./rtl8192cu-fixes
    dkms install 8192cu/1.10
    depmod -a
    cp ./rtl8192cu-fixes/blacklist-native-rtl8192.conf /etc/modprobe.d/

Now build and install a version of hostapd with rtl871xdrv support (Note - this removes and replaces the old hostapd present on the system)

    apt-get -y remove hostapd

    #   Note if you prefer to pull the sources from w1.fi and pritambaral/hostapd-rtl871xdrv then run the following lines now:
    #      rm -rf hostapd-rtl871xdrv hostapd-2.4.tar.gz
    #      git clone https://github.com/pritambaral/hostapd-rtl871xdrv.git
    #      wget http://w1.fi/releases/hostapd-2.4.tar.gz

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

Install dhcpd server to provide dhcp on the AP

    apt-get install isc-dhcp-server

Final steps - configuration

Open up the "configs" folder, where there are configuration files for hostapd, dhcpd and etc/network/interfaces.

Check and modify these as necessary.  The config files present should  work out of the box for the following configuration:

    hostapd version 2.4
    dhcpd version 4.3.1 
    ethernet dhcp, wlan0 dhcp (for client) and wlan1 static (for AP)

In hostapd.conf, the configuration is as follows by default:

    #AP SSID: MySoftAP
    #AP password: MyPassword
    #AP IP address: 192.168.12.1
    #AP dhcp range: 192.168.12.10 - 192.168.12.20
    #WPA2 (realtek driver has problems with WPA1)

These and other settings may be altered at this point, or later in /etc/hostapd/hostapd.conf.  If you have a different version of isc-dhcp-server installed or need a different network configuration, you can alter the dhcp.conf and interfaces configs as necessary now before installing.  If you are not sure, leave them alone so you hopefully get a working AP to use as a baseline and can modify as desired later.

Once ready, back up any old configs on the system and replace them with the working set:

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

Finally, reboot.

    sync
    reboot

After reboot, neither AP nor client interface will be up automatically - but connection of these is covered in "Post-install - Connection setup" section below.

### Installation - Option 2 - not recommended but useful for scripted installation

If you used option 1 like suggested, skip on to the post install below.

Warning - this option is not fully tested and is basically just a script which does everything in the "Option 1" section in two commands.  

    git clone https://github.com/desflynn/realtek-8192cu-concurrent-softAP.git && cd realtek-8192cu-concurrent-softAP


Before you run the script, check the configs in the /configs folder as these will be copied to /etc and overwrite any existing configs.

    ./install-realtek-8192cu-concurrent-softAP.sh

Note - there is no validation, debugging, catching errors etc.  No warranties exist for option 2 (nor for option 1 for that matter, but especially option 2!).  It is better to do it manually via option 1 the first time so you can catch any errors encountered as they happen.

## Post-install - Connection setup

To check that the driver installed successfully, run `iwconfig`. It should provide output similar to below.  There should be two wlan interfaces visible - one may be used for the client connection and one for the AP.  I used wlan0 for client and wlan1 for AP, but it should not matter.

    wlan0     unassociated  Nickname:"<WIFI@REALTEK>"
          Mode:Auto  Frequency=2.412 GHz  Access Point: Not-Associated   
          Sensitivity:0/0  
          Retry:off   RTS thr:off   Fragment thr:off
          Encryption key:off
          Power Management:off
          Link Quality=0/100  Signal level=0 dBm  Noise level=0 dBm
          Rx invalid nwid:0  Rx invalid crypt:0  Rx invalid frag:0
          Tx excessive retries:0  Invalid misc:0   Missed beacon:0

    lo        no wireless extensions.

    eth0      no wireless extensions.

    usb0      no wireless extensions.

    wlan1     unassociated  Nickname:"<WIFI@REALTEK>"
          Mode:Auto  Frequency=2.412 GHz  Access Point: Not-Associated   
          Sensitivity:0/0  
          Retry:off   RTS thr:off   Fragment thr:off
          Encryption key:off
          Power Management:off
          Link Quality=0/100  Signal level=0 dBm  Noise level=0 dBm
          Rx invalid nwid:0  Rx invalid crypt:0  Rx invalid frag:0
          Tx excessive retries:0  Invalid misc:0   Missed beacon:0

If not, run `dkms status` and check for a message indicating the driver module is installed.  If you get output like `"#8192cu, 1.10, ... (WARNING! Diff between built and installed module!)"`, it means that there is another module loaded instead of the one we just built.  In this case, double check the "Removal of previous driver modules" section above and then start again!

Before bringing up the wireless interfaces, if you need to create a wpa_supplicant configuration for the client connection, run

    wpa_passprase SSID_To_Connect_To SSID_Password > /etc/wpa_supplicant.conf

### Bring-up code
Then running the following "Bring-up" code will create a softAP and also connect the client.  After running, you can run ifconfig and do some ping tests to verify.  If not, check the hostapd and dhcpd logs.

    killall wpa_supplicant hostapd dnsmasq dhcpd
    ifdown wlan1
    ifup wlan1
    dhcpd wlan1
    hostapd -B /etc/hostapd/hostapd.conf
    ifdown wlan0
    wpa_supplicant -B -iwlan0 -Dwext -c/etc/wpa_supplicant.conf
    ifup wlan0

This can also be done by running ./bring-up.sh in the project root.

## Further steps

At this point you should be able to connect to and ping the AP from another device, and also use the client connection on the BBB/RPI/Host machine simukltaneously.

Note - I have not added any routing to IPTABLES.  So while you will be able to ping your AP you won't get internet.  There are plenty of tutorials on setting up Bridging / Routing elsewhere (I think) so google it!  What this should hopefully give you is a stable base with a simultaneous AP / Client running, on top of which to do whatever else you'd like.

Beyond that - I'm not going to give any further direction on what to do from here.  There are two approaches possible for managing the connections:

1. Disable hostapd, isc-dhcp-server, dnsmasq (if installed) from running at startup and manually start the interfaces.  This could be done by inserting the startup code into a rc5.d script or otherwise.

2. Leave hostapd, isc-dhcp-server start at startup and modify /etc/network/interfaces to have auto wlan0 wlan1.  This did not work for me as the interface was not ready in time for hostapd or isc-dhcp-server, but I am sure with a little tweaking it could be done and fully managed by the system.

For me - doing it via a rc5.d script was enough for my needs.  I may come back and finish option 2 later but no guarantees.

## Notes

Concurrent mode has been enabled in the modified realtek driver in rtl8192cu-fixes/include/autoconf.h - after modification the section looks like:

    #define CONFIG_CONCURRENT_MODE 1
    #ifdef CONFIG_CONCURRENT_MODE
    	#define CONFIG_TSF_RESET_OFFLOAD 1			// For 2 PORT TSF SYNC.
    	#define CONFIG_HWPORT_SWAP				//Port0->Sec , Port1 -> Pri
    	#define CONFIG_STA_MODE_SCAN_UNDER_AP_MODE
    	//#define CONFIG_MULTI_VIR_IFACES //besides primary&secondary interfaces, extend to support more interfaces
    #endif	// CONFIG_CONCURRENT_MODE

## Credits

This repository came out of an excellent blog post by Aid Vllasaliu here: http://randomstuffidosometimes.blogspot.com/2016/03/rtl8192cu-and-rtl8188cus-in-station-and.html along with the modified realtek sources at https://github.com/pvaret/rtl8192cu-fixes and hostapd rebuild script at https://github.com/oblique/create_ap/blob/master/howto/realtek.md and patches from https://github.com/pritambaral/hostapd-rtl871xdrv

