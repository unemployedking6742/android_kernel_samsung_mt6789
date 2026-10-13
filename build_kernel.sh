#!/bin/bash

# Color Variables
RED="\e[1;31m"
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
RESET="\e[0m"

print_msg() {
    local COLOR=$1
    shift
    echo -e "${COLOR}$*${RESET}"
}

print_runtime() {
    runtime=$(($3 - $2))
    hours=$((runtime / 3600))
    minutes=$(((runtime % 3600) / 60))
    seconds=$((runtime % 60))
    printf "\e[1;32m$1: %02d:%02d:%02d\n" $hours $minutes $seconds
}

config_start_time=$(date +%s)

print_msg "$GREEN" "\n - Build script for Samsung kernel image - "
print_msg "$RED" "       by poqdavid \n"

./clean_build.sh

print_msg "$GREEN" "Modifying configs..."

# ========================================
# SAMSUNG SECURITY DISABLES (FRAGMENT)
# ========================================
./kernel-5.10/scripts/config --file kernel-5.10/arch/arm64/configs/a15_00_defconfig \
--set-val UH n \
--set-val RKP n \
--set-val KDP n \
--set-val SECURITY_DEFEX n \
--set-val SECURITY_DSMS n \
--set-val SEC_NFC_LOGGER n \
--set-val INTEGRITY n \
--set-val FIVE n \
--set-val TRIM_UNUSED_KSYMS n \
--set-val PROCA n \
--set-val PROCA_GKI_10 n \
--set-val PROCA_S_OS n \
--set-val PROCA_CERTIFICATES_XATTR n \
--set-val PROCA_CERT_ENG n \
--set-val PROCA_CERT_USER n \
--set-val GAF_V6 n \
--set-val FIVE_CERT_USER n \
--set-val FIVE_DEFAULT_HASH n \
--set-val UH_RKP n \
--set-val UH_LKMAUTH n \
--set-val UH_LKM_BLOCK n \
--set-val RKP_CFP_JOPP n \
--set-val RKP_CFP n \
--set-val KDP_CRED n \
--set-val KDP_NS n \
--set-val KDP_TEST n \
--set-val RKP_CRED n

# ========================================
# TELEMETRY / DEBUG DISABLES (FRAGMENT) — FIXED PREFIX
# ========================================
./kernel-5.10/scripts/config --file kernel-5.10/arch/arm64/configs/a15_00_defconfig \
--set-val SAMSUNG_PRODUCT_SHIP n \
--set-val SEC_DEBUG n \
--set-val SEC_DEBUG_TSP_LOG n \
--set-val SEC_DEBUG_LEVEL n \
--set-val SEC_DEBUG_ENG n \
--set-val SEC_DEBUG_USER n \
--set-val SEC_LOG n \
--set-val MTK_AEE_FEATURE n \
--set-val MTK_AEE_AED n \
--set-val MTK_AEE_HANGDET n \
--set-val MTK_AEE_IPANIC n \
--set-val MTK_AEE_UT n \
--set-val MTK_DRAM_LOG_STORE n \
--set-val MTK_LOAD_TRACKER n \
--set-val MMSTAT_TRACER n \
--set-val MTK_BLOCK_IO_TRACER n \
--set-val MTK_MET n \
--set-val MTPROF n \
--set-val MTK_ATF_LOGGER n \
--set-val MTK_PRINTK n \
--set-val MTK_PRINTK_UART_CONSOLE n \
--set-val MTK_HANG_DETECT n \
--set-val MTK_HANG_DETECT_DB n \
--set-val MTK_SUBPMIC_MISC n \
--set-val MT6360_DBG n \
--set-val MTK_IRQ_DBG n \
--set-val MTK_DBGTOP n

# ========================================
# KERNEL OPTIMIZATIONS (FRAGMENT)
# ========================================
./kernel-5.10/scripts/config --file kernel-5.10/arch/arm64/configs/a15_00_defconfig \
--set-val TMPFS_XATTR y \
--set-val IP_NF_TARGET_TTL y \
--set-val TCP_CONG_ADVANCED y \
--set-val TCP_CONG_BBR y \
--set-val NET_SCH_FQ y \
--set-val TCP_CONG_BIC y \
--set-val DEFAULT_BBR y \
--set-str DEFAULT_TCP_CONG "bbr"

print_msg "$GREEN" "Modified configs ..."

cd kernel-5.10

# ========================================
# SETUP KERNELSU-NEXT
# ========================================
print_msg "$GREEN" "Setting up KernelSU-Next..."

curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -

print_msg "$GREEN" "KernelSU-Next setup complete."

# ========================================
# SETUP NOMOUNT
# ========================================
print_msg "$GREEN" "Setting up NoMount..."

