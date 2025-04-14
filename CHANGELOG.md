# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.1.0] - 2025-04-13

### Added
- New `--destination` parameter to specify project installation path during setup.
- Automatically disable Redis cache locally in `wp-config-local.php` to avoid Redis connection errors in Lando.

### Changed
- Updated `.lando.yml` generation to explicitly use `via: nginx` for local development.
- Corrected proxy settings to map the main project URL to `appserver_nginx` to avoid double URL assignment errors in Lando.

## [1.0.0] - 2025-04-12

### Added
- Initial stable release of the WEBCARE Local Setup Script.
- Authenticates to Pantheon using machine token.
- Clones Git repository for the project.
- Pulls fresh database and files backup from Pantheon.
- Extracts and moves media files correctly into local WordPress structure.
- Generates `.lando.yml`, `.lando.local.yml`, and patches `wp-config-local.php`.
- Rebuilds Lando environment, imports database, updates WordPress URLs, and opens the site automatically.
