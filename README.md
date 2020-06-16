# Makefile for Drupal
Generic makefile rules to manage a drupal 8+ project

## Installation
```bash
composer require kgaut/drupal-makefile
```

Edit your `.env` file and copy / paste the following vars, do not forget to update values  : 
```
### --- PROD_ENV ----
PROD_USER=my_user # SSH User 
PROD_HOST=my_host # SSH Host or IP
PROD_PATH=/path/to/website # SSH path to website (composer folder, not docroot) (ie : ~/website)
PROD_DRUSH=path/to/drush # path to drush (ie : ~/website/vendor/bin/drush)
PROD_URL=my-website.net # Prod url
PROD_DB_PATH=db # Database folder containing dumps relative to PROD_PATH (ie: db)

### --- PREPROD_ENV ----
PREPROD_USER=my_user_preprod # SSH User 
PREPROD_HOST=my_host_preprod # SSH Host or IP
PREPROD_PATH=/path/to/website # SSH path to website (composer folder, not docroot) (ie : ~/website)
PREPROD_DRUSH=~/website/vendor/bin/drush # path to drush (ie : ~/website/vendor/bin/drush)
PREPROD_URL=preprod.my-website.net # preprod url
PREPROD_DB_PATH=db # Database folder containing dumps relative to PREPROD_PATH (ie: db)

### --- LOCAL_ENV ----
LOCAL_TMP_PATH=./files/tmp # Local path to drupal temporary files
LOCAL_DB_PATH=db # Local path where to store database dumps
```

Edit `Makefile` and add just after the line `include .env` : 

```
include vendor/kgaut/drupal-makefile/drupal.mk
```

Mount your local dump folder to `/var/db` within your mariadb container.

Sample of mariadb service definition : 
```
  mariadb:
    image: wodby/mariadb:$MARIADB_TAG
    container_name: "${PROJECT_NAME}_mariadb"
    stop_grace_period: 30s
    environment:
      MYSQL_ROOT_PASSWORD: $DB_ROOT_PASSWORD
      MYSQL_DATABASE: $DB_NAME
      MYSQL_USER: $DB_USER
      MYSQL_PASSWORD: $DB_PASSWORD
    volumes:
      - ./$LOCAL_DB_PATH:/var/db
```

## Availables rules
### db-dump
```make db-dump```
Create a local database gziped dump.

### db-preprod-dump
```make db-preprod-dump```
Create a preproduction database gziped dump.

### db-prod-dump
```make db-prod-dump```
Create a production database gziped dump.

### db-prod-import
```make db-prod-import```
Empty local database, import the most recent database dump from production, rebuild caches, run database updates, import configuration and provide an authentification url as user 1.

### db-preprod-import
```make db-preprod-import```
Empty local database, import the most recent database dump from preproduction, rebuild caches, run database updates, import configuration and provide an authentification url as user 1.

### db-prod-get
```make db-prod-get```
Download the most recent database dump from production.

### db-preprod-get
```make db-preprod-get```
Download the most recent database dump from preproduction.

### db-import
```make db-preprod-get```
Empty local database, import the most recent dump available localy, rebuild caches, run database updates, import configuration and provide an authentification url as user 1.

### db-post-import
```make db-preprod-get```
Rebuild caches, run database updates, import configuration and provide an authentification url as user 1.

### db-empty
```make db-empty```
Empty local database.

### dd-tail
```make dd-tail```
Tail the drupal-debug.txt files.

### watchdog
```make watchdog```
Tail the watchdog entries.

### ssh-prod
```make ssh-prod```
Open a ssh connexion to production server.
  
### ssh-preprod
```make ssh-preprod```
Open a ssh connexion to preproduction server.
  
### sapi
```make sapi```
Rebuild Search API indexes
