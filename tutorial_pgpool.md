Configuração do Pgpool
======================


Balanceamento de carga
======================

Arquivo pcp.conf:

	# echo postgres:`pg_md5 postgres` >> /usr/local/etc/pcp.conf

Arquivo pgpool.conf:

	# cd /usr/local/etc
	# cp pgpool.conf.sample-stream pgpool.conf

Editar pgpool.conf:

	>>> listen_addresses = '*'
	    backend_hostname0 = 'postgresql01'
	    backend_port0 = 5432
	    backend_weight0 = 1
	    backend_data_directory0 = '/dados/postgresql'
	    backend_flag0 = 'ALLOW_TO_FAILOVER'
	    backend_hostname1 = 'postgresql02'
	    backend_port1 = 5432
	    backend_weight1 = 1
	    backend_data_directory1 = '/dados/postgresql'
	    backend_flag1 = 'ALLOW_TO_FAILOVER'
	    log_per_node_statement = on
	    sr_check_user = 'postgres'
	    health_check_user = 'postgres'

Failover automático
===================

Criar script failover.sh

	>>> failed_node_id=$1
	    failed_host_name=$2
	    failed_port=$3
	    failed_db_cluster=$4
	    new_master_id=$5
	    old_master_id=$6
	    new_master_host_name=$7
	    old_primary_node_id=$8
	    if [ $failed_node_id = $old_primary_node_id ];then	# master failed
	        ssh postgres@$new_master_host_name "pg_ctl -D /dados/postgresql promote"
	    fi

Permitir conexão SSH sem senha do usuário root do master para o usuário postgres do slave:

	# ssh-copy-id postgres@postgresql02

Editar o pgpool.conf:

	>>> failover_command = '/usr/local/etc/failover.sh %d "%h" %p %D %m %M "%H" %P'

Watchdog
========

Editar pgpool.conf (Master):

	>>> use_watchdog = on
	    trusted_servers = 'postgresql01,postgresql02'
	    wd_hostname = 'postgresql01'
	    delegate_IP = '192.168.148.100'
	    heartbeat_destination0 = 'postgresql02'
	    heartbeat_device0 = 'eth0'
	    wd_lifecheck_user = 'postgres'
	    other_pgpool_hostname0 = 'postgresql02'
	    other_pgpool_port0 = 9999

Editar pgpool.conf (Standby):

	>>> use_watchdog = on
	    trusted_servers = 'postgresql01,postgresql02'
	    wd_hostname = 'postgresql02'
	    delegate_IP = '192.168.148.100'
	    heartbeat_destination0 = 'postgresql01'
	    heartbeat_device0 = 'eth0'
	    wd_lifecheck_user = 'postgres'
	    other_pgpool_hostname0 = 'postgresql01'
	    other_pgpool_port0 = 9999
