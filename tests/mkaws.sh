mkdir config && cd ./config/ && curl -O https://mkstorage277353.s3.eu-central-1.amazonaws.com/config_inc.php

cd ../

ANTIS_DB_NAME=bugtracker
MANTIS_BOOTSTRAP=tests/bootstrap.php
MANTIS_CONFIG=config/config_inc.php

TIMESTAMP=$(date "+%s")

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

$DB_CMD "$SQL_CREATE_PROJECT" $DB_CMD_SCHEMA
$DB_CMD "$SQL_CREATE_VERSIONS" $DB_CMD_SCHEMA
$DB_CMD "$SQL_CREATE_TAGS" $DB_CMD_SCHEMA
	

php -S $HOSTNAME:$PORT >& /dev/null &

TOKEN=$(php ./tests/travis_create_api_token.php)

cat <<-EOF >> ./tests/bootstrap.php
	<?php
		\$GLOBALS['MANTIS_TESTSUITE_SOAP_ENABLED'] = true;
		\$GLOBALS['MANTIS_TESTSUITE_SOAP_HOST'] = 'http://$HOSTNAME:$PORT/api/soap/mantisconnect.php?wsdl';
		\$GLOBALS['MANTIS_TESTSUITE_REST_ENABLED'] = true;
		\$GLOBALS['MANTIS_TESTSUITE_REST_HOST'] = 'http://$HOSTNAME:$PORT/api/rest/';
		\$GLOBALS['MANTIS_TESTSUITE_API_TOKEN'] = '$TOKEN';
	EOF

