###############################################################################################
#Uruchamiam Cepha na 3 maszynach vagrant 
###############################################################################################
#TUTAJ JEST SKRYPT Z FUNKCJAMI DO GŁÓWNEGO SKRYPTU
#curl https://pastebin.com/raw/FMxYTYhF | sed 's/\r//g' > VAskryptglownyCentos.txt
#curl https://pastebin.com/raw/2y9B4KhW | sed 's/\r//g' > VAskryptglownyUbuntu.txt 
#curl https://pastebin.com/raw/GQF1MwtB | sed 's/\r//g' > VAskryptglownyMiniUbuntu.txt 
#curl https://pastebin.com/raw/Ey6qHu37 | sed 's/\r//g' > VAskryptglownyProxmox.txt 
#curl https://pastebin.com/raw/xYGzrccq | sed 's/\r//g' > VAdocker4all.txt 
###############################################################################################
#FUNKCJE DO TEGO SKRYPTU W OSOBNYM SKRYPCIE
#curl https://pastebin.com/raw/anHdueta | sed 's/\r//g' > VAskryptfunkcje.sh
#sh VAskryptfunkcje.sh

###############################################################################################
#ssh nie pyta o klucze
[ ! -d ~/.ssh ] && mkdir ~/.ssh
echo StrictHostKeyChecking no >> ~/.ssh/config
###############################################################################################
#SKRYPT TWORZY MASZYNĘ WIRTUALNĄ
#CreateVM <OS_NAME> <VBOX_OS> <VB_DIR> <VM_ISO_IMAGE>
#CreateVM "Centos73" "RedHat_64" "/mnt/dc/VBox/" "/mnt/dc/IMAGES/CentOS-7-x86_64-Minimal-1611.iso"
cat << 'EOF' > /usr/local/bin/VACreateVM
VM=$1
VBOS=$2
VBFOLDER=$3
ISO4VM=$4
DISK_SIZE=$5
[ -z $DISK_SIZE ] && DISK_SIZE=8192
[ ! -d $VBFOLDER ] && mkdir -p $VBFOLDER
cd $VBFOLDER
VMFOLDER="${VBFOLDER}/${VM}"
echo VBoxManage controlvm $VM poweroff
VBoxManage controlvm $VM poweroff
sleep 5
echo VBoxManage unregistervm --delete $VM
VBoxManage unregistervm --delete $VM 
echo VBoxManage createvm --name $VM --register
VBoxManage createvm --name $VM --register
echo VBoxManage createhd --filename ${VMFOLDER}/${VM}_1.vdi --size $DISK_SIZE
VBoxManage createhd --filename ${VMFOLDER}/${VM}_1.vdi --size $DISK_SIZE
echo VBoxManage createhd --filename ${VMFOLDER}/${VM}_2.vdi --size 8192
VBoxManage createhd --filename ${VMFOLDER}/${VM}_2.vdi --size 8192
#VBoxManage list ostypes
echo VBoxManage modifyvm $VM --ostype $VBOS
VBoxManage modifyvm $VM --ostype $VBOS 
echo VBoxManage modifyvm $VM --cpus 2 --memory 2048 --acpi on --x2apic on --vram 128 --accelerate3d on --graphicscontroller vboxvga
VBoxManage modifyvm $VM --cpus 2 --memory 2048 --acpi on --x2apic on --vram 128 --accelerate3d on --graphicscontroller vboxvga
#VBoxManage modifyvm $VM --audio alsa --audiocontroller ac97
echo VBoxManage storagectl $VM --name IDE --add ide --controller PIIX4 --bootable on
VBoxManage storagectl $VM --name IDE --add ide --controller PIIX4 --bootable on
echo VBoxManage storageattach $VM --storagectl IDE --port 0 --device 0 --type dvddrive --tempeject on --medium $ISO4VM
VBoxManage storageattach $VM --storagectl IDE --port 0 --device 0 --type dvddrive --tempeject on --medium $ISO4VM
echo VBoxManage storagectl $VM --name SATA --add sata --controller IntelAhci --bootable on
VBoxManage storagectl $VM --name SATA --add sata --controller IntelAhci --bootable on
echo VBoxManage storageattach $VM --storagectl SATA --port 1 --device 0 --type hdd --medium ${VMFOLDER}/${VM}_1.vdi --discard on --nonrotational on
VBoxManage storageattach $VM --storagectl SATA --port 1 --device 0 --type hdd --medium ${VMFOLDER}/${VM}_1.vdi --discard on --nonrotational on
echo VBoxManage storageattach $VM --storagectl SATA --port 2 --device 0 --type hdd --medium ${VMFOLDER}/${VM}_2.vdi --discard on --nonrotational on
VBoxManage storageattach $VM --storagectl SATA --port 2 --device 0 --type hdd --medium ${VMFOLDER}/${VM}_2.vdi --discard on --nonrotational on
echo VBoxManage modifyvm $VM --ioapic on
VBoxManage modifyvm $VM --ioapic on
echo VBoxManage modifyvm $VM --boot1 dvd --boot2 disk --boot3 none --boot4 none
VBoxManage modifyvm $VM --boot1 dvd --boot2 disk --boot3 none --boot4 none
echo VBoxManage modifyvm $VM --nic1 nat --nictype1 82540EM --cableconnected1 on
VBoxManage modifyvm $VM --nic1 nat --nictype1 82540EM --cableconnected1 on
#echo VBoxManage modifyvm $VM --nic2 bridged  --nictype2 82540EM --bridgeadapter2 enp0s31f6 --cableconnected2 on
#VBoxManage modifyvm $VM --nic2 bridged  --nictype2 82540EM --bridgeadapter2 enp0s31f6 --cableconnected2 on
EOF
chmod 755 /usr/local/bin/VACreateVM

