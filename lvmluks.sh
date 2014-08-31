#!/bin/bash

# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ''AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
# EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Written by cCore@freenode


if [ "$(whoami)" != 'root' ]; then
        echo 'Run as root.'
        exit 1;
fi
ls -l /dev/[sh]d[a-z]
read -e -p 'Select the disk you want to prepare for luks and lvm: ' disk
read -p 'Would you like to fill the disk with random data? [Y/N]' fill
if [ fill = 'y' ];
then
	dd if=/dev/urandom of=$disk
fi
read -n1 -r -p "Ready to partition the disk. Press any key to continue..."
fdisk $disk <<EOF
d
4
d
3
d
2
d
1
n
p
1

+100M
a
1
n
p
2


t
2
8e
w
EOF
clear
fdisk $disk -l
echo -e '\nDone partitioning\nLets encrypt some 1s and 0s\n'
part='2'
diskpart=$disk$part
cryptsetup -s 256 -y luksFormat $diskpart
sleep 2
cryptsetup luksOpen $diskpart crypt
pvcreate /dev/mapper/crypt
read -p 'Would you like to name your volume group? Default: vgenc [Y/N]' askvg
if [ $askvg = 'y' ];
then
	read -p 'Enter then name of your new volume group: ' volumename
		vgcreate $volumename /dev/mapper/crypt
fi
read -p 'Chose your root partition size. eg. 10G/1024M: ' root
	lvcreate -L $root -n root vgenc
read -p 'Chose your home partition size. eg. 10G/1024M: ' home
	lvcreate -L $home -n home vgenc
read -p 'Chose your swap partition size. eg. 10G/1024M: ' swap
	lvcreate -L $swap -n swap vgenc
read -p 'Would you like to create additional partitions? [Y/N]' ask
while [ $ask = 'y' ];
do
	read -p 'Enter the mountpoint of your partition. eg. var: ' newpart
	read -p 'Enter your '$newpart' partition size. eg. 10G/1024M: ' newsize
	lvcreate -L $newsize -n $newpart vgenc
	read -p 'Add more? [Y/N]' ask
done
vgscan --mknodes
vgchange -ay
if [ -e '/dev/vgenc/' ];
then
	mkswap /dev/vgenc/swap
else
	mkswap /dev/$volumename/swap
fi
cryptsetup luksDump $disk
echo -e '\nAll done.\nYou can now run setup.'
