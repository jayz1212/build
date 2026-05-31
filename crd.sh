echo "machine gitlab.com" >> ~/.netrc
echo "login dtiven13" >> ~/.netrc
export PASS=$(cat pass.txt)
echo "$PASS" >> ~/.netrc
chmod 600 ~/.netrc  # Important: strict permissions required
rm -rf test2  # Backup your ZIP file first!
git clone https://gitlab.com/dtiven13/test4.git crdroid10
cd crdroid10

# Setup LFS
sudo apt update
sudo apt install git-lfs -y
git lfs install
git lfs track "*.zip"
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
git add .gitattributes
git commit -m "Enable LFS"
git config --global http.version HTTP/1.1
git config --global http.postBuffer 524288000
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999
git config --global lfs.concurrenttransfers 1
cd ..
cp out/target/product/*/recovery.img crdroid10
cp out/target/product/*/*.zip crdroid10


cd crdroid10
git add .
git commit -m "Add ROM zip via LFS"

# Push
git push origin main
