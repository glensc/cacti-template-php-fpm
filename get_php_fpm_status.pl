#!/usr/bin/perl
use Getopt::Long;

if (! eval "require LWP::UserAgent;")
{
	$ret = "LWP::UserAgent not found";
}


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
	my @content = split (/\n/, $response->content);
	my $var_accepted = -1;
	if ($content[4] =~ /^accepted conn:\s+(\d+)\s*$/i) {
		$var_accepted = $1;
	}
	my $var_active = -1;
	if ($content[9] =~ /^active processes:\s+(\d+)\s*$/i) {
		$var_active = $1;
	}
	my $var_idle = -1;
	if ( $content[8] =~ /^idle processes:\s+(\d+)\s*$/i ) {
		$var_idle = $1;
	}
	my $var_total = -1;
	if ($content[10] =~ /^total processes:\s+(\d+)\s*$/i) {
		$var_total = $1;
	}
print 'accepted:' . $var_accepted . ' idle:' . $var_idle . ' active:'. $var_active . ' total:' . $var_total . "\n";

