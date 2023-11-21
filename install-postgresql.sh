#!/bin/bash

echo "### Verificando versões do postgresql ###"

yum module list postgresql

echo ""

echo -n "Por favor, selecione a versão a ser instalada: "
read version
echo ""

echo "Configurando a versão selecionada como padrão"
yum module enable postgresql:$version
echo ""

echo "Instalando..."
yum install postgresql-server
echo ""

echo "Iniciando e habilitando o serviço no boot..."
#Verificando se o diretório /var/lib/pgsql/data/ está vazio
if [" $ (ls -A /var/lib/pgsql/data/pg_hba.conf)"]
then
	echo "Postgre já está funcionando"
else
	service postgresql initdb
	systemctl start postgresql
	systemctl enable postgresql
fi
echo ""

echo "Configurando o postgresql para acesso remoto..."
echo "------"
echo "Alterando o arquivo pg_hba.conf"
sed -i 's/127.0.0.1\/32/0.0.0.0\/0/g' /var/lib/pgsql/data/pg_hba.conf
sed -1 's/ident/trust/g' /var/lib/pgsql/data/pg_hba.conf



