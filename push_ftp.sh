#!/bin/bash

ftp ftp.mornati.net << EOF
cd public_html
cd rrdtool
lcd /var/www/html/rrdtool
prompt n
mput *
close
quit
EOF

