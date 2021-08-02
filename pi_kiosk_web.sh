#!/bin/bash

#   PI-KIOSK (pi_kiosk_web.sh)
#
#   Version 1.0 (2018-05-09)
#   Version 1.1 (2018-05-14)
#   Version 1.2 (2018-05-15)
#   Version 1.3 (2018-05-23)
#   Version 1.4 (2018-05-24)
#   Version 1.5 (2018-05-28)
#   Version 1.6 (2018-05-29)
#   Version 1.7 (2019-02-08)
#   Version 2.0 (2020-01-13)
#   Version 2.1 (2020-06-29)
#   Version 2.2 (2020-06-30)
#   Version 2.3 (2020-07-09)
#   Version 2.4 (2020-08-03)
#   Version 2.5 (2020-08-12)
#   Version 2.6 (2020-08-25)
#   Version 2.7 (2020-08-26)
#   Version 3.0 (2021-08-02)
#
#   PI-KIOSK is a installation script for your Raspberry PI which turns
#   your PI into a kiosk computer.
#
#   Copyright (C) 2018-2021  Klaus Fröhlich [code@sclause.net]
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#   
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#   
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#   

VERSION=3.0
DEMOPAGE=https://sclause.net/pikiosk/demo
SCRIPTPATH="$( cd -- "$(dirname "$0")" > /dev/null 2>&1 ; pwd -P )"

echo "PI-KIOSK"
echo "========"
echo ""
echo "Copyright (C) 2018-2021  Klaus Fröhlich"
echo "This program comes with ABSOLUTELY NO WARRANTY"
echo ""
echo ""


installed()
{
	if [ -f /home/pi/pikioskinstalled ]; then
		echo 1
	else
		echo 0
	fi
}

passwdstandard ()
{
	PWD=$(sudo cat /etc/shadow | grep ^pi | cut -d ':' -f 2)
	DELIM=\\$
	SALT=$DELIM$(echo $PWD | cut -d '$' -f 2)$DELIM$(echo $PWD | cut -d '$' -f 3)$DELIM
	CMD="print crypt(\"raspberry\",\"$SALT\")"
	CHECK=$(perl -e "$CMD")

	if [ "$PWD" = "$CHECK" ]; then
		echo 1
	else
		echo 0
	fi
}

is_maintencance()
{
	if [ -f "/home/pi/maintenance" ]; then
		echo 1
	else
		echo 0
	fi
}

pkginstalled()
{
	INST=`dpkg -s $1 2>/dev/null | grep 'Status: install'`

	if [ -z "$INST" ]; then
		echo 0
	else
		echo 1
	fi
}

pkgremove()
{
	if [ $(pkginstalled $1) = "1" ]; then
		echo -e "\033[0;36mRemoving $1...\033[0m"
		sudo DEBIAN_FRONTEND=noninteractive apt -y purge $1
	else
		echo -e "\033[0;36mRemoving $1: not installed\033[0m"
	fi
}

pkginstall()
{
	if [ $(pkginstalled $1) = "0" ]; then
		echo -e "\033[0;36mInstalling $1...\033[0m"
		sudo DEBIAN_FRONTEND=noninteractive apt -y install --no-install-recommends $1
	else
		echo -e "\033[0;36mInstalling $1: already installed\033[0m"
	fi
}

pkgupdate()
{
	sudo DEBIAN_FRONTEND=noninteractive apt -y update
	sudo DEBIAN_FRONTEND=noninteractive apt -y --fix-broken install
	sudo DEBIAN_FRONTEND=noninteractive dpkg --configure -a
	sudo DEBIAN_FRONTEND=noninteractive apt -y -f install
}

getbrowser()
{
	if [ -f /home/pi/cbrowser ]; then
		BROWSER=$(cat /home/pi/cbrowser)
	else
		BROWSER=luakit
	fi
	if [ -z $BROWSER ]; then
		BROWSER=luakit
	fi
	echo $BROWSER
}

