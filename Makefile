all: install docker-start
	@echo "Project installed successfully! You can access Kadokadéo at http://kadokadeo.localhost/."

docker-start: docker-stop
	docker compose up -d --no-recreate --remove-orphans --build

docker-watch:
	docker compose up --no-recreate --remove-orphans

docker-stop:
	docker compose stop

docker-remove: docker-stop
	docker rm kadokadeo_app kadokadeo_database kadokadeo_eternaltwin

bash-app:
	docker exec -u dev -it kadokadeo_app bash

bash-app-root:
	docker exec -it kadokadeo_app bash

bash-db:
	docker exec -it kadokadeo_database bash

bash-eternaltwin:
	docker exec -it kadokadeo_eternaltwin bash

reset-dependencies: install-app install-eternaltwin

build:
	docker compose build
	docker compose run -u node kadokadeo_eternaltwin chown -R node:node /www
	docker compose up --no-start --remove-orphans

install: setup-env-variables build start-kadokadeo-database install-app
	docker compose run -u node kadokadeo_eternaltwin yarn install
	docker compose run -u node kadokadeo_eternaltwin yarn etwin db create

install-app:
	docker compose run -u dev kadokadeo_app composer install
	docker compose run -u dev kadokadeo_app php artisan key:generate --ansi
	docker compose run -u dev kadokadeo_app php artisan migrate:fresh --force

install-eternaltwin:
	docker compose run -u node kadokadeo_eternaltwin yarn install

reset-database:
	docker compose run -u dev kadokadeo_app php artisan migrate:fresh --force --seed

reset-eternaltwin-database:
	docker compose run -u node kadokadeo_eternaltwin yarn etwin db create

start-kadokadeo-database:
	docker start kadokadeo_database

setup-env-variables:
	cp docker-compose.override.yml.example docker-compose.override.yml
	cp .env.example .env
	cp eternaltwin/etwin.toml.example eternaltwin/etwin.toml

sync-database:
	docker compose run -u dev kadokadeo_app php artisan migrate --force

update-games:
	git submodule update --init --recursive
	git submodule update --recursive --remote
