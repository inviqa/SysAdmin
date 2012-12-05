#Description
check_jira_issues_stats is a BASH Script for NAGIOS to fetch JIRA projects stats

This is a script that interacts with a JIRA service via REST API
and fetch the counting TOTAL,OPENED,CLOSED,IN_PROGRESS issued for a given project

List the statistics of a specified Project of a specified JIRA instance

So far the script only returns statistics but it doesn't trigger any kind of notification as there is no definition of what could be considered a 'Warning' or a 'Critical' situation.
Maybe we can think to consider warning/critical when there is a specific percentage of unresolved issued against the total of opened issues.

#Installation
Place the script in "/usr/lib/nagios/plugins/" or in the NAGIOS plugin directory referenced in your nagios.cfg file.

Define the 'nagios' check command ... in commands.cfg or any command file reference in your nagios.cfg file, as follow:

define command {
  command_name  check_jira_issues_stats
  command_line  $USER1$/check_jira_issues_stats $ARG1$ $ARG2$ $ARG3$ $ARG4$
}

#Usage
check_jira_issues_stats requires 4 parameters
- ARG1: the JIRA server URI
- ARG2: the JIRA username that have access to the desired project to be monitored
- ARG3: the JIRA user password
- ARG4: the JIRA project shortcode

check_jira_issues_stats-h
check_jira_issues_stats https://jira_server_uri username password project

#Example
check_jira_issues_stats https://instance.jira.com user 12345678 PROJECT-0

#Usage
It's advised to place the script in a common path i.e. /usr/bin.
The best use of the script is to execute it periodically via a 'cron' script
When executed the script do not need any command-line parameter as it sources them from the .netrc and the .gg

#TODO
- make it more nagios friedly: accept Warning and Critical threshold values and return the relative notification

#License and Author
Author: Marco Massari Calderone (mmassari@inviqa.com)

Copyright (C) 2012 Inviqa UK Ltd

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.

