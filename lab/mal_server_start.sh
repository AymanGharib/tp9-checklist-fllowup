#!/bin/bash
mkdir -p /tmp/malware
cd /tmp/malware
echo "FAKE MALWARE PAYLOAD" > W32.Nimda.Amm.exe
python3 -m http.server 6666
