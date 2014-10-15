simployer
=========

## Overview

This vagrant bootstrap script is intended to help create minimally configured Debian-family Linux machine (Ubuntu, in the most cases).

## Prerequisites
  
  1. VT-x / AMD-V support (typically enabled in BIOS/UEFI shell)
  2. Oracle Virtualbox 4.3.XX from [here](https://www.virtualbox.org/wiki/Downloads)
  3. Vagrant from [here](https://www.vagrantup.com/downloads.html)

## Usage

The only thing you need to create a portable deployment procedure via Vagrant is a Vagrant file. This repo contains a simplified template of such a file.
To make the Vagrant file valid, just replace the placeholders with real values:

* `__BOX__` -- image ([box](https://docs.vagrantup.com/v2/boxes.html)) of the machine to deploy: e.g. ubuntu/trusty64.
* `__HOST_NAME__` -- name of your server
* `__GUEST_PORT__` -- TCP-port of the guest machine forwarded to a TCP-port of the host machine
* `__HOST_PORT__` -- corresponding TCP-port of the host machine
