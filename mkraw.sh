#!/bin/bash

echo -e "Save as?\nUse full path."
read -e save
echo -e "\n"

echo -e "Select the raw device.\nUse full path."
read -e device
echo -e "\n"

VBoxManage internalcommands createrawvmdk -filename $save.vdmk -rawdisk $device