###############################################################################################
#ZMIEŃ ISO i przekierowanie portów na eth0
cat << 'EOF' > /usr/local/bin/VAChangeVMStorage  
VM=$1
echo VBoxManage storageattach $VM --storagectl IDE --port 0 --device 0 --type dvddrive --medium none
VBoxManage storageattach $VM --storagectl IDE --port 0 --device 0 --type dvddrive --medium none
#sprawdź wersję Virtualbox i pobierz właściwą płytę VBoxGuestAdditions.iso
[ ! -f /mnt/dc/IMAGES/VBoxGuestAdditions.iso ] && wget http://download.virtualbox.org/virtualbox/5.1.18/VBoxGuestAdditions_5.1.18.iso -O /mnt/dc/IMAGES/VBoxGuestAdditions.iso
echo VBoxManage storageattach $VM --storagectl IDE --port 0 --device 0 --type dvddrive --medium /mnt/dc/IMAGES/VBoxGuestAdditions.iso
VBoxManage storageattach $VM --storagectl IDE --port 0 --device 0 --type dvddrive --medium /mnt/dc/IMAGES/VBoxGuestAdditions.iso
#przekierowanie portów
echo VBoxManage modifyvm $VM --natpf1 delete guestssh
VBoxManage modifyvm $VM --natpf1 delete guestssh
echo VBoxManage modifyvm $VM --natpf1 "guestssh,tcp,,2222,,22"
VBoxManage modifyvm $VM --natpf1 "guestssh,tcp,,2222,,22"
EOF
chmod 755 /usr/local/bin/VAChangeVMStorage 

#PODAJ POSORTOWANE ROZMIARY ZAINSTALOWANYCH PAKIETÓW 
cat << 'EOF' > /usr/local/bin/va_prpmsize  
rpm -qa --queryformat '%10{size} - %-25{name} \t %{version}\n' | sort -n
EOF
chmod 755 /usr/local/bin/va_prpmsize  

###############################################################################################
#WYGENERUJ MAC DLA VIRTUALBOXA 
cat << 'EOF' > /usr/local/bin/va_genmac
echo /etc/hostname `date` |md5sum|sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/020027\3\4\5/'
EOF
chmod 755 /usr/local/bin/va_genmac

###############################################################################################
#NA KONCIE VAGRANT ZRÓB SSHD
cat << 'EOF' > /usr/local/bin/va_ssh4vagrant
#ssh-keygen -t rsa -b 2048 -N '' -f ~/.ssh/id_rsa
[ ! -d ~/.ssh ] && mkdir ~/.ssh
echo StrictHostKeyChecking no >> ~/.ssh/config
wget https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub -O ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chown -R vagrant:vagrant ~/.ssh
EOF
chmod 755 /usr/local/bin/va_ssh4vagrant

###############################################################################################
#ZAKTUALIZUJ VM CENTOSA
cat << 'EOF' > /usr/local/bin/va_update_vmcentos
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
echo StrictHostKeyChecking no >> ~/.ssh/config
yum install -y epel-release
rpm -Uvh http://download.ceph.com/rpm-jewel/el7/noarch/ceph-release-1-1.el7.noarch.rpm
#https://apt.puppetlabs.com/
#https://www.digitalocean.com/community/tutorials/how-to-install-puppet-4-in-a-master-agent-setup-on-centos-7
rpm -Uvh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
#http://www.itzgeek.com/how-tos/linux/centos-how-tos/setup-chef-12-centos-7-rhel-7.html
#http://linoxide.com/linux-how-to/chef-workstation-server-node-centos-7/
yum install -y deltarpm
yum update -y && yum upgrade -y
yum install -y vim ansible nmap sg3_utils wget nano bash-completion ceph-deploy puppetserver puppet ansible sysbench iperf bonnie++ gcc bzip2 make kernel-devel-`uname -r`  net-tools ntp ntpdate ntp-doc traceroute pssh
[ -f /etc/ansible/hosts ] && mv /etc/ansible/hosts /etc/ansible/hosts.orig -f
echo "[web]" > /etc/ansible/hosts
#echo server1 >> /etc/ansible/hosts
#echo server2 >> /etc/ansible/hosts
#echo server3 >> /etc/ansible/hosts
echo 'ansible all -s -m shell -a "$1"' > /usr/local/bin/ae
chmod 700 /usr/local/bin/ae
ntpdate 0.us.pool.ntp.org
hwclock --systohc
systemctl enable ntpd && systemctl start ntpd
curl ix.io/client > /usr/local/bin/ix
chmod +x /usr/local/bin/ix
groupadd admin
usermod -G admin vagrant
echo 'Defaults    env_keep += "SSH_AUTH_SOCK"' >> /etc/sudoers
echo '%admin ALL=NOPASSWD: ALL' >> /etc/sudoers
sed -i 's/ONBOOT=no/ONBOOT=yes/g' /etc/sysconfig/network-scripts/ifcfg-enp0s3
echo NM_CONTROLLED=yes >> /etc/sysconfig/network-scripts/ifcfg-enp0s3
#Instaluje sterowniki Virtualbox
[ ! -d /mnt/dvd ] && mkdir /mnt/dvd
mount -t iso9660 -o ro /dev/sr0 /mnt/dvd
cd /mnt/dvd
./VBoxLinuxAdditions.run
su - vagrant /usr/local/bin/va_ssh4vagrant
yum erase -y kernel kernel-devel
yum clean all
cd 
curl https://pastebin.com/raw/FMxYTYhF | sed 's/\r//g' > VAskryptglownyCentos.txt
curl https://pastebin.com/raw/anHdueta | sed 's/\r//g' > VAskryptfunkcje.sh
sh VAskryptfunkcje.sh
EOF
chmod 755 /usr/local/bin/va_update_vmcentos

