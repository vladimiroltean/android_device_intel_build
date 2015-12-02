LOCAL_PATH := $(call my-dir)

# Base directory for our Makefiles.
EFI_BUILD_SYSTEM := $(LOCAL_PATH)

# Used in Android.mk to produce a binary
BUILD_UEFI_EXECUTABLE := $(EFI_BUILD_SYSTEM)/uefi_executable.mk

# Override default definition
CLEAR_VARS := $(EFI_BUILD_SYSTEM)/clear_vars.mk

ifeq ($(TARGET_ARCH),x86)
    EFI_ARCH := ia32
    EFI_ARCH_CFLAGS := -m32 -DCONFIG_X86
    EFI_ASFLAGS  := -m32
endif

ifneq (,$(filter $(TARGET_ARCH),x86-64)$(filter $(BOARD_USE_64BIT_KERNEL),true)$(filter $(TARGET_UEFI_ARCH),x86_64))
    EFI_ARCH := x86_64
    EFI_ARCH_CFLAGS := -m64 -DCONFIG_X86_64
    EFI_ASFLAGS  := -m64
endif

EFI_CFLAGS := $(EFI_ARCH_CFLAGS) -fPIC -fPIE \
	-fshort-wchar -ffreestanding -Wall -fstack-protector \
	-Wl,-z,noexecstack -O2 -g -fno-merge-constants \
	-D_FORTIFY_SOURCE=2 -DEFI_FUNCTION_WRAPPER -DGNU_EFI_USE_MS_ABI

EFI_EXTRA_CFLAGS := $(EFI_CFLAGS)

EFI_LDFLAGS := -Bsymbolic -shared -z relro -z now --no-undefined \
	-fstack-protector -fPIC -pie -nostdlib -znocombreloc

EFI_CRT0 := $(call intermediates-dir-for,STATIC_LIBRARIES,crt0-efi)/crt0-efi.o

EFI_LDFLAGS += -T $(EFI_BUILD_SYSTEM)/elf_$(EFI_ARCH)_efi.lds
EFI_OBJCOPY_FLAGS := \
	-j .text -j .sdata -j .data \
	-j .dynamic -j .dynsym  -j .rel \
	-j .rela -j .rela.dyn -j .reloc -j .eh_frame

EFI_TOOLCHAIN_ROOT := prebuilts/gcc/$(HOST_PREBUILT_TAG)/x86/x86_64-linux-android-$(TARGET_GCC_VERSION)
EFI_TOOLS_PREFIX := $(EFI_TOOLCHAIN_ROOT)/bin/x86_64-linux-android-
EFI_LD := $(EFI_TOOLS_PREFIX)ld.bfd$(HOST_EXECUTABLE_SUFFIX)
EFI_CC := $(EFI_TOOLS_PREFIX)gcc$(HOST_EXECUTABLE_SUFFIX)
EFI_OBJCOPY := $(EFI_TOOLS_PREFIX)objcopy$(HOST_EXECUTABLE_SUFFIX)
EFI_LIBGCC := $(shell $(EFI_CC) $(EFI_CFLAGS) -print-libgcc-file-name)
