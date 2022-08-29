# Purpose

Build and import a pfSense image for usage on AWS using Hashicorp Packer with Virtualbox.

# Information
This Instructions are to build a pfSense 2.4.5 version to Virtualbox, if you need another version please check the tags of this repository, the master branch must to have the last version tested.

Feel free to send recommendations, bugfixes like issues in this repository.

# License
Unlicense

# Prerequisites
* Packer installed: https://www.packer.io/downloads
* Virtualbox or qemu instaled
* A pfSense-CE-2.4.5-RELEASE-amd64.iso iso image from <http://mirror.transip.net/pfsense/downloads/>
* aws-cli installed and configured 

# Instructions
* Download a copy of the pfSense image `pfSense-CE-2.4.5-RELEASE-amd64.iso` to the `input/` directory and then run `packer build pfsense-vbox.json`.
* `remote-vbox-rdp.sh` can be used to view the build process. Do not manually press keys during viewing.
* Created images are placed in the `output-vbox/` directory.
* `aws/import-role/import-role.sh` contains the required roles for the AWS import processes. Policies need to be modified to match your AWS account.
* `aws/ec2-snapshot.sh` is prepeared for importing the created image to AWS. Need to be adjusted to meet your configuration.
* Create an EC2 Instance from the imported image. Before starting it, attach a second network interface (ENI) to the instance, otherwise pfSense will not come up properly.

Depending on the build machine and available resources it might be necessary to adjust timings in the jsons for the keystrokes. This files build nicely on a NVME backed setup.


# Configuration
This pfSense config.xml contains the following modifications in `config/config.xml` compared to stock config:

  * disabled dhcpd and dhcpdv6 (on LAN interface)
  * Webinterface listens on port 7373
  * OpenSSH listens on port 6736
  * allow Webinterface and OpenSSH traffic on WAN interface from ANY source 
  * allow private network connections on WAN interface (for packer & testing)
  * disable HTTP_REFERERCHECK for accessing WebInterface through ANY ip/dns
  * enabled login on console

As soon as your instance is up and running, __update the settings to suit your needs__!

# Post Install

* The default disk of this image is 4GB, if you want more space when the ec2 is created choose more disk, for example 10GB and when boot login into a shell <https://chowdera.com/2022/144/202205242139158040.html>:

    swapoff -a
    gpart delete -i 2 ada0s1
    gpart resize -i 1 ada0
    gpart resize -i 1 -s 9000M ada0s1
    gpart add -t freebsd-swap ada0s1
    growfs /

To increase the disk space and reboot.

* The ssh user is root and his default password is pfsense
* The webconfig user is admin and his default password is pfsense
* Please change the password after login
