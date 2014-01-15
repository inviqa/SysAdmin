<?
/*
 * (c) 2009 by Michael Bladowski (info@macropage.de)
 * GPLv2, no warranty of any kind given.
*/


$url = $argv[1];
$warning = $argv[2];
$error = $argv[3];

$url = preg_replace('/\s*/','',$url);
$warning = preg_replace('/\s*/','',$warning);
$error = preg_replace('/\s*/','',$error);

function microtime_float()
{
    list($usec, $sec) = explode(" ", microtime());
        return ((float)$usec + (float)$sec);
        }

$time_start = microtime_float();
$bla = file_get_contents($url);
$time_end = microtime_float();
$time = $time_end - $time_start;

print "Response Time: $time ";

if ($time<$warning) {
        print "OK";
        exit(0);
}
if ($time>=$warning && $time<$error) {
        print "WARNING";
        exit(2);
}
if ($time>$error) {
        print "ERROR";
        exit(1);
}

?>
