source ${prefix}/func.sh;

if [ "$grub_platform" = "efi" -a "$grub_cpu" = "i386" ];
then
  return;
fi;

probe --set=fs -f "${grubfm_device}";
if [ "${fs}" != "fat" -a "${fs}" != "exfat" -a "${fs}" != "ntfs" ];
then
  return;
fi;

if search --set=vt_root --file /ventoy/ventoy.cpio;
then
  set vtoy_path=($vt_root)/ventoy;
else
  if [ "$grub_platform" = "pc" ];
  then
    loopback -d ventoy;
    loopback ventoy "${prefix}/ventoy.gz";
  else
    map --type=HD -n "${prefix}/ventoy.gz";
    map -u;
  fi;
  search --set=vt_root --file /ventoy/ventoy.cpio;
  set vtoy_path=($vt_root)/ventoy;
fi;
set grubfm_test=1;
