#!/bin/bash

apppath=/usr/local/bin/easy-proxy-changer.sh
if [ -f $apppath ]
then
  echo "The script it's already installed in $apppath. Nothing to do."
else

function addNew {
  DEFAULT_PROXY="http://10.20.4.15:3128"
  echo "Add proxy url: [ $DEFAULT_PROXY ]"
  read PROXY_DIR
  if [ "$PROXY_DIR" = "" ]
  then
    PROXY_DIR="$DEFAULT_PROXY"
  fi
  
  tee "$fileproxyurl" << EOF
# Setting proxy!
$PROXY_DIR
EOF
  echo "Modificated $fileproxyurl"
}

fileproxyurl="$HOME/fileproxyurl.conf"
if [[ ! -e "$fileproxyurl" ]]
then
echo "File $fileproxyurl not found!"
  addNew
  exit
fi


  # rationale: Configuración del PROXY UDistrital
  sudo tee -a $apppath << 'EOF'
if [ -z "$PROXY_DIR" ]; then
  PROXY_DIR=http://10.20.4.15:3128
fi

# rationale: agregar proxy a "apt-key adv"
# link: https://unix.stackexchange.com/questions/361213/unable-to-add-gpg-key-with-apt-key-behind-a-proxy
function proxy_apt_key {
if [ "$1" != "off" ]; then
  alias apt-key="apt-key --keyserver-options http-proxy=$PROXY_DIR"
else
  if alias | grep apt-key &> /dev/null
  then
    unalias apt-key
  fi
fi
}

# rationale: agrega el proxy para el comando "npm"
# link: https://stackoverflow.com/questions/21228995/how-to-clear-https-proxy-setting-of-npm
# link: https://stackoverflow.com/questions/25660936/using-npm-behind-corporate-proxy-pac
function proxy_npm {
if npm --version &> /dev/null
then
  if [ "$1" != "off" ]
  then
    # set global proxy npm
    npm config set proxy $PROXY_DIR
    npm config set http-proxy $PROXY_DIR
    npm config set https-proxy $PROXY_DIR
  else
    # remove global proxy npm
    npm config delete proxy
    npm config delete http-proxy
    npm config delete https-proxy
  fi
  npm config list | grep -i proxy
fi
}

# rationale: agrega proxy a la terminal de bash mediante variables de entorno
# además excluye ciertas IP's de tener el dominio, como las de loopback e intranet
function proxy_bash {
  if [ "$1" != "off" ]
  then
    export {HTTP,HTTPS,FTP,ALL,SOCKS,RSYNC}_PROXY=$PROXY_DIR
    export {http,https,ftp,all,socks,rsync}_proxy=$PROXY_DIR
    export {NO_PROXY,no_proxy}="localhost,127.0.0.1,localaddress,.localdomain.com,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12"
  else
    unset {HTTP,HTTPS,FTP,ALL,SOCKS,RSYNC,NO}_PROXY
    unset {http,https,ftp,all,socks,rsync,no}_proxy
  fi
  env | grep -i proxy
}

# rationale: muestra al usuario el estado actual del proxy
# ponga aquí los demás testigos del cambio del proxy en su comando o entorno
function proxy_status {
  env | grep -i proxy
  npm config list | grep -i proxy
}

# rationale: agrega proxy a todo lo conocido y usado en el glud
# si desea agregar proxy a aplicaciones, puede generar nuevas funciones
# que validen la existencia del programa y establezcan su proxy con alias
# u otras técnicas, hay varios ejemplos puestos
# link: https://www.arin.net/knowledge/address_filters.html
# link: https://wiki.archlinux.org/index.php/proxy_settings
function proxy {
  proxy_bash
  proxy_apt_key
  proxy_npm
}

# rationale: desactivar el proxy a las aplicaciones y entornos anteriores
function proxyoff {
  proxy_bash off
  proxy_apt_key off
  proxy_npm off
}

EOF

# rationale: Mostrar al usuario qué hay que hacer
echo
echo 'Para usar ejecuta el comando y agrega la línea al archivo .bashrc o .zshrc:'
echo "source $apppath"