install_pikiosk()
{
	GREEN='\033[1;32m'
	YELLOW='\033[1;33m'
	NC='\033[0m'

	clear
	echo -e "${YELLOW}"
	echo "==========================================="
	echo "= PI-KIOSK will be installed/updated now! ="
	echo "==========================================="
	echo -e "${NC}"

	echo -e "${GREEN}Disable screen blanking${NC}"
	# disable screen blanking
	if [ -f /etc/kbd/config ]; then
		cat /etc/kbd/config | sed -e 's/POWERDOWN_TIME=.*/POWERDOWN_TIME=0/g' > /tmp/kbdconfig
		cat /tmp/kbdconfig | sed -e 's/BLANK_TIME=.*/BLANK_TIME=0/g' > /tmp/kbdconfig2
		sudo rm /etc/kbd/config
		sudo mv /tmp/kbdconfig2 /etc/kbd/config
	fi

	echo -e "${GREEN}Install scripts for environment${NC}"
	sudo mount -o remount,rw /boot

	sudo fsck -y /boot
	sudo fsck -y /


	CMDLINE=`cat /boot/cmdline.txt | grep "consoleblank=0"`
	if [ -z "$CMDLINE" ]; then
		sed '$s/$/ consoleblank=0/' /boot/cmdline.txt >/tmp/cmdline.txt
		sudo cp /boot/cmdline.txt /boot/cmdline.txt.consoleblank.backup
		sudo rm /boot/cmdline.txt
		sudo cp /tmp/cmdline.txt /boot/cmdline.txt
	fi
	CMDLINE=`cat /boot/cmdline.txt | grep " fastboot"`
	if [ -z "$CMDLINE" ]; then
		sed '$s/$/ fastboot/' /boot/cmdline.txt >/tmp/cmdline.txt
		sudo cp /boot/cmdline.txt /boot/cmdline.txt.fastboot.backup
		sudo rm /boot/cmdline.txt
		sudo cp /tmp/cmdline.txt /boot/cmdline.txt
	fi
	CMDLINE=`cat /boot/cmdline.txt | grep "quiet"`
	if [ -z "$CMDLINE" ]; then
		sed '$s/$/ quiet/' /boot/cmdline.txt >/tmp/cmdline.txt
		sudo cp /boot/cmdline.txt /boot/cmdline.txt.quiet.backup
		sudo rm /boot/cmdline.txt
		sudo cp /tmp/cmdline.txt /boot/cmdline.txt
	fi
	CMDLINE=`cat /boot/cmdline.txt | grep "logo.nologo"`
	if [ -z "$CMDLINE" ]; then
		sed '$s/$/ logo.nologo/' /boot/cmdline.txt >/tmp/cmdline.txt
		sudo cp /boot/cmdline.txt /boot/cmdline.txt.nologo.backup
		sudo rm /boot/cmdline.txt
		sudo cp /tmp/cmdline.txt /boot/cmdline.txt
	fi

	CMDLINE=`cat /boot/cmdline.txt | grep "splash"`
	if [ -z "$CMDLINE" ]; then
		sed '$s/$/ splash plymouth.ignore-serial-consoles/' /boot/cmdline.txt >/tmp/cmdline.txt
		sudo cp /boot/cmdline.txt /boot/cmdline.txt.splash.backup
		sudo rm /boot/cmdline.txt
		sudo cp /tmp/cmdline.txt /boot/cmdline.txt
	fi

	#CMDLINE=`cat /boot/config.txt | grep "disable_splash=1"`
	#if [ -z "$CMDLINE" ]; then
	#	sudo sh -c 'echo disable_splash=1 >> /boot/config.txt'
	#fi


	####################
	### INSTALLATION ###
	####################

	echo -e "${GREEN}Set up text only mode${NC}"
	if [ -f /etc/default/grub ]; then
		if [ ! "\$(cat /etc/default/grub | grep GRUB_CMDLINE_LINUX_DEFAULT | cut -c 1)" = "#" ]; then
			sudo sed /etc/default/grub -i -e "s/^GRUB_CMDLINE_LINUX_DEFAULT=/#GRUB_CMDLINE_LINUX_DEFAULT=/"
			sudo sed /etc/default/grub -i -e "s/^#*GRUB_CMDLINE_LINUX=\"\"/GRUB_CMDLINE_LINUX=\"text\"/"
			sudo sed /etc/default/grub -i -e "s/^#*GRUB_TERMINAL=.*/GRUB_TERMINAL=console/"
			sudo update-grub
		fi
	fi
	sudo systemctl set-default multi-user.target
	sudo ln -fs /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@tty1.service
	cat > /tmp/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I \$TERM
EOF
	sudo rm -f /etc/systemd/system/getty@tty1.service.d/autologin.conf
	sudo cp /tmp/autologin.conf /etc/systemd/system/getty@tty1.service.d/autologin.conf
	sudo rm -f /etc/profile.d/boottoscratch.sh
	#sudo raspi-config nonint do_serial 1 1
	#sudo sed -i /boot/cmdline.txt -e "s/console=ttyAMA0,[0-9]\+ //"
	#sudo sed -i /boot/cmdline.txt -e "s/console=serial0,[0-9]\+ //"
	#sudo sed -i /boot/config.txt -e "s/enable_uart\s*=\s*1//"
	#UARTLINE=\`cat /boot/config.txt | grep "enable_uart"\`
	#if [ -z "$UARTLINE" ]; then
	#	echo 'enable_uart=0' | sudo tee --append /boot/config.txt > /dev/null
	#fi
	#sudo sed -i /boot/config.txt -e "s/enable_uart\s*=\s*1/enable_uart=0/"
	sudo systemctl disable console-setup.service
	sudo rm -f /etc/systemd/system/dhcpcd.service.d/wait.conf

	echo -e "${GREEN}Update package list${NC}"
	pkgupdate
	echo -e "${GREEN}Remove obsolete packages${NC}"
#	sudo DEBIAN_FRONTEND=noninteractive dpkg --purge rsyslog
#	pkgremove logrotate
#	pkgremove dphys-swapfile
	pkgremove lightdm
	pkgremove wolfram-engine
	pkgremove sonic-pi
	pkgremove scratch
	pkgremove scratch2
	pkgremove fake-hwclock
	pkgremove python-pygame
	pkgremove minecraft-pi
	pkgremove libreoffice
	echo -e "${GREEN}Update whole system${NC}"
	sudo DEBIAN_FRONTEND=noninteractive apt -y upgrade
	sudo DEBIAN_FRONTEND=noninteractive apt -y dist-upgrade
	sudo DEBIAN_FRONTEND=noninteractive dpkg --configure -a
	sudo DEBIAN_FRONTEND=noninteractive apt -y -f install
	echo -e "${GREEN}Install required packages${NC}"
	if [ -f /home/pi/installssh ]; then
		pkginstall openssh-server
		rm /home/pi/installssh
	fi
	pkginstall matchbox
	pkginstall xorg
	pkginstall x11-xserver-utils
	pkginstall xserver-xorg-legacy
	pkginstall unclutter
	pkginstall xinit
	pkginstall ttf-mscorefonts-installer
	pkginstall fonts-wqy-microhei
	pkginstall ntp
	pkginstall omxplayer
	pkginstall python-serial
	pkginstall plymouth
	pkginstall ntpdate
	pkginstall ntpstat
	if [ -f /home/pi/installbrowser ]; then
		do_changebrowser $(cat /home/pi/installbrowser)
		rm /home/pi/installbrowser
	fi
	echo -e "${GREEN}Clean up installation${NC}"
	sudo DEBIAN_FRONTEND=noninteractive dpkg --configure -a
	sudo DEBIAN_FRONTEND=noninteractive apt -y -f install
	sudo DEBIAN_FRONTEND=noninteractive apt -y --purge autoremove
	sudo DEBIAN_FRONTEND=noninteractive dpkg --configure -a
	sudo DEBIAN_FRONTEND=noninteractive apt -y -f install
	sudo DEBIAN_FRONTEND=noninteractive apt -y --fix-broken install
	REMOVEABLE=$(dpkg -l | grep "^rc" | awk '{print $2}')
	if [ ! -z "$REMOVABLE" ]; then
		sudo DEBIAN_FRONTEND=noninteractive dpkg --purge $REMOVABLE
	fi
	sudo DEBIAN_FRONTEND=noninteractive apt -y autoclean
	sudo DEBIAN_FRONTEND=noninteractive apt -y clean

#	echo -e "${GREEN}Update overlay system${NC}"
#	INITRD=`ls -1 /lib/modules/ | tail -1 | sed -e s/\-.*//g`${INITRD}
#	sudo rm /boot/initrd.img-${INITRD}
#	sudo rm /boot/initrd.img
#	sudo update-initramfs -c -k ${INITRD}
#	sudo mv /boot/initrd.img-${INITRD} /boot/initrd.img

	echo -e "${GREEN}Install KIOSK scripts${NC}"

	sudo usermod -aG tty pi
	sudo usermod -aG video pi

	sudo sed /etc/X11/Xwrapper.config -i -e "s/allowed_users=.*/allowed_users=anybody/"


# write startup wrapper for arduino
	rm /home/pi/arduino.sh
	cat >/home/pi/arduino.sh <<EOF
#!/bin/bash
echo Arduino light initialized
while true; do
	/home/pi/startarduino.sh
	sleep 30
done
EOF
	chmod +x /home/pi/arduino.sh

# write python script for arduino
	rm /home/pi/arduinolight.py
	cat >/home/pi/arduinolight.py <<EOF
#!/usr/bin/env python
import time
import serial
import urllib
import sys

ser = serial.Serial(
	port = '/dev/ttyUSB0',
	baudrate = 1200,
	parity = serial.PARITY_NONE,
	stopbits = serial.STOPBITS_ONE,
	bytesize = serial.EIGHTBITS,
	timeout = 1
)

p_link = sys.argv[1]
p_time = int(sys.argv[2])

while 1:
	f = urllib.urlopen(p_link)
	content = f.read()
	ser.write(content)
	time.sleep(p_time)
EOF

# write script for screen off
	cat >/tmp/screen_off <<EOF
#!/bin/bash
echo "Switch screen off"
if [[ \$EUID -ne 0 ]]; then
	echo "Run as root!"
	exit 1
fi
/opt/vc/bin/tvservice -o
echo "[done]"
EOF
	sudo rm /usr/bin/screen_off
	sudo cp /tmp/screen_off /usr/bin/screen_off
	sudo chown root:root /usr/bin/screen_off
	sudo chmod 755 /usr/bin/screen_off

# write script for screen on
	cat >/tmp/screen_on <<EOF
#!/bin/bash
echo "Switch screen on"
if [[ \$EUID -ne 0 ]]; then
	echo "Run as root!"
	exit 1
fi
echo Screen resolution script by: http://blogs.wcode.org/2013/09/howto-boot-your-raspberry-pi-into-a-fullscreen-browser-kiosk/
# Wait for the TV-screen to be turned on...
TRY=0
if [ ! -f /opt/vc/bin/tvservice ]; then
	TRY=11
fi
SCREENOK=True
while ! \$( /opt/vc/bin/tvservice --dumpedid /tmp/edid | fgrep -qv 'Nothing written!' ); do
	((TRY++))
	if [ \$TRY -ge 10 ]; then
		printf "===> ERROR: TIMEOUT. Continue without waiting.\n"
		SCREENOK=False
		break;
	fi
	printf "===> Screen is not connected, off or in an unknown mode, waiting for it to become available...\n"
	printf "\$TRY\n"
	sleep 10;
done;

if [ "\$SCREENOK" = True ]; then
	printf "===> Screen is on, extracting preferred mode...\n"
	if [ -f /home/pi/cdepth ]; then
		_DEPTH=\$(cat /home/pi/cdepth)
	else
		_DEPTH=32
	fi
	eval \$( /opt/vc/bin/edidparser /tmp/edid | fgrep 'preferred mode' | tail -1 | sed -Ene 's/^.+(DMT|CEA) \(([0-9]+)\) ([0-9]+)x([0-9]+)[pi]? @.+/_GROUP=\1;_MODE=\2;_XRES=\3;_YRES=\4;/p' );

	printf "===> Resetting screen to preferred mode: %s-%d (%dx%dx%d)...\n" \$_GROUP \$_MODE \$_XRES \$_YRES \$_DEPTH
	/opt/vc/bin/tvservice --explicit="\$_GROUP \$_MODE"
	sleep 1;

	printf "===> Resetting frame-buffer to %dx%dx%d...\n" \$_XRES \$_YRES \$_DEPTH
	fbset --all --geometry \$_XRES \$_YRES \$_XRES \$_YRES \$_DEPTH -left 0 -right 0 -upper 0 -lower 0;
fi
sudo killall chromium-browser &>/dev/null
sudo killall chromium &>/dev/null
sudo killall luakit &>/dev/null
sudo killall midori &>/dev/null
sudo killall dillo &>/dev/null
echo "[done]"
EOF
	sudo rm /usr/bin/screen_on
	sudo cp /tmp/screen_on /usr/bin/screen_on
	sudo chown root:root /usr/bin/screen_on
	sudo chmod 755 /usr/bin/screen_on

# write rc.local file

	if [ ! -f /etc/rc.local.backup ]; then
		sudo cp /etc/rc.local /etc/rc.local.backup
	fi
	cat >/home/pi/.bash_profile <<EOF
#!/bin/bash

rm /tmp/testmode 2>/dev/null
sudo setupcon -k --force 2>/dev/null

sudo /usr/bin/screen_on
sudo setterm -powersave off
sudo setterm -powerdown 0

_IP=\$(hostname -I) || true
if [ "\$_IP" ]; then
	printf "===============================\n"
	printf "My IP address is %s\n" "\$_IP"
	printf "===============================\n\n"
fi

echo ""
echo "Waiting for time to be synced..."
sudo /etc/init.d/ntp stop
sudo ntpdate pool.ntp.org
sudo /etc/init.d/ntp start

sudo ntpstat
T=\$?
X=0
#try to sync within 2 minutes - otherwise continue (e.g. if no network)
while [ "\$T" != "0" ] && [ "\$X" -le "120" ]
do
	echo "Waiting (\$X/120)"
	sleep 1
	sudo ntpstat
	T=\$?
	X=\$((X+1))
done

if [ "\$T" != "0" ]; then
	echo "Error while syncing. Time may be not correct!"
else
	echo "Time is synched"
fi

RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ ! -f "/home/pi/maintenance" ]; then
	echo ""
	echo ""
	echo -e "\${GREEN}"
	echo -e "********************"
	echo -e "* PI-KIOSK RUNNING *"
	echo -e "********************"
	echo -e "\${NC}"
	echo ""
	echo ""
	/home/pi/arduino.sh &
	sleep 1
	/home/pi/browser.sh &
	sleep 1
