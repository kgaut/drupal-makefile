PREPROD_PORT := $(if $(PREPROD_PORT),$(PREPROD_PORT),22)
PROD_PORT := $(if $(PROD_PORT),$(PROD_PORT),22)


## db-dump	:	Dump the database in a dated gzip file within ./db folder
.PHONY: db-dump
db-dump:
	docker exec $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") drush -r $(DRUPAL_ROOT) $(filter-out $@,$(MAKECMDGOALS)) sql-dump --gzip --result-file="../$(LOCAL_DB_PATH)/`date +%Y-%m-%d_%H-%M-%S`-$(PROJECT_BASE_URL)-DEV.sql"

## db-preprod-dump	: Dump the preproduction database
.PHONY: db-preprod-dump
db-preprod-dump:
	ssh -t -p $(PREPROD_PORT) $(PREPROD_USER)@$(PREPROD_HOST) 'cd $(PREPROD_PATH) ; $(PREPROD_DRUSH) sql-dump --structure-tables-key=light --gzip > "$(PREPROD_PATH)/$(PREPROD_DB_PATH)/`date +%Y-%m-%d_%H-%M-%S`-$(PREPROD_URL)-preprod-light.sql.gz"'

## db-prod-dump	: Dump the production database
.PHONY: db-prod-dump
db-prod-dump:
	ssh -t -p $(PROD_PORT) $(PROD_USER)@$(PROD_HOST) 'cd $(PROD_PATH) ; $(PROD_DRUSH) sql-dump --structure-tables-key=light --gzip > "$(PROD_PATH)/db/`date +%Y-%m-%d_%H-%M-%S`-$(PROD_URL)-prod-light.sql.gz"'

## db-preprod-import	:	Récupère le dump le plus récent en prod et l'import en local
##		vide le cache
##		réimporte la configuration
.PHONY: db-prod-import
db-prod-import:
	$(MAKE) db-prod-get
	$(MAKE) db-import

## db-preprod-import	:	Récupère le dump le plus récent en preprod et l'import en local
##		vide le cache
##		réimporte la configuration
.PHONY: db-preprod-import
db-preprod-import:
	$(MAKE) db-preprod-get
	$(MAKE) db-import

## db-prod-get	:	Récupère le dump le plus récent en preprod et l'import
.PHONY: db-prod-get
db-prod-get:
	$(eval DUMP=$(shell ssh $(PROD_USER)@$(PROD_HOST) -p $(PROD_PORT) 'ls -t $(PROD_PATH)/$(PROD_DB_PATH)/ | head -1'))
	@echo Get dump : $(PROD_PATH)/$(PROD_DB_PATH)/$(DUMP)
	@scp -P $(PROD_PORT) $(PROD_USER)@$(PROD_HOST):$(PROD_PATH)/$(PROD_DB_PATH)/$(DUMP) $(LOCAL_DB_PATH)/
	@echo Dump : Dump downloaded in $(LOCAL_DB_PATH)/$(DUMP)

## db-preprod-get	:	Récupère le dump le plus récent en preprod et l'import
.PHONY: db-preprod-get
db-preprod-get:
	$(eval DUMP=$(shell ssh $(PREPROD_USER)@$(PREPROD_HOST) -p $(PREPROD_PORT) 'ls -t $(PREPROD_PATH)/$(PREPROD_DB_PATH)/ | head -1'))
	@echo Get dump : $(PREPROD_PATH)/$(PREPROD_DB_PATH)/$(DUMP)
	@scp -P $(PREPROD_PORT)$(PREPROD_USER)@$(PREPROD_HOST):$(PREPROD_PATH)/$(PREPROD_DB_PATH)/$(DUMP) $(LOCAL_DB_PATH)/
	@echo Dump : Dump downloaded in $(LOCAL_DB_PATH)/$(DUMP)

## db-import	:	Supprime la base de données
##		Recrée la base de données
##		importe le dump le plus récent du dossier db/,
##		vide le cache
##		réimporte la configuration
.PHONY: db-import
db-import: db-empty
	$(eval DUMP=$(shell ls -t $(LOCAL_DB_PATH)/ | head -1))
	@echo Import dump : $(DUMP)
	@docker-compose exec -T $(DB_HOST) zcat /var/db/$(DUMP) | docker-compose exec -T $(DB_HOST) mysql -u"$(DB_USER)" -p"$(DB_PASSWORD)" $(DB_NAME)
	@echo Dump $(DUMP) imported
	$(MAKE) db-post-import
	$(MAKE) drush uli

## db-post-import	:	Supprime la base de données
##		Recrée la base de données
##		importe le dump le plus récent du dossier db/,
##		vide le cache
##		réimporte la configuration

## post-db-import	:	Récupère le dump le plus récent en prod
.PHONY: db-post-import
db-post-import:
	$(MAKE) drush cr
	$(MAKE) drush "updb --no-post-updates"
	$(MAKE) drush cim
	$(MAKE) drush updb

## db-empty	: drop and recreate database
.PHONY: db-empty
db-empty:
	@docker-compose exec -T $(DB_HOST) mysql -u"$(DB_USER)" -p"$(DB_PASSWORD)" -e "DROP DATABASE IF EXISTS $(DB_NAME)"
	@echo Database $(DB_NAME) dropped
	@docker-compose exec -T $(DB_HOST) mysql -u"$(DB_USER)" -p"$(DB_PASSWORD)" -e "CREATE DATABASE $(DB_NAME)"

## dd-tail	: show the tail of drupal-debug.txt file
.PHONY: dd-tail
dd-tail:
	tail -f $(LOCAL_TMP_PATH)/drupal_debug.txt

## watchdog	: tail watchdog messages
.PHONY: watchdog
watchdog:
	while sleep 2; do $(MAKE) drush "watchdog-show"; done

## ssh-preprod	: ssh to preprod
.PHONY: ssh-preprod
ssh-preprod:
	ssh $(PREPROD_USER)@$(PREPROD_HOST) -p $(PREPROD_PORT)

## ssh-prod	: ssh to prod
.PHONY: ssh-prod
ssh-prod:
	ssh $(PROD_USER)@$(PROD_HOST) -p $(PROD_PORT)

## sapi	:	Recharge l'index de solr
.PHONY: sapi
sapi:
	$(MAKE) drush sapi-r
	$(MAKE) drush sapi-i