###############################################################################################
cat << 'EOF' > /usr/local/bin/Vagrantfile.3Centos
servers=[
  {
    :hostname => "server1",
    :ip => "192.168.2.11",
    :bridge => "enp0s31f6",
    #:box => "42n4/centos73_1611",
	:box => "vCentos73",
    :ram => 2048,
    :cpu => 2,
    :mac => "02002751a1bc"
  },
  {
    :hostname => "server2",
    :ip => "192.168.2.12",
    :bridge => "enp0s31f6",
    #:box => "42n4/centos73_1611",
	:box => "vCentos73",
    :ram => 2048,
    :cpu => 2,
    :mac => "0200272864d1"
  },
  {
    :hostname => "server3",
    :ip => "192.168.2.13",
    :bridge => "enp0s31f6",
    #:box => "42n4/centos73_1611",
	:box => "vCentos73",
    :ram => 2048,
    :cpu => 2,
    :mac => "020027092383"
  }
]
Vagrant.configure(2) do |config|
    servers.each do |machine|
        config.vm.define machine[:hostname] do |node|
            node.vm.box = machine[:box]
            node.vm.hostname = machine[:hostname]
            node.vm.network "public_network", bridge: machine[:bridge] ,ip: machine[:ip], mac: machine[:mac]
            node.vm.provider "virtualbox" do |vb|
                vb.customize ["modifyvm", :id, "--memory", machine[:ram]]
                vb.customize ["modifyvm", :id, "--nic2", "bridged",  "--nictype2", "82540EM", "--bridgeadapter2", machine[:bridge], "--cableconnected2", "on" ]
            end
        end
    end
  # default router
  config.vm.provision "shell",
    run: "always",
    inline: "route add default gw 192.168.2.1"
  # delete default gw on enp0s3 (eth0)
  config.vm.provision "shell",
    run: "always",
    inline: "eval `route -n | awk '{ if ($8 ==\"enp0s3\" && $2 != \"0.0.0.0\") print \"route del default gw \" $2; }'`"
end
EOF

###############################################################################################
cat << 'EOF' > /usr/local/bin/Vagrantfile.3Ubuntu
$ip01="71"
$ip02="72"
$ip03="73"
#in MSWin it gives you names: VBoxManage.exe list bridgedifs
#$bridge = "Intel(R) Ethernet Connection (2) I219-V"
$bridge = "enp0s31f6"
#$bridge="wlp3s0"
#$box = "42n4/UbuntuServerYakkety"
$box="42n4/ubuntu"
$net="192.168.0."
servers=[
  {
    :hostname => "server1",
    :ip => $net+$ip01,
    :bridge => $bridge,
    :box => $box,
    :ram => 2048,
    :cpu => 2,
    :mac => "02002751a1bc"
  },
  {
    :hostname => "server2",
    :ip => $net+$ip02,
    :bridge => $bridge,
    :box => $box,
    :ram => 2048,
    :cpu => 2,
    :mac => "0200272864d1"
  },
  {
    :hostname => "server3",
    :ip => $net+$ip03,
    :bridge => $bridge,
    :box => $box,
    :ram => 2048,
    :cpu => 2,
    :mac => "020027092383"
  }
]
Vagrant.configure(2) do |config|
    servers.each do |machine|
        config.vm.define machine[:hostname] do |node|
            node.vm.box = machine[:box]
            node.vm.hostname = machine[:hostname]
            node.vm.network "public_network", bridge: machine[:bridge] ,ip: machine[:ip], mac: machine[:mac]
	    #node.vm.network "forwarded_port", guest: 8006, host: 8006 if machine[:hostname] == "server1"
            node.vm.provider "virtualbox" do |vb|
                vb.customize ["modifyvm", :id, "--memory", machine[:ram]]
                vb.customize ["modifyvm", :id, "--nic2", "bridged",  "--nictype2", "82540EM", "--bridgeadapter2", machine[:bridge], "--cableconnected2", "on", "--nicpromisc2", "allow-all" ]
            end
        end
    end
  config.vm.provision "shell",
    run: "once",
    inline: "sed -i 's/192.168.2./"+$net+"/g' /usr/local/bin/va_hosts4ssh && \
    sed -i 's/192.168.2./"+$net+"/g' /usr/local/bin/va_ceph.conf && \
    sed -i 's/ip01=11/ip01="+$ip01+"/g' /usr/local/bin/va_hosts4ssh && \
    sed -i 's/ip02=12/ip02="+$ip02+"/g' /usr/local/bin/va_hosts4ssh && \
    sed -i 's/ip03=13/ip03="+$ip03+"/g' /usr/local/bin/va_hosts4ssh"
  # default router
  config.vm.provision "shell",
    run: "always",
    inline: "route add default gw "+$net+"1 && \
    eval `route -n | awk '{ if ($8 ==\"enp0s3\" && $2 != \"0.0.0.0\") print \"route del default gw \" $2; }'`"
