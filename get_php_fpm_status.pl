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
use constant { MODE_FCGI => 1, MODE_HTTP => 2 };

# command line parameters with some defaults
# server host
my $host = '';
# tcp port
my $port = 80;
# script (absolute path starting at / - root directory -)
my $script = '/fpm-status';
# query string
my $query_string = '';
# timeout in seconds
my $timeout = 3;
# connection mode: FCGI or HTTP
# FCGI talks directly to PHP-FPM port
# HTTP talks to PHP-FPM status url mapped by webserver
my $mode = MODE_FCGI;

# check command line options
GetOptions(
	'H=s' => \$host,
	'p=i' => \$port,
	's=s' => \$script,
	'q=s' => \$query_string,
	'http' => sub { $mode = MODE_HTTP },
	'fcgi' => sub { $mode = MODE_FCGI },
	't=i' => \$timeout,
) or die "ERROR: parsing commandline options!\n";

if (!$host || !$port) {
	print "Usage: check_php-cgi.pl -H host -p port [-s <script path>] [-q <query string>] [-t <timeout seconds>]\n";
	exit(-1);
}

# retrieve PHP-FPM status over HTTP protocol
sub get_data_http {
	require LWP::UserAgent;
	my $ua = LWP::UserAgent->new;

	$ua->timeout($timeout);
	$ua->default_header('Host' => $host);

	my $url = 'http://'.$host.':'.$port.$script;
	if ($query_string) {
		$url .= '?' . $query_string;
	}
	my $response = $ua->request(HTTP::Request->new('GET', $url));
	unless ($response->is_success) {
		die "GET $url: ". $response->message;
	}
	return $response->content;
}

sub get_data_fcgi {
	require IO::Socket::INET;
	require FCGI::Client;

	my $sock = IO::Socket::INET->new(
		PeerAddr => $host,
		PeerPort => $port,
		Timeout  => $timeout,
		Proto    => 'tcp',
	) or die;

	my $client = FCGI::Client::Connection->new(sock => $sock) or die;
	my ($stdout, $stderr) = $client->request(
		+{
			REQUEST_METHOD  => 'GET',
			PHP_SELF        => $script,
			SCRIPT_FILENAME => $script,
			SCRIPT_NAME 	=> $script,
			QUERY_STRING    => $query_string,
		},
		''
	) or die;

	my ($headers, $body) = split("\r\n\r\n",$stdout);
	return $body;
}

my $content;
if ($mode == MODE_HTTP) {
	$content = get_data_http();
} elsif ($mode == MODE_FCGI) {
	$content = get_data_fcgi();
} else {
	die "Unknown mode";
}

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
