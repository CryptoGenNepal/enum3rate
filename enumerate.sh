#!/bin/bash

#starting sublist3r
sublist3r -d $1 -v -o domains.txt

#running assetfinder
~/go/bin/assetfinder --subs-only $1 | tee -a domains.txt

#removing duplicate entries
sort -u domains.txt -o domains.txt

#checking for alive domains
echo "[+] Checking for alive domains.."
cat domains.txt | ~/go/bin/httprobe | tee -a alive.txt

echo "Converting to ip addresses"
echo "-------------------------"

for i in $(cat alive.txt);
do
        a=`echo $i | cut -d '/' -f3`
        b=`host $a | grep -i 'has address' | awk '{print $4}'`
        echo $b >> ip_temp.txt
        echo $b
done
echo "removing duplicates"
sort -u ip_temp.txt -o final.txt

uniq -d final.txt

echo "Checking for possible CVEs"

for i in $(cat final.txt);
do
        vulns=`shodan host $i | grep -i "Vulnerabilities"`
        if [ -z "$vulns" ]
        then
                echo ''
        else
                echo "IP:$i " $vulns
                echo "IP:$i " $vulns >> cves.txt
        fi
done

for i in $(cat final.txt);
do
	nmap -Pn --script vuln $i -oN $i -v
done
