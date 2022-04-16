#!/bin/bash
# ./ngb.sh "GHTOKENGOESHERE" GHORG 10
# ref. https://www.notgitbleed.com/

TOKEN=${1}
ORG=${2}
PER_PAGE=${3}
LOG_FILE="ngb_${ORG}_${RANDOM}.log"
REPO_LAST_PAGE=$(curl -sI -H "Authorization: token ${TOKEN}" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/orgs/${ORG}/repos?per_page=${PER_PAGE}" | egrep '^link' | sed -r 's/.*rel="next".*per_page.*&page=(.*)>; rel="last"/\1/')
REPO_LAST_PAGE="${REPO_LAST_PAGE//[$'\t\r\n ']}"
[ -z "${REPO_LAST_PAGE}" ] && REPO_LAST_PAGE="1"

echo "Results log will be saved on ${LOG_FILE}."
echo "Retrieving repo names for org ${ORG} with ${PER_PAGE} per page and ${REPO_LAST_PAGE} as last page." | tee -a ${LOG_FILE}
for REPO_PAGE in $(eval echo "{1..${REPO_LAST_PAGE}}"); do
	REPOS=$(curl -s -H "Authorization: token ${TOKEN}" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/orgs/${ORG}/repos?per_page=${PER_PAGE}&page=${REPO_PAGE}" | jq -Mr '.[].name')
	echo "${REPOS}" | while read -r REPO; do
		REPO="${REPO//[$'\t\r\n ']}"
		COMMITS_LAST_PAGE=$(curl -sI -H "Authorization: token ${TOKEN}" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/${ORG}/${REPO}/commits?per_page=${PER_PAGE}" | egrep '^link' | sed -r 's/.*rel="next".*per_page.*&page=(.*)>; rel="last"/\1/')
		COMMITS_LAST_PAGE="${COMMITS_LAST_PAGE//[$'\t\r\n ']}"
		[ -z "${COMMITS_LAST_PAGE}" ] && COMMITS_LAST_PAGE="1"
		echo "Retrieving commits from org ${ORG} repo ${REPO} with ${PER_PAGE} per page and ${COMMITS_LAST_PAGE} as last page." | tee -a ${LOG_FILE}
		for COMMITS_PAGE in $(eval echo "{1..${COMMITS_LAST_PAGE}}"); do
			COMMITS=$(curl -s -H "Authorization: token ${TOKEN}" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/${ORG}/${REPO}/commits?per_page=${PER_PAGE}&page=${COMMITS_PAGE}")
			COMMIT_ID="0"
			echo "${COMMITS}" | jq -Mrc '.[].commit' | while read -r COMMIT; do
				COMMIT_ID=$((COMMIT_ID+1))
				AUTHOR_EMAIL=$(echo ${COMMIT} | jq -Mr '.author.email')
				COMMITTER_EMAIL=$(echo ${COMMIT} | jq -Mr '.committer.email')
				printf "\rRepo Page: ${REPO_PAGE//[$'\t\r\n ']} Commit Page: ${COMMITS_PAGE//[$'\t\r\n ']} Commint ID: ${COMMIT_ID//[$'\t\r\n ']} Author Email: ${AUTHOR_EMAIL//[$'\t\r\n ']} Committer Email: ${COMMITTER_EMAIL//[$'\t\r\n ']} "
				if [[ ! ${AUTHOR_EMAIL} =~ ^[][a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$ || ! ${COMMITTER_EMAIL} =~ ^[][a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$  ]]; then
					echo ""
					echo ""
					echo "INTERSTING EMAIL FIELD FOUND!" | tee -a ${LOG_FILE}
					AUTHOR_NAME=$(echo ${COMMIT} | jq -Mr '.author.name')
					COMMITTER_NAME=$(echo ${COMMIT} | jq -Mr '.author.name')
					COMMIT_URL=$(echo ${COMMIT} | jq -Mr '.url')
					echo "Author Name: ${AUTHOR_NAME}" | tee -a ${LOG_FILE}
					echo "Author Email: ${AUTHOR_EMAIL}" | tee -a ${LOG_FILE}
					echo "Commiteer Name: ${COMMITTER_NAME}" | tee -a ${LOG_FILE}
					echo "Commiteer Email: ${COMMITTER_EMAIL}" | tee -a ${LOG_FILE}
					echo "Commit URL: ${COMMIT_URL}" | tee -a ${LOG_FILE}
					echo "" | tee -a ${LOG_FILE}
				fi
			done
		done
		echo ""
	done
done