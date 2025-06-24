# aserdev-plymouth-theme
my plymouth theme for my linux distro

a remade version of my spinner theme

## install plymouth

### archlinux

```zsh
sudo pacman -Syu
```

```zsh
sudo pacman -S plymouth curl git grub
```

### debian/ubuntu/ other deb distros


```zsh
sudo apt update && sudo apt install plymouth plymouth-themes -y
```

## install theme

### archlinux

```zsh
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/aserdev-yt/aserdev-plymouth-theme/main/install-arch.sh)"
```

### debian/ubuntu

```zsh
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/aserdev-yt/aserdev-plymouth-theme/main/install-deb.sh)"
```
