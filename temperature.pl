#!/usr/bin/perl
#
# RRD script to display hardware temperature
# 2003,2007,2011 (c) by Christian Garbs <mitch@cgarbs.de>
# Licensed under GNU GPL.
#
# This script should be run every 5 minutes.
#
use strict;
use warnings;
use RRDs;

# parse configuration file
my %conf;
eval(`cat ~/.rrd-conf.pl`);
die $@ if $@;

# set variables
my $datafile = "$conf{DBPATH}/temperature.rrd";
my $picbase  = "$conf{OUTPATH}/temperature-";

my $sensors  = $conf{SENSORS_BINARY};
my $hddtemp  = $conf{HDDTEMP_BINARY};
my $cpus     = $conf{SENSOR_MAPPING_CPU};
my $fans     = $conf{SENSOR_MAPPING_FAN};
my $temps    = $conf{SENSOR_MAPPING_TEMP};

# global error variable
my $ERR;

# whoami?
my $hostname = `/bin/hostname`;
chomp $hostname;

# generate database if absent
if ( ! -e $datafile ) {
    # max 9000 for fan, 100 for temperature
    RRDs::create($datafile,
		 "DS:Core0:GAUGE:600:10:100",
		 "DS:Core1:GAUGE:600:10:100",
		 "DS:disk00:GAUGE:600:10:100",
		 "RRA:AVERAGE:0.5:1:600",
		 "RRA:AVERAGE:0.5:6:700",
		 "RRA:AVERAGE:0.5:24:775",
		 "RRA:AVERAGE:0.5:288:797"
		 );
      $ERR=RRDs::error;
      die "ERROR while creating $datafile: $ERR\n" if $ERR;
      print "created $datafile\n";
}

# get disk data
my %val;
open HDDTEMP, "$hddtemp |", or die "can't open $hddtemp: $!\n";
while (my $hd = <HDDTEMP>) {
    $hd =~ tr /0-9//cd;
    if (length $hd) {
	$val{'HDD_TEMP_' . ($. - 1)} = $hd.'.0';
    }
}
close HDDTEMP, or die "can't close $hddtemp: $!\n";

# get cpu data
open SENSORS, "$sensors -A |", or die "can't open $sensors: $!\n";
my $multiline = 0;
while (my $line = <SENSORS>) {
    chomp $line;
    # celcius sign is garbaged, so pre-treat string 
    $line =~ y/-.:a-zA-Z0-9 / /c;
    if ($multiline and $line !~ /:/) {
	if ($line =~ /^\s+\+?(-?\d+(\.\d+)?) /) {
	    $val{$multiline} = $1;
	}
	$multiline = 0;
    } else {
	if ($line =~ /^([^:]+):(\s+\+?(-?\d+(\.\d+)?) )?/) {
	    if (defined $2) {
		my $key = $1;
		$key =~ tr/ //ds;
		$val{$key} = $3;
	    } else {
		$multiline = $1;
	    }
	}
    }
}
close SENSORS, or die "can't close $sensors: $!\n";


# prepare values
sub getval($)
{
    my $key = shift;
    return 'U' unless defined $key;
    return 'U' unless exists $val{$key};
    return $val{$key};
}

my $rrdstring = 'N';
foreach my $i (0..1) {
    $rrdstring .= ':' . getval($cpus->[$i]);
}

foreach my $i (0..0) {
    $rrdstring .= ':' . getval("HDD_TEMP_$i");
}

# update database
RRDs::update($datafile,
	     $rrdstring
	     );
$ERR=RRDs::error;
die "ERROR while updating $datafile: $ERR\n" if $ERR;

# draw pictures
foreach ( [3600, "hour"], [86400, "day"], [604800, "week"], [31536000, "year"] ) {
    my ($time, $scale) = @{$_};
    RRDs::graph($picbase . $scale . ".png",
		"--start=-${time}",
		'--lazy',
		'--imgformat=PNG',
		"--title=${hostname} temperature (last $scale)",
		"--width=$conf{GRAPH_WIDTH}",
		"--height=$conf{GRAPH_HEIGHT}",
		'--alt-autoscale',
		'--slope-mode',

		"DEF:Core0=${datafile}:Core0:AVERAGE",
		"DEF:Core1=${datafile}:Core1:AVERAGE",
		"DEF:disk00=${datafile}:disk00:AVERAGE",

		'LINE1:Core0#FF8888:Core0[°C]',
		'COMMENT:\n',
		'LINE2:Core1#FFFF88:Core1[°C]',

		'COMMENT:\n',
		'LINE3:disk00#0000FF:sda [°C]',

		'COMMENT:\n',
		);
    $ERR=RRDs::error;
    die "ERROR while drawing $datafile $time: $ERR\n" if $ERR;
}
