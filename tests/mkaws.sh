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

