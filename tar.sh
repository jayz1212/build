export GH_TOKEN=$(cat gh_token.txt)
git clone https://$GH_TOKEN@github.com//jayz1212/crdroid10.x
cd /tmp/src/android/out/target/product/a5ltechn

# Create tar.md5 for Odin


tar -cvf recovery.tar recovery.img



echo "Created: recovery.tar"
cd -
rm -rf crdroid10.x/*.img crdroid10.x/*.zip crdroid10.x/*.tar
cp out/target/product/*/recovery.img crdroid10.x
cp out/target/product/*/*.zip crdroid10.x
cp out/target/product/*/*.tar crdroid10.x
cd crdroid10.x
chmod +x multi_upload.sh
./multi_upload.sh

