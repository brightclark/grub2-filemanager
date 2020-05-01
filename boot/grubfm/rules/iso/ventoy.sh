# Grub2-FileManager
# Copyright (C) 2020  A1ive.
#
# Grub2-FileManager is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Grub2-FileManager is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Grub2-FileManager.  If not, see <http://www.gnu.org/licenses/>.

function get_os_type
{
  set vtoy_os=Linux
  for file in "efi/microsoft" "sources/boot.wim" "boot/bcd" "bootmgr.efi" "boot/etfsboot.com";
  do
    if [ -e $1/$file ];
    then
      set vtoy_os=Windows
      break
    fi
  done
  if [ -n "${vtdebug_flag}" ];
  then
    echo ISO is $vtoy_os
  fi
}

function locate_initrd
{
  vt_linux_locate_initrd
  if [ -n "${vtdebug_flag}" ];
  then
    vt_linux_dump_initrd
    sleep 5
  fi
}

function find_wim_file
{
  unset ventoy_wim_file
  for file in "sources/boot.wim" "sources/BOOT.WIM" "Sources/Win10PEx64.WIM" "boot/BOOT.WIM" "winpe_x64.wim" "x64/sources/boot.wim";
  do
    if [ -e $1/$file ];
    then
      set ventoy_wim_file=$1/$file
      break
    fi
  done
}

function distro_specify_initrd_file
{
  if [ -e (loop)/boot/all.rdz ];
  then
    vt_linux_specify_initrd_file /boot/all.rdz
  elif [ -e (loop)/boot/xen.gz -a -e (loop)/install.img ];
  then
    vt_linux_specify_initrd_file /install.img
  elif [ -d (loop)/casper ];
  then
    if [ -e (loop)/casper/initrd ];
    then
      vt_linux_specify_initrd_file /casper/initrd
    fi
    if [ -e (loop)/casper/initrd-oem ];
    then
      vt_linux_specify_initrd_file /casper/initrd-oem
    fi
  elif [ -e (loop)/boot/grub/initrd.xz ];
  then
    vt_linux_specify_initrd_file /boot/grub/initrd.xz
  elif [ -e (loop)/initrd.gz ];
  then
    vt_linux_specify_initrd_file /initrd.gz
  elif [ -e (loop)/slax/boot/initrfs.img ];
  then
    vt_linux_specify_initrd_file /slax/boot/initrfs.img
  elif [ -e (loop)/pmagic/initrd.img ];
  then
    vt_linux_specify_initrd_file /pmagic/initrd.img
  elif [ -e (loop)/boot/initrd.xz ];
  then
    vt_linux_specify_initrd_file /boot/initrd.xz
  elif [ -f (loop)/boot/initrd ];
  then
    vt_linux_specify_initrd_file /boot/initrd
  elif [ -f (loop)/boot/x86_64/loader/initrd ];
  then
    vt_linux_specify_initrd_file /boot/x86_64/loader/initrd
  elif [ -f (loop)/boot/initramfs-x86_64.img ];
  then
    vt_linux_specify_initrd_file /boot/initramfs-x86_64.img
  fi
}

function distro_specify_initrd_file_phase2
{
  if [ -f (loop)/boot/initrd.img ];
  then
    vt_linux_specify_initrd_file /boot/initrd.img
  elif [ -f (loop)/Setup/initrd.gz ]; then
    vt_linux_specify_initrd_file /Setup/initrd.gz
  fi
}

function uefi_windows_menu_func
{
  vt_windows_reset
  if [ "$ventoy_compatible" = "NO" ];
  then
    find_wim_file (loop)
    if [ -n "$ventoy_wim_file" ];
    then
      vt_windows_locate_wim $ventoy_wim_file
    fi
  fi
  vt_windows_chain_data "${1}"
  if [ -n "${vtdebug_flag}" ];
  then
    sleep 5
  fi
  if [ -n "$vtoy_chain_mem_addr" ];
  then
    terminal_output  console
    chainloader ${vtoy_path}/ventoy_x64.efi  env_param=${env_param} isoefi=${LoadIsoEfiDriver} ${vtdebug_flag} mem:${vtoy_chain_mem_addr}:size:${vtoy_chain_mem_size}
    boot
  else
    echo "chain empty failed"
    sleep 5
  fi
}

function uefi_linux_menu_func
{
  if [ "$ventoy_compatible" = "NO" ];
  then
    vt_load_cpio  ${vtoy_path}/ventoy.cpio
    vt_linux_clear_initrd
    if [ -d (loop)/pmagic ];
    then
      vt_linux_specify_initrd_file /pmagic/initrd.img
    else
      for file in "boot/grub/grub.cfg" "EFI/BOOT/grub.cfg" "EFI/boot/grub.cfg" "efi/boot/grub.cfg" "EFI/BOOT/BOOTX64.conf";
      do
        if [ -e (loop)/$file ];
        then
          vt_linux_parse_initrd_grub  file  (loop)/$file
        fi
      done
    fi
    # special process for special distros
    if [ -d (loop)/loader/entries ];
    then
      set LoadIsoEfiDriver=on
      vt_linux_parse_initrd_grub  dir  (loop)/loader/entries/
    elif [ -d (loop)/boot/grub ];
    then
      vt_linux_parse_initrd_grub  dir  (loop)/boot/grub/
    fi
    if [ -e (loop)/syslinux/alt0/full.cz ];
    then
      set LoadIsoEfiDriver=on
      set FirstTryBootFile='@EFI@BOOT@grubx64.efi'
    fi
    distro_specify_initrd_file
    vt_linux_initrd_count vtcount
    if [ $vtcount -eq 0 ];
    then
      distro_specify_initrd_file_phase2
      if [ "$vt_efi_dir" = "NO" ];
      then
        if [ -f (loop)/efi.img ];
        then
          vt_add_replace_file 0 "initrd"
        fi
      fi
    fi
    locate_initrd
  fi
  vt_linux_chain_data "${1}"
  if [ -n "$vtoy_chain_mem_addr" ];
  then
    terminal_output  console
    chainloader ${vtoy_path}/ventoy_x64.efi  env_param=${env_param} isoefi=${LoadIsoEfiDriver} FirstTry=${FirstTryBootFile} ${vtdebug_flag} mem:${vtoy_chain_mem_addr}:size:${vtoy_chain_mem_size}
    boot
  else
    echo "chain empty failed"
    sleep 5
  fi
}