else
	echo ""
	echo ""
	echo ""
	echo -e "\${YELLOW}+++++++++++++++++++++++++++++++++++++"
	echo -e "+ \${BLUE}################################# \${YELLOW}+"
	echo -e "+ \${BLUE}# \${RED}***************************** \${BLUE}# \${YELLOW}+"
	echo -e "+ \${BLUE}# \${RED}* PI-KIOSK MAINTENANCE MODE * \${BLUE}# \${YELLOW}+"
	echo -e "+ \${BLUE}# \${RED}***************************** \${BLUE}# \${YELLOW}+"
	echo -e "+ \${BLUE}################################# \${YELLOW}+"
	echo -e "+++++++++++++++++++++++++++++++++++++"
	echo -e "\${NC}"
	echo ""
	echo ""
fi
EOF

# write splashscreen file
	cat >/tmp/plymouthd.conf <<EOF
[Daemon]
Theme=pikiosk
EOF
	sudo rm /etc/plymouth/plymouthd.conf
	sudo cp /tmp/plymouthd.conf /etc/plymouth/plymouthd.conf

	mkdir /tmp/pikiosktheme
	cat >/tmp/pikiosktheme/pikiosk.plymouth <<EOF
[Plymouth Theme]
Name=pikiosk
Description=PI KIOSK Splash Screen
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/pikiosk
ScriptFile=/usr/share/plymouth/themes/pikiosk/pikiosk.script
EOF
	cat >/tmp/pikiosktheme/pikiosk.script <<EOF
