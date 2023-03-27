PKG_NAME="u-boot-Phicomm_N1"
PKG_VERSION="1.0"
PKG_LICENSE="GPL"
PKG_DEPENDS_TARGET="toolchain u-boot-tools u-boot-script"
PKG_DEPENDS_UNPACK="linux"
PKG_TOOLCHAIN="manual"

DT_ID="meson_gxl_s905d_phicomm_n1"

make_target() {
  # Enter kernel directory
  pushd $BUILD/build/linux-$(kernel_version) > /dev/null
  
  cp -av $PKG_DIR/sources/$DT_ID.dts arch/$TARGET_KERNEL_ARCH/boot/dts/amlogic/coreelec-gxl/
  
  # Compile device trees
  kernel_make coreelec-gxl/$DT_ID.dtb
  cp arch/$TARGET_KERNEL_ARCH/boot/dts/amlogic/coreelec-gxl/$DT_ID.dtb $PKG_BUILD
  
  popd > /dev/null
}

makeinstall_target() {
  # Install dtb file
  mkdir -p $INSTALL/usr/share/bootloader  
  cp -av $BUILD/build/linux-$(kernel_version)/arch/$TARGET_KERNEL_ARCH/boot/dts/amlogic/coreelec-gxl/$DT_ID.dtb $INSTALL/usr/share/bootloader/Phicomm_N1_dtb.img
  
  # For update
  mkdir -p $INSTALL/usr/share/bootloader/device_trees
  cp -av $BUILD/build/linux-$(kernel_version)/arch/$TARGET_KERNEL_ARCH/boot/dts/amlogic/coreelec-gxl/$DT_ID.dtb $INSTALL/usr/share/bootloader/device_trees/
}
