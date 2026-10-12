# Un día en HackathonLabs Networks

## Declaración de exención de responsabilidad

Esta es una obra de ficción. Los nombres, personajes, lugares y sucesos son producto de la imaginación de los autores o utilizados de manera ficticia. Cualquier parecido con personas reales, vivas o muertas, es mera coincidencia.

## Introducción

**¡ Bienvenidos al hackathonCopa 2024 en su quinta edición !**

Su primer desafío del día, será finalizar la configuración de un servidor, así como identificar una contraseña que deberá ser modificada. Este reto requiere habilidades técnicas y capacidad para resolver problemas bajo presión.

## Contexto del desafío

Las tareas asociadas a la gestión de **Linux** son el día a día para los administradores de sistemas, su resolución implica en muchas ocasiones investigar y saber usar los comandos y/o herramientas que las permitan resolver de manera efectiva y muy importante en un ambiente colaborativo.

## Primer asignación - Configuración del sistema operativo

![Reto 01 Arquitectura de Referencia](/imgs/2024030401_reto_01-02_w_fgt_arch.drawio.png)

Un día como cualquier otro, en un equipo técnico de **HackathonLabs Networks**, les han solicitado configurar el firewall de Fortigate para implementar la seguridad perimetral de un nuevo grupo de servidores. Los objetivos para la protección perimetral de la infraestructura que alberga el workload ***MTWA FlightDB*** son:

1. Todos los servidores tendrán acceso a internet solamente a través de los protocolos `http`, `https` y `dns`.
2. La microsegmentación `East-West` solo permitirá accesos de la red FrontEnd (FE) a la red BackEnd (BE).
3. El único servidor que se publicará hacia internet será el servidor web cliente, el cual tendrá una IP pública distinta de la que se usa para navegar por internet, y los protocolos permitidos serán solamente `http` y `https`.

El `Fortigate` se encuentra precargado con la configuración mínima de enrutamiento hacia el Address Space y la política de acceso a internet. También será imperativo instalar la licencia, ya que de otro modo la configuración mínima no funcionará y no se podrán actualizar ni descargar los paquetes necesarios para trabajar y desplegar la aplicación en los servidores. Ambas redes, tanto la DMZ como la red de los servidores de producción, están protegidas por el `Fortigate`.

Lo primero que deben hacer, es crear una cuenta en el sitio de soporte de `Fortinet` [https://support.fortinet.com/](https://support.fortinet.com/) para así poder licenciar el firewall `Fortigate`, ya sea entrando vía web o SSH a través de la interfaz de Out of Band Management (OOBM), la cual tiene el DNS configurado como `fortigate.${CODE_NAME}.reto12.copa.hacktonlabs.net`. El firewall se puede administrar desde el `bastion` vía web o SSH con el DNS `fortigate.${CODE_NAME}.reto12.copa.hacktonlabs.local`. Para licenciar el `Fortigate`, se recomienda buscar la documentación oficial de `Fortinet` sobre "Permanent trial mode for FortiGate-VM" en [https://docs.fortinet.com/](https://docs.fortinet.com/). 

Recuerden que si tienen una cuenta previa creada o licencia, deben eliminarla ya que su cuenta solo permitirá la creación de una sola licencia y no más. Esta licencia es del tipo "Permanent trial mode" y solo les permitirá configurar 3 rutas estáticas y 3 políticas. Recuerden que todas las reglas configuradas en el `Fortigate` deben estar definidas con `Addresses` y no con segmentos o IPs.

Una vez que el `Fortigate` esté licenciado y puedan acceder vía web o SSH, encontrarán preconfigurado el enrutamiento en el `Fortigate` para que funcione con la red de `Microsoft Azure`, la cual está definida con el destino del `address space`, y la interfaz de salida interna (`inside`) apuntando al gateway, que corresponde a la primera IP de la subred `003`.

La política de acceso a internet debe tener el flujo de tráfico de la interfaz interna (`inside`) a la interfaz externa (`outside`), además de quedar explícito que la única red interna definida es la supernet o `address space` y la red externa debe ser `0/0`.

---

Uno de los administradores de sistemas se encuentra fuera debido a una licencia por paternidad, quien se encontraba desarrollando un playbook para poder configurar un grupo de servidores que van a soportar una aplicación crítica en producción. Su líder les ha solicitado completar la configuración en **menos de 2 horas a partir de este momento** y para lo cual, les ha dado libertad de completar el desarrollo del playbook o configurar los servidores manualmente. Las siguientes tareas son las que deben llevar a cabo:

1. Garantizar que el sistema operativo de todos los servidores se encuentre completamente actualizado (no deben tener actualizaciones pendientes).
2. Cada servidor debe tener instalado la última versión de los paquetes:
    - samba
    - samba-client
3. Cada servidor debe tener el servicio de **SELinux activo** de forma permanente.
4. En cada servidor deben crear cinco (5) usuarios adicionales con sus respectivas contraseñas seguras asignadas, asegurando que dichas credenciales expiren cada 3 meses (90 días), que los usuarios deban esperar al menos 10 días para poder hacer un cambio de password, y que se les notifique con 7 días de anticipación al venimiento de su password, que el mismo va a expirar. Los usuarios creados deben relacionarse con el grupo `hackatonLabs`, en caso de que el grupo no exista, deben crearlo.
   
| Usuario | Password | Grupo |
| --- | --- | --- |
| compras | DefaultHackatonLabs123* | hackatonLabs |
| comercial | DefaultHackatonLabs123* | hackatonLabs |
| ventas | DefaultHackatonLabs123* | hackatonLabs |
| administrativo | DefaultHackatonLabs123* | hackatonLabs |
| soporte | DefaultHackatonLabs123* | hackatonLabs |

5. En cada servidor deben crear una carpeta llamada `/guias` que pertenezca al grupo `hackatonLabs` y además los usuarios que pertenezcan a este grupo puedan leer, escribir, ejecutar sobre dicha carpeta. Esta carpeta se debe poblar con 100 archivos de texto vacíos con el nombre: `archivo-1.txt`, `archivo-2.txt`... `archivo-100.txt`.
6. En cada servidor creen una subcarpeta llamada `/guias/config` y copien en esta ubicación los archivos `/etc/redhat-release`, `/etc/passwd` y `/usr/share/dict/linux.words`.
7. En cada servidor almacenen la versión exacta del sistema operativo en el archivo `/tmp/os-version.txt`.
8. En cada servidor creen un enlace simbólico llamado `/guias/config/grupos` apuntando al archivo `/etc/group`.
9. En cada servidor incluyan el mensaje **"El problema no es problema"** en el archivo `/etc/motd`, para que cuando un usuario haga login se muestra el MOTD (mensaje del dia).

## Epílogo

Este desafío requerirá de habilidades técnicas en cuanto a conocimiento de Linux se refiere y está diseñado para que resuelvan en un entorno colaborativo, situaciones reales que les permitan potenciar sus habilidades técnicas. 

**¡ Mucha suerte y diviértanse !**
