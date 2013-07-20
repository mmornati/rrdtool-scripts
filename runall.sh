#!/bin/sh
RRD_WAIT=1s
LANG=C

/bin/sleep $RRD_WAIT
/root/rrd/network.pl
#/bin/sleep $RRD_WAIT
#/root/rrd/tunnels.pl
/bin/sleep $RRD_WAIT
/root/rrd/temperature.pl 2> /dev/null

/bin/sleep $RRD_WAIT
/root/rrd/buffalo_hddtemp.pl 2> /dev/null
/bin/sleep $RRD_WAIT
/root/rrd/raspberrypi_cputemp.pl 2> /dev/null


/bin/sleep $RRD_WAIT
/root/rrd/memory.pl
/bin/sleep $RRD_WAIT
#/root/rrd/load.pl
#/bin/sleep $RRD_WAIT
/root/rrd/diskfree.pl 2> /dev/null

/bin/sleep $RRD_WAIT
#/root/rrd/ups.pl
#/bin/sleep $RRD_WAIT
/root/rrd/cpu.pl
/bin/sleep $RRD_WAIT

/root/rrd/io.pl 2> /dev/null
/bin/sleep $RRD_WAIT
/root/rrd/netstat.pl 2>&1 | fgrep -v 'error parsing /proc/net/snmp: Success'
#/bin/sleep $RRD_WAIT
#/root/rrd/unbound.pl
#/bin/sleep $RRD_WAIT
#/root/rrd/firewall.pl

/bin/sleep $RRD_WAIT
/root/rrd/connecttime.pl
#/bin/sleep $RRD_WAIT
#/root/rrd/bogofilter.pl
#/bin/sleep $RRD_WAIT
#/root/rrd/cpufreq.pl

#/bin/sleep $RRD_WAIT
#/root/rrd/roundtrip.pl

/root/rrd/push_ftp.sh
