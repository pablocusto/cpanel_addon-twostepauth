#!/usr/local/bin/php
<?php

require_once 'googleauth.php';

$shortopts  = "";
$shortopts .= "c:";
$shortopts .= "p:";  // Required value
$shortopts .= "v::";
$shortopts .= "t::"; // Optional value

$longopts  = array(
    "command:",     // Required value
    "privatekey:",     // Required value
    "title::",    // Optional value
);
$options = getopt($shortopts, $longopts);
$ga = new PHPGangsta_GoogleAuthenticator();
$options['p'] = $ga->setSecret($options['p']);
switch ($options['c']) {
	case "qr":
		echo $ga->getQRCodeGoogleUrl($options['t'], $options['p']);
		break;
	case "verify":
		if ($ga->verifyCode($options['p'], $options['v'], 1)) {
			echo "true";
		} else {
			echo "false";
		}
		break;
	case "qr_text":
		echo $ga->getURI($options['t'], $options['p']);
		break;
}
