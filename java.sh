#!/usr/bin/env bash

sudo rm -rf /etc/pacman.d/gnupg /var/cache/pacman/pkg/*
sudo pacman-key --init
sudo pacman-key --populate archlinux
sudo pacman-key --refresh-keys --keyserver hkps://keyserver.ubuntu.com
#sudo pacman -Sy --noconfirm archlinux-keyring
sudo pacman -Syu --noconfirm


sudo pacman -S --noconfirm jdk8-openjdk ncurses python && \
sudo archlinux-java set java-8-openjdk && \
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk && \
export PATH=$JAVA_HOME/bin:$PATH && \
sudo ln -sf /usr/lib/libncurses.so.6 /usr/lib/libncurses.so.5 && \
sudo ln -sf /usr/lib/libtinfo.so.6 /usr/lib/libtinfo.so.5 && \
sudo ln -sf /usr/bin/python3 /usr/bin/python
