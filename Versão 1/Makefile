NAME = inception

COMPOSE_FILE = srcs/docker-compose.yml
DATA_DIR = /home/$(USER)/data

GREEN = \033[1;32m
YELLOW = \033[33m
RESET = \033[0m

# ===================== RULES =====================

all: up

up: setup
	@echo "$(YELLOW)Building Inception...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) up --build -d
	@echo "$(GREEN)Inception is Ready!$(RESET)"

setup:
	@./srcs/requirements/tools/setup.sh
	@mkdir -p $(DATA_DIR)/mariadb
	@mkdir -p $(DATA_DIR)/wordpress

down:
	@docker compose -f $(COMPOSE_FILE) down
	@echo "$(GREEN)Containers stopped!$(RESET)"


# ===================== CLEAN =====================

clean: down
	@docker compose -f $(COMPOSE_FILE) down -v --rmi local
	@sudo rm -rf $(DATA_DIR)
	@echo "$(GREEN)Clean done!$(RESET)"

fclean: clean
	@docker system prune -af
	@echo "$(GREEN)Full clean done!$(RESET)"

re: fclean all

# ===================== DEBUG =====================

logs:
	@docker compose -f $(COMPOSE_FILE) logs -f

status:
	@docker compose -f $(COMPOSE_FILE) ps

config:
	@docker compose -f $(COMPOSE_FILE) config

images:
	@docker compose -f $(COMPOSE_FILE) config --images

network:
	@docker network ls

help:
	@echo "$(YELLOW)Available commands:$(RESET)"
	@echo "  make         Build and start the project"
	@echo "  make up      Build and start the project"
	@echo "  make down    Stop containers"
	@echo "  make clean   Remove containers, images and data"
	@echo "  make fclean  Clean Docker resources"
	@echo "  make re      Full rebuild"
	@echo "  make logs    Show logs"
	@echo "  make status  Show container status"
	@echo "  make config  Validate Compose configuration"
	@echo "  make images  Show image names"
	@echo "  make network Show Docker networks"


.PHONY: all up setup down clean fclean re logs status config images network help
