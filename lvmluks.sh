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

echo -e 'Select the disk you want to prepare for luks and lvm'
ls -l /dev/[sh]d[a-z]
read -e disk

echo -e 'Would you like to fill the disk with random data?\nNOTE: This will take a while! But offers better cryptoanalytical integrity.\nY/N?'
read = fill
	if [ fill = 'y' ]; then
	dd if=/dev/urandom of=$disk
fi

echo -e '\nNow we will use fdisk to partition the drive and create 2 partitions.'
echo -e '1st partition will be used as /boot and will not be encrypted.'
echo -e '2nd partition will be the remainder of the disk, and we will use this for the lvm encrypted part.\n'
read -n1 -r -p "Press any key to continue..."
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
disk=$disk$part

cryptsetup -s 256 -y luksFormat $disk
sleep 2
cryptsetup luksOpen $disk crypt
pvcreate /dev/mapper/crypt

echo -e '\nWould you like to set your own name on the volume group?\nIf not, i will create one called vgcrypt\nY/N?'
	read -e askvg
if [ $askvg = 'y' ]; then
	echo -e 'Enter then name of your new volume group.'
	read volumename
		vgcreate vgcrypt /dev/mapper/crypt
fi
echo -e Chose your root partition size. eg. 10G/1024M
	read -r root
		lvcreate -L $root -n root vgenc
echo -e Chose your home partition size. eg. 10G/1024M
	read -r home
		lvcreate -L $home -n home vgenc
echo -e Chose your swap partition size. eg. 10G/1024M
	read -r swap
		lvcreate -L $swap -n swap vgenc

echo -e '\nWould you like to create additional partitions?\nY/N'
read -e ask
while [ $ask = 'y' ]; do
	echo -e 'Enter the mountpoint of your partition. eg. var'
		read -e part1
	echo -e 'Enter your '$part1' partition size. eg. 10G/1024M'
		read -e size1
		lvcreate -L $size1 -n $part1 vgenc
	echo -e 'Add more?\nY/N'
		read -e ask
done

vgscan --mknodes
vgchange -ay
mkswap /dev/vgenc/swap

echo -e '\nAll done.\nYou can now run setup.'
