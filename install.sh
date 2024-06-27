#!/bin/bash

# Farben und Formatierungen
red="\e[0;91m"
green="\e[0;92m"
bold="\e[1m"
reset="\e[0m"

runtime_link=$1

# BashSelect-Skriptquelle ändern
source <(curl -s https://raw.githubusercontent.com/LukeCodingDeveloper/BashSelect.sh/main/BashSelect.sh)

clear

status(){
  clear
  echo -e $green$@'...'$reset
  sleep 1
}

runCommand(){
    COMMAND=$1

    if [[ ! -z "$2" ]]; then
      status $2
    fi

    eval $COMMAND
    BASH_CODE=$?
    if [ $BASH_CODE -ne 0 ]; then
      echo -e "${red}Ein Fehler ist aufgetreten:${reset} ${white}${COMMAND}${reset}${red} hat zurückgegeben${reset} ${white}${BASH_CODE}${reset}"
      exit ${BASH_CODE}
    fi
}

source <(curl -s https://raw.githubusercontent.com/LukeCodingDeveloper/BashSelect.sh/main/BashSelect.sh)


status "Installiere MariaDB/MySQL und phpmyadmin"

export OPTIONS=("ja" "nein")

bashSelect

case $? in
     0 )
        phpmaInstall=0;;
     1 )
        ;;
esac

function examServData() {
  runCommand "mkdir -p $dir/server-data"

  runCommand "git clone -q https://github.com/citizenfx/cfx-server-data.git $dir/server-data" "Die server-data wird heruntergeladen"

  status "Erstelle Beispiel server.cfg"

  cat << EOF > $dir/server-data/server.cfg
# Nur die IP ändern, wenn ein Server mit mehreren Netzwerk-Schnittstellen verwendet wird, ansonsten nur den Port ändern.
endpoint_add_tcp "0.0.0.0:30120"
endpoint_add_udp "0.0.0.0:30120"

# Diese Ressourcen werden standardmäßig gestartet.
ensure mapmanager
ensure chat
ensure spawnmanager
ensure sessionmanager
ensure basic-gamemode
ensure hardcap
ensure rconlog

# Erlaubt Spielern die Verwendung von scripthook-basierten Plugins wie das Lambda-Menü.
# Auf 1 setzen, um scripthook zu erlauben. Dies garantiert jedoch nicht, dass Spieler keine externen Plugins verwenden können.
sv_scriptHookAllowed 0

# RCON aktivieren und Passwort setzen. Ändere das Passwort - es sollte wie folgt aussehen: rcon_password "DEINPASSWORT"
#rcon_password ""

# Eine durch Kommas getrennte Liste von Tags für deinen Server.
# Beispiel:
# - sets tags "drifting, cars, racing"
# Oder:
# - sets tags "roleplay, military, tanks"
sets tags "default"

# Eine gültige locale-ID für die Hauptsprache des Servers.
# Beispiel "en-US", "fr-CA", "nl-NL", "de-DE", "en-GB", "pt-BR"
sets locale "root-AQ"
# bitte root-AQ in der obigen Zeile durch eine echte Sprache ersetzen! :)

# Optionale Server-Info und Verbindungs-Banner-Bild-URL setzen.
# Größe ist egal, jedes Bannerbild passt.
#sets banner_detail "https://url.to/image.png"
#sets banner_connecting "https://url.to/image.png"

# Den Hostnamen des Servers setzen. Dieser wird normalerweise in Listen nicht angezeigt.
sv_hostname "FXServer, aber unkonfiguriert"

# Den Projektnamen des Servers setzen
sets sv_projectName "Mein FXServer Projekt"

# Die Projektbeschreibung des Servers setzen
sets sv_projectDesc "Standard FXServer, der Konfiguration benötigt"

# Verschachtelte Konfigurationen!
#exec server_internal.cfg

# Server-Symbol laden (96x96 PNG-Datei)
#load_server_icon myLogo.png

# Convars, die in Skripten verwendet werden können
set temp_convar "hey world!"

# Entferne die `#` in der folgenden Zeile, wenn du nicht möchtest, dass dein Server in der Server-Browserliste aufgeführt wird.
# Nicht bearbeiten, wenn du möchtest, dass dein Server aufgelistet wird.
#sv_master1 ""

# Systemadministratoren hinzufügen
add_ace group.admin command allow # alle Befehle erlauben
add_ace group.admin command.quit deny # aber "quit" nicht erlauben
add_principal identifier.fivem:1 group.admin # admin zur Gruppe hinzufügen

# OneSync aktivieren (erforderlich für serverseitige Zustandsüberwachung)
set onesync on

# Server-Spieler-Slot-Limit (siehe https://fivem.net/server-hosting für Limits)
sv_maxclients 48

# Steam-Web-API-Schlüssel, wenn Steam-Authentifizierung verwendet werden soll (https://steamcommunity.com/dev/apikey)
# -> "" durch den Schlüssel ersetzen
set steam_webApiKey ""

# Lizenzschlüssel für deinen Server (https://keymaster.fivem.net)
sv_licenseKey changeme
EOF
}