end
EOF

###############################################################################################
#va_hosts4ssh "server"
cat << 'EOF' > /usr/local/bin/va_hosts4ssh
server=$1
[ -e /usr/bin/parallel-ssh ] && ln -sfn /usr/bin/parallel-ssh /usr/bin/pssh
if [ -n "$server" ]; then    
	#tu wpisuje uzyskane z dhcp ip
	ip01=11
	ip02=12
	ip03=13
	echo "127.0.0.1 localhost localhost.localdomain localhost4 localhost4.localdomain4" > /etc/hosts
	echo "192.168.2.${ip01} ${server}1" >> /etc/hosts
	echo "192.168.2.${ip02} ${server}2" >> /etc/hosts
	echo "192.168.2.${ip03} ${server}3" >> /etc/hosts
	echo "${server}1" >> /etc/ansible/hosts
	echo "${server}2" >> /etc/ansible/hosts
	echo "${server}3" >> /etc/ansible/hosts
 
	ssh-keygen -t rsa -b 2048 -N '' -f ~/.ssh/id_rsa
	echo StrictHostKeyChecking no >> ~/.ssh/config

	#for node in ${server}1 ${server}2 ${server}3; do ssh-copy-id -i $node ; done
	#http://unix.stackexchange.com/a/204986/23303
    echo "root@192.168.2.${ip01}" > ./ips.txt
    echo "root@192.168.2.${ip02}" >> ./ips.txt
    echo "root@192.168.2.${ip03}" >> ./ips.txt
    cat ~/.ssh/id_rsa.pub | pssh -h ./ips.txt -l remoteuser -A -I -i  \
    '                                                                 \
     umask 077;                                                       \
     [ ! -d ~/.ssh ] && mkdir -p ~/.ssh;                              \
	 echo StrictHostKeyChecking no >> ~/.ssh/config;                  \
     afile=~/.ssh/authorized_keys;                                    \
     cat - >> $afile;                                                 \
     sort -u $afile -o $afile                                         \
    '

	scp /etc/hosts root@${server}2:/etc
	scp /etc/hosts root@${server}3:/etc
	scp /etc/ansible/hosts root@${server}2:/etc/ansible
	scp /etc/ansible/hosts root@${server}3:/etc/ansible
	ssh ${server}1 "echo ${server}1 > /etc/hostname"
	ssh ${server}2 "echo ${server}2 > /etc/hostname"
	ssh ${server}3 "echo ${server}3 > /etc/hostname"
else
	echo Server name argument required e.g: va_hosts4centos server
fi 
EOF
chmod 755 /usr/local/bin/va_hosts4ssh

#DODATKOWE DANE DO CEPH.CONF
cat << 'EOF' > /usr/local/bin/va_ceph.conf
mon_pg_warn_max_per_osd = 0
public network = 192.168.2.0/24
#cluster network = 192.168.2.0/24
#Choose reasonable numbers for number of replicas and placement groups.
osd pool default size = 2 # Write an object 2 times
osd pool default min size = 1 # Allow writing 1 copy in a degraded state
osd pool default pg num = 64
osd pool default pgp num = 64
#Choose a reasonable crush leaf type
#0 for a 1-node cluster.
#1 for a multi node cluster in a single rack
#2 for a multi node, multi chassis cluster with multiple hosts in a chassis
#3 for a multi node cluster with hosts across racks, etc.
osd crush chooseleaf type = 1
osd journal size = 200
EOF

#INICJALIZACJA CEPHA
cat << 'EOF' > /usr/local/bin/va_ceph_init
#su - cephuser 
ceph-deploy purge server1 server2 server3
ceph-deploy purgedata server1 server2 server3
ceph-deploy forgetkeys
ceph-deploy new server1 server2 server3
#ceph-deploy install --release jewel --no-adjust-repos server1 server2 server3
#ceph-deploy install --release jewel server1 server2 server3
ceph-deploy install --repo-url http://download.ceph.com/rpm-jewel/el7/ server1 server2 server3
ceph-deploy --overwrite-conf mon create server1
ceph-deploy --overwrite-conf mon create server2
ceph-deploy --overwrite-conf mon create server3
ceph --admin-daemon /var/run/ceph/ceph-mon.server1.asok mon_status
#poczekaj kilka sekund
sleep 5 
cat /usr/local/bin/va_ceph.conf >> ./ceph.conf
scp ./ceph.conf root@server1:/etc/ceph/ceph.conf
scp ./ceph.conf root@server2:/etc/ceph/ceph.conf
scp ./ceph.conf root@server3:/etc/ceph/ceph.conf
 
