#Description
check_apcups-perfdata is a patch to output Performance Data for NAGVIS for the BASH Script check_apcups for NAGIOS that monitors APC UPS perferomances.

The patch is bases on the check_apcupsd version 2.5
http://exchange.nagios.org/directory/Plugins/Hardware/UPS/APC/check_apcupsd_v1_3-%28performance-data-output-added%29/details

#Installation
Place the script in "/usr/lib/nagios/plugins/" or in the NAGIOS plugin directory referenced in your nagios.cfg file.

Define the 'nagios' check command ... in commands.cfg or any command file reference in your nagios.cfg file, as follow:

define command {
  command_name  check_apcupsd
  command_line  $USER1$/check_apcups -h $HOSTADDRESS$ -w $ARG2$ -c $ARG3$ $ARG1$
}

#Usage
check_apcups requires 4 parameters
- ARG1: checks[bcharge|itemp|loadpct|timeleft|status]i
- ARG2: WARNING threshold
- ARG3: CRTICAL threshold
- ARG4: hostname

#Example
check_apcups -h localhost -w 80 -c 50 timeleft

#Usage
It's advised to place the script in a common path i.e. /usr/bin.

#TODO
nothing so far

#License and Author
Author Martin Toft <mt@martintoft.dk>

perfData patch Author: Marco Massari Calderone (mmassari@inviqa.com)

Copyright (c) 2008 Martin Toft <mt@martintoft.dk>
Copyright (c) 2010 Gerold Gruber <Gerold.Gruber@edv2g.de> (perfdata)
Copyright (C) 2010 Gabriele Tozzi <gabriele@tozzi.eu> (Back-UPS)
Copyright (c) 2010 Ermanno Baschiera <ebaschiera@gmail.com> (Back-UPS ES)
Copyright (c) 2012 Patrick Reinhardt <pr@reinhardtweb.de> (more Back-UPS ES)

 Permission to use, copy, modify, and distribute this software for any
 purpose with or without fee is hereby granted, provided that the above
 copyright notice and this permission notice appear in all copies.

 THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
