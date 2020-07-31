# Nextcloud on Ubuntu 2004

Bash install of Nextcloud 19.0.1 on Ubuntu Server 2004


#################################################################################################

Distributor ID: Ubuntu
Description:    Ubuntu 20.04 LTS
Release:        20.04
Codename:       focal

PHP 7.4.8 (cli) (built: Jul 13 2020 16:46:22) ( NTS )
Copyright (c) The PHP Group
Zend Engine v3.4.0, Copyright (c) Zend Technologies
with Zend OPcache v7.4.8, Copyright (c), by Zend Technologies

MariaDB  Server version: 10.5.4-MariaDB-1:10.5.4+maria~focal mariadb.org binary distribution

Nextcloud ver 19.0.1

Instance Build 17/07/20

#################################################################################################

1. Télécharger et Installer Ubuntu Server 2004 sur votre serveur ou votre PC / Download and Install Ubuntu Server 2004 on your server or your computer.

2. `git clone https://github.com/ElPenguin/BashScriptNextcloud19.0.1UbuntuServer2004.git`

3. `cd ./BashScriptNextcloud19.0.1UbuntuServer2004`.

4. `sudo bash nextcloudInstall_v1.7.sh`.

5. Le Bash d'installation vient de finir veuillez aller sur votre IP pour configurer Nextcloud / The install Bash has just finished please go to your IP to configure Nextcloud.

6. (ATTENTION) (WARNING) Au moment de la création de ce tuto certains avertissements étaient présents, voici comment régler ces problèmes / At the time of the creation of this tutorial certain warnings were present, here's how to fix them.
    - Errors :
    - PHP getenv("path") -> `sudo bash phpgetenv.sh`
    - PHP limit 512 Mo -> `sudo bash phplimit.sh`
    - Pas de cache mémpoire / No memory cache -> `sudo su` -> `sudo bash nocache.sh`

7. `sudo reboot`

8. Enjoy !