for i in server1 server2 server3; do ceph-deploy disk zap $i:sdb; done
ae "parted -s /dev/sdb mklabel gpt mkpart primary xfs 0% 100%"
#sprawdź, czy na wszystkich serwerach się wykonało
ceph-deploy gatherkeys server1
ssh server2 ceph-deploy gatherkeys server2
ssh server3 ceph-deploy gatherkeys server3
 
#http://tracker.ceph.com/issues/13833
#ae "chown ceph:ceph /dev/sda2"
for i in server1 server2 server3; do
ceph-deploy --overwrite-conf osd prepare $i:/dev/sdb1; done
 
#poczekać chwilę
for i in server1 server2 server3; do
ceph-deploy --overwrite-conf osd activate $i:/dev/sdb1; done
#sprawdzić "ceph -s", czy osd się dodały
 
#ceph-deploy  --username ceph osd create osd3:/dev/sdb1
ceph-deploy admin server1 server2 server3
ae "chmod +r /etc/ceph/ceph.client.admin.keyring"
ae "systemctl enable ceph-mon.target"
ae "systemctl enable ceph-mds.target"
ae "systemctl enable ceph-osd.target"
ceph -s
EOF
chmod 755 /usr/local/bin/va_ceph_init

#TWORZENIE CEPHA DYSKU
cat << 'EOF' > /usr/local/bin/va_ceph_create
#object storage gateway
ceph-deploy rgw create server1 server2 server3
#cephfs requirements
ceph-deploy mds create server1 server2 server3
ceph osd pool create mypool 1
echo "test data" > testfile
rados put -p mypool testfile testfile
rados -p mypool setomapval testfile mykey myvalue
rados -p mypool getomapval testfile mykey
rados get -p mypool testfile testfile2
md5sum testfile testfile2
ceph osd pool create cephfs_data 32
ceph osd pool create cephfs_metadata 32
ceph fs new cephfs cephfs_metadata cephfs_data
echo [ ! -d /mnt/mycephfs ] && mkdir /mnt/mycephfs
echo mount -t ceph `ifconfig enp0s8 | grep inet\ | awk '{print $2}'`:6789:/ /mnt/mycephfs -o name=admin,secret=`cat /etc/ceph/ceph.client.admin.keyring | grep key | cut -f 2 | sed 's/key = //g'`
echo "free && sync && echo 3 > /proc/sys/vm/drop_caches && free"
echo bonnie++ -s 2048 -r 1024 -u root -d /mnt/mycephfs -m BenchClient
EOF
chmod 755 /usr/local/bin/va_ceph_create


###############################################################################################
#updatuje Ubuntu, dodając pakiety np. ceph-deploy
cat << 'EOF' > /usr/local/bin/va_update_vmubuntu
wget https://apt.puppetlabs.com/puppetlabs-release-pc1-yakkety.deb
dpkg -i puppetlabs-release-pc1-yakkety.deb
apt-get update
apt-get dist-upgrade -y
apt-get install -y ceph-deploy curl iotop vim nano git bash-completion sg3-utils mc ethtool wpagui wireless-tools bonnie++ iperf sysbench ansible ntp ntpdate ntpstat rdate nmap aptitude openssh-server arp-scan gdebi-core puppet-master pssh traceroute debian-goodies wajig
#puppet resource package puppet-master ensure=latest
#apt install -y quota lm-sensors glusterfs-server 
#wget http://prdownloads.sourceforge.net/webadmin/webmin_1.831_all.deb
#gdebi webmin_1.831_all.deb -n
#rm webmin_1.831_all.deb
#curl http://ix.io/pnr > /etc/ntp.conf
ntpdate 0.us.pool.ntp.org
hwclock --systohc
systemctl restart ntp
systemctl enable ntp
ufw status verbose
ufw disable
[ -f /etc/ansible/hosts ] && mv /etc/ansible/hosts /etc/ansible/hosts.orig -f
echo "[web]" > /etc/ansible/hosts
#echo server1  > /etc/ansible/hosts
#echo server2 >> /etc/ansible/hosts
#echo server3 >> /etc/ansible/hosts
echo 'ansible all -s -m shell -a "$1"' > /usr/local/bin/ae
chmod 700 /usr/local/bin/ae
curl ix.io/client > /usr/local/bin/ix
chmod +x /usr/local/bin/ix
sed -i 's/prohibit-password/yes/g' /etc/ssh/sshd_config
#VAGRANT STUFF
useradd -ms /bin/bash vagrant
adduser vagrant users
echo "vagrant:vagrant" | chpasswd
groupadd admin
usermod -G admin vagrant
echo 'Defaults    env_keep += "SSH_AUTH_SOCK"' >> /etc/sudoers
echo '%admin ALL=NOPASSWD: ALL' >> /etc/sudoers
apt-get install -y build-essential 
#Instaluje sterowniki Virtualbox
[ ! -d /mnt/dvd ] && mkdir /mnt/dvd
mount -t iso9660 -o ro /dev/sr0 /mnt/dvd
cd /mnt/dvd
./VBoxLinuxAdditions.run
su - vagrant /usr/local/bin/va_ssh4vagrant
#wajig large
#dpigs
#apt remove -y linux-headers-4.8.0-22 linux-image-4.8.0-22-generic linux-image-extra-4.8.0-22-generic
apt-get -y remove build-essential
apt-get -y autoremove
#dpkg --list | grep "^rc" | cut -d " " -f 3 | xargs sudo dpkg --purge
EOF
chmod 755 /usr/local/bin/va_update_vmubuntu

