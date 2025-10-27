#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<'EOF'
make_image.sh [--img PATH] [--size-mb N] [--boot-sz-mib N] [--stage1 PATH] [--stage2 PATH] [--fat-label LABEL]

You can also set the same via environment variables:
  IMG, SIZE_MB, BOOT_SZ_MIB, STAGE1, STAGE2, FAT_LABEL

Examples:
  IMG=out/image.img SIZE_MB=256 BOOT_SZ_MIB=4 \
    STAGE1=build/stage1.bin STAGE2=build/stage2.bin \
    ./make_image.sh

  ./make_image.sh --img out/image.img --size-mb 256 --boot-sz-mib 4 \
    --stage1 build/stage1.bin --stage2 build/stage2.bin --fat-label AIDOSDATA
EOF
}

# ---- defaults (can be overridden by env or flags) ----
IMG="${IMG:-out/image.img}"
SIZE_MB="${SIZE_MB:-128}"                                  # total image size
BOOT_SZ_MIB="${BOOT_SZ_MIB:-3}"                            # boot partition size
STAGE1="${STAGE1:-build/src/bootloader/stage1/stage1.bin}" # 512-byte stage1 (ends with 0x55AA)
STAGE2="${STAGE2:-}"                                       # stage2 payload (raw binary)
FAT_LABEL="${FAT_LABEL:-AIDOSDATA}"

# ---- parse flags (override env/defaults) ----
while [[ $# -gt 0 ]]; do
	case "$1" in
	--img)
		IMG="$2"
		shift 2
		;;
	--size-mb)
		SIZE_MB="$2"
		shift 2
		;;
	--boot-sz-mib)
		BOOT_SZ_MIB="$2"
		shift 2
		;;
	--stage1)
		STAGE1="$2"
		shift 2
		;;
	--stage2)
		STAGE2="$2"
		shift 2
		;;
	--fat-label)
		FAT_LABEL="$2"
		shift 2
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		echo "Unknown arg: $1"
		usage
		exit 2
		;;
	esac
done

# ---- sanity checks ----
command -v dd >/dev/null 2>&1 || {
	echo "dd not found" >&2
	exit 1
}
command -v parted >/dev/null 2>&1 || {
	echo "parted not found" >&2
	exit 1
}
[[ "$SIZE_MB" =~ ^[0-9]+$ ]] || {
	echo "SIZE_MB must be an integer" >&2
	exit 1
}
[[ "$BOOT_SZ_MIB" =~ ^[0-9]+$ ]] || {
	echo "BOOT_SZ_MIB must be an integer" >&2
	exit 1
}

mkdir -p "$(dirname "$IMG")"

echo "==> Config:"
echo "    IMG         = $IMG"
echo "    SIZE_MB     = $SIZE_MB"
echo "    BOOT_SZ_MIB = $BOOT_SZ_MIB"
echo "    STAGE1      = $STAGE1"
echo "    STAGE2      = ${STAGE2:-<none>}"
echo "    FAT_LABEL   = $FAT_LABEL"

# ---- create empty image ----
dd if=/dev/zero of="$IMG" bs=1M count="$SIZE_MB" status=none

# ---- MBR + partitions ----
# layout:
#  p1: 1MiB .. (1MiB + BOOT_SZ_MIB)   (bootable, raw, custom type)
#      LBA+0: stage1 (PBR)
#      LBA+1: header (already present per user)
#      LBA+2.. : stage2
#  p2: remainder (FAT32, NOT bootable)
parted -s "$IMG" mklabel msdos
parted -s "$IMG" unit mib mkpart primary $((1)) $((1 + BOOT_SZ_MIB))
parted -s "$IMG" unit mib mkpart primary fat32 $((1 + BOOT_SZ_MIB)) 100%
parted -s "$IMG" set 1 boot on

# ---- compute start sectors (for writing into partition 1) ----
START1=$(
	parted -sm "$IMG" unit s print |
		awk -F: '$1=="1" { sub(/s$/,"",$2); print $2; exit }'
)
START2=$(
	parted -sm "$IMG" unit s print |
		awk -F: '$1=="2" { sub(/s$/,"",$2); print $2; exit }'
)
echo "p1 starts at LBA=$START1, p2 at LBA=$START2"

# ---- write 512-byte stage1 into first sector of partition 1 ----
if [ ! -f "$STAGE1" ]; then
	echo "ERROR: $STAGE1 does not exist" >&2
	exit 1
fi
if [ "$(stat -c%s "$STAGE1")" -ne 512 ]; then
	echo "ERROR: $STAGE1 must be exactly 512 bytes" >&2
	exit 1
fi
dd if="$STAGE1" of="$IMG" bs=512 seek="$START1" conv=notrunc status=none

# ---- write stage2 (if provided) at LBA (START1 + 2), right after header ----
if [ -n "$STAGE2" ]; then
	if [ ! -f "$STAGE2" ]; then
		echo "ERROR: $STAGE2 does not exist" >&2
		exit 1
	fi

	# sector math
	STAGE2_BYTES=$(stat -c%s "$STAGE2")
	STAGE2_SECTORS=$(((STAGE2_BYTES + 511) / 512))

	# capacity check within boot partition
	P1_CAP_SECTORS=$((BOOT_SZ_MIB * 2048)) # 1 MiB = 2048 * 512B
	# reserved: +0 stage1, +1 header -> usable starts at +2
	P1_USABLE_AFTER_HEADER=$((P1_CAP_SECTORS - 2))
	if ((STAGE2_SECTORS > P1_USABLE_AFTER_HEADER)); then
		echo "ERROR: stage2 ($STAGE2_SECTORS sectors) exceeds partition-1 capacity after header ($P1_USABLE_AFTER_HEADER sectors)." >&2
		exit 1
	fi

	echo "Writing stage2: ${STAGE2_BYTES} bytes (${STAGE2_SECTORS} sectors) at LBA=$((START1 + 1))"
	dd if="$STAGE2" of="$IMG" bs=512 seek="$((START1 + 1))" conv=notrunc status=none
else
	echo "Note: STAGE2 not provided; only stage1 written (header assumed pre-existing)."
fi

sync
echo "Done. Image: $IMG"
