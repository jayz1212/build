mkdir -p rbe  # Ensure the target directory exists

if [ ! -f "client-linux-amd64.zip" ]; then
    echo "File not found. Downloading..."
    wget -O client-linux-amd64.zip "https://storage.googleapis.com/chrome-infra-packages/store/SHA256/9fdc44153a24ecda030d63313fa9ebc56fc456445c7b9324d279cf0377e5d9d6?Expires=1738973851&GoogleAccessId=chrome-infra-packages%40appspot.gserviceaccount.com&Signature=OvyDTYzrRY6Fy%2BhKHjXSkR2FTT93Shx8Em5gpIbd2VboI7ER7miWRKGaQfwpFmNIPT6mSLlSJEWyEkFoKt5mVn%2BEIERn63%2FXMOGVIWMKFoQalCVpLJ5%2BW3cZReqBxMfhIpLjIlQIW3qMsDwTyGg%2BWntDNNz%2Bhe%2F%2Fi8C7BRabcQ49mpAZIhs5hh43geDQmSUwHyilMbFAbzJF6Hnmc%2BUkQ2sz0fMqe69CduNbViKO89ZezFuxi1ExnPiNNWrbtANMhi1PW9m4gjSZCl%2FSvb9hmHgp9%2FIv8XgqvDWywhyveu5rGzrSt9P39dmFsprlxa6KDbUi104WAP0OqhOSgUSwbA%3D%3D&response-content-disposition=attachment%3B+filename%3D%22client-linux-amd64.zip%22"
else
    echo "File already exists. Skipping download."
fi

unzip -o client-linux-amd64.zip -d rbe  # Extract and overwrite if needed


sudo apt-get update
sudo apt-get install -y ccache
export USE_CCACHE=1






export USE_RBE=1                                      
export RBE_DIR="rbe"                      # Path to the extracted reclient directory (relative or absolute)
export NINJA_REMOTE_NUM_JOBS=500                        # Number of parallel remote jobs (adjust based on your RAM, buildbuddy has 80 CPU cores in the free tier)

# --- BuildBuddy Connection Settings ---
export RBE_service="remote.buildbuddy.io:443"        # BuildBuddy instance address (without grpcs://, add the port 443)
export RBE_remote_headers="x-buildbuddy-api-key=NF5nEUUyU7LIy2QkkIIe"    # Your BuildBuddy API key
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





rm -rf .repo/local_manifests/ 
repo init -u https://github.com/crdroidandroid/android.git -b 15.0 --git-lfs --depth=1
git clone https://github.com/jayz1212/local.git --depth 1 -b main .repo/local_manifests
/opt/crave/resync.sh 
source build/envsetup.sh 
#brunch vayu