###############################################################################################
#python docker_netinfo dockername
cat << 'EOF' > /usr/local/bin/docker_netinfo
#!/usr/bin/python2.7
import json
import subprocess
import sys
try:
    CONTAINER = sys.argv[1]
except Exception as e:
    print "\n\tSpecify the container name, please."
    print "\t\tEx.:  script.py my_container\n"
    sys.exit(1)
# Inspecting container via Subprocess
proc = subprocess.Popen(["docker","inspect",CONTAINER],
                      stdout=subprocess.PIPE,
                      stderr=subprocess.STDOUT)
out = proc.stdout.read()
json_data = json.loads(out)[0]
net_dict = {}
for network in json_data["NetworkSettings"]["Networks"].keys():
    net_dict['mac_addr']  = json_data["NetworkSettings"]["Networks"][network]["MacAddress"]
    net_dict['ipv4_addr'] = json_data["NetworkSettings"]["Networks"][network]["IPAddress"]
    net_dict['ipv4_net']  = json_data["NetworkSettings"]["Networks"][network]["IPPrefixLen"]
    net_dict['ipv4_gtw']  = json_data["NetworkSettings"]["Networks"][network]["Gateway"]
    net_dict['ipv6_addr'] = json_data["NetworkSettings"]["Networks"][network]["GlobalIPv6Address"]
    net_dict['ipv6_net']  = json_data["NetworkSettings"]["Networks"][network]["GlobalIPv6PrefixLen"]
    net_dict['ipv6_gtw']  = json_data["NetworkSettings"]["Networks"][network]["IPv6Gateway"]
    for item in net_dict:
        if net_dict[item] == "" or net_dict[item] == 0:
            net_dict[item] = "null"
    print "\n[%s]" % network
    print "\n{}{:>13} {:>14}".format(net_dict['mac_addr'],"IP/NETWORK","GATEWAY")
    print "--------------------------------------------"
    print "IPv4 settings:{:>16}/{:<5}  {}".format(net_dict['ipv4_addr'],net_dict['ipv4_net'],net_dict['ipv4_gtw'])
    print "IPv6 settings:{:>16}/{:<5}  {}".format(net_dict['ipv6_addr'],net_dict['ipv6_net'],net_dict['ipv6_gtw'])
EOF
chmod 755 /usr/local/bin/docker_netinfo


###############################################################################################
#clean docker space
cat << 'EOF' > /usr/local/bin/docker_clean
#!/bin/bash
# remove exited containers:
docker ps -aq --filter status=dead --filter status=exited | xargs -r docker rm -v
docker rm -v $(docker ps -aq -f status=exited)
# remove unused images:
docker images --no-trunc | grep '<none>' | awk '{ print $3 }' | xargs -r docker rmi
# remove unused volumes:
#newer version for docker 1.9
docker volume ls -qf dangling=true | xargs -r docker volume rm
docker rmi $(docker images -qf dangling=true)
#older
#find '/var/lib/docker/volumes/' -mindepth 1 -maxdepth 1 -type d | grep -vFf <(
#  docker ps -aq | xargs docker inspect | jq -r '.[] | .Mounts | .[] | .Name | select(.)'
#) | xargs -r rm -fr
EOF
chmod 755 /usr/local/bin/docker_clean

###############################################################################################
#remove all dockers
cat << 'EOF' > /usr/local/bin/docker_remove
docker rm -f `docker ps -aq`
EOF
chmod 755 /usr/local/bin/docker_remove

###############################################################################################
#network config /etc/network/interfaces
cat << 'EOF' > /usr/local/bin/va_interfaces
auto lo
iface lo inet loopback

auto enp0s3
iface enp0s3 inet static
        address  10.0.2.15
        netmask  255.255.255.0
        gateway  10.0.2.2

iface enp0s8 inet manual

auto vmbr0
iface vmbr0 inet static
        address  192.168.2.71
        netmask  255.255.255.0
        gateway  192.168.2.1
        bridge_ports enp0s8
        bridge_stp off
        bridge_fd 0
EOF

