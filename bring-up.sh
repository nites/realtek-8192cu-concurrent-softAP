#Script to kill any existing hostapd, dhcps, wpa_supplicant, dhcpd, dnsmasq etc then bring up AP and Client
killall wpa_supplicant hostapd dnsmasq dhcpd
ifdown wlan1
ifup wlan1
dhcpd wlan1
hostapd -B /etc/hostapd/hostapd.conf
ifdown wlan0
wpa_supplicant -B -iwlan0 -Dwext -c/etc/wpa_supplicant.conf
ifup wlan0
