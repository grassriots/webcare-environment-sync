# WEBCARE Project Setup Script

**Version:** 1.1.0  
**Release Date:** April 13, 2025

Welcome to the WEBCARE WordPress Local Environment Setup.  
This script automates the full process of creating a Lando-powered local WordPress site based on your Pantheon environment.

## What This Script Does

- Authenticates to Pantheon using your machine token
- Clones the Git repository for your project
- Creates a fresh database backup from Pantheon
- Creates a fresh files (uploads) backup from Pantheon
- Extracts and places all media uploads correctly
- Sets up `.lando.yml` and `.lando.local.yml`
- Generates a working `wp-config-local.php`
- Rebuilds the Lando environment
- Imports the database
- Replaces Pantheon URLs with local URLs
- Automatically opens the local site in your browser

One script. Full setup. Under 5 minutes.

## Requirements

Make sure you have the following installed before using the script:

| Tool | How to Get It |
|:---|:---|
| [Lando](https://docs.lando.dev/) | Install Lando (latest stable version recommended) |
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | Install and start Docker Desktop |
| [Pantheon Terminus](https://pantheon.io/docs/terminus) | Install Terminus CLI |
| Pantheon Machine Token | Generate from your Pantheon Dashboard under Account → Machine Tokens |

## Installation

1. Clone this project repository (or wherever your `create-lando-project.sh` script lives).
2. Ensure the script is executable:

```bash
chmod +x create-lando-project.sh
```

## Usage

Run the script from your terminal:

```bash
./create-lando-project.sh
```

You can optionally provide a destination directory where the project will be installed:

```bash
./create-lando-project.sh --destination /path/to/your/folder
```

If no destination is provided, the project will be created inside the current working directory by default.

You will be prompted for:

- Your Pantheon project machine token
- Your Pantheon project machine name (example: `grassriots`, `ceiu-seic`, etc.)

The script will handle everything else.

## Important Notes

- **Environment Choice:**  
  By default, the script pulls database and files from the **live** environment.  
  This ensures you get the most complete and up-to-date data.

- **Uploads Handling:**  
  Uploads are extracted carefully to match the expected WordPress folder structure.

- **No Rsync Needed:**  
  We use official Pantheon backups (`terminus backup:get`) to ensure full data integrity.

- **Automatic Browser Open:**  
  After setup, your site automatically opens at:

  ```
  http://yourprojectname.lndo.site
  ```

## Troubleshooting

| Problem | Solution |
|:---|:---|
| Docker or Lando won't start | Restart Docker Desktop, then run `lando rebuild -y` manually. |
| Terminus not found | Install Terminus CLI and make sure it's on your PATH. |
| Authentication errors | Double-check your Pantheon machine token. |
| Missing images/files | Ensure you're pulling from **live** and that backups complete successfully. |

## Helpful Commands

| Command | Purpose |
|:---|:---|
| `lando rebuild -y` | Rebuilds Lando environment cleanly |
| `lando start` | Starts the Lando app if it’s stopped |
| `lando stop` | Stops the Lando app |
| `lando phpmyadmin` | Opens PHPMyAdmin locally |
| `lando wp` | Runs WordPress CLI commands inside container |

## Future Improvements (Optional)

- Support CLI flags (e.g., `--project`, `--token`) for non-interactive runs.
- Automated file integrity check after extraction.
- Self-updating project URL detection if project naming conventions change.

## Contributing

Internal WebCare team members:  
Feel free to suggest updates, improvements, or bugfixes.  
We aim for smooth onboarding and clean local environments for every developer.

# Installation Guide and Developer Checklist

## Part 1: Install Required Software

### 1. Docker Desktop
- Install Docker:  
  https://www.docker.com/products/docker-desktop/
- Start Docker Desktop after installation.

### 2. Lando
- Install Lando (latest stable version):  
  https://docs.lando.dev/core/v3/installation.html
- After install, verify with:

```bash
lando version
```
Expected: A version like `v3.x.x`

### 3. Pantheon Terminus CLI
- Install Terminus:

```bash
brew install terminus
```
(or manually via https://pantheon.io/docs/terminus/install)

- Verify installation:

```bash
terminus --version
```
Expected: Something like `3.x.x`

### 4. Pantheon Machine Token
- Go to your Pantheon Dashboard.
- Navigate: **Account → Machine Tokens → Create Token**
- Copy this token safely — you will paste it into the setup script when prompted.

### 5. Permissions
Make sure your script is executable:

```bash
chmod +x create-lando-project.sh
```

## Part 2: Initial Setup Process

1. Run the setup script:

```bash
./create-lando-project.sh
```

2. Input required values when prompted:
   - Paste your Pantheon Machine Token.
   - Enter your project machine name (e.g., `grassriots`, `ceiu-seic`).

3. The script will:
   - Authenticate to Pantheon
   - Clone the Git repository
   - Create and pull fresh backups (database and files)
   - Extract and move media files correctly
   - Generate `.lando.yml` and `.lando.local.yml`
   - Patch `wp-config-local.php`
   - Start Lando containers
   - Import the database
   - Perform WordPress search-replace (update URLs)
   - Open the local website in your browser

## Part 3: Post-Setup Verification Checklist

| Step | Command | Expected Result |
|:---|:---|:---|
| Docker is running | Look for Docker whale icon in system tray | Docker is active |
| Lando is running | `lando list` | Your app listed with status "Running" |
| Local WordPress site opens | Visit `http://projectname.lndo.site` | Website loads, no 403/500 errors |
| Media is visible | Check for logos, images in site header | Images load correctly |
| WordPress Admin | `http://projectname.lndo.site/wp-admin` | Admin dashboard reachable |
| PHPMyAdmin access | `http://pma.projectname.lndo.site` | Database accessible locally |

## Troubleshooting Common Problems

| Problem | Solution |
|:---|:---|
| Docker not starting | Restart Docker Desktop manually |
| Lando start issues | Run `lando rebuild -y` inside the project folder |
| Site not resolving | Ensure Docker/Lando networking is healthy |
| Terminus authentication error | Check your Machine Token and re-login with `terminus auth:login` |
| Media missing | Confirm fresh backup created from **live** and that backups complete successfully |

## Notes

- Always work on a separate Git branch when running migrations or environment updates.
- `.lando.local.yml` should **not** be committed to Git — it is personal and machine-specific.
- Only `.lando.yml` should be version-controlled for team consistency.
- Use the `README.md` for instructions when onboarding new developers.

## Final Visual Architecture After Setup

```
/Sites/projectname/
  ├── .lando.yml
  ├── .lando.local.yml
  ├── wp-content/
  │   └── uploads/
  ├── wp-config-local.php
  ├── README.md
  └── create-lando-project.sh
```

## Ready to Work

Once setup is complete:

- Run `lando wp` to use WP-CLI.
- Run `lando phpmyadmin` to manage databases visually.
- Develop and debug safely with full local media and database copies.
