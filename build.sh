




rm -rf .repo/local_manifests/ 
repo init -u https://github.com/crdroidandroid/android.git -b 15.0 --git-lfs --depth 1
git clone https://github.com/jayz1212/local.git --depth 1 -b main .repo/local_manifests
/opt/crave/resync.sh 
source build/envsetup.sh 
make installclean
brunch vayu







