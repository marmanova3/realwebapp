#!/bin/bash

urls="${PWD}/urls.txt"

if [[ ! -e "$urls" ]]; then
    echo "Missing file with URL's"
    exit 1
fi

evaluate_site () {

    local website=$1

    error_log=""
    output_log=""

    output_log=$(curl -L -S -m 10 -w '%{http_code},%{http_connect},%{time_namelookup},%{time_connect},%{time_pretransfer},%{time_starttransfer},%{size_download},%{speed_download},%{time_total},%{num_redirects},%{url_effective}' -o /dev/null -s $website 2>error.log)

    if [[ $? -ne 0 ]]; then
        error_log=$(cat error.log)
        rm error.log
        echo "$output_log,$error_log"
    else
        echo "$output_log,$error_log"
    fi

    }

while true; do

    # log rotation
    day_to_compare=$(date | awk '{print $3}')
    
    if [[ "$day_to_compare" != "$day" ]]; then
        
        timestamp=$(date -d "today" +"%Y%m%d%H%M")
        day=$(date | awk '{print $3}')
    fi
    
    # connectivity check 
    ping -c 4 -q www.google.com 1>/dev/null
    if [[ $? -ne 0 ]]; then

        echo "$(date -d "today" +"%b %d %H:%M:%S") Connectivity issue" >> ${PWD}/status-${timestamp}.log
    fi

    # read urls and check status
    log_time=$(date -d "today" +"%b %d %H:%M:%S")

    while read line; do
        #echo "$line"
        result="$log_time,$(evaluate_site $line),$line"

        url_folder="${PWD}/logs/$line"
        mkdir -p $url_folder

        url_file="$url_folder/$timestamp.log"
        if [[ ! -e "$url_file" ]]; then
            echo "timestamp,http_code,http_connect,time_namelookup,time_connect,time_pretransfer,time_starttransfer,size_download,speed_download,time_total,num_redirects,url_effective,curl_exit_code,url" >> $url_file
        fi
        echo "$result" >> $url_file
        
    done < "$urls"

    sleep 595
done
