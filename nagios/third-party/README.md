#Requirements
some script may require Perl and or Ruby installed in the system

#Redis
yum install perl-Time-HiRes cpan make
cpan -i  Redis

#SOLR Server Status
yum install expat-devel
cpan -i XML::Parser
cpan -i XML::XPath

#Memcached Status
yum install cpan
cpan YAML Nagios::Plugins::Memcached

#License and Author
The scripts contained in third-party directory belong to the author cited in the script themselves.