screen_width = Window.GetWidth();
screen_height = Window.GetHeight();

theme_image = Image("splash.png");
image_width = theme_image.GetWidth();
image_height = theme_image.GetHeight();

scale_x = image_width / screen_width;
scale_y = image_height / screen_height;

flag = 1;

if (scale_x > 1 || scale_y > 1)
{
	if (scale_x > scale_y)
	{
		resized_image = theme_image.Scale (screen_width, image_height / scale_x);
		image_x = 0;
		image_y = (screen_height - ((image_height  * screen_width) / image_width)) / 2;
	}
	else
	{
		resized_image = theme_image.Scale (image_width / scale_y, screen_height);
		image_x = (screen_width - ((image_width  * screen_height) / image_height)) / 2;
		image_y = 0;
	}
}
else
{
	resized_image = theme_image.Scale (image_width, image_height);
	image_x = (screen_width - image_width) / 2;
	image_y = (screen_height - image_height) / 2;
}

if (Plymouth.GetMode() != "shutdown")
{
	sprite = Sprite (resized_image);
	sprite.SetPosition (image_x, image_y, -100);
}

message_sprite = Sprite();
message_sprite.SetPosition(screen_width * 0.1, screen_height * 0.9, 10000);

fun message_callback (text) {
	my_image = Image.Text(text, 1, 1, 1);
	message_sprite.SetImage(my_image);
	sprite.SetImage (resized_image);
}

