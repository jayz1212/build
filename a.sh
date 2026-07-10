#!/bin/bash
#git clone https://github.com/xc112lg/rbe1 >/dev/null 2>&1

# rm -rf .repo/local_manifests 
# git clone https://github.com/LG-G6/scripts.git -b lineage-21 
# mkdir .repo/local_manifests 
# cp scripts/roomservice.xml .repo/local_manifests/ 
#repo sync -c -j32 --force-sync --no-clone-bundle --no-tags
#/opt/crave/resync.sh

#make clean
git clone https://github.com/Rares6567/new_rbe_fix tutorial
bash tutorial/scripts/build_patched_reclient.sh .

PATCH_FILE="tutorial/patches/android-rbe-buildbuddyfix-defaults.patch"
if patch -p1 --dry-run --forward < "$PATCH_FILE" >/dev/null 2>&1; then
    echo "[PATCH] Not yet applied, applying now..."
    patch -p1 < "$PATCH_FILE"
else
    echo "[PATCH] Already applied (or conflicts), skipping."
fi

export RBE_service="xc112lg.buildbuddy.io:443"        # BuildBuddy instance address (without grpcs://, add the port 443)
export RBE_remote_headers="x-buildbuddy-api-key=D2SvmJdB1v8oM6KaNg6J"    # Your BuildBuddy API key
export RBE_use_rpc_credentials=false
export RBE_service_no_auth=true

# --- Enable RBE and General Settings ---
export USE_RBE=1
export RBE_DIR="prebuilts/remoteexecution-client/buildbuddyfix"                     # Set this to the output folder produced by the fix script
export NINJA_REMOTE_NUM_JOBS=300                        # Number of parallel remote jobs (adjust based on your RAM, AOSP default is 500)

# --- Unified Downloads/Uploads (Recommended) ---
export RBE_use_unified_downloads=true
export RBE_use_unified_uploads=true
export RBE_compression_algorithm=gzip                 # Faster network transfer
export RBE_local_slow_threshold=100ms 

# --- Execution Strategies (remote_local_fallback is generally best) ---
export RBE_R8_EXEC_STRATEGY=remote_local_fallback
export RBE_D8_EXEC_STRATEGY=remote_local_fallback
export RBE_JAVAC_EXEC_STRATEGY=remote_local_fallback
export RBE_JAR_EXEC_STRATEGY=remote_local_fallback
export RBE_ZIP_EXEC_STRATEGY=remote_local_fallback
export RBE_TURBINE_EXEC_STRATEGY=remote_local_fallback
export RBE_SIGNAPK_EXEC_STRATEGY=remote_local_fallback
export RBE_CXX_EXEC_STRATEGY=remote_local_fallback    # Important see below.
export RBE_CXX_LINKS_EXEC_STRATEGY=remote_local_fallback
export RBE_ABI_LINKER_EXEC_STRATEGY=remote_local_fallback
export RBE_ABI_DUMPER_EXEC_STRATEGY=    # Will make build slower, by a lot. Keeping this for documentation
export RBE_CLANG_TIDY_EXEC_STRATEGY=remote_local_fallback
export RBE_METALAVA_EXEC_STRATEGY=remote_local_fallback
export RBE_LINT_EXEC_STRATEGY=remote_local_fallback

# --- Enable RBE for Specific Tools ---
export RBE_R8=1
export RBE_D8=1
export RBE_JAVAC=1
export RBE_JAR=1
export RBE_ZIP=1
export RBE_TURBINE=1
export RBE_SIGNAPK=1
export RBE_CXX_LINKS=1
export RBE_CXX=1
export RBE_ABI_LINKER=1
export RBE_ABI_DUMPER=    # Will make build slower, by a lot. Keeping this for documentation
export RBE_CLANG_TIDY=1
export RBE_METALAVA=1
export RBE_LINT=1

# --- Resource Pools ---
export RBE_JAVA_POOL=default
export RBE_METALAVA_POOL=default
export RBE_LINT_POOL=default

# --- Timeouts ---
export RBE_reclient_timeout=60m
export RBE_exec_timeout=10m
