#!/bin/bash

echo "Atualizando o sistema..."
yum update -y

echo "### Verificando versões do postgresql ###"

yum module list postgresql

echo ""

echo -n "Por favor, selecione a versão a ser instalada: "
read version
echo ""

echo "Configurando a versão selecionada como padrão"
yum module enable postgresql:$version -y
echo ""

echo "Instalando..."
yum install postgresql-server -y
echo ""

echo "Iniciando e habilitando o serviço no boot..."
#Verificando se o diretório /var/lib/pgsql/data/ está vazio
if [ -d /var/lib/pgsql/data/* ]
then
	# Se o diretório não estiver vazio
	echo "O postgresql já está funcionando!!!"
else
	# Se o diretório estiver vazio
	service postgresql initdb
	systemctl start postgresql
	systemctl enable postgresql
fi
echo ""

echo "Configurando o postgresql para acesso remoto..."
echo "------"
echo "Alterando o arquivo pg_hba.conf"
sed -i 's/127.0.0.1\/32/0.0.0.0\/0/g' /var/lib/pgsql/data/pg_hba.conf
sed -i 's/ident/trust/g' /var/lib/pgsql/data/pg_hba.conf
echo "------"
echo "Alterando o arquivo /var/lib/pgsql/data/postgresql.conf"
sed -i 's/#listen_addresses/listen_addresses/g' /var/lib/pgsql/data/postgresql.conf
sed -i 's/localhost/\*/g' /var/lib/pgsql/data/postgresql.conf
sed -i 's/#port = 5432/port = 5432/g' /var/lib/pgsql/data/postgresql.conf
