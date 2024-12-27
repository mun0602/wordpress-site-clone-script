#!/bin/bash
# Script to copy a WordPress site on WordOps to a new domain on the same server

# Prompt for old and new domain names
read -p "Enter the old domain name (e.g., olddomain.tld): " OLDDOMAIN
read -p "Enter the new domain name (e.g., newdomain.tld): " NEWDOMAIN

# 1. Create a new WordPress site on the new domain
wo site create $NEWDOMAIN --wpredis

# 2. Clean default data from the new site
sudo -u www-data -H wp db clean --yes --path=/var/www/$NEWDOMAIN/htdocs
rm -rf /var/www/$NEWDOMAIN/htdocs/*

# 3. Sync files from the old domain to the new domain
rsync -avzh /var/www/$OLDDOMAIN/htdocs/ /var/www/$NEWDOMAIN/htdocs/

# 4. Remove wp-config.php to avoid conflicts
rm /var/www/$NEWDOMAIN/htdocs/wp-config.php

# 5. Export the database from the old site
cd /var/www/$OLDDOMAIN/htdocs
wp db export ${OLDDOMAIN}.sql --allow-root

# 6. Import the database to the new site
cp /var/www/$OLDDOMAIN/htdocs/${OLDDOMAIN}.sql /var/www/$NEWDOMAIN/htdocs/
cd /var/www/$NEWDOMAIN/htdocs
wp db import ${OLDDOMAIN}.sql --allow-root
rm ${OLDDOMAIN}.sql

# 7. Update URLs in the new database
wp search-replace "https://$OLDDOMAIN" "https://$NEWDOMAIN" --skip-columns=guid --allow-root

# 8. Enable SSL for the new domain
wo site update $NEWDOMAIN -le

# 9. Restart services
wo stack restart

# Completion message
echo "Site $OLDDOMAIN has been successfully copied to $NEWDOMAIN."
