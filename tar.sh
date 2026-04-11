export GH_TOKEN=$(cat gh_token.txt)

cd /tmp/src/android/out/target/product/a5ltechn

# Create tar.md5 for Odin


tar -cvf recovery.tar recovery.img

# Add md5 checksum
md5sum -t recovery.tar >> recovery.tar
mv recovery.tar recovery.tar.md5

# Or one-liner
tar -cvf recovery.tar recovery.img && md5sum -t recovery.tar >> recovery.tar && mv recovery.tar recovery.tar.md5




echo "Created: recovery.tar.md5"

cp out/target/product/a5ltechn/recovery.tar.md5 crdroid10.x
cd crdroid10.x
chmod +x multi_upload.sh
./multi_upload.sh

