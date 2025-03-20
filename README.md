# Kadokadeo

## Configuration

Start by copying `.env.example` into `.env`.

This is an example of Apache config
```
<VirtualHost *:80>
    DocumentRoot "C:\Julien\Sites Web\eternaltwin\kadokadeo\kadokadeo\public"
    ServerName kadokadeo.localhost
    <Directory "C:\Julien\Sites Web\eternaltwin\kadokadeo\kadokadeo\public">
        AllowOverride All
        Require all granted
		FallbackResource /index.php
    </Directory>
</VirtualHost>
```

## Project commands

### Ensure the database is up-to-date

```
composer run-script db:sync
```

### Reset the DB

```
composer run-script db:reset
```

## Installing with Docker

### Windows Users

Windows users first need to install WSL2 and Docker Desktop.

Docker Desktop for Windows can be downloaded [here](https://docs.docker.com/desktop/install/windows-install/).

WSL2 should be installed by default on recent Windows 10+ versions. Try running `wsl --set-default-version 2` in a Powershell terminal. If it doesn't work, follow the instructions [here](https://learn.microsoft.com/fr-fr/windows/wsl/install-manual).

Install [Debian](https://apps.microsoft.com/detail/9msvkqc78pk6) with WSL2 : `wsl --install -d Debian`

Then launch it : `wsl -d Debian`

After configuring your Debian account, you can install the project following the instructions below.

### Install build tools and Docker

- Install build tools and Git :

```bash
sudo -s
apt update -y
apt install build-essential curl git -y
```
- Install Docker and Docker Compose in command line :

```bash
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update -y
apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
exit # Quit root mode
cd ~ # Go back to your home directory
```
Then, add your user to the Docker group :

```bash
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
```

Run `docker run hello-world` to check if Docker is correctly installed. If not :
- try to run it in a new terminal ;
- log off and log in again ;
- restart your computer and try again.

### Install the project

- If not done yet, generate a SSH key and add it to your GitLab profile :
  - Generate the key : `ssh-keygen -t rsa -b 2048 -C "SSH Key for Kadokadéo repository (https://gitlab.com/eternaltwin/kadokadeo/kadokadeo)"`
  - Display the key : `cat ~/.ssh/id_rsa.pub`
  - Copy the key and add it to your GitLab profile here : https://gitlab.com/-/user_settings/ssh_keys/

- Clone the repository and move to it : `git clone git@gitlab.com:eternaltwin/kadokadeo/kadokadeo.git && cd kadokadeo`

- Checkout on main : `git checkout main`

- Build the project : `make`

Everything in one copy/paste :
```bash
git clone git@gitlab.com:eternaltwin/kadokadeo/kadokadeo.git 
cd kadokadeo 
git checkout main 
make
```

 If everything goes well you should be able to access to :
  -  KadoKadéo on http://kadokadeo.localhost/
  -  Eternaltwin on http://localhost:50320


### Troubleshooting

Please contact @evian6930 on Discord if you have any issue.

- `Ports are not available: listen tcp 0.0.0.0:50320: bind : An attempt was made to access a socket in a way forbidden by its access permissions.`
Open Powershell as an administrator and run the following commands :
```powershell
netsh int ipv4 set dynamic tcp start=60536 num=5000
netsh int ipv6 set dynamic tcp start=60536 num=5000
```
Restart your computer, then try to run `make` again.

## Some useful commands

- `make docker-watch` : Start the project with logs
- `make docker-start` : Start the project in the background
- `make bash-app` : Enter the application container to run `composer` or `php` commands
- `make reset-database` : Reset the database
- `make sync-database` : Update the database with your migrations defined in `db` folder

Please see more commands in the [`Makefile`](Makefile) or the [`composer.json`](composer.json#L16-L19) file.