if [ "$EUID" -ne 0 ]; then
	echo -e "${red}Bitte als root ausführen";
	exit
fi

status "Wähle den Bereitstellungstyp"
export OPTIONS=("Vorlage über TxAdmin installieren" "cfx-server-data verwenden")
bashSelect
deployType=$( echo $? )

runCommand "apt -y update" "Aktualisieren"

runCommand "apt -y upgrade " "Aktualisieren"

runCommand "apt install -y wget git curl dos2unix net-tools sed screen tmux xz-utils lsof" "Erforderliche Pakete installieren"

clear

dir=/home/FiveM

lsof -i :40120
if [[ $( echo $? ) == 0 ]]; then
  status "Es sieht so aus, als ob bereits etwas auf dem Standard-TxAdmin-Port läuft. Können wir es stoppen/beenden?" "/"
  export OPTIONS=("PID auf Port 40120 töten" "Skript beenden")
  bashSelect
  case $? in
    0 )
      status "PID auf 40120 töten"
      runCommand "apt -y install psmisc"
	  runCommand "fuser -4 40120/tcp -k"
      ;;
    1 )
      exit 0
      ;;
  esac
fi

if [[ -e $dir ]]; then
  status "Es sieht so aus, als ob bereits ein $dir-Verzeichnis existiert. Können wir es entfernen?" "/"
  export OPTIONS=("Alles in $dir entfernen" "Skript beenden")
  bashSelect
  case $? in
    0 )
      status "Lösche $dir"
      runCommand "rm -r $dir"
      ;;
    1 )
      exit 0
      ;;
  esac
fi

if [[ $phpmaInstall == 0 ]]; then
  bash <(curl -s https://raw.githubusercontent.com/LukeCodingDeveloper/FiveM-installer-HighQualityNetwork/main/install.sh) -s
fi

runCommand "mkdir -p $dir/server" "Verzeichnisse für den FiveM-Server erstellen"
runCommand "cd $dir/server/"

runCommand "wget $runtime_link" "FxServer wird heruntergeladen"

runCommand "tar xf fx.tar.xz" "FxServer-Archiv entpacken"
runCommand "rm fx.tar.xz"

case $deployType in
  0 )
    sleep 0;; # nichts tun
  1 )
    examServData
    ;;
esac

status "Start-, Stopp- und Zugriffsskript erstellen"
cat << EOF > $dir/start.sh
#!/bin/bash
red="\e[0;91m"
green="\e[0;92m"
bold="\e[1m"
reset="\e[0m"
port=\$(lsof -Pi :40120 -sTCP:LISTEN -t)
if [ -z "\$port" ]; then
    screen -dmS fivem sh $dir/server/run.sh
    echo -e "\n\${green}TxAdmin wurde gestartet!\${reset}"
else
    echo -e "\n\${red}Der Standard \${reset}\${bold}TxAdmin\${reset}\${red} wird bereits verwendet -> Läuft ein \${reset}\${bold}FiveM Server\${reset}\${red} bereits?\${reset}"
fi
EOF
runCommand "chmod +x $dir/start.sh"

runCommand "echo \"screen -xS fivem\" > $dir/attach.sh"
runCommand "chmod +x $dir/attach.sh"

runCommand "echo \"screen -XS fivem quit\" > $dir/stop.sh"
runCommand "chmod +x $dir/stop.sh"

