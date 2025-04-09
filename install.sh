#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi


echo "=============================================="
echo ">> Beginning Deployment <<"
echo "=============================================="

echo
echo ">> Checking for .env file <<"
if [ ! -f ".env" ]; then
    echo "Environment file not found."
    echo "Creating .env from .env.example"
    cp .env.example .env
    echo "WARNING: .env created. Please configure it before continuing."
    echo "Re-run this script after editing the .env!"
    exit 1
else
    echo ".env found. Proceeding..."
fi

echo
echo ">> Loading environment variables <<"
set -o allexport
source .env
set +o allexport
echo "Variables loaded for project: ${PROJECT_NAME:-mssql-server}"

echo
echo ">> Pulling SQL Server image <<"
docker pull mcr.microsoft.com/mssql/server:${SQL_SERVER_TAG:-latest}

echo
echo ">> Creating Docker network if not exists <<"
docker network inspect ${PROJECT_NAME:-mssql-server}_network >/dev/null 2>&1 || \
docker network create \
    --driver bridge \
    --subnet 172.28.0.0/16 \
    ${PROJECT_NAME:-mssql-server}_network
echo "Network ready."

echo
echo ">> Creating Docker volumes if not exists <<"
for volume in data log secrets; do
    docker volume inspect ${PROJECT_NAME:-mssql-server}_${volume} >/dev/null 2>&1 || \
    docker volume create --name ${PROJECT_NAME:-mssql-server}_${volume}
done
echo "Volumes ready."

echo
echo ">> Deploying containers <<"
sudo docker compose up -d

echo
echo "=============================================="
echo ">> Deployment finished successfully! <<"
echo "=============================================="
