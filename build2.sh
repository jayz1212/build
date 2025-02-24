rm -rf Evolution-X
git clone https://$GH_TOKEN@github.com/xc112lg/Evolution-X.git
rm Evolution-X/*.zip

cp -r out/target/product/*/*.zip out/target/product/*/recovery.img Evolution-X/
cd Evolution-X/
chmod +x multi_upload.sh
. multi_upload.sh
