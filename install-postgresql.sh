#!/bin/bash

echo "### Atualizando o sistema ###"
yum update -y

echo "### Verificando versões do postgresql ###"

yum module list postgresql

echo ""

echo -n "Por favor, selecione a versão a ser instalada: "
read version
echo ""

echo "### Configurando a versão selecionada como padrão ###"
yum module enable postgresql:$version -y
echo ""

echo "### Instalando ###"
yum install postgresql-server -y
echo ""

echo "### Iniciando e habilitando o serviço no boot ###"
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

echo "### Configurando o postgresql para acesso remoto ###"
echo "------"
echo "### Alterando o arquivo pg_hba.conf ###"
sed -i 's/127.0.0.1\/32/0.0.0.0\/0/g' /var/lib/pgsql/data/pg_hba.conf
sed -i 's/ident/trust/g' /var/lib/pgsql/data/pg_hba.conf
echo "------"
echo "### Alterando o arquivo /var/lib/pgsql/data/postgresql.conf ###"
sed -i 's/#listen_addresses/listen_addresses/g' /var/lib/pgsql/data/postgresql.conf
sed -i 's/localhost/\*/g' /var/lib/pgsql/data/postgresql.conf
sed -i 's/#port = 5432/port = 5432/g' /var/lib/pgsql/data/postgresql.conf
echo ""

echo "### Alterando a senha do usuário postgre ###"
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'postgres'"
echo ""
echo "### Reiniciando o serviço do postgresql ###"
systemctl restart postgresql
echo ""

echo "### Configurando firewall ###"
systemctl stop firewalld
systemctl disable firewalld
systemctl mask firewalld

systemctl start nftables
systemctl enable nftables
touch /etc/nftables/firewall.nft
cat << EOF > /etc/nftables/firewall.nft
	#!/usr/sbin/nft -f

	# Flush the rule set
	flush ruleset

	table ip filter {
        	chain INPUT {
                	type filter hook input priority filter; policy accept;
                	iifname "lo" counter packets 0 bytes 0 accept
                	ip saddr 127.0.0.0/8 counter packets 0 bytes 0 accept
                	ct state established,related counter packets 0 bytes 0 accept
                	tcp dport 5432 counter packets 0 bytes 0 drop
                	tcp dport 5672 counter packets 0 bytes 0 drop
                	tcp dport 15672 counter packets 0 bytes 0 drop
                	tcp dport 9009 counter packets 0 bytes 0 accept
                	tcp dport 81 counter packets 0 bytes 0 accept
                	ip saddr 10.0.0.0/8 counter packets 0 bytes 0 accept
                	ip saddr 172.16.0.0/12 counter packets 0 bytes 0 accept
                	ip saddr 192.168.0.0/16 counter packets 0 bytes 0 accept
                	ip saddr 100.64.0.0/10 counter packets 0 bytes 0 accept
                	ip saddr 169.254.0.0/16 counter packets 0 bytes 0 accept
                	ip daddr 224.0.0.0/24 counter packets 0 bytes 0 accept
                	ip daddr 255.255.255.255 counter packets 0 bytes 0 accept
                	ip saddr 177.144.137.20 counter packets 0 bytes 0 accept
                	ip saddr 191.8.182.77 counter packets 0 bytes 0 accept
                	ip saddr 187.87.247.60 counter packets 0 bytes 0 accept
                	ip saddr 191.252.204.126 counter packets 0 bytes 0 accept
                	counter packets 0 bytes 0 drop
        	}
	}
EOF

sed -i 's/\/etc\/nftables\/main.nft/\/etc\/nftables\/firewall.nft/g' /etc/sysconfig/nftables.conf
sed -i 's/#include/include/g' /etc/sysconfig/nftables.conf

systemctl restart nftables
