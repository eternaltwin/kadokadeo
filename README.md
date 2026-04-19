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

# Kadokadéo

## Configuration

Go to [Install the project](#install-the-project) if you need to install the project first.

Here are the configuration variables:

| Variable                    | Description                                                                | Default                           |
| --------------------------- | -------------------------------------------------------------------------- | --------------------------------- |
| `KADO_GAMES_PER_DAY`        | Games allowed to play per user per day                                     | 100                               |
| `KADO_RUNS_MAX_CONCURRENCY` | Maximum amount of games a user can play in parallel before being throttled | 5                                 |
| `KADO_RSA_PRIVATE_KEY_PATH` | Private RSA key path of the server. Should be kept **private**.            | `storage/app/private/privkey.pem` |
| `KADO_RSA_PUBLIC_KEY_PATH`  | Public key path associated with the private key                            | `storage/app/private/pubkey.pem`  |

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

| Command                   | Description                                                   | Ran in CRON                                                    |
| ------------------------- | ------------------------------------------------------------- | -------------------------------------------------------------- |
| `migrate`                 | Synchronises the database                                     | ❌                                                             |
| `kado:prepare-new-period` | Close current period and begin a new one.                     | ✅ Every week on monday, but it still makes periods of 2 weeks |
| `kado:reset-daily-games`  | Resets the daily games for every user to the configured value | ✅ Everyday at 00:00                                           |

## Installing / Updating games

To update/compile every game (resources/hx):

```
make compile-games
```

## Installing with Docker

### Install the project

Everything in one copy/paste :

```bash
git clone git@gitlab.com:eternaltwin/kadokadeo/kadokadeo.git
cd kadokadeo
git checkout main
make
```

If everything goes well you should be able to access to :

- KadoKadéo on http://kadokadeo.localhost/
- Eternaltwin on http://localhost:50320

> [!WARNING]  
> When logging in for the first time, you should create a local EternalTwin account.
> But the redirect URL is something like http://kadokadeo-eternaltwin:50320/....
> You need to manually replace by http://localhost:50320/...

## Some useful commands

- `make docker-watch` : Start the project with logs
- `make docker-start` : Start the project in the background
- `make bash-app` : Enter the application container to run `composer` or `php` commands
- `make reset-database` : Reset the database
- `make sync-database` : Update the database with the migrations

Please see more commands in the [`Makefile`](Makefile) or the [`composer.json`](composer.json#L56-L66) file.

## Porting a game

Some useful documents are located in `.opencode/skills` folder, depending or what you are trying to achieve.
Please read them.
