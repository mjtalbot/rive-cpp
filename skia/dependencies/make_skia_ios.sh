#!/bin/bash

set -ex

export MAKE_SKIA_FILE="$0"
source ./get_skia2.sh
source ./cache_helper.sh

build_skia_ios(){
    cd $SKIA_DIR_NAME

    BASE=out/ios
    case $1 in 
        arm64) 
            ARCH=arm64
            FOLDER=$BASE/arm64
            ;;
        arm) 
            ARCH=arm
            FOLDER=$BASE/arm
            ;;
        x86) 
            ARCH=x86
            FOLDER=$BASE/x86
            ;;
        x64) 
            ARCH=x64
            FOLDER=$BASE/x64
            ;;
        iossim_arm64) 
            ARCH=arm64
            FOLDER=$BASE/iossim_arm64
            EXTRA_CFLAGS=", \"--target=arm64-apple-ios12.0.0-simulator\""
            EXTRA_LDLAGS="\"--target=arm64-apple-ios12.0.0-simulator\""
            ;;
        *) 
            echo "Do not know build configuration for $1"
            exit 1
    esac

    
    # use Rive optimized/stripped Skia for iOS static libs.
    bin/gn gen $FOLDER --type=static_library --args="   \
        target_os=\"ios\"                                   \
        target_cpu=\"$ARCH\"                                \
        extra_cflags=[                                      \
            \"-fno-rtti\",                                  \
            \"-fembed-bitcode\",                            \
            \"-mios-version-min=10.0\",                     \
            \"-flto=full\",                                 \
            \"-DSK_DISABLE_SKPICTURE\",                     \
            \"-DSK_DISABLE_TEXT\",                          \
            \"-DRIVE_OPTIMIZED\",                           \
            \"-DSK_DISABLE_LEGACY_SHADERCONTEXT\",          \
            \"-DSK_DISABLE_LOWP_RASTER_PIPELINE\",          \
            \"-DSK_FORCE_RASTER_PIPELINE_BLITTER\",         \
            \"-DSK_DISABLE_AAA\",                           \
            \"-DSK_DISABLE_EFFECT_DESERIALIZATION\"         \
            ${EXTRA_CFLAGS}
        ]                                                   \

        extra_ldflags=[                                     \
            ${EXTRA_LDLAGS}                                 \
        ]                                                   \

        is_official_build=true \
        skia_use_freetype=true \
        skia_use_metal=true \
        skia_use_zlib=true \
        skia_enable_gpu=true \
        skia_use_libpng_encode=true \
        skia_use_libpng_decode=true \
        skia_skip_codesign=true \
        
        skia_use_angle=false \
        skia_use_dng_sdk=false \
        skia_use_egl=false \
        skia_use_expat=false \
        skia_use_fontconfig=false \
        skia_use_system_freetype2=false \
        skia_use_icu=false \
        skia_use_libheif=false \
        skia_use_system_libpng=false \
        skia_use_system_libjpeg_turbo=false \
        skia_use_libjpeg_turbo_encode=false \
        skia_use_libjpeg_turbo_decode=true \
        skia_use_libwebp_encode=false \
        skia_use_libwebp_decode=true \
        skia_use_system_libwebp=false \
        skia_use_lua=false \
        skia_use_piex=false \
        skia_use_vulkan=false \
        skia_use_gl=false \
        skia_use_system_zlib=false \
        skia_enable_fontmgr_empty=false \
        skia_enable_spirv_validation=false \
        skia_enable_pdf=false \
        skia_enable_skottie=false \
        $OVERRIDES
        "
    ninja -C $FOLDER
    cd ..
}

if is_build_cached_locally; then 
    echo "Build is cached, nothing to do."
else
    if is_build_cached_remotely; then 
        pull_cache
    else 
        getSkia
        build_skia_ios $1
        # hmm not the appiest with this guy
        OUTPUT_CACHE=$FOLDER upload_cache
    fi 
fi

cd ..
