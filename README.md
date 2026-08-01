## Post-installation Steps

After the installation script finishes, complete the following steps:

1. Switch to the newly created user:

   ```bash
   sudo su <username>
   ```

2. Navigate to the dotfiles repository and run the user setup script:

   ```bash
   cd ~/dotfiles
   bash setup-user.sh
   ```

3. Install the official Arch Linux packages:

   ```bash
   awk '{print $1}' ~/dotfiles/pkg/pacman-packages.txt | sudo pacman -S --needed -
   ```

4. Install the AUR packages:

   ```bash
   awk '{print $1}' ~/dotfiles/pkg/aur-packages.txt | yay -S --needed -
   ```

5. Import or copy your SSH keys into `~/.ssh`.

6. Reconnect using a login shell:

   ```bash
   sudo su --login <username>
   ```
