#!/usr/bin/env bash
set -e

echo "🔑 Fixing pacman keys (non-interactive)..."

sudo rm -rf /etc/pacman.d/gnupg

sudo pacman-key --init
sudo pacman-key --populate archlinux

# Install/update keyring (fallback included)
sudo pacman -Sy --noconfirm archlinux-keyring || \
sudo pacman -U --noconfirm https://archive.archlinux.org/packages/a/archlinux-keyring/archlinux-keyring-20260323-1-any.pkg.tar.zst

# Full system sync
sudo pacman -Syyu --noconfirm


echo "☕ Installing build dependencies..."

sudo pacman -S --noconfirm \
    jdk8-openjdk \
    ncurses \
    python


echo "⚙️ Setting Java 8..."

sudo archlinux-java set java-8-openjdk

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk
export PATH=$JAVA_HOME/bin:$PATH


echo "🔧 Fixing ncurses compatibility (safer)..."

# Only create symlinks if missing
[ ! -f /usr/lib/libncurses.so.5 ] && \
sudo ln -s /usr/lib/libncurses.so.6 /usr/lib/libncurses.so.5

[ ! -f /usr/lib/libtinfo.so.5 ] && \
sudo ln -s /usr/lib/libtinfo.so.6 /usr/lib/libtinfo.so.5


echo "🐍 Fixing python symlink (safe)..."

# Only link if python doesn't exist
[ ! -f /usr/bin/python ] && \
sudo ln -s /usr/bin/python3 /usr/bin/python


echo "✅ Environment ready for Android build!"
