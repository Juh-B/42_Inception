NAME = inception

COMPOSE = docker compose
COMPOSE_FILE = srcs/docker-compose.yml
DATA_DIR = /home/$(USER)/data

GREEN = \033[1;32m
YELLOW = \033[33m
RED = \033[1;31m
RESET = \033[0m

# ===================== RULES =====================

all: up

up: create_dirs
	@echo "$(YELLOW)Building and starting Inception...$(RESET)"
	@$(COMPOSE) -f $(COMPOSE_FILE) up -d --build
	@echo "$(GREEN)Inception is Ready!$(RESET)"

create_dirs:
	@mkdir -p $(DATA_DIR)/mariadb
	@mkdir -p $(DATA_DIR)/wordpress

down:
	@echo "$(YELLOW)Stopping Inception...$(RESET)"
	@$(COMPOSE) -f $(COMPOSE_FILE) down
	@echo "$(GREEN)Inception stopped!$(RESET)"

# ===================== STATUS =====================

status:
	@$(COMPOSE) -f $(COMPOSE_FILE) ps

logs:
	@$(COMPOSE) -f $(COMPOSE_FILE) logs -f

# ===================== CLEAN =====================

clean: down
	@echo "$(YELLOW)Removing volumes...$(RESET)"
	@$(COMPOSE) -f $(COMPOSE_FILE) down -v
	@sudo rm -rf $(DATA_DIR)
	@echo "$(GREEN)Clean done!$(RESET)"

fclean: clean
	@echo "$(YELLOW)Removing Docker images and unused resources...$(RESET)"
	@docker system prune -af
	@echo "$(GREEN)Full clean done!$(RESET)"

re: fclean all

.PHONY: all up create_dirs down status logs clean fclean re
