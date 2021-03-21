HOSTNAME=127.0.0.1
PORT=8080
MANTIS_DB_NAME=bugtracker
MANTIS_BOOTSTRAP=tests/bootstrap.php
MANTIS_CONFIG=config/config_inc.php

TIMESTAMP=$(date "+%s")
SQL_CREATE_DB="CREATE DATABASE $MANTIS_DB_NAME;"
SQL_CREATE_PROJECT="INSERT INTO mantis_project_table
	(name, inherit_global, description)
	VALUES
	('Test Project',true,'Travis-CI Test Project');"
SQL_CREATE_VERSIONS="INSERT INTO mantis_project_version_table
	(project_id, version, description, released, obsolete, date_order)
	VALUES
	(1, '1.0.0', 'Obsolete version', true, true, $(($TIMESTAMP - 120))),
	(1, '1.1.0', 'Released version', true, false, $(($TIMESTAMP - 60))),
	(1, '2.0.0', 'Future version', false, false, $TIMESTAMP);"
SQL_CREATE_TAGS="INSERT INTO mantis_tag_table
	(user_id, name, description, date_created, date_updated)
	VALUES
	(0, 'modern-ui', '', $TIMESTAMP, $TIMESTAMP),
	(0, 'patch', '', $TIMESTAMP, $TIMESTAMP);"
DB_TYPE='mysqli'
DB_USER='admin'
DB_PASSWORD=''
DB_CMD='mysql -e'
DB_CMD_SCHEMA="$MANTIS_DB_NAME"
$DB_CMD "CREATE USER 'admin'@'$HOSTNAME' IDENTIFIED BY '';"
$DB_CMD "GRANT ALL PRIVILEGES ON bugtracker.* TO 'admin'@'$HOSTNAME';"
$DB_CMD "$SQL_CREATE_DB"
php -S $HOSTNAME:$PORT >& /dev/null &
sleep 20
#-------------------------------------------------
declare -A query=(
	[install]=2
	[db_type]=$DB_TYPE
	[hostname]=$HOSTNAME
	[database_name]=$MANTIS_DB_NAME
	[db_username]=$DB_USER
	[db_password]=$DB_PASSWORD
	[admin_username]=$DB_USER
	[admin_password]=$DB_PASSWORD
	[timezone]=UTC
)
unset query_string
for param in "${!query[@]}"
do
	value=${query[$param]}
	query_string="${query_string}&${param}=${value}"
done

curl --data "${query_string:1}" http://$HOSTNAME:$PORT/admin/install.php
#-------------------------------------------------
#echo CREATING TABLES
#$DB_CMD "CREATE TABLE mantis_project_table();" $DB_CMD_SCHEMA
#$DB_CMD "CREATE TABLE mantis_project_version_table();" $DB_CMD_SCHEMA
#$DB_CMD "CREATE TABLE mantis_tag_table();" $DB_CMD_SCHEMA
#echo TABLES CREATED
$DB_CMD "$SQL_CREATE_PROJECT" $DB_CMD_SCHEMA
$DB_CMD "$SQL_CREATE_VERSIONS" $DB_CMD_SCHEMA
$DB_CMD "$SQL_CREATE_TAGS" $DB_CMD_SCHEMA
	
chmod 777 config

sleep 10
TOKEN=$(php ./tests/travis_create_api_token.php)

cat <<-EOF >> ./tests/bootstrap.php
	<?php
		\$GLOBALS['MANTIS_TESTSUITE_SOAP_ENABLED'] = true;
		\$GLOBALS['MANTIS_TESTSUITE_SOAP_HOST'] = 'http://$HOSTNAME:$PORT/api/soap/mantisconnect.php?wsdl';
		\$GLOBALS['MANTIS_TESTSUITE_REST_ENABLED'] = true;
		\$GLOBALS['MANTIS_TESTSUITE_REST_HOST'] = 'http://$HOSTNAME:$PORT/api/rest/';
		\$GLOBALS['MANTIS_TESTSUITE_API_TOKEN'] = '$TOKEN';
	EOF


chmod 777 $MANTIS_CONFIG
cat <<-EOF >> $MANTIS_CONFIG
	# Configs required to ensure all PHPUnit tests are executed
	\$g_allow_no_category = ON;
	\$g_due_date_update_threshold = DEVELOPER;
	\$g_due_date_view_threshold = DEVELOPER;
	\$g_enable_product_build = ON;
	\$g_enable_project_documentation = ON;
	\$g_time_tracking_enabled = ON;
	EOF

echo script done and out
