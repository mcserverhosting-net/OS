```sh
dd if=/dev/zero of=/srv/uor/flash.img bs=1M count=1000 status=progress
```

The dd command in this example is creating a new disk image called flash.img in the /srv/uor directory. The disk image will be 1 gigabyte in size and will be filled with zeros.



```sh
losetup /dev/loop0 /srv/uor/flash.img
```

The losetup command is used to set up a loop device, which is a virtual block device associated with a regular file or block device. In this case, the losetup command is setting up a loop device called /dev/loop0 that is associated with the /srv/uor/flash.img file. This allows the contents of the flash.img file to be accessed through the /dev/loop0 device.


```sh
gdisk /dev/loop0 << EOF
o
n
1
1
+90%
n
2
1

w
Y
EOF
```

To summarize, the gdisk command in this example creates two partitions on the flash.img disk image, with the first partition being 90% of the disk and the second partition being the remaining 10%. It does this by using the o and n commands to create a new empty partition table and the two partitions, respectively.


partprobe /dev/loop0

The partprobe command informs the Linux kernel of partition table changes on a block device. In this case, it is used to inform the kernel of changes to the /dev/loop0 device and allow the kernel to access the new partitions on the flash.img disk image.

mkfs.fat -F 32 /dev/loop0p1

The mkfs.fat command creates a FAT filesystem on a block device. In this case, it is used to create a FAT32 filesystem on the /dev/loop0p1 device, which enables you to mount the device and access the filesystem using the mount command.

fatlabel /dev/loop0p1 ARCH_202212

mount /dev/loop0p1 /mnt/uor/boot

mkfs.ext4 /dev/loop0p2

mount /dev/loop0p2 /mnt/uor/config

