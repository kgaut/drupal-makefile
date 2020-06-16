# Makefile for Drupal
Generic makefile rules to manage a drupal 8+ project

## Installation
```bash
composer require kgaut/drupal-makefile
```

Edit your .env file and copy / paste the following vars, do not forget to update values  : 
```
### --- PROD_ENV ----
PROD_USER=my_user # SSH User 
PROD_HOST=my_host # SSH Host or IP
PROD_PATH=/path/to/website # SSH path to website (composer folder, not docroot) (ie : ~/website)
PROD_DRUSH=path/to/drush # path to drush (ie : ~/website/vendor/bin/drush)
PROD_URL=my-website.net # Prod url

### --- PREPROD_ENV ----
PREPROD_USER=my_user_preprod # SSH User 
PREPROD_HOST=my_host_preprod # SSH Host or IP
PREPROD_PATH=/path/to/website # SSH path to website (composer folder, not docroot) (ie : ~/website)
PREPROD_DRUSH=~/website/vendor/bin/drush # path to drush (ie : ~/website/vendor/bin/drush)
PREPROD_URL=preprod.my-website.net # preprod url

### --- LOCAL_ENV ----
LOCAL_TMP_PATH=./files/tmp # Local path to drupal temporary files
LOCAL_DB_PATH=./db # Local path where to store database dumps
```

Edit `./Makefile` and add just after the line `include .env` : 

```
include vendor/kgaut/drupal-makefile/drupal.mk
```
