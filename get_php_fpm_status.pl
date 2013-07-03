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

# command line parameters with some defaults
my $host = '';         # server host
my $port = 80;       # tcp port
my $script = '/fpm-status';       # script (absolute path starting at / - root directory -)
my $timeout = 3;       # timeout in seconds

# check command line options
GetOptions(
	'H=s' => \$host,
	'p=i' => \$port,
	's=s' => \$script,
	't=i' => \$timeout,
);

if (!$host || !$port) {
	print "Usage: check_php-cgi.pl -H host -p port [-s <script path>] [-t <timeout seconds>]\n";
	exit(-1);
}

# retrieve PHP-FPM status over HTTP protocol
sub get_data_http {
	use LWP::UserAgent;
	my $ua = LWP::UserAgent->new;

	$ua->timeout($timeout);
	$ua->default_header('Host' => $host);

	my $url = 'http://'.$host.':'.$port.$script;
	my $response = $ua->request(HTTP::Request->new('GET', $url));
	unless ($response->is_success) {
		die "GET $url: ". $response->message;
	}
	return $response->content;
}

my $content = get_data_http();

# parse response
my %data;
foreach my $line (split /\n/, $content) {
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
my $out = '';
while (my($key, $tag) = each %keys) {
	my $value = defined $data{$key} ? $data{$key} : -1;
	$out .= sprintf("%s:%s ", $tag, $value);
}
print $out, "\n";
