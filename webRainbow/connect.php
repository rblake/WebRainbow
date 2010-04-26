<?php
$fp = fsockopen("192.168.1.99", 23, $errno, $errstr, 3);
if (!$fp) {
    echo "$errstr ($errno)<br />\n";
} else {

switch($_GET['type']) {
	case 0:
		$in = "webRainbow-client\n";
		$in .= "0\n";
		$in .= "ID:".$_GET['ID']."\n";
		$in .= "X:".$_GET['X']."\n";
		$in .= "Y:".$_GET['Y']."\n";
		$in .= "r:".$_GET['r']."\n";
		$in .= "g:".$_GET['g']."\n";
		$in .= "b:".$_GET['b']."\n";
	break;
	
	case 1:
		$in = "webRainbow-client\n";
		$in .= "1\n";
		$in .= "ID:".$_GET['ID']."\n";
		$in .= "r:".$_GET['r']."\n";
		$in .= "g:".$_GET['g']."\n";
		$in .= "b:".$_GET['b']."\n";
	break;
}

    fwrite($fp, $in);
    while (!feof($fp)) {
        echo fgets($fp, 128);
    }
    fclose($fp);
}
?>
