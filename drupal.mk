PREPROD_PORT := $(if $(PREPROD_PORT),$(PREPROD_PORT),22)
PROD_PORT := $(if $(PROD_PORT),$(PROD_PORT),22)


## db-dump :
##	Dump the database in a dated gzip file within ./db folder
.PHONY: db-dump
db-dump:
	$(eval DUMP := $(if $(filter-out $@,$(MAKECMDGOALS)),$(filter-out $@,$(MAKECMDGOALS)),DEV))
	docker exec $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") drush -r $(DRUPAL_ROOT) sql-dump --gzip --result-file="../$(LOCAL_DB_PATH)/`date +%Y-%m-%d_%H-%M-%S`-$(PROJECT_BASE_URL)-$(DUMP).sql"

## db-preprod-dump :
##	Dump the preproduction database
.PHONY: db-preprod-dump
db-preprod-dump:
	@echo "Database dump started"
	ssh -t -p $(PREPROD_PORT) $(PREPROD_USER)@$(PREPROD_HOST) 'cd $(PREPROD_PATH) ; $(PREPROD_DRUSH) sql-dump --structure-tables-key=light --gzip > "$(PREPROD_PATH)/$(PREPROD_DB_PATH)/`date +%Y-%m-%d_%H-%M-%S`-$(PREPROD_URL)-preprod-light.sql.gz"'
	@echo "Database dump over" :
	@ssh -t -p $(PREPROD_PORT) $(PREPROD_USER)@$(PREPROD_HOST) 'ls -alh $(PREPROD_PATH)/$(PREPROD_DB_PATH)'


## db-prod-dump	: 
##	Dump the production database
.PHONY: db-prod-dump
db-prod-dump:
	@echo Database dump started
	ssh -t -p $(PROD_PORT) $(PROD_USER)@$(PROD_HOST) 'cd $(PROD_PATH) ; $(PROD_DRUSH) sql-dump --structure-tables-key=light --gzip > "$(PROD_PATH)/$(PROD_DB_PATH)/`date +%Y-%m-%d_%H-%M-%S`-$(PROD_URL)-prod-light.sql.gz"'
	@echo Database dump over :
	@ssh -t -p $(PROD_PORT) $(PROD_USER)@$(PROD_HOST) 'ls -alh $(PROD_PATH)/$(PROD_DB_PATH)'

## db-preprod-import :	
##	Récupère le dump le plus récent en prod et l'import en local
##	vide le cache
##	réimporte la configuration
.PHONY: db-prod-import
db-prod-import:
	$(MAKE) db-prod-get
	$(MAKE) db-import

## db-preprod-import :	
##	Récupère le dump le plus récent en preprod et l'import en local
##	vide le cache
##	réimporte la configuration
.PHONY: db-preprod-import
db-preprod-import:
	$(MAKE) db-preprod-get
	$(MAKE) db-import

## db-prod-get :
##	Récupère le dump le plus récent en preprod et l'import
.PHONY: db-prod-get
db-prod-get:
	$(eval DUMP=$(shell ssh $(PROD_USER)@$(PROD_HOST) -p $(PROD_PORT) 'ls -t $(PROD_PATH)/$(PROD_DB_PATH)/ | egrep '\.sql.gz' | head -1'))
	@echo Get dump : $(PROD_PATH)/$(PROD_DB_PATH)/$(DUMP)
	@scp -P $(PROD_PORT) $(PROD_USER)@$(PROD_HOST):$(PROD_PATH)/$(PROD_DB_PATH)/$(DUMP) $(LOCAL_DB_PATH)/
	@echo Dump : Dump downloaded in $(LOCAL_DB_PATH)/$(DUMP)

## db-preprod-get :
##	Récupère le dump le plus récent en preprod et l'import
.PHONY: db-preprod-get
db-preprod-get:
	$(eval DUMP=$(shell ssh $(PREPROD_USER)@$(PREPROD_HOST) -p $(PREPROD_PORT) 'ls -t $(PREPROD_PATH)/$(PREPROD_DB_PATH)/ | egrep '\.sql.gz' | head -1'))
	@echo Get dump : $(PREPROD_PATH)/$(PREPROD_DB_PATH)/$(DUMP)
	@scp -P $(PREPROD_PORT) $(PREPROD_USER)@$(PREPROD_HOST):$(PREPROD_PATH)/$(PREPROD_DB_PATH)/$(DUMP) $(LOCAL_DB_PATH)/
	@echo Dump : Dump downloaded in $(LOCAL_DB_PATH)/$(DUMP)