Plymouth.SetUpdateStatusFunction(message_callback);
EOF


	cp $SCRIPTPATH/splash.png /tmp/pikiosktheme/splash.png
	sudo cp -a /tmp/pikiosktheme /usr/share/plymouth/themes/pikiosk

	echo -e "${GREEN}Finalization PI-KIOSK installation${NC}"

	touch /home/pi/pikioskinstalled

	echo ""
	echo ""
	echo ""
	echo -e "${YELLOW}"
	echo "============================="
	echo "= Installation/Update done! ="
	echo "============================="
	echo -e "${NC}"
	do_restart
}


do_killbrowser()
{
	sudo killall chromium-browser &>/dev/null
	sudo killall chromium &>/dev/null
	sudo killall luakit &>/dev/null
	sudo killall midori &>/dev/null
	sudo killall dillo &>/dev/null
}

do_selectbrowser()
{

	MENU=()

	MENU+=("luakit" "Luakit")
	MENU+=("chromium" "Chromium")
	MENU+=("midori" "Midori")
	MENU+=("dillo" "Dillo (no scripts, limited CSS)")

	BROWSER=$(whiptail --menu "Please select the browser you want to use:" 20 60 10 \
		"${MENU[@]}" \
		--title "PI-KIOSK" --backtitle "v $VERSION" --nocancel --notags 3>&1 1>&2 2>&3)

	echo $BROWSER>/home/pi/installbrowser

}

do_changebrowser()
{

	BROWSER=$1

	if [ -z "$BROWSER" ]; then

		BROWSER=$(getbrowser)

		MENU=()

		if [ $(pkginstalled luakit) = "1" ]; then
			MENU+=("luakit" "Luakit (installed)")
		else
			MENU+=("luakit" "Luakit (try to install)")
		fi
		if [ $(pkginstalled chromium-browser) = "1" ] || [ $(pkginstalled chromium) = "1" ]; then
			MENU+=("chromium" "Chromium (installed)")
		else
			MENU+=("chromium" "Chromium (try to install)")
		fi
		if [ $(pkginstalled midori) = "1" ]; then
			MENU+=("midori" "Midori (installed)")
		else
			MENU+=("midori" "Midori (try to install)")
		fi
		if [ $(pkginstalled dillo) = "1" ]; then
			MENU+=("dillo" "Dillo (no scripts, limited CSS, installed)")
		else
			MENU+=("dillo" "Dillo (no scripts, limited CSS, try to install)")
		fi

		BROWSER=$(whiptail --menu "Please select the browser you want to use:" 20 60 10 \
			"${MENU[@]}" \
			--default-item $BROWSER \
			--title "PI-KIOSK" --backtitle "v $VERSION" --nocancel --notags 3>&1 1>&2 2>&3)
	fi

	LINK=$DEMOPAGE
	if [ -f /home/pi/clink ]; then
		LINK=$(cat /home/pi/clink)
	fi

	echo $BROWSER>/home/pi/cbrowser
	cat <<EOF >/home/pi/startbrowser.sh
#!/bin/bash
xset -dpms
xset s off
xset s noblank
unclutter &
matchbox-window-manager -use_titlebar no &

LINK=$DEMOPAGE
if [ -f /home/pi/clink ]; then
	LINK=\$(cat /home/pi/clink)
fi

EOF
	case $BROWSER in
		chromium)
			if [ $(pkginstalled chromium) = "0" ] && [ $(pkginstalled chromium-browser) ]; then
				pkgupdate
				pkginstall chromium
				if [ $(pkginstalled chromium) = "0" ]; then
					pkginstall chromium-browser
				fi
				pkginstall chromium-l10n
			fi

			if [ "$(command -v chromium)" = "" ]; then
				C=chromium-browser
			else
				C=chromium
			fi
			echo "$C --noerrdialogs --disable-infobars --user-data-dir=/home/pi/chromium --incognito --kiosk \$LINK" >>/home/pi/startbrowser.sh
			;;
		luakit)
			if [ $(pkginstalled luakit) = "0" ]; then
				pkgupdate
				pkginstall luakit
			fi
			cat <<EOF >/tmp/userconf.lua
