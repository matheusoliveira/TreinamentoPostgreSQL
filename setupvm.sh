#!/bin/sh

version=9.3.4
pgdata=/usr/local/pgsql/data
uid="$( id -u )"

if [ x"$uid" != x"0" ]; then
	echo "Voce deve rodar como root. Execute: sudo $0 $@"
	exit 1
fi

if [ $# -ge 1 ]; then
	vmid="$1"
else
	read -p "Qual o numero dessa VM? 1 ou 2: " vmid
fi

if [ x"$vmid" != x1 ] && [ x"$vmid" != x2 ]; then
	echo "Numero \`$vmid' invalido!"
	exit 1
fi

iface="$( ip -oneline addr show | grep '192\.168.56\.' | head -n1 | awk '{print $2}' )"

if [ x"$iface" = x ]; then
	echo "Interface da rede 192.168.56.0/24 nao encontrada! Certifique-se de ter adicionado a rede hosted-only."
	exit 1
fi

cat >> /etc/network/interfaces <<EOS
auto $iface
iface $iface inet static
	address 192.168.56.10$vmid
	netmask 255.255.255.0
EOS

cat >> /etc/hosts <<EOS
192.168.56.101  postgresql01
192.168.56.102  postgresql02
EOS

echo "postgresql0$vmid" > /etc/hostname

echo "Instalando o PostgreSQL..."
apt-get install -y libreadline6-dev zlib1g-dev build-essential
cd /usr/local/src/
wget http://ftp.postgresql.org/pub/source/v$version/postgresql-$version.tar.bz2
tar xvf postgresql-$version.tar.bz2
cd postgresql-$version/
./configure --prefix=/usr/local/pgsql-$version
make
make install
cd /usr/local/
ln -s pgsql-$version/ pgsql

cat >> /etc/profile.d/postgresql.sh <<EOS
	export PGDATA=$pgdata
	export PATH=/usr/local/pgsql/bin:$PATH
	export LD_LIBRARY_PATH=/usr/local/pgsql/lib:$LD_LIBRARY_PATH
EOS

echo "Inicializando banco de dados..."
useradd --system --user-group --create-home --comment "PostgreSQL Admin User" --shell /bin/bash postgres
mkdir -p "$pgdata/"
chown -R postgres:postgres "$pgdata/"
su - postgres -c "/usr/local/pgsql/bin/initdb -D $pgdata"
su - postgres -c "echo 'listen_addresses = \"*\"' > $pgdata/postgresql.conf"

cp /usr/local/src/postgresql-$version/contrib/start-scripts/linux /etc/init.d/postgresql
chmod a+x /etc/init.d/postgresql
update-rc.d postgresql defaults
service postgresql start

echo "Instalacao finalizada! Reinicia a VM para aplicar as configuracoes de rede!"

