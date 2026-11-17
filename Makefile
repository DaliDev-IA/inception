NAME = inception

COMPOSE = docker compose --parallel 1 -f srcs/docker-compose.yml

.PHONY: all up down stop start restart build logs ps clean fclean re

all: up

up:
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start

restart:
	$(COMPOSE) restart

build:
	$(COMPOSE) build

logs:
	$(COMPOSE) logs

ps:
	$(COMPOSE) ps

clean:
	$(COMPOSE) down --remove-orphans

fclean:
	$(COMPOSE) down --rmi all --remove-orphans

re: fclean all
