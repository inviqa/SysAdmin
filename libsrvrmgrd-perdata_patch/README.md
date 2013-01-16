#Description
libsrvrmgrd-osx-perfdata is a patch to output Performance Data for NAGVIS for Script check_osx_server part of the libsrvrmgrd-osx plugin for NAGIOS that monitors MAC OS X servers perferomances.

The patch is bases on the libsrvrmgrd-osx version 0.6.5
http://code.google.com/p/libsrvrmgrd-osx/

#Installation
http://code.google.com/p/libsrvrmgrd-osx/wiki/NagiosPluginInstallation

Place the script in "/usr/lib/nagios/plugins/" or in the NAGIOS plugin directory referenced in your nagios.cfg file.

Define the 'nagios' check command ... in commands.cfg or any command file reference in your nagios.cfg file, as follow:

#Usage
It's advised to place the script in a common path i.e. /usr/bin.

#TODO
add the perfData output to the most of the check commands.

#License and Author
Author 'felimwhiteley' <felimwhiteley@gmail.com>

perfData patch Author: Marco Massari Calderone (mmassari@inviqa.com)

Copyright (c) 2012 'felimwhiteley' <felimwhiteley@gmail.com>

Licese: GNU Lesser General Public License
http://www.gnu.org/licenses/lgpl.html

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
