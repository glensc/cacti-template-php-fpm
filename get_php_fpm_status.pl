#!/usr/bin/perl
# get_php_fpm_status.pl
# cacti script to collect stats for PHP-FPM server
# URL: https://github.com/glensc/cacti-template-php-fpm
#
# Copyright (c) 2013 Elan Ruusamäe <glen@delfi.ee>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Getopt::Long;
use LWP::UserAgent;

# command line parameters with some defaults
my $host = '';         # server host
my $port = 80;       # tcp port
my $script = '/fpm-status';       # test script (absolute path starting at / - root directory -)
my $timeout = 3;       # timeout in seconds

# check command line options
GetOptions ('H=s' => \$host, 'p=i' => \$port, 's=s' => \$script, 't=i' => \$timeout);

if (($host eq '') || ($port eq '')) {
	print "Usage: check_php-cgi.pl -H host -p port [-s <test script>] [-t <timeout seconds>]\n";
	exit(-1);
}
 
# run check
my $ua = LWP::UserAgent->new;

$ua->timeout($timeout);
$ua->default_header('Host' => $host);

my $response = $ua->request(HTTP::Request->new('GET','http://'.$host.':'.$port.$script));
unless ($response->is_success) {
	die $response->message;
}

# parse response
my %data;
foreach my $line (split /\n/, $response->content) {
	next unless (my($key, $value) = $line =~ /^([^:]+)\s*:\s*(\S+)/);
	$data{$key} = $value;
}

# print out only wanted keys
my %keys = (
	'accepted conn' => 'accepted',
	'active processes' => 'active',
	'idle processes' => 'idle',
	'total processes' => 'total',
);
while (my($key, $tag) = each %keys) {
	my $value = defined $data{$key} ? $data{$key} : -1;
	printf("%s:%s ", $tag, $value);
}
print "\n";
