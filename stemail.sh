#!/bin/bash
# ./stemail.sh "YOURSECURITYTRAILAPIKEYGOESHERE" "domain@fb.com" stemail.log
# ref. https://docs.securitytrails.com/docs

API_KEY="${1}"
EMAIL="${2}"
LOG_FILE="${3}"
FIRST="$(curl -s --request POST --url "https://api.securitytrails.com/v1/domains/list?apikey=${API_KEY}&page=1&scroll=true" --data "{\"filter\":{\"whois_email\":\"${EMAIL}\"}}")"
PAGES=$(echo ${FIRST} | jq -Mr '.meta.total_pages')
TOTAL_RECORDS=$(echo ${FIRST} | jq -Mr '.record_count')

echo "Downloading ${TOTAL_RECORDS} domains for whois email ${EMAIL} with total pages ${PAGES} and saving on ${LOG_FILE}."
for PAGE in $(eval echo "{1..${PAGES}}"); do
	echo "Downloading page ${PAGE}."
	curl -s --request POST --url "https://api.securitytrails.com/v1/domains/list?apikey=${API_KEY}&page=${PAGE}&scroll=true" --data "{\"filter\":{\"whois_email\":\"${EMAIL}\"}}" | jq -Mr '.records[].hostname' >> ${LOG_FILE}
done
sort -u ${LOG_FILE} -o ${LOG_FILE}
echo "Finished."