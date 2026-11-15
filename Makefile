
NAME = inception

COMPOSE = docker compose -f srcs/docker-compose.yml

DATA_DIR = /home/mohchams/data

.PHONY: all up down stop start restart build logs ps clean fclean re

all: up

up:
	mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
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

fclean: clean
	$(COMPOSE) down -v --rmi all
	sudo rm -rf $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress

re: fclean all
