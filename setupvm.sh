#!/bin/sh

version=9.3.4
pgdata=/usr/local/pgsql/data

if [ x"$USER" <> x"root" ]; then
	echo "Voce deve rodar como root. Execute: sudo $0 $@"
	exit 1
fi

if [ $# -le 1 ]; then
	VMID="$1"
else
	read -i "Qual o numero dessa VM? 1 ou 2: " VMID
	if [ x"$VMID" != x1 ] && [ x"$VMID" != x2 ]; then
		echo "Numero invalido!"
		exit 1
	fi
fi

iface="$( ip -oneline addr show | grep '192\.168.56\.' | awk '{print $2}' )"

if [ x"$iface" = x ]; then
	echo "Interface da rede 192.168.56.0/24 nao encontrada! Certifique-se de ter adicionado a rede hosted-only."
	exit 1
fi

cat >> /etc/network/interfaces <<EOS
auto $iface
iface $iface inet static
	address 192.168.56.10$VMID
	netmask 255.255.255.0
EOS

echo "postgresql0$VMID" > /etc/hostname

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

cp /usr/local/src/postgresql-$version/contrib/start-scripts/linux /etc/init.d/postgresql
chmod a+x /etc/init.d/postgresql
update-rc.d postgresql defaults
service postgresql start

echo "Instalacao finalizada! Reinicia a VM para aplicar as configuracoes de rede!"