## db-prod-send :
##	Envoi le dump le plus récent en prod
.PHONY: db-prod-send
db-prod-send:
	$(eval DUMP=$(shell ls -t ./$(LOCAL_DB_PATH) | egrep '\.sql.gz' | head -1))
	@echo Send dump : $(DUMP)
	@scp -P $(PROD_PORT) $(LOCAL_DB_PATH)/$(DUMP) $(PROD_USER)@$(PROD_HOST):$(PROD_PATH)/$(PROD_DB_PATH)/
	@echo Dump : Dump sended to $(PROD_PATH)/$(PROD_DB_PATH)/$(DUMP)


## db-preprod-send :
##	Envoi le dump le plus récent en preprod
.PHONY: db-preprod-send
db-preprod-get:
	$(eval DUMP=$(shell ls -t ./$(LOCAL_DB_PATH) | egrep '\.sql.gz' | head -1))
	@echo Send dump : $(DUMP)
	@scp -P $(PREPROD_PORT) $(LOCAL_DB_PATH)/$(DUMP) $(PREPROD_USER)@$(PREPROD_HOST):$(PREPROD_PATH)/$(PREPROD_DB_PATH)/
	@echo Dump : Dump sended to $(PREPROD_PATH)/$(PREPROD_DB_PATH)/$(DUMP)

## db-import :	
##	Supprime la base de données
##	Recrée la base de données
##	importe le dump le plus récent du dossier db/, ou le dump passé en paramètre
##	Vide le cache
##	Réimporte la configuration
.PHONY: db-import
db-import: db-empty
	$(eval DUMP := $(if $(filter-out $@,$(MAKECMDGOALS)),$(filter-out $@,$(MAKECMDGOALS)),$(shell ls -t $(LOCAL_DB_PATH)/ | head -1)))
	@echo Import dump : $(DUMP)
	@docker compose exec -T $(DB_HOST) zcat /var/db/$(DUMP) | docker compose exec -T $(DB_HOST) mysql -u"$(DB_USER)" -p"$(DB_PASSWORD)" $(DB_NAME)
	@echo Dump $(DUMP) imported
	$(MAKE) drush deploy
	$(MAKE) drush uli


## db-import-only :	
##	Supprime la base de données
##	Recrée la base de données
##	importe le dump le plus récent du dossier db/, ou le dump passé en paramètre
##	Vide le cache
.PHONY: db-import-only
db-import-only: db-empty
	$(eval DUMP := $(if $(filter-out $@,$(MAKECMDGOALS)),$(filter-out $@,$(MAKECMDGOALS)),$(shell ls -t $(LOCAL_DB_PATH)/ | head -1)))
	@echo Import dump : $(DUMP)
	@docker compose exec -T $(DB_HOST) zcat /var/db/$(DUMP) | docker compose exec -T $(DB_HOST) mysql -u"$(DB_USER)" -p"$(DB_PASSWORD)" $(DB_NAME)
	@echo Dump $(DUMP) imported
	$(MAKE) drush cr
	$(MAKE) drush uli


## db-empty :
##	drop and recreate database
.PHONY: db-empty
db-empty:
	@docker compose exec -T $(DB_HOST) mysql -u"$(DB_USER)" -p"$(DB_PASSWORD)" -e "DROP DATABASE IF EXISTS $(DB_NAME)"
	@echo Database $(DB_NAME) dropped
	@docker compose exec -T $(DB_HOST) mysql -u"$(DB_USER)" -p"$(DB_PASSWORD)" -e "CREATE DATABASE $(DB_NAME)"

## dd-tail :
##	show the tail of drupal-debug.txt file
.PHONY: dd-tail
dd-tail:
	tail -f $(LOCAL_TMP_PATH)/drupal_debug.txt

## watchdog :
##	tail watchdog messages
.PHONY: watchdog
watchdog:
	$(MAKE) drush "watchdog-show --tail --count=50"

## ssh-preprod :
##	ssh to preprod
.PHONY: ssh-preprod
ssh-preprod:
	ssh $(PREPROD_USER)@$(PREPROD_HOST) -p $(PREPROD_PORT)

## ssh-prod :
##	ssh to prod
.PHONY: ssh-prod
ssh-prod:
	ssh $(PROD_USER)@$(PROD_HOST) -p $(PROD_PORT)

## sapi	:
##	Recharge l'index de solr
.PHONY: sapi
sapi:
	$(MAKE) drush sapi-r
	$(MAKE) drush sapi-i

