#!/bin/bash

# ================================================================
# WEBCARE WordPress Local Setup Script
#
# This script automates the setup of a local Lando environment
# for a WordPress site hosted on Pantheon.
#
# It will:
# - Authenticate to Pantheon
# - Clone the Git repository
# - Pull the latest database and files
# - Generate proper local configuration files
# - Start and rebuild Lando
# - Update WordPress URLs for local development
# - Open the local site automatically
#
# Author: WebCare Team
# Last Updated: 2025-04-12
# ================================================================

clear
cat << "EOF"
 __     __     ______     ______     ______     ______     ______     ______                                    
/\ \  _ \ \   /\  ___\   /\  == \   /\  ___\   /\  __ \   /\  == \   /\  ___\                                   
\ \ \/ ".\ \  \ \  __\   \ \  __<   \ \ \____  \ \  __ \  \ \  __<   \ \  __\                                   
 \ \__/".~\_\  \ \_____\  \ \_____\  \ \_____\  \ \_\ \_\  \ \_\ \_\  \ \_____\                                 
  \/_/   \/_/   \/_____/   \/_____/   \/_____/   \/_/\/_/   \/_/ /_/   \/_____/                                 
                                                                                                                
 ______     ______     ______   __  __     ______      ______     ______     ______     __     ______   ______  
/\  ___\   /\  ___\   /\__  _\ /\ \/\ \   /\  == \    /\  ___\   /\  ___\   /\  == \   /\ \   /\  == \ /\__  _\ 
\ \___  \  \ \  __\   \/_/\ \/ \ \ \_\ \  \ \  _-/    \ \___  \  \ \ \____  \ \  __<   \ \ \  \ \  _-/ \/_/\ \/ 
 \/\_____\  \ \_____\    \ \_\  \ \_____\  \ \_\       \/\_____\  \ \_____\  \ \_\ \_\  \ \_\  \ \_\      \ \_\ 
  \/_____/   \/_____/     \/_/   \/_____/   \/_/        \/_____/   \/_____/   \/_/ /_/   \/_/   \/_/       \/_/ 
                                                                                                                
EOF

# Default destination to current directory
DESTINATION=$(pwd)

# Parse parameters
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -d|--destination)
      DESTINATION="$2"
      shift
      shift
      ;;
    *)    
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "Destination directory: $DESTINATION"

echo ""
echo "Starting WEBCARE Project Setup"
echo "------------------------------------"

# --------------------------------------------------
# Authenticate to Pantheon
# --------------------------------------------------
echo "Enter the project machine name (example: grassriots):"
read PROJECT_NAME

echo "Enter your Pantheon Machine Token:"
read -s MACHINE_TOKEN
echo ""

# Authenticate to Terminus
echo "Authenticating to Pantheon..."
terminus auth:login --machine-token=$MACHINE_TOKEN
if [ $? -ne 0 ]; then
  echo -e "\033[0;31m❌ Authentication to Pantheon failed. Exiting.\033[0m"
  exit 1
fi

# Try to get Git URL and verify Pantheon connection
echo "Retrieving Git URL from Pantheon..."
if ! terminus connection:info "$PROJECT_NAME.dev" >/dev/null 2>&1; then
  echo -e "\033[0;31m❌ Unable to connect to Pantheon site '$PROJECT_NAME'. Please verify the site name and your authentication.\033[0m"
  exit 1
fi

# --------------------------------------------------
# Clone Git Repository
# --------------------------------------------------
GIT_URL=$(terminus connection:info "$PROJECT_NAME.dev" --field=git_url)
if [ -z "$GIT_URL" ]; then
  # Try alternate field name
  GIT_URL=$(terminus connection:info "$PROJECT_NAME.dev" --format=json | grep -o '"ssh_url":"[^"]*"' | cut -d'"' -f4)
  if [ -z "$GIT_URL" ]; then
    echo -e "\033[0;31m❌ Unable to get Git URL from Pantheon. Please verify the site exists and you have access.\033[0m"
    exit 1
  fi
fi

mkdir -p "$DESTINATION/$PROJECT_NAME"
cd "$DESTINATION/$PROJECT_NAME" || exit

echo "Cloning Git repository..."
git clone "$GIT_URL" .
if [ $? -ne 0 ]; then
  echo "Git clone failed. Exiting."
  exit 1
fi
git checkout master

# --------------------------------------------------
# Download Database and Files
# --------------------------------------------------
echo "Downloading latest database backup..."
terminus backup:get $PROJECT_NAME.dev --element=db --to=database.sql.gz
if [ -f database.sql.gz ]; then
  gunzip database.sql.gz
else
  echo -e "\033[0;31mWarning: database.sql.gz not found, skipping DB extraction.\033[0m"
fi

# Create a fresh backup for files
echo "Creating fresh files backup on Pantheon..."
terminus backup:create $PROJECT_NAME.live --element=files

echo "Downloading latest files backup..."
terminus backup:get $PROJECT_NAME.live --element=files --to=files.tar.gz

