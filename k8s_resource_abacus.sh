#!/bin/bash

DEPLOYMENT=""
NAMESPACE="default"
SCRAPE_INTERVAL="5s"

[[ ! -d metrics ]] && mkdir metrics

cd metrics
i=0
start=$(date +"%T")

echo "=> Metric scrape initiated [!]"
echo "=> Interrupt with ANY key when satisfied with data gather, hopefully hours (more the marrier :))"
while [ true ]; do
  read -t 3 -n 1
  if [ $? = 0 ] ; then
    break
  else
    ((i=i+1))
    echo "=> Metrics gather, iter: #${i} [start: ${start}; current: $(date +"%T")]" | tee -a "${DEPLOYMENT}"
    kubectl top pods --namespace "${NAMESPACE}" | grep "${DEPLOYMENT}" | tee -a "${DEPLOYMENT}"
    sleep "${SCRAPE_INTERVAL}"
    #
  fi
done
echo " <= Received, breaking [!]"

echo "=> Processing metrics ..."
METRICS_TOTAL=$(grep -v 'Metrics gather' "${DEPLOYMENT}" | wc -l)
P90=$(echo $(( METRICS_TOTAL*90/100 )))
P99=$(echo $(( METRICS_TOTAL*99/100 )))
CPU_P90=$(grep -v 'Metrics gather' "${DEPLOYMENT}" | sort -nk 2 | tail -n+${P90} | head -1 | awk '{print $2}')
CPU_P99=$(grep -v 'Metrics gather' "${DEPLOYMENT}" | sort -nk 2 | tail -n+${P99} | head -1 | awk '{print $2}')
MEMORY_P90=$(grep -v 'Metrics gather' "${DEPLOYMENT}" | sort -nk 3 | tail -n+${P90} | head -1 | awk '{print $3}')
MEMORY_P99=$(grep -v 'Metrics gather' "${DEPLOYMENT}" | sort -nk 3 | tail -n+${P99} | head -1 | awk '{print $3}')

echo
echo "=> Stats of ${DEPLOYMENT} deployment"
echo
echo "     Metrics (total): ${METRICS_TOTAL}"
echo "         CPU p90 (m): ${CPU_P90}"
echo "         CPU p99 (m): ${CPU_P99}"
echo "     Memory p90 (Mi): ${MEMORY_P90}"
echo "     Memory p99 (Mi): ${MEMORY_P99}"
echo

