wget https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz
tar xzf Python-2.7.18.tgz
cd Python-2.7.18

# Configure with prefix to avoid overwriting system Python
./configure --prefix=/usr/local --enable-optimizations
make -j$(nproc)
sudo make altinstall  # Use altinstall to avoid overriding python3

# Create symlink for convenience
sudo ln -s /usr/local/bin/python2.7 /usr/local/bin/python2

# Verify installation
python2 --version