function uefi_iso_menu_func
{
  loopback -d loop
  if [ -n "$vtisouefi" ];
  then
    set LoadIsoEfiDriver=on
    unset vtisouefi
  elif [ -n "$VTOY_ISO_UEFI_DRV" ];
  then
    set LoadIsoEfiDriver=on
  else
    unset LoadIsoEfiDriver
  fi
  loopback loop "${1}"
  get_os_type (loop)
  if [ -d (loop)/EFI -o -d (loop)/efi ];
  then
    set vt_efi_dir=YES
  else
    set vt_efi_dir=NO
  fi
  if [ -n "$vtcompat" ];
  then
    set ventoy_compatible=YES
    unset vtcompat
  else
    vt_check_compatible (loop)
  fi
  vt_img_sector "${1}"
  if [ "$vtoy_os" = "Windows" ];
  then
    if [ -f (loop)/HBCD_PE.ini ];
    then
      set ventoy_compatible=YES
    fi
    uefi_windows_menu_func "${1}"
  else
    uefi_linux_menu_func "${1}"
  fi
  terminal_output  gfxterm
}

function legacy_windows_menu_func
{
  vt_windows_reset
  if [ "$ventoy_compatible" = "NO" ];
  then
    find_wim_file (loop)
    if [ -n "$ventoy_wim_file" ];
    then
      vt_windows_locate_wim $ventoy_wim_file
    elif [ -n "${vtdebug_flag}" ];
    then
      echo No wim file found
    fi
  fi
  vt_windows_chain_data "${1}"
  if [ -n "${vtdebug_flag}" ];
  then
    sleep 5
  fi
  if [ -n "$vtoy_chain_mem_addr" ];
  then
    linux16   $vtoy_path/ipxe.krn ${vtdebug_flag} ibft
    initrd16  mem:${vtoy_chain_mem_addr}:size:${vtoy_chain_mem_size}
    boot
  else
    echo "chain empty failed"
    sleep 5
  fi
}

function legacy_linux_menu_func
{
  if [ "$ventoy_compatible" = "NO" ];
  then
    vt_load_cpio $vtoy_path/ventoy.cpio
    vt_linux_clear_initrd
    if [ -d (loop)/pmagic ];
    then
      vt_linux_specify_initrd_file /pmagic/initrd.img
    else
      for dir in "isolinux" "boot/isolinux" "boot/x86_64/loader" "syslinux" "boot/syslinux";
      do
        if [ -d (loop)/$dir ];
        then
          vt_linux_parse_initrd_isolinux (loop)/$dir/
        fi
      done
    fi
    # special process for special distros
    #archlinux
    if [ -d (loop)/arch/boot/syslinux ];
    then
      vt_linux_parse_initrd_isolinux (loop)/arch/boot/syslinux/ /arch/
      vt_linux_parse_initrd_isolinux (loop)/arch/boot/syslinux/ /arch/boot/syslinux/
    #manjaro
    elif [ -d (loop)/manjaro ];
    then
      if [ -e (loop)/boot/grub/kernels.cfg ];
      then
        vt_linux_parse_initrd_grub file (loop)/boot/grub/kernels.cfg
      fi
    elif [ -e (loop)/boot/grub/grub.cfg ];
    then
      vt_linux_parse_initrd_grub file (loop)/boot/grub/grub.cfg
    fi
    distro_specify_initrd_file
    vt_linux_initrd_count vtcount
    if [ $vtcount -eq 0 ];
    then
      distro_specify_initrd_file_phase2
    fi
    locate_initrd
  fi
  vt_linux_chain_data "${1}"
  if [ -n "${vtdebug_flag}" ];
  then
    sleep 5
  fi
  if [ -n "$vtoy_chain_mem_addr" ];
  then
    linux16 $vtoy_path/ipxe.krn ${vtdebug_flag}
    initrd16 mem:${vtoy_chain_mem_addr}:size:${vtoy_chain_mem_size}
    boot
  else
    echo "chain empty failed"
    sleep 5
  fi
}

function legacy_iso_menu_func
{
  loopback -d loop
  loopback loop "${1}"
  get_os_type (loop)
  if [ -n "$vtcompat" ];
  then
    set ventoy_compatible=YES
    unset vtcompat
  else
    vt_check_compatible (loop)
  fi
  vt_img_sector "${1}"
  if [ "$vtoy_os" = "Windows" ];
  then
    if [ -f (loop)/HBCD_PE.ini ];
    then
      set ventoy_compatible=YES
    fi
    legacy_windows_menu_func "${1}"
  else
    legacy_linux_menu_func "${1}"
  fi
}

if [ "$grub_platform" = "pc" ];
then
  legacy_iso_menu_func "${grubfm_file}"
else
  uefi_iso_menu_func "${grubfm_file}"
fi;
