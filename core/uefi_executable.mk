ifeq ($(strip $(LOCAL_MODULE_CLASS)),)
LOCAL_MODULE_CLASS := EFI
endif

ifeq ($(strip $(LOCAL_MODULE_SUFFIX)),)
LOCAL_MODULE_SUFFIX := .efi
endif

ifeq ($(strip $(LOCAL_MODULE_PATH)),)
LOCAL_MODULE_PATH := $(PRODUCT_OUT)/efi
endif

LOCAL_CC := $(EFI_CC)
LOCAL_NO_DEFAULT_COMPILER_FLAGS := true
LOCAL_CFLAGS += $(EFI_CFLAGS)
LOCAL_ASFLAGS += $(EFI_ASFLAGS )
LOCAL_LDFLAGS := $(EFI_LDFLAGS) $(LOCAL_LDFLAGS)
LOCAL_OBJCOPY_FLAGS := $(EFI_OBJCOPY_FLAGS) $(LOCAL_OBJCOPY_FLAGS)

skip_build_from_source :=
ifdef LOCAL_PREBUILT_MODULE_FILE
ifeq (,$(call if-build-from-source,$(LOCAL_MODULE),$(LOCAL_PATH)))
include $(BUILD_SYSTEM)/prebuilt_internal.mk
skip_build_from_source := true
endif
endif

ifndef skip_build_from_source

ifdef LOCAL_IS_HOST_MODULE
$(error This file should not be used to build host binaries.  Included by (or near) $(lastword $(filter-out config/%,$(MAKEFILE_LIST))))
endif

WITHOUT_LIBCOMPILER_RT := true
include $(BUILD_SYSTEM)/binary.mk
WITHOUT_LIBCOMPILER_RT :=

all_objects += $(EFI_CRT0)

EFI_UNSIGNED := $(basename $(LOCAL_BUILT_MODULE)).unsigned.efi
$(EFI_UNSIGNED): PRIVATE_OBJCOPY_FLAGS := $(LOCAL_OBJCOPY_FLAGS)
$(EFI_UNSIGNED): PRIVATE_ALL_OBJECTS += $(LOCAL_EXT_OBJS)
$(EFI_UNSIGNED): $(all_objects) $(all_libraries)
	@echo "target EFI Executable: $(notdir $@) ($@)"
	@echo "all_objects: $(notdir $@) ($(notdir $(PRIVATE_ALL_OBJECTS)))"
	$(hide) mkdir -p $(dir $@)
	$(hide) $(EFI_LD) $(PRIVATE_LDFLAGS) \
    		$(EFI_CRT0) $(PRIVATE_ALL_OBJECTS) --start-group $(PRIVATE_ALL_STATIC_LIBRARIES) --end-group $(EFI_LIBGCC) \
    		-o $(@:.efi=.so)
	$(hide) $(EFI_OBJCOPY) $(PRIVATE_OBJCOPY_FLAGS) \
    		--target=efi-app-$(EFI_ARCH) $(@:.efi=.so) $(@:.efi=.efi)
	@echo "checking symbols: $(notdir $@) ($@)"
	$(hide) unknown=`nm -u $@` ; if [ -n "$$unknown" ] ; then echo "Unknown symbol(s): $$unknown" && exit -1 ; fi

# sign the efi app with the isu
TARGET_BOOT_IMAGE_KEYS_PATH ?= vendor/intel/tools/isu/testkeys
TARGET_BOOT_LOADER_PRIV_KEY ?= $(TARGET_BOOT_IMAGE_KEYS_PATH)/OSBL_priv.pem
TARGET_BOOT_LOADER_PUB_KEY ?= $(TARGET_BOOT_IMAGE_KEYS_PATH)/OSBL_pub.pub

EFI_SIGNING_TOOL := $(HOST_OUT_EXECUTABLES)/isu

$(LOCAL_BUILT_MODULE): EFI_MANIFEST_OUT := $(EFI_UNSIGNED)_manifest__OS_manifest.bin
$(LOCAL_BUILT_MODULE): $(EFI_UNSIGNED) $(EFI_SIGNING_TOOL)
	@mkdir -p $(@D)
	@echo "signing: $(notdir $@) with $(EFI_SIGNING_TOOL)"
	$(hide) $(EFI_SIGNING_TOOL) -h 0 -i $< -o $@ \
		-l $(TARGET_BOOT_LOADER_PRIV_KEY) -k $(TARGET_BOOT_LOADER_PUB_KEY) -t 11 -p 2 -v 1 > /dev/null
	$(hide) cat $< $@_OS_manifest.bin > $@

endif # skip_build_from_source
