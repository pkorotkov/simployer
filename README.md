simployer
=========

## Overview

This vagrant bootstrap script is intended to help create minimally configured Debian-family Linux machine (Ubuntu, in the most cases).

## Prerequisites
  
  1. Oracle Virtualbox 4.3.XX from [here](https://www.virtualbox.org/wiki/Downloads)
  2. Vagrant from [here](https://www.vagrantup.com/downloads.html)

## Using

The only thing you need to create a portable deployment procedure via Vagrant is a Vagrant file. This repo contains a simplified template of such a file.
To make the Vagrant file valid, just replace the placeholders with real values:

* __BOX__ (e.g. ubuntu/trusty64)
* __HOST_NAME__ (e.g. myserver)
* __HOST_PORT__
* __GUEST_PORT__