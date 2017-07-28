# abathur

Abathur is a customized raspberry pi image designed for installing linux over PXE to a networked computer.
This method can potentially be more preferable than install media because the raspberry pi sits between the client computer and the network, allowing for more complex package retreval instructions.


This repo is the home of code pertaining to the bare-metal **disk** provisioning of workstations via network boot.
We have had issues with inconsistent use of install USBs and install disks, so the intention of this is to Destroy All Human's intervention in the install process by automating the install entirely.

## Foreward

PXE is "Preboot Execution Enviornment" and is a way to instruct the BIOS to recieve its boot drive from a networked DHCP server over TFTP (Trivial File Transfer Protocol).
We utilize PXE booting from a directly-connected host machine to send an automated install image to the baremetal pairing station to be installed.
Debian installer provides an interface for automated, unattended installs called "preseeding"; we use this interface to automate baremetal installs and prevent inconsistencies.

## High Level Parts

Overall, these are the moving pieces needed to make the current approach work.
These pieces are extremely tied to the implementation and changing them will require significant rework of the provisioning approach described here.

* DHCP/TFTP PXE server
  - A host capable of connecting directly to the install machine and providing the PXE netboot image
* Modified netboot Debian install image
  - A netboot image capabale of being automated throughout the install
* Workstation set to network boot mode
  - A machine capable of netbooting and following PXE in UEFI mode.

## Low Level Parts

The following is the implementation of this process.
These pieces are largely interchangable with other options in the ecosystem, but will be described for the value they bring to the project and what role they play.

* Raspberry Pi 3B
  - This tiny computer is more than capable of serving LAN assets to PXE booting machines.
    The 3B also has both Wifi and Ethernet, allowing the device to act as a network passthrough for installing machines.
* Raspbian Jessie
  - This is the base image used for Raspberry Pi and it works well for quickly booting the PXE server setup.
    The version of linux doesn't matter much, but staying in the Debian ecosystem is a plus.
* Iptables rules
  - Rules to make the raspberry pi utilize the wifi as it's primary network and offer ethernet as a bridge network to a client machine.
* Dnsmasq / dnsmasq.conf
  - This is a lightweight DNS/DHCP/TFTP/PXE server which provides a majority of our required host functionality.
    There are other servers which could also work for independent pieces, but dnsmasq provides the most complete suite.
* Debian Stretch netboot image
  - UEFIBoot sector
  - initrd.gz initial ramdisk
  - linux kernel
  - grub modules
  - Debian Stretch is currently the Debian Testing image.
    At the time of writing, (May 2017) it is in "Freeze" which is their pre-long-term-stable state.
    This image is capable of PXE in UEFI (and BIOS, but we ignore that) and can be preseeded to automate installs.
* Debian preseed.cfg
  - A preseed file for automating the install of the Debian Stetch image.
    This file will make all of the important choices for a user to prevent snowflake images

In order to make these pieces work together, the preseed.cfg file must be injected into the netboot image's initrd.gz file.
This modified netboot image must be hosted by dnsmasq over TFTP to offer for PXE to the client.
The Raspberry pi network must be setup to enable direct connection over ethernet.
The client must have network boot be its primary boot method (set in BIOS).
The client must support UEFI and have it enabled.
The Raspberry Pi server must be connected to the client machine over a direct ethernet connection and the Pi should be on for approximately 2 minutes before booting the client.


## Usage

1. Ensure the microSD card is installed in the Raspberry Pi
2. Plug the Raspberry Pi power supply in.
   It recieves power through the microUSB port.
   A green light should flash on the back when it is powered sufficiently by a > 2.5A power supply.
3. Plug one end of an ethernet cable into the the Raspberry Pi.
4. Plug the other end of the ethernet cable into the pairing station, on the primary ethernet port.
5. Turn on the pairing station and enter the BIOS (usually this is F1 before it prints a logo).
6. Set the pairing station boot order to use network first (this will need to be set every boot).
   Also take some time to ensure that UEFI mode is set to enabled in the BIOS.
7. Save BIOS changes and restart
8. Allow the machine to boot in PXE mode.
9. Ensure there are no USB or external hard drives plugged into the pairing station. **THESE WILL BE WIPED**
9. Select "Install" at the grub boot menu. **THIS IS YOUR LAST CHANCE TO STOP, EVERYTHING WILL BE WIPED**
10. Allow the install to proceed.
    It may pause for a few questions which require intervention.
    Hostname is one of the notable points where it stops.
    Ensure hostname is descriptive of the team (Do not use team codenames) and unique.
11. When the server reboots, it should boot into a fresh Linux install and the machine can be connected to the network normally.
12. **RETURN THE RASPBERRY PI TO WHOMEVER YOU BORROWED IT FROM**