local adblock = require "adblock"
adblock.enabled = false

local window = require "window"
window.add_signal("init", function(w)
   w.win.fullscreen = true
end)

local webview = require "webview"
webview.add_signal("init", function(v)
   v:reload()
end)
EOF
			sudo rm /etc/xdg/luakit/userconf.lua
			sudo mv /tmp/userconf.lua /etc/xdg/luakit/
			echo "luakit -u \$LINK" >>/home/pi/startbrowser.sh
			;;
		midori)
			if [ $(pkginstalled midori) = "0" ]; then
				pkgupdate
				pkginstall midori
			fi
			echo "midori -e Fullscreen -a \$LINK" >>/home/pi/startbrowser.sh
			;;
		dillo)
			if [ $(pkginstalled dillo) = "0" ]; then
				pkgupdate
				pkginstall dillo
			fi
			echo "dillo -f \$LINK" >>/home/pi/startbrowser.sh
			;;
	esac
	chmod +x /home/pi/startbrowser.sh

	cat <<EOF >/home/pi/browser.sh
#!/bin/bash

dir()
{
	[ -d /home/pi/\$1 ] && sudo rm -r /home/pi/\$1
	mkdir /home/pi/\$1
	sudo chmod -R 777 /home/pi/\$1
	sudo chown pi:pi /home/pi/\$1
}

BROWSER=\$(cat /home/pi/cbrowser)

while true; do

	while [ "\$1" != "test" ] && [ -f /tmp/testmode ]; do
		sleep 5
	done

	dir \$BROWSER
EOF
if [ $(getbrowser) = "chromium" ]; then
	cat <<EOF >>/home/pi/browser.sh
	touch "/home/pi/chromium/First Run"
	mkdir /home/pi/chromium/Default
	echo '{"translate":{"enabled":false},"browser":{"enable_spellchecking":false}}' > /home/pi/chromium/Default/Preferences
EOF
fi
cat <<EOF >>/home/pi/browser.sh
	sudo chmod 1777 /tmp/.X11-unix
	startx /home/pi/startbrowser.sh
	sudo rm -rf /home/pi/\$BROWSER
	sudo rm -rf /home/pi/.cache
	sudo rm -rf /home/pi/.config
	sudo rm -rf /home/pi/.local
	sudo rm -rf /home/pi/.pki
	sudo rm -rf /home/pi/.fltk
	sudo rm -rf /home/pi/.dillo
	sudo rm -rf /home/pi/.Xauthority
	if [ "\$1" = "test" ]; then
		break
	else
		sleep 30
	fi
done

EOF
	chmod +x /home/pi/browser.sh
}

do_changeweb()
{
	LL=$DEMOPAGE
	if [ -f /home/pi/clink ]; then
		LL=$(cat /home/pi/clink)
	fi

	LINK=$(whiptail --inputbox "Please provide the web address you want to load:" 10 60 "$LL" \
		--title "PI-KIOSK" --backtitle "v $VERSION" --nocancel 3>&1 1>&2 2>&3)
	if [ -z "$LINK" ]; then
		LINK=$DEMOPAGE
	fi

	echo $LINK>/home/pi/clink
}

do_changearduino()
{
	LL=
	if [ -f /home/pi/carduino ]; then
		LL=$(cat /home/pi/carduino)
	fi
	LINKARDUINO=$(whiptail --inputbox "Please provide the ARDUINO web address you want to load:" 10 60 "$LL" \
		--title "PI-KIOSK" --backtitle "v $VERSION" --nocancel 3>&1 1>&2 2>&3)

	LL=1
	if [ -f /home/pi/carduinotime ]; then
		LL=$(cat /home/pi/carduinotime)
	fi

	TIMEARDUINO=1
	if [ ! -z "$LINKARDUINO" ]; then
		TIMEARDUINO=$(whiptail --inputbox "Time for arduino refresh intervall (in seconds):" 10 60 "$LL" \
			--title "PI-KIOSK" --backtitle "v $VERSION" --nocancel 3>&1 1>&2 2>&3)
		if [ -z "$TIMEARDUINO" ]; then
			TIMEARDUINO=1
		fi
	fi
	echo $LINKARDUINO>/home/pi/carduino
	echo $TIMEARDUINO>/home/pi/carduinotime

	cat <<EOF >/home/pi/startarduino.sh
#!/bin/bash
EOF
	if [ ! -z "$LINKARDUINO" ]; then
		echo "python /home/pi/arduinolight.py $LINKARDUINO $TIMEARDUINO" >>/home/pi/startarduino.sh
	fi
	chmod +x /home/pi/startarduino.sh

	MIDO=`ps cax | grep python`
	if [ ! -z "$MIDO" ]; then
		sudo killall python &>/dev/null
	fi
}