if [ -f files.tar.gz ]; then
  echo "Extracting files backup..."
  mkdir -p extracted_files
  tar -xvf files.tar.gz -C extracted_files

  echo "Preparing uploads directory..."
  mkdir -p wp-content/uploads

  # Dynamically locate the uploads folder
  UPLOADS_PATH=""
  if [ -d extracted_files/files-live ]; then
    UPLOADS_PATH="extracted_files/files-live"
  elif [ -d extracted_files/files_live ]; then
    UPLOADS_PATH="extracted_files/files_live"
  elif [ -d extracted_files/files/uploads ]; then
    UPLOADS_PATH="extracted_files/files/uploads"
  elif [ -d extracted_files/uploads ]; then
    UPLOADS_PATH="extracted_files/uploads"
  fi

  if [ -n "$UPLOADS_PATH" ]; then
    echo "Moving uploads from detected path: $UPLOADS_PATH"
    mv "$UPLOADS_PATH"/* wp-content/uploads/
  else
    echo -e "\033[0;31mWarning: Could not locate uploads folder after extraction.\033[0m"
  fi

  echo "Cleaning up temporary extraction..."
  rm -rf extracted_files
else
  echo -e "\033[0;31mWarning: files.tar.gz not found. Skipping file extraction.\033[0m"
fi

# --------------------------------------------------
# Configure Lando
# --------------------------------------------------
echo "Creating .lando.yml configuration..."
cat > .lando.yml <<EOL
name: $PROJECT_NAME
recipe: wordpress

config:
  webroot: .
  php: '8.2'
  database: mariadb:10.4
  xdebug: true
  via: nginx

services:
  appserver:
    type: php
    xdebug: true
    overrides:
      environment:
        XDEBUG_MODE: debug,develop

  database:
    type: mariadb:10.4
    portforward: true
    overrides:
      platform: linux/amd64

  pma:
    type: phpmyadmin
    port: 8081
    hosts:
      - database
    overrides:
      platform: linux/amd64

proxy:
  appserver_nginx:
    - ${PROJECT_NAME}.lndo.site
  pma:
    - pma.${PROJECT_NAME}.lndo.site

tooling:
  wp:
    service: appserver
  mysql:
    service: database
  phpmyadmin:
    service: pma
EOL

# Create .lando.local.yml
echo "Creating .lando.local.yml for local overrides..."
cat > .lando.local.yml <<EOL
# Local-only configuration. Can be empty for now.
EOL

# --------------------------------------------------
# Setup wp-config-local.php
# --------------------------------------------------
echo "Preparing wp-config-local.php for local development..."
if [ -f wp-config-local-sample.php ]; then
  cp wp-config-local-sample.php wp-config-local.php

  # Patch database settings
  sed -i '' "s/'database_name'/'wordpress'/" wp-config-local.php
  sed -i '' "s/'database_username'/'wordpress'/" wp-config-local.php
  sed -i '' "s/'database_password'/'wordpress'/" wp-config-local.php
  sed -i '' "s/'database_host'/'database'/" wp-config-local.php

  # Patch WP_HOME and WP_SITEURL
  sed -i '' "s|'<YOUR LOCAL DOMAIN>'|'http://${PROJECT_NAME}.lndo.site'|" wp-config-local.php

  # Insert HTTPS proxy fix only
  sed -i '' "2i\\
\\
// Lando local HTTPS handling\\
if (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && \$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {\\
  \$_SERVER['HTTPS'] = 'on';\\
}\\
" wp-config-local.php

  # Insert Redis disabling fix after HTTPS handling
  sed -i '' "10i\\
\\
// Disable Redis cache when running locally\\
if (defined('PANTHEON_ENVIRONMENT') && PANTHEON_ENVIRONMENT === 'lando') {\\
  define('WP_REDIS_DISABLED', true);\\
}\\
" wp-config-local.php
else
  echo -e "\033[0;31mWarning: wp-config-local-sample.php not found. Skipping wp-config-local.php setup.\033[0m"
fi

# --------------------------------------------------
# Rebuild Lando and Import Database
# --------------------------------------------------
# Harden .gitignore
echo "Ensuring proper .gitignore rules..."
if [ ! -f ".gitignore" ]; then
  touch .gitignore
fi

for pattern in ".lando.local.yml" "database.sql" "database.sql.gz" "files.tar.gz" "files_dev/" "web/wp-content/uploads/" "wp-config-local.php" "*.tar.gz" "*.sql" "*.sql.gz"; do
  if ! grep -q "$pattern" ".gitignore"; then
    echo "$pattern" >> .gitignore
  fi
done

# Rebuild and start Lando
echo "Rebuilding and starting Lando environment..."
lando rebuild -y

# Wait for the database service to be ready
echo "Waiting for Lando database service to be ready..."
TRIES=0
MAX_TRIES=10

until lando mysqladmin ping --silent; do
  sleep 3
  TRIES=$((TRIES + 1))
  if [ $TRIES -ge $MAX_TRIES ]; then
    echo -e "\033[0;31mDatabase did not become ready in time. Skipping database import.\033[0m"
    break
  fi
done

# Import database if database.sql exists
if [ -f database.sql ]; then
  echo "Importing local database..."
  lando db-import database.sql

  echo "Running search-replace to update URLs..."
  OLD_URL="https://${PROJECT_NAME}.pantheonsite.io"
  NEW_URL="http://${PROJECT_NAME}.lndo.site"
  lando wp search-replace "$OLD_URL" "$NEW_URL" --skip-columns=guid
else
  echo -e "\033[0;31mWarning: database.sql not found. Skipping database import.\033[0m"
fi

# --------------------------------------------------
# Finalize Setup and Open Site
# --------------------------------------------------
echo ""
echo "WEBCARE Project setup complete!"
echo ""
echo "Visit your site at: https://${PROJECT_NAME}.lndo.site"

# Open the site automatically if possible
echo "Opening your site in the browser..."
if [[ "$OSTYPE" == "darwin"* ]]; then
  open "https://${PROJECT_NAME}.lndo.site"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  xdg-open "https://${PROJECT_NAME}.lndo.site"
fi