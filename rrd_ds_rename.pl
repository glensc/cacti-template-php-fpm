#!/usr/bin/perl
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

#
# use this tool to rename < 0.4 datasources (in .rrd files) to new names:
# ./rrd_ds_rename.pl /var/lib/cacti/rra/14/4726.rrd tmp.rrd
# mv -b tmp.rrd /var/lib/cacti/rra/14/4726.rrd

use strict;
use warnings;
use RRD::Editor ();

die "Usage: $0 INPUTFILE OUTPUTFILE\n" if @ARGV != 2;

my $input = shift;
my $output = shift;

# Create a new object
my $rrd = RRD::Editor->new();

# Load RRD from a file.
# Automagically figures out the file format (native-double, portable-double etc)
$rrd->open($input);

# Change the names of data-sources
$rrd->rename_DS("PHPFPM_total_cons", "total");
$rrd->rename_DS("PHPFPM_idle_cons", "idle");
$rrd->rename_DS("PHPFPM_accptd_cons", "accepted");
$rrd->rename_DS("PHPFPM_active_cons", "active");

# Save RRD to a file
$rrd->save($output);
$rrd->close();
