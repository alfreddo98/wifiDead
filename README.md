
wifiDead
======
Es una herramienta hecha en Bash para automatizar los ataques a redes inalámbricas con WPSK y WPSK2. La herramienta primero comprueba que se tienen los programas necesarios para realizar los ataques y después eecuta los ataques.

El programa se ha realizado para el aprender a usar y crear programas en bash. Además de aprender ataques a redes wifi.

**Requisitos previos**

El programa por si mismo te informa de los programas que se deben tener para ejecutar la herramienta y las instala directamente en caso de que no esten instaladas.

**Cómo ejecutar la aplicación**

Se realizarán dos modos de ataque: Handshake que es un ataque que consiste en deautenticar a un cliente de la AP y cuando este intente conectarse de nuevo capturar el handshake (en el que va la contraseña hasheada), de forma que se saca la contraseña y crackearla con otra herramienta de crackeo. PKMID que es un ataque que usa hcxdumptool y hcxpcaptool para sacar los hashes y usar hashcat para crackear las contraseñas.

Se deberá introducir el nombre de la tarjeta de red (La antena alfa). En mi caso, con la tarjeta AWUS036ACH y Kali Linux, no añade mon al final cuando la tarjeta se pone en modo monitor, las tarjetas de red que se les añade mon al final, deberá añadirse también en este apartado.

Se deberá introducir también la ruta al diccionario que se usará para el crackeo de la contraseña.
