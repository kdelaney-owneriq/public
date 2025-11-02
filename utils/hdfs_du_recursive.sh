# file:    hdfs_du_recursive.sh
# created: 2025-01-11 by Keith Delaney

# this script recursivly scans and count size of directories in HDFS.
# intereseted in the distribution of volume in HDFS without descending to level of individual files or partitions.
# this recursively scans directories starting from root, then descends.
# scans are run in serial, not parallel, as the hdfs count is a heavy operation

run_date=$(date +"%Y%m%d")
project_home="${HOME}/hdfs_counts" ; cd ; [ -d "${project_home}" ] || mkdir -p "${project_home}" ;
data_home="${project_home}/hdfs_counts_${run_date}" ; [ -d "${data_home}" ] && rm -rf "${data_home}" || mkdir -p "${data_home}" ;

function hdfs_count() {
  local HDFS_PATH="${1}"
  local out_dir="${data_home}/${HDFS_PATH}" ;
  [ -d "${out_dir}" ] || mkdir -p "${out_dir}"

  local out="${out_dir}/root"
  echo "$(date +"%F %T") begin ${HDFS_PATH}/*"

  HADOOP_USER_NAME=root hadoop fs -count "${HDFS_PATH}/*" 2> /dev/null |
  awk 'NF == 4                                    &&   # keep only valid output
       $1 > 0                                     &&   # drop rows which are not dirs (where dir = 0)
       $3 > 0                                     {    # drop rows with no volume (where bytes are zero)
        n = split($4, a, "/")
        if ( a[n] ~ /^(.*date.*=)?[0-9]{4}-?[0-9]{2}-?[0-9]{2}$/ ) {
          is_date = 1
          d = split(a[n],b, "=")
          part = b[1]
          if ( min == "" || min > b[d] ) min = b[d]
          if ( max == "" || max < b[d] ) max = b[d]
        }
       else print
       } END {
          if ( is_date == 1 ) printf "date_part %s %s %s\n", part, min, max
        }' > "${out}.tmp"

  cat "${out}.tmp" | sort -k3nr | awk '$1 > 0 && $3 > 0 {print}' > $out
  rm "${out}.tmp"

  echo "$(date +"%F %T") done with ${HDFS_PATH}/*.  OUT has $(wc -l $out | awk '{print $1}') lines."
  local dirs=( $(cat $out | grep -v "date_part" | sort -k3nr | awk '{print $4}') )

  # call hdfs_count recursively, in serial
  for dir in ${dirs[@]}; do
    hdfs_count "${dir}"
  done
}

log=~/hdfs_count.log
(
  echo "$(date +"%F %T") begin $(basename -- $0)"
  hadoop fs -count $(hadoop fs -ls / | awk '{print $8}' ) 2> /dev/null | sort -k3nr > ${data_home}/root
  DIRS=( $( cat ${data_home}/root | awk '$1 > 0 && $3 > 0 && NF == 4 {print $4}' ) )
  for DIR in ${DIRS[@]}; do
    hdfs_count "${DIR}"
  done
  echo "$(date +"%F %T") done $(basename -- $0) with status $?."
) &> ${log}
