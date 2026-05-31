


# cd /tmp
# git clone https://aur.archlinux.org/ncurses5-compat-libs.git
# cd ncurses5-compat-libs
# makepkg -si --skippgpcheck --noconfirm
# cd /tmp/src/android



# Check if libncurses.so.5 already exists
if ls /usr/lib/libncurses.so.5* >/dev/null 2>&1; then
    echo "[✓] libncurses.so.5 already exists — skipping install"
else
    echo "[!] libncurses.so.5 missing — installing ncurses5-compat-libs..."

    cd /tmp || exit 1

    # Clean old folder if exists
    rm -rf ncurses5-compat-libs

    git clone https://aur.archlinux.org/ncurses5-compat-libs.git
    cd ncurses5-compat-libs || exit 1

    makepkg -si --skippgpcheck --noconfirm
fi

# Return to your build directory
cd /tmp/src/android || exit 1