curl -LSs "https://raw.githubusercontent.com/maxsteeel/nomount/refs/heads/dev/kernel/setup.sh" | bash -

print_msg "$GREEN" "NoMount setup complete."

# ========================================
# GENERATE MERGED CONFIG
# ========================================
print_msg "$GREEN" "Generating configs..."

python2 scripts/gen_build_config.py --kernel-defconfig a15_00_defconfig --kernel-defconfig-overlays entry_level.config -m user -o ../out/target/product/a15/obj/KERNEL_OBJ/build.config

print_msg "$GREEN" "Finished Generating configs..."

# ========================================
# APPLY CHANGES TO THE MERGED .config
# ========================================
print_msg "$GREEN" "Applying final config overrides to merged .config..."

MERGED_CONFIG="../out/target/product/a15/obj/KERNEL_OBJ/.config"

./kernel-5.10/scripts/config --file "$MERGED_CONFIG" \
--set-val IP_NF_TARGET_TTL y \
--set-val IP6_NF_TARGET_HL y \
--set-val IP6_NF_MATCH_HL y \
--set-val TCP_CONG_WESTWOOD y \
--set-val TCP_CONG_HTCP y \
--set-val IP_SET y \
--set-val IP_SET_MAX 65534 \
--set-val IP_SET_BITMAP_IP y \
--set-val IP_SET_BITMAP_IPMAC y \
--set-val IP_SET_BITMAP_PORT y \
--set-val IP_SET_HASH_IP y \
--set-val IP_SET_HASH_IPMARK y \
--set-val IP_SET_HASH_IPPORT y \
--set-val IP_SET_HASH_IPPORTIP y \
--set-val IP_SET_HASH_IPPORTNET y \
--set-val IP_SET_HASH_IPMAC y \
--set-val IP_SET_HASH_MAC y \
--set-val IP_SET_HASH_NETPORTNET y \
--set-val IP_SET_HASH_NET y \
--set-val IP_SET_HASH_NETNET y \
--set-val IP_SET_HASH_NETPORT y \
--set-val IP_SET_HASH_NETIFACE y \
--set-val IP_SET_LIST_SET y \
--set-val TMPFS_POSIX_ACL y \
--set-val DEBUG_KERNEL n \
--set-val DEBUG_INFO n \
--set-val DEBUG_INFO_DWARF4 n \
--set-val DEBUG_INFO_REDUCED n \
--set-val DEBUG_INFO_SPLIT n \
--set-val DEBUG_INFO_BTF n \
--set-val GDB_SCRIPTS n \
--set-val MAGIC_SYSRQ n \
--set-val FRAME_POINTER n \
--set-val FTRACE n \
--set-val FUNCTION_TRACER n \
--set-val DYNAMIC_FTRACE n \
--set-val STACK_TRACER n \
--set-val BLK_DEV_IO_TRACE n \
--set-val NFC n \
--set-val NFC_DIGITAL n \
--set-val NFC_NCI n \
--set-val NFC_HCI n \
--set-val SAMSUNG_NFC n \
--set-val SEC_NFC n \
--set-val NFC_PN547 n \
--set-val NFC_FEATURE_SN100U n \
--set-val NFC_PVDD_LATE_ENABLE n \
--set-val SEC_NFC_LOGGER n \
--set-val SEC_NFC_COMPAT_IOCTL n \
--set-val NFC_ST21NFC n \
--set-val NFC_ST54_SPI n \
--set-val NFC_CHIP_SUPPORT n \
--set-val IRTX_PWM_SUPPORT n \
--set-val FMRADIO n \
--set-val MTK_COMBO_ANT n \
--set-val CAN n \
--set-val BT_HIDP n \
--set-val NOMOUNT y

print_msg "$GREEN" "Final config overrides applied."

config_end_time=$(date +%s)
build_start_time=$(date +%s)

export LTO=thin
export ARCH=arm64
export PLATFORM_VERSION=12
export LLVM=1
export LLVM_IAS=1
export CROSS_COMPILE="aarch64-linux-gnu-"
export CROSS_COMPILE_COMPAT="arm-linux-gnueabi-"
export OUT_DIR="../out/target/product/a15/obj/KERNEL_OBJ"
export DIST_DIR="../out/target/product/a15/obj/KERNEL_OBJ"
export BUILD_CONFIG="../out/target/product/a15/obj/KERNEL_OBJ/build.config"

print_msg "$GREEN" "Building Kernel..."

cd ../kernel
./build/build.sh

build_end_time=$(date +%s)

print_msg "$GREEN" "Finished Building Kernel..."

echo " "
print_runtime "Config runtime" config_start_time config_end_time
print_runtime "Build runtime" build_start_time build_end_time
