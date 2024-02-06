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

## Install with Docker

### Windows Users

Windows users first need to install [WSL2](https://learn.microsoft.com/fr-fr/windows/wsl/install) and [Docker Desktop](https://docs.docker.com/desktop/install/windows-install/).

WSL2 should be installed by default on recent Windows 10+ versions. Try running `wsl --help` in a Powershell terminal. If it doesn't work, follow the link above to install it.

Install [Ubuntu](https://apps.microsoft.com/store/detail/ubuntu/9PDXGNCFSCZV?hl=fr-fr&gl=fr&rtc=1) with WSL2 : `wsl --install -d Ubuntu`

Then launch it : `wsl -d Ubuntu`

After configuring your Ubuntu account, you can install the project following the instructions below.


### Install build tools
```bash
sudo -s
apt-get update -y
apt-get install build-essential curl git -y
```

- Install Docker and Docker Compose in command line (alternative to Docker Desktop for WSL2 users) :
```bash
apt-get install lsb-release -y
mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get install docker docker-compose docker-compose-plugin -y
exit
cd ~
```

### Install the project

- If not done yet, generate a SSH key and add it to your GitLab profile :
  - Generate the key : `ssh-keygen -t rsa -b 2048 -C "SSH Key for Kadokadéo repository (https://gitlab.com/eternaltwin/kadokadeo/kadokadeo)"`
  - Display the key : `cat ~/.ssh/id_rsa.pub`
  - Copy the key and add it to your GitLab profile here : https://gitlab.com/-/profile/keys

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

WSL2 users :

Although it is possible to run Kadokadeo from a Windows folder mounted to WSL2, it will be very slow at best case and you may run to issues during installation at worst case (this is why we moved to home folder `~` in the previous steps).

You can work with the repo cloned in Ubuntu home with VSCode's [WSL remote](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl) or accessing files through SMB (e.g. `\\wsl$\Ubuntu\kadokadeo`).

### Troubleshooting
Don't hesitate to mention @evian6930 on Discord if you have any issue.

- `Ports are not available: listen tcp 0.0.0.0:50320: bind : An attempt was made to access a socket in a way forbidden by its access permissions.` :
Open Powershell as an administrator and run the following commands :
```powershell
netsh int ipv4 set dynamic tcp start=60536 num=5000
netsh int ipv6 set dynamic tcp start=60536 num=5000
```
Restart your computer, then try to run `make` again.

- `cache lookup failed for type xxxx` : Re install everything with `make` . 
Make sure you wait for the Eternaltwin server to be fully up before trying to access to KadoKadéo (you can check the logs with `make docker-watch`. The server is ready when you see `kadokadeo_eternaltwin  | Listening on internal port 50320, externally available at http://localhost:50320/`)

- `Database does not exist` : Try to remove all your Docker volumes with `docker volume prune` and re install everything with `make` .