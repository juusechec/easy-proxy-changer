#!/bin/bash

apppath=/usr/local/bin/easy-proxy-changer.sh
function addNew {
  DEFAULT_PROXY="http://10.20.4.15:3128"
  echo "Set proxy url: [ $DEFAULT_PROXY ]"
  read NEW_PROXY_DIR
  if [ "$NEW_PROXY_DIR" = "" ]
  then
    NEW_PROXY_DIR="$DEFAULT_PROXY"
  fi
  
  tee "$fileproxyurl" << EOF
# Setting proxy!
PROXY_DIR=$NEW_PROXY_DIR
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
  export $(grep -v '^#' fileproxyurl.conf | xargs -0)
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


function proxystatus {
  env | grep -i proxy
  npm config list | grep -i proxy
}

function proxy {
  proxy_bash
  proxy_apt_key
  proxy_npm
}

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
