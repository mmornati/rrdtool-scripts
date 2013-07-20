#!/usr/bin/perl
#
# copyright Martin Pot 2003
# http://martybugs.net/linux/hddtemp.cgi
#
# rrd_hddtemp.pl

use RRDs;

my %conf;
eval(`cat ~/.rrd-conf.pl`);
die $@ if $@;

# set variables
my $datafile = "$conf{DBPATH}/buffalo.rrd";
my $picbase  = "$conf{OUTPATH}/buffalo-";

# define location of rrdtool databases

# process data for each specified HDD (add/delete as required)
&ProcessHDD("sdb", "1TB");

sub ProcessHDD
{
# process HDD
# inputs: $_[0]: hdd (ie, hda, etc)
#         $_[1]: hdd description

	# get hdd temp for master drive on secondary IDE channel
	# my $temp=`/usr/local/sbin/hddtemp -n /dev/$_[0]`;
        #Improve this script with parameters and correct "split"
	my $temp=`ssh root\@192.168.0.102 "/usr/local/sbin/smartctl -A -d marvell /dev/sda" | grep 194`;
        my @values = split(/ /, $temp);
	$counter = 0;
        foreach my $val (@values) {
	  $counter++;
	  if ($val =~ /^[0-9]+$/) {
            if ($counter=5) {	
		$temp=$val;
            }
          }
        }
	# remove eol chars and white space
	$temp =~ s/[\n ]//g;
	
	print "$_[1] (/dev/$_[0]) temp: $temp degrees C\n";

	# if rrdtool database doesn't exist, create it
	if (! -e "$datafile")
	{
		print "creating rrd database for /dev/$_[0]...\n";
		RRDs::create "$datafile",
			"-s 300",
			"DS:temp:GAUGE:600:0:100",
			"RRA:AVERAGE:0.5:1:576",
			"RRA:AVERAGE:0.5:6:672",
			"RRA:AVERAGE:0.5:24:732",
			"RRA:AVERAGE:0.5:144:1460";
	}

	# insert value into rrd
	RRDs::update "$datafile",
		"-t", "temp",
		"N:$temp";

	# draw pictures
    foreach ( [3600, "hour"], [86400, "day"], [604800, "week"], [31536000, "year"] ) {
    my ($time, $scale) = @{$_};
    RRDs::graph($picbase . $scale . ".png",
                "--start=-${time}",
                '--lazy',
                '--imgformat=PNG',
                "--title=Buffalo Linkstation HDD Temp  (last $scale)",
                '--base=1024',
                "--width=$conf{GRAPH_WIDTH}",
                "--height=$conf{GRAPH_HEIGHT}",
                '--slope-mode',

                "DEF:temp=${datafile}:temp:AVERAGE",

                'COMMENT:\n',
                'LINE1:temp#00D000:Temp [°C]',
                'COMMENT:\n',
                );
    $ERR=RRDs::error;
    die "ERROR while drawing $datafile $time: $ERR\n" if $ERR;
}

}