do_changecron()
{
	sudo touch /tmp/mycron
	sudo chmod 777 /tmp/mycron
	sudo crontab -l > /tmp/mycron
	CRT=`cat /tmp/mycron | grep "=== MONITOR ==="`
	if [ -z "$CRT" ]; then
		echo "# === MONITOR ===" >> /tmp/mycron
		echo "# Use this lines for automatically switching on/off the monitor." >> /tmp/mycron
		echo "# Attention! Be careful when changing something. You may only change" >> /tmp/mycron
		echo "# the columns Minutes and Hours - do not change the rest." >> /tmp/mycron
		echo "# The first line of each day is for switching on, the second for switching off" >> /tmp/mycron
		echo "# If you do not want to switch the screen add a # at the beginning of the line" >> /tmp/mycron
		echo "# Every monday there is an additional reboot (+ switch screen off)" >> /tmp/mycron
		echo "#" >> /tmp/mycron
		echo "# MINUTES   HOUR    dom mon dow command" >> /tmp/mycron
		echo "# Monday" >> /tmp/mycron
		echo "  0         7       *   *   1   /usr/bin/screen_on" >> /tmp/mycron
		echo "  30        17      *   *   1   /usr/bin/screen_off" >> /tmp/mycron
		echo "# Tuesday" >> /tmp/mycron
		echo "  0         7       *   *   2   /usr/bin/screen_on" >> /tmp/mycron
		echo "  30        17      *   *   2   /usr/bin/screen_off" >> /tmp/mycron
		echo "# Wednesday" >> /tmp/mycron
		echo "  0         7       *   *   3   /usr/bin/screen_on" >> /tmp/mycron
		echo "  30        17      *   *   3   /usr/bin/screen_off" >> /tmp/mycron
		echo "# Thursday" >> /tmp/mycron
		echo "  0         7       *   *   4   /usr/bin/screen_on" >> /tmp/mycron
		echo "  30        17      *   *   4   /usr/bin/screen_off" >> /tmp/mycron
		echo "# Friday" >> /tmp/mycron
		echo "  0         7       *   *   5   /usr/bin/screen_on" >> /tmp/mycron
		echo "  30        15      *   *   5   /usr/bin/screen_off" >> /tmp/mycron
		echo "# Saturday" >> /tmp/mycron
		echo "# 0         7       *   *   6   /usr/bin/screen_on" >> /tmp/mycron
		echo "# 30        17      *   *   6   /usr/bin/screen_off" >> /tmp/mycron
		echo "# Sunday" >> /tmp/mycron
		echo "# 0         7       *   *   0   /usr/bin/screen_on" >> /tmp/mycron
		echo "# 30        17      *   *   0   /usr/bin/screen_off" >> /tmp/mycron
		echo "# Reboot on Monday" >> /tmp/mycron
		echo "  5         0       *   *   1   /sbin/reboot" >> /tmp/mycron
		echo "  10        0       *   *   1   /usr/bin/screen_off" >> /tmp/mycron
	fi
	nano /tmp/mycron
	sudo crontab /tmp/mycron
	sudo rm /tmp/mycron
}

do_setcolordepth()
{
	if [ -f /home/pi/cdepth ]; then
		_DEPTH=$(cat /home/pi/cdepth)
	else
		_DEPTH=$(fbset -s | grep geometry | rev | cut -d ' ' -f 1 | rev)
		echo $_DEPTH>/home/pi/cdepth
	fi

	MENU=()
	MENU+=("8" "8 bit")
	MENU+=("16" "16 bit")
	MENU+=("24" "24 bit")
	MENU+=("32" "32 bit")

	RET=$(whiptail --menu "Please select an option:" 20 60 10 \
		"${MENU[@]}" \
		--default-item $_DEPTH \
		--title "PI-KIOSK" --backtitle "v $VERSION" --nocancel --notags 3>&1 1>&2 2>&3)

	if [ ! "$_DEPTH" = "$RET" ]; then
		echo $RET>/home/pi/cdepth
	fi
}

