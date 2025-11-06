# Summary

- Kadokadeo
    - [Configuration](#configuration)
    - [Project commands](#project-commands)
    - [Updating games](#installing--updating-games)
    - [Installing with Docker](#installing-with-docker)
        - [Windows Users](#windows-users)
        - [Install build tools and Docker](#install-build-tools-and-docker)
        - [Install the project](#install-the-project)
        - [Troubleshooting](#troubleshooting)
    - [Some useful commands](#some-useful-commands)

# Kadokadeo

## Configuration

Go to [Install the project](#install-the-project) if you need to install the project first.

Here are the configuration variables:

Variable | Description | Default
---------|-------------|---------
`KADO_GAMES_PER_DAY` | Games allowed to play per user per day | 100
`KADO_RUNS_MAX_CONCURRENCY` | Maximum amount of games a user can play in parallel before being throttled | 5
`KADO_RSA_PRIVATE_KEY_PATH` | Private RSA key path of the server. Should be kept **private**. | `storage/app/private/privkey.pem`
`KADO_RSA_PUBLIC_KEY_PATH` | Public key path associated with the private key | `storage/app/private/pubkey.pem`

You can generate keys with :
```bash
openssl genrsa -out keypair.pem
openssl rsa -in keypair.pem -pubout -out public.pem
```

## Project commands

> [!NOTE]
> All the below commands are meant to be ran on docker, with :
>
> `docker exec -u dev -it kadokadeo_app php artisan`
>
> Example: `docker exec -u dev -it kadokadeo_app php artisan migrate`

Command | Description | Ran in CRON
--------|-------------|------
`migrate` | Synchronises the database | ❌
`kado:prepare-new-period` | Close current period and begin a new one. | ✅ Every week on monday, but it still makes periods of 2 weeks
`kado:reset-daily-games` | Resets the daily games for every user to the configured value | ✅ Everyday at 00:00

## Installing / Updating games

For now, each game is remade with Godot. You don't need Godot to be installed.

You just need to run:

```
make update-games
```

Or :
```
docker compose run --rm kadokadeo_app sh /www/update_games.sh
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
- `make sync-database` : Update the database with the migrations

Please see more commands in the [`Makefile`](Makefile) or the [`composer.json`](composer.json#L56-L66) file.
