#!/bin/bash

# Color Variables
RED="\e[1;31m"
GREEN="\e[1;32m"
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

./kernel-5.10/scripts/config --file kernel-5.10/arch/arm64/configs/a15_00_defconfig \
--set-val UH n \
--set-val RKP n \
--set-val KDP n \
--set-val SECURITY_DEFEX n \
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
--set-val FIVE n \
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

# Kernel optimizations
./kernel-5.10/scripts/config --file kernel-5.10/arch/arm64/configs/a15_00_defconfig \
--set-val TMPFS_XATTR y \
--set-val IP_NF_TARGET_TTL y \
--set-val TCP_CONG_ADVANCED y \
--set-val TCP_CONG_BBR y \
--set-val NET_SCH_FQ y \
--set-val NET_SCH_FQ_CODEL y \
--set-val TCP_CONG_CUBIC y \
--set-val TCP_CONG_BIC n \
--set-val TCP_CONG_WESTWOOD n \
--set-val TCP_CONG_HTCP n \
--set-val NET_SCH_CAKE y \
--set-val NET_SCH_PIE y \
--set-val NET_SCH_FQ_PIE y \
--set-val TCP_CONG_BBR3 y \
--set-val DEFAULT_BBR3 y \
--set-val DEFAULT_BIC n \
--set-str DEFAULT_TCP_CONG "bbr" \
--set-val DEFAULT_RENO n \
--set-val DEFAULT_CUBIC n

print_msg "$GREEN" "Modified configs ..."

cd kernel-5.10

# Setup NoMount (MUST be inside kernel-5.10)
print_msg "$GREEN" "Setting up NoMount..."
curl -LSs "https://raw.githubusercontent.com/maxsteeel/nomount/refs/heads/dev/kernel/setup.sh" | bash -s dev
# Force enable the config flag just in case the script missed it
./scripts/config --file arch/arm64/configs/a15_00_defconfig --set-val NOMOUNT y
print_msg "$GREEN" "NoMount setup complete."

# Apply BBRv3 Patches
print_msg "$GREEN" "Applying BBRv3 patches..."
patch -p1 < ../patches/bbrv3/0001-net-tcp-backport-BBRv3-to-android12-5.10.patch || true

if ! grep -qF 'int proc_dou8vec_minmax(' ./include/linux/sysctl.h; then
    patch -p1 < ../patches/bbrv3/sysctl_add_proc_dou8vec_minmax.patch || true
    patch -p1 < ../patches/bbrv3/sysctl_fix_data-races_in_proc_dou8vec_minmax.patch || true
fi
print_msg "$GREEN" "BBRv3 patches applied."

print_msg "$GREEN" "Generating configs..."

# Fix Python 2 script for Python 3 runner
sed -i "s/^\(\s*\)print \(.*\)$/\1print(\2)/g" scripts/gen_build_config.py

python3 scripts/gen_build_config.py --kernel-defconfig a15_00_defconfig --kernel-defconfig-overlays entry_level.config -m user -o ../out/target/product/a15/obj/KERNEL_OBJ/build.config

print_msg "$GREEN" "Finished Generating configs..."

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