do_install()
{
	if [ "$(id -u pi)" = "" ]; then
		RET=$(whiptail --msgbox "User PI is not existing on this computer. Cannot continue!" 10 60 \
			--title "PI-KIOSK" --backtitle "v $VERSION" 3>&1 1>&2 2>&3)
		exit 1
	fi

	if [ "$(sudo cat /etc/sudoers | grep ^pi)" = "" ]; then
		RET=$(whiptail --msgbox "User PI is not part of the sudoers groups! This will be changed now." 10 60 \
			--title "PI-KIOSK" --backtitle "v $VERSION" 3>&1 1>&2 2>&3)
		sudo cp /etc/sudoers /tmp/sudoers
		sudo chmod 666 /tmp/sudoers
		echo -e 'pi\tALL=(ALL) NOPASSWD: ALL'>>/tmp/sudoers
		sudo chmod 440 /tmp/sudoers
		sudo cp /tmp/sudoers /etc/sudoers
	fi

	RET=$(whiptail --yesno "Do you want to change some default settings now?\n* Locale\n* Keyboard\n* Timezone" 10 60 \
		--title "PI-KIOSK" --backtitle "v $VERSION" 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		sudo dpkg-reconfigure locales
		sudo dpkg-reconfigure keyboard-configuration
		sudo dpkg-reconfigure tzdata
	fi

	if [ $(passwdstandard) = "1" ]; then
		RET=$(whiptail --yesno "The standard password is still in use for the pi user. This is not recommended. Do you want to change the password now?" 10 60 \
			--title "PI-KIOSK" --backtitle "v $VERSION" 3>&1 1>&2 2>&3)
		if [ $? -eq 0 ]; then
			clear
			sudo passwd pi
		fi
	fi

	dpkg -s openssh-server &> /dev/null
	if [ ! $? -eq 0 ]; then
		RET=$(whiptail --yesno "SSH is not installed. Do you want to install it?" 10 60 \
			--title "PI-KIOSK" --backtitle "v $VERSION" 3>&1 1>&2 2>&3)
		if [ $? -eq 0 ]; then
			touch /home/pi/installssh
		fi
	fi

	if service ssh status | grep -q inactive; then
		RET=$(whiptail --yesno "Do you want to activate SSH?" 10 60 \
			--title "PI-KIOSK" --backtitle "v $VERSION" 3>&1 1>&2 2>&3)
		if [ $? -eq 0 ]; then
			sudo update-rc.d ssh enable
			sudo invoke-rc.d ssh start
		fi
	fi

	do_selectbrowser
	do_changeweb
	do_changearduino
	do_changecron
	install_pikiosk

	exit
}

do_setmaintenance()
{
	if [ ! -f "/home/pi/maintenance" ]; then
		touch /home/pi/maintenance
	fi
	do_restart
}

do_setkiosk()
{
	if [ -f "/home/pi/maintenance" ]; then
		rm /home/pi/maintenance
	fi
	do_restart
}

do_restart()
{
	RED='\033[1;31m'
	echo -e "${RED}"
	echo "============================="
	echo "=   Reboot in 10 seconds.   ="
	echo "============================="
	echo -e "${NC}"
	sleep 10
	rm /tmp/testmode 2>/dev/null
	sudo reboot
	exit
}

do_startbrowser()
{
	RET=$(whiptail --msgbox "Test mode will now start. Press CTRL+ALT+F1 to get back to console." 10 60 \
	--title "PI-KIOSK" --backtitle "v $VERSION" 3>&1 1>&2 2>&3)

	sudo /home/pi/browser.sh test &
	sleep 10
	RET=$(whiptail --msgbox "Press a key to exit test mode" 10 60 \
	--title "PI-KIOSK" --backtitle "v $VERSION" 3>&1 1>&2 2>&3)
	do_killbrowser
}

touch /tmp/testmode
do_killbrowser

while true; do

	MENU=()

	if [ $(installed) = "0" ]; then
		MENU+=("1" "Install PI-KIOSK")
	else
		if [ $(is_maintencance) = "1" ]; then
			MENU+=("7" "Switch to kiosk mode")
		else
			MENU+=("6" "Switch to maintenance mode")
		fi
		MENU+=("2" "Change Web address")
		MENU+=("3" "Change Arduino settings")
		MENU+=("4" "Change Cronjob settings")
		MENU+=("8" "Change color depth (if colors are wrong)")
		MENU+=("1" "Update PI-KIOSK (all settings)")
		MENU+=("12" "Change Browser (currently: $(getbrowser))")
		MENU+=("10" "Test browser")
		MENU+=("11" "Restart browser")
	fi
	MENU+=("9" "Restart computer")
	MENU+=("0" "Exit installer")

	RET=$(whiptail --menu "Please select an option:" 20 60 10 \
		"${MENU[@]}" \
		--title "PI-KIOSK" --backtitle "v $VERSION" --nocancel --notags 3>&1 1>&2 2>&3)


	case "$RET" in
		1) do_install ;;
		2) do_changeweb;;
		3) do_changearduino ;;
		4) do_changecron ;;
		6) do_setmaintenance ;;
		7) do_setkiosk ;;
		8) do_setcolordepth ;;
		9) do_restart ;;
		10) do_startbrowser ;;
		11) do_killbrowser ;;
		12) do_changebrowser ;;
		0) break;
	esac

done

rm /tmp/testmode

clear
echo "PI-KIOSK"
echo "========"
echo ""
echo "Copyright (C) 2018-2021  Klaus Fröhlich"

exit
