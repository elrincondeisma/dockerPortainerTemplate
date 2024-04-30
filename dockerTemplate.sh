#!/bin/bash

# Actualizar el sistema
echo "Updating system"
sudo apt-get update && sudo apt-get -s -o Debug::NoLocking=true upgrade

# Eliminar paquetes en conflicto
echo "Remove conflicting packages"
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    sudo apt-get remove -y $pkg
done

# Instalar el repositorio de Docker
echo "Install Docker repository"
sudo apt-get install ca-certificates curl --yes
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Configurar el repositorio de Docker
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Actualizar e instalar Docker
sudo apt-get update
echo "Installing Docker"
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin --yes

# Crear el volumen para Portainer
echo "Creating portainer_data volume"
docker volume create portainer_data

# Detener y eliminar el contenedor existente, si existe
if docker ps -a | grep -q portainer; then
    echo "Stopping and removing existing Portainer container"
    docker stop portainer
    docker rm portainer
fi

# Instalar y ejecutar Portainer con los puertos correctos
echo "Installing Portainer"
docker run -d --name=portainer --restart=always -p 8000:8000 -p 8443:9443 -p 8880:9000 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:2.20.1
# Confirmar la instalación y proporcionar la dirección de acceso
echo "Installation complete ✅"
public_ip=$(curl -s4 icanhazip.com)
echo "To access Portainer via HTTP: http://$public_ip:8880"
echo "To access Portainer via HTTPS: https://$public_ip:8443"