###############################################################################################
#updatuje proxmox
#va_update_proxmox jessie jewel
cat << 'EOF' > /usr/local/bin/va_update_proxmox
DEBIAN=$1
[ -z $1 ] && DEBIAN=stretch
CEPH=$2
[ -z $2 ] && CEPH=luminous
#export HOME=/root
#echo "export HOME=/root" >> $HOME/.bashrc
#echo "export SHELL=/bin/bash" >> $HOME/.bashrc
sed -i 's/#\ You/export SHELL=\/bin\/bash #/g' $HOME/.bashrc
sed -i 's/# alias/alias/g' $HOME/.bashrc
sed -i 's/# export/export/g' $HOME/.bashrc
sed -i 's/# eval/eval/g' $HOME/.bashrc
sed -i 's/# PS1/PS1/g' $HOME/.bashrc
sed -i 's/# unmask/unmask/g' $HOME/.bashrc
. $HOME/.bashrc
echo 'gpg --keyserver pgpkeys.mit.edu --recv-key  "$1"' > /usr/local/bin/pgpkeyadd
echo 'gpg -a --export "$1" | apt-key add -' >> /usr/local/bin/pgpkeyadd
chmod 755 /usr/local/bin/pgpkeyadd
#pgpkey glusterfs
#pgpkeyadd "DAD761554A72C1DF"
echo "deb http://ftp.pl.debian.org/debian $DEBIAN main contrib" > /etc/apt/sources.list
echo "deb http://security.debian.org $DEBIAN/updates main contrib" >> /etc/apt/sources.list
echo "deb http://download.proxmox.com/debian $DEBIAN pve-no-subscription" >> /etc/apt/sources.list
echo "deb http://download.proxmox.com/debian $DEBIAN pvetest" >> /etc/apt/sources.list
sed -i 's/^deb/#deb/g' /etc/apt/sources.list.d/pve-enterprise.list
wget -O - http://download.gluster.org/pub/gluster/glusterfs/3.10/rsa.pub | apt-key add -
echo deb http://download.gluster.org/pub/gluster/glusterfs/LATEST/Debian/$DEBIAN/apt $DEBIAN main > /etc/apt/sources.list.d/gluster.list
apt-get update
apt-get install -y locales dirmngr
sed -i 's/^# pl_PL.UTF/pl_PL.UTF/g' /etc/locale.gen && locale-gen 
update-locale LANG=pl_PL.UTF-8
apt-get dist-upgrade -y
apt-get install -y sudo openssh-server curl iotop vim git lm-sensors sg3-utils mc ethtool wpagui wireless-tools bonnie++ iperf glusterfs-server ansible ntp ntpdate ntpstat rdate aptitude nano git bash-completion sysbench nmap arp-scan gdebi-core pssh traceroute debian-goodies wajig
#curl http://ix.io/nS5 > /etc/ntp.conf
#systemctl stop system-timesync.service;systemctl disable system-timesync.service;systemctl mask #system-timesync.service
#systemctl restart ntp
#systemctl enable ntp
apt-get install quota gdebi-core -y
wget http://prdownloads.sourceforge.net/webadmin/webmin_1.831_all.deb
apt-get install libnet-ssleay-perl libauthen-pam-perl libpam-runtime libio-pty-perl  apt-show-versions -y  
gdebi webmin_1.831_all.deb -n
rm -f webmin_1.831_all.deb
sed -i 's/DEFAULT="quiet"/DEFAULT="quiet intel_iommu=on vfio_iommu_type1.allow_unsafe_interrupts=1 pci=realloc"/g' /etc/default/grub
update-grub
echo "#etc/modules: kernel modules to load at boot time" > /etc/modules
echo vfio              >> /etc/modules
echo vfio_iommu_type1  >> /etc/modules
echo vfio_pci          >> /etc/modules
echo vfio_virqfd       >> /etc/modules
echo "deb http://www.deb-multimedia.org $DEBIAN main non-free" > /etc/apt/sources.list.d/mint.list
apt-get update
apt-get install -y --force-yes deb-multimedia-keyring
apt-get update
apt-get dist-upgrade -y
apt-get autoremove -y
#apt-get install -y mate-desktop-environment xorg lightdm X11vnc
#apt-get install -y firefox-esr-l10n-pl
apt-get install -y openvswitch-switch
#https://serversforhackers.com/an-ansible-tutorial
#http://www.cyberciti.biz/faq/
[ ! -d /etc/ansible ] && mkdir /etc/ansible
[ -f /etc/ansible/hosts ] && mv /etc/ansible/hosts /etc/ansible/hosts.orig -f
echo "[web]" > /etc/ansible/hosts
#echo "192.168.11.5${host01}" >> /etc/ansible/hosts
echo 'ansible all -s -m shell -a "$1"' > /usr/local/bin/ae
chmod 700 /usr/local/bin/ae
[ ! -d /mnt/SambaShare ] && mkdir /mnt/SambaShare
echo "#!/bin/sh -e" > /etc/rc.local
echo "mount /mnt/SambaShare" >> /etc/rc.local
echo "mount -a" >> /etc/rc.local
echo "gluster volume start vol0" >> /etc/rc.local
sed -i 's/exit/\#exit/g' /etc/rc.local
echo "exit 0" >> /etc/rc.local
chmod 755 /etc/rc.local
update-rc.d rc.local defaults
update-rc.d rc.local enable
cat << __EOF__ >  /etc/systemd/system/rc-local.service
[Unit]
 Description=/etc/rc.local Compatibility
 ConditionPathExists=/etc/rc.local
 After=network.target
