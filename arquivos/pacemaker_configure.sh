#!/bin/sh

# INICIO EDIÇÃO:

# Interface de rede a associar ao VIP
iface=eth0
# Último octeto do VIP (p.e. se IP da máquina for 192.168.1.X e master_sub_ip=200 então master_vip=192.168.1.200)
master_sub_ip=200

# FIM EDIÇÃO


basedir=$(dirname $0)
# Recupera IP e máscara
inet_addr=$(ip -oneline -family inet addr show ${iface} | head -n1 | awk '{print $4}')
ip=$(echo ${inet_addr} | awk -F '/' '{print $1}')
netmask=$(echo ${inet_addr} | awk -F '/' '{print $2}')
master_ip=$(echo ${ip} | awk -F '.' '{printf("%d.%d.%d.'${master_sub_ip}'", $1, $2, $3)}')
bind_addr=$(echo ${ip} | awk -F '.' '{printf("%d.%d.%d.0", $1, $2, $3)}')

set -x

# Desabilitar STONITH
crm configure property stonith-enabled=false

# Evita troca de recurso desnecessária entre servidores
crm configure rsc_defaults resource-stickiness=100

# Ignora quorum (obrigatório para um cluster de 2 nós)
crm configure property no-quorum-policy=ignore

# Configura IP virtual
crm configure primitive DBIP ocf:heartbeat:IPaddr2 \
    params \
    ip="${master_ip}" cidr_netmask="${netmask}" \
    op monitor interval="30s"

# Configura o PostgreSQL
crm configure primitive pgsql ocf:heartbeat:pgsr \
    params \
    pgctl="/usr/local/pgsql/bin/pg_ctl" \
    psql="/usr/local/pgsql/bin/psql" \
    pgdata="/usr/local/pgsql/data" \
    pgdba="postgres" pgport="5432"

# Força ambos a estarem juntos
crm configure colocation pgsql-with-dbip inf: DBIP pgsql

# Preferência ao postgresql01
crm configure location prefer-master pgsql 100: postgressql01