status "Crontab-Eintrag zum automatischen Start von TxAdmin erstellen (empfohlen)"
export OPTIONS=("ja" "nein")
bashSelect
case $? in
  0 )
    status "Crontab-Eintrag erstellen"
    runCommand "echo \"@reboot         root    cd /home/FiveM/ && bash start.sh\" >> /etc/crontab"
    ;;
  1 )
    sleep 0;;
esac

port=$(lsof -Pi :40120 -sTCP:LISTEN -t)

if [[ -z "$port" ]]; then
	if [[ -e '/tmp/fivem.log' ]]; then
    rm /tmp/fivem.log
	fi
    screen -L -Logfile /tmp/fivem.log -dmS fivem $dir/server/run.sh

    sleep 2

    line_counter=0
    while true; do
      while read -r line; do
        echo $line
        if [[ "$line" == *"able to access"* ]]; then
          break 2
        fi
      done < /tmp/fivem.log
      sleep 1
    done

    cat -v /tmp/fivem.log > /tmp/fivem.log.tmp

    while read -r line; do
      echo $line_counter
      if [[ "$line" == *"PIN"*  ]]; then
        let "line_counter += 2"
        break 2
      fi
      let "line_counter += 1"
    done < /tmp/fivem.log.tmp

    pin_line=$( head -n $line_counter /tmp/fivem.log | tail -n +$line_counter )
    echo $line_counter
    echo $pin_line > /tmp/fivem.log.tmp
    pin=$( cat -v /tmp/fivem.log.tmp | sed --regexp-extended --expression='s/\^\[\[([0-9][0-9][a-z])|([0-9][a-z])|(\^\[\[)|(\[.*\])|(M-bM-\^TM-\^C)|(\^M)//g' )
    pin=$( echo $pin | sed --regexp-extend --expression='s/[\ ]//g' )

    echo $pin
    rm /tmp/fivem.log.tmp
    clear

    echo -e "\n${green}${bold}TxAdmin${reset}${green} wurde erfolgreich gestartet${reset}"
    txadmin="http://$(ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'):40120"
    echo -e "\n\n${red}${uline}Befehle nur über SSH nutzbar\n"
    echo -e "${red}Zum ${reset}${blue}Starten${reset}${red} von TxAdmin -> ${reset}${bold}sh $dir/start.sh${reset} ${red}!\n"
    echo -e "${red}Zum ${reset}${blue}Stoppen${reset}${red} von TxAdmin -> ${reset}${bold}sh $dir/stop.sh${reset} ${red}!\n"
    echo -e "${red}Um die ${reset}${blue}\"Live-Konsole\"${reset}${red} zu sehen -> ${reset}${bold}sh $dir/attach.sh${reset} ${red}!\n"

    echo -e "\n${green}TxAdmin Webinterface: ${reset}${blue}${txadmin}\n"

    echo -e "${green}Pin: ${reset}${blue}${pin:(-4)}${reset}${green} (innerhalb der nächsten 5 Minuten verwenden!)"

    echo -e "\n${green}Server-Daten Pfad: ${reset}${blue}$dir/server-data${reset}"

    if [[ $phpmaInstall == 0 ]]; then
      echo
      echo "MariaDB und PHPMyAdmin Daten:"
      runCommand "cat /root/.mariadbPhpma"
      runCommand "rm /root/.mariadbPhpma"
      rootPasswordMariaDB=$( cat /root/.mariadbRoot )
      rm /root/.mariadbRoot
      fivempasswd=$( pwgen 32 1 )
      mariadb -u root -p$rootPasswordMariaDB -e "CREATE DATABASE fivem;"
      mariadb -u root -p$rootPasswordMariaDB -e "GRANT ALL PRIVILEGES ON fivem.* TO 'fivem'@'localhost' IDENTIFIED BY '${fivempasswd}';"
      echo "
FiveM MySQL-Daten
    Benutzer: fivem
    Passwort: ${fivempasswd}
    Datenbankname: fivem
      FiveM MySQL-Verbindungszeichenfolge:
        set mysql_connection_string \"server=127.0.0.1;database=fivem;userid=fivem;password=${fivempasswd}\""

    fi
    sleep 2

else
    echo -e "\n${red}Der Standard ${reset}${bold}TxAdmin${reset}${red}-Port wird bereits verwendet -> Läuft ein ${reset}${bold}FiveM Server${reset}${red} bereits?${reset}"
fi