[Service]
 Type=forking
 ExecStart=/etc/rc.local start
 TimeoutSec=0
 StandardOutput=tty
 RemainAfterExit=yes
 SysVStartPriority=99
[Install]
 WantedBy=multi-user.target
__EOF__
systemctl enable rc-local
/etc/init.d/kmod start  
update-rc.d kmod enable
curl ix.io/client > /usr/local/bin/ix
chmod +x /usr/local/bin/ix
echo "T" | pveceph install -version $CEPH
[ ! -d /etc/ceph ] && mkdir /etc/ceph
ln -sfn /etc/pve/ceph.conf  /etc/ceph/ceph.conf  
#VAGRANT STUFF
useradd -ms /bin/bash vagrant
adduser vagrant users
echo "vagrant:vagrant" | chpasswd
groupadd admin
usermod -G admin vagrant
echo 'Defaults    env_keep += "SSH_AUTH_SOCK"' >> /etc/sudoers
echo '%admin ALL=NOPASSWD: ALL' >> /etc/sudoers
apt install -y pve-headers-`uname -r` build-essential 
#Instaluje sterowniki Virtualbox
[ ! -d /mnt/dvd ] && mkdir /mnt/dvd
mount -t iso9660 -o ro /dev/sr0 /mnt/dvd
cd /mnt/dvd
./VBoxLinuxAdditions.run
su - vagrant /usr/local/bin/va_ssh4vagrant
#wajig large
#dpigs
apt-get remove -y pve-headers-`uname -r` build-essential
apt-get -y autoremove
#dpkg --list | grep "^rc" | cut -d " " -f 3 | xargs sudo dpkg --purge
cd
curl https://pastebin.com/raw/anHdueta | sed 's/\r//g' > VAskryptfunkcje.sh
sh VAskryptfunkcje.sh
curl https://pastebin.com/raw/Ey6qHu37 | sed 's/\r//g' > VAskryptglownyProxmox.txt
EOF
chmod 755 /usr/local/bin/va_update_proxmox

###############################################################################################
cat << 'EOF' > /usr/local/bin/Vagrantfile.3Proxmox
$ip01="71"
$ip02="72"
$ip03="73"
#in MSWin it gives you names: VBoxManage.exe list bridgedifs
#$bridge = "Intel(R) Ethernet Connection (2) I219-V"
$bridge = "enp0s31f6"
#$bridge="wlp3s0"
#$box = "42n4/UbuntuServerYakkety"
$box="42n4/proxmoxbeta"
$net="192.168.0."
servers=[
  {
    :hostname => "server1",
    :ip => $net+$ip01,
    :bridge => $bridge,
    :box => $box,
    :ram => 2048,
    :cpu => 2,
    :mac => "02002751a1bc"
  },
  {
    :hostname => "server2",
    :ip => $net+$ip02,
    :bridge => $bridge,
    :box => $box,
    :ram => 2048,
    :cpu => 2,
    :mac => "0200272864d1"
  },
  {
    :hostname => "server3",
    :ip => $net+$ip03,
    :bridge => $bridge,
    :box => $box,
    :ram => 2048,
    :cpu => 2,
    :mac => "020027092383"
  }
]
Vagrant.configure(2) do |config|
    servers.each do |machine|
        config.vm.define machine[:hostname] do |node|
            node.vm.box = machine[:box]
            node.vm.hostname = machine[:hostname]
            node.vm.network "public_network", bridge: machine[:bridge] ,ip: machine[:ip], mac: machine[:mac]
	    node.vm.network "forwarded_port", guest: 8006, host: 8006 if machine[:hostname] == "server1"
	    node.vm.network "forwarded_port", guest: 8006, host: 8016 if machine[:hostname] == "server2"
	    node.vm.network "forwarded_port", guest: 8006, host: 8026 if machine[:hostname] == "server3"
            node.vm.provider "virtualbox" do |vb|
                vb.customize ["modifyvm", :id, "--memory", machine[:ram]]
                vb.customize ["modifyvm", :id, "--nic2", "bridged",  "--nictype2", "82540EM", "--bridgeadapter2", machine[:bridge], "--cableconnected2", "on", "--nicpromisc2", "allow-all" ]
            end
        end
    end
  config.vm.provision "shell",
    run: "once",
    inline: "mkdir -p /etc/pve/priv && touch /etc/pve/priv/authorized_keys && \
    sed -i 's/192.168.2./"+$net+"/g' /usr/local/bin/va_hosts4ssh && \
    sed -i 's/192.168.2./"+$net+"/g' /usr/local/bin/va_ceph.conf && \
    sed -i 's/ip01=11/ip01="+$ip01+"/g' /usr/local/bin/va_hosts4ssh && \
    sed -i 's/ip02=12/ip02="+$ip02+"/g' /usr/local/bin/va_hosts4ssh && \
    sed -i 's/ip03=13/ip03="+$ip03+"/g' /usr/local/bin/va_hosts4ssh"
  # default router
  config.vm.provision "shell",
    run: "always",
    inline: "route add default gw "+$net+"1 && \
    eval `route -n | awk '{ if ($8 ==\"enp0s3\" && $2 != \"0.0.0.0\") print \"route del default gw \" $2; }'`"
end
EOF
