# packer-ubuntu

[![CircleCI](https://img.shields.io/circleci/project/pwasiewi/packer-ubuntu.svg?maxAge=2592000)](https://circleci.com/gh/pwasiewi/packer-ubuntu)

packer template to build Ubuntu Server images

vagrant images are available at [42n4 vagrant account](https://app.vagrantup.com/42n4/boxes/ubuntu).

## Building Images

To build images, simply run:

```
git clone https://github.com/pwasiewi/packer-ubuntu
cd packer-ubuntu
export VAGRANT_CLOUD_TOKEN=the token string taken from Vagrant https://app.vagrantup.com/settings/security
packer build -only=virtualbox-iso template.json
```

If you want to build only virtualbox, vmware or qemu, but now only virtualbox one works with ceph.

```
packer build -only=virtualbox-iso template.json
packer build -only=vmware-iso template.json
packer build -only=qemu template.json
```

## Setting up the ubuntu cluster (START FOR BEGINNERS!)
Next, try to execute it in a new directory:  

```
#vagrant destroy -f          #remove ALL previous instances
#vagrant box add 42n4/ubuntu #add new box
#vagrant box update          #update the old box in order to make 3 hosts
wget https://raw.githubusercontent.com/pwasiewi/packer-ubuntu/master/Vagrantfile.3hosts -O Vagrantfile
sed -i 's/192.168.0/192.168.<your local net number>/g' Vagrantfile
sed -i 's/enp0s31f6/eth0/g' Vagrantfile # you change the host bridge name if it is not 'enp0s31f6'
#in MSWin it gives you names: VBoxManage.exe list bridgedifs
#:bridge => "Intel(R) Ethernet Connection (2) I219-V",
vagrant up
vagrant ssh server1
```

### In M$Windows: https://www.sitepoint.com/getting-started-vagrant-windows/ - you use putty after converting with puttygen a vagrant openssh key to a putty key

![Screen](https://github.com/pwasiewi/packer-proxmox/blob/master/picture/win10connectionwithvagranthost.png)

Login to the server1 root account 

```
sudo su -
```

and execute:

```
va_hosts4ssh server
va_ceph_init
va_ceph_create
[ ! -d /mnt/mycephfs ] && mkdir /mnt/mycephfs
mount -t ceph `ifconfig enp0s8 | grep inet\ | awk '{print $2}'`:6789:/ /mnt/mycephfs -o name=admin,secret=`cat /etc/ceph/ceph.client.admin.keyring | grep key | cut -f 2 | sed 's/key = //g'`
#ceph disk tests, where -s file size in MB, -r RAM in MB (defaults: 8192 and all available memory)
free && sync && echo 3 > /proc/sys/vm/drop_caches && free
bonnie++ -s 2048 -r 1024 -u root -d /mnt/mycephfs -m BenchClient
```

## Release setup

Vagrant images at [Vagrant](https://app.vagrantup.com) are released by [Circle CI](https://circleci.com/).
setup instructions are the following:

1. Sign up
  - [Vagrant](https://app.vagrantup.com/account/new)
  - [Circle CI](https://circleci.com/signup).
2. Get API token
  - [Vagrant](https://app.vagrantup.com/settings/security)
  - [Circle CI](https://circleci.com/account/api)
3. Create new build configuration at [Vagrant](https://app.vagrantup.com/boxes/new)
  and [generate token](https://app.vagrantup.com/settings/security).
4. Create project at [Circle CI](https://circleci.com/add-projects)
5. Add Vagrant environment variables to Circle CI project:
  
  ```console
  $ VAGRANT_CLOUD_TOKEN={{ your vagrant api token here }}
  $ CIRCLE_USERNAME={{ your circle ci username here }}
  $ CIRCLE_PROJECT={{ your circle ci project here }}
  $ CIRCLE_TOKEN={{ your circle ci token here }}
  $ CIRCLE_ENVVARENDPOINT="https://circleci.com/api/v1/project/$CIRCLE_USERNAME/$CIRCLE_PROJECT/envvar?circle-token=$CIRCLE_TOKEN"
  $ json="{\"name\":\"VAGRANT_CLOUD_TOKEN\",\"value\":\"$VAGRANT_CLOUD_TOKEN\"}"
  $ curl -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d "$json" "$CIRCLE_ENVVARENDPOINT"
  ```
  
6. Edit circle.yml

## License

[![CC0](http://i.creativecommons.org/p/zero/1.0/88x31.png "CC0")](http://creativecommons.org/publicdomain/zero/1.0/deed)

dedicated to public domain, no rights reserved.
