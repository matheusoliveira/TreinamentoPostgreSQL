#!/bin/sh

master_ip=192.168.56.200
netmask=24

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
    pgdba="postgres" pgport="5432" \
    op monitor interval="30s"

# Força ambos a estarem juntos
crm configure colocation pgsql-with-dbip inf: DBIP pgsql

# Preferência ao postgresql01
crm configure location prefer-master pgsql 100: postgresql01

