sudo apt update
sudo apt install -y build-essential wget libssl-dev zlib1g-dev \
libncurses5-dev libffi-dev libsqlite3-dev libreadline-dev

cd /tmp
wget https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz
tar -xf Python-2.7.18.tgz
cd Python-2.7.18



cd /tmp/Python-2.7.18
export CFLAGS="-std=gnu89"
make clean

./configure --prefix=/usr/local/python2
make -j$(nproc)
sudo make install

export PATH="/usr/local/python2/bin:$PATH"
export PYTHON=python2
