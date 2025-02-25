git clone https://github.com/xc112lg/rbe --depth 1



export USE_RBE=1                                      
export RBE_DIR="rbe"                      # Path to the extracted reclient directory (relative or absolute)
export NINJA_REMOTE_NUM_JOBS=500                       # Number of parallel remote jobs (adjust based on your RAM, buildbuddy has 80 CPU cores in the free tier)

# --- BuildBuddy Connection Settings ---
export RBE_service="remote.buildbuddy.io:443"        # BuildBuddy instance address (without grpcs://, add the port 443)
export RBE_remote_headers="x-buildbuddy-api-key=agvbfhIb0K9IxDbawp09"    # Your BuildBuddy API key
export RBE_use_rpc_credentials=false                   
export RBE_service_no_auth=true                       

# --- Unified Downloads/Uploads (Recommended) ---
export RBE_use_unified_downloads=true
export RBE_use_unified_uploads=true

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












rm -rf .repo/local_manifests
rm -rf hardware/xiaomi
rm -rf device/xiaomi
rm -rf vendor/xiaomi
rm -rf vendor/lineage-priv
rm -rf kernel/xiaomi
rm -rf frameworks/base
repo init -u https://github.com/Evolution-X/manifest -b vic --git-lfs
git clone https://github.com/vayu-development-sources/local_manifests.git -b evo15-dolby .repo/local_manifests
/opt/crave/resync.sh
git clone https://gitlab.com/ArmSM/vendor_xiaomi_miuicamera.git vendor/xiaomi/miuicamera

cd frameworks/base/
git fetch https://github.com/xc112lg/android_frameworks_base.git patch-2
git cherry-pick 3a3b3718ffcfe53127cbfa228577f02d825e1960
cd -
# cd device/xiaomi/vayu
# git fetch https://github.com/jayz1212/device_xiaomi_vayu.git patch-1
# git cherry-pick eabc02b7c8c3d6669646770ceab08c37df3c5c9a
# cd -

. build/envsetup.sh && lunch lineage_vayu-ap4a-user && m evolution


rm -rf Evolution-X
git clone https://$GH_TOKEN@github.com/xc112lg/Evolution-X.git
rm Evolution-X/*.zip

cp -r out/target/product/*/*.zip out/target/product/*/recovery.img Evolution-X/
cd Evolution-X/
chmod +x multi_upload.sh
. multi_upload.sh
