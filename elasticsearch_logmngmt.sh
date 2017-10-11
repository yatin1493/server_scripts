daysagoyear=$(date --date="15 days ago" +'%Y')
daysagomonth=$(date --date="15 days ago" +'%m')
daysagoday=$(date --date="15 days ago" +'%d')

INDEX_PREFIXES='filebeat-'

indices=`curl -u admin:Njj2MYTnTneoD localhost:9200/_cat/indices?v|grep $INDEX_PREFIXES|awk '{print $3}'`

for index in $indices
do
	index_date=`echo "$index"|cut -d "-" -f2`
	index_date=`echo "$index_date"|tr . -`
	index_date_yr=`date -d $index_date "+%Y"`
	index_date_mon=`date -d $index_date "+%m"`
	index_date_day=`date -d $index_date "+%d"`
	delete=0
	SNAPSHOT_NAME=${INDEX_PREFIXES}${index_date}"-snapshot"
	bucket_name="snapshots321"
        if [ "$daysagoyear" -gt "$index_date_yr" ]
	then
	    delete=1
        elif [ "$daysagoyear" -eq "$index_date_yr" -a "$daysagomonth" -gt "$index_date_mon" ]
	then
	    delete=1
        elif [ "$daysagoyear" -eq "$index_date_yr" -a "$daysagomonth" -eq "$index_date_mon" -a "$daysagoday" -ge "$index_date_day" ]
        then
            delete=1 
	fi
        if [ $delete -eq 1 ]
	then
          echo "Creating snapshot of $index ..."
#          curl -u admin:Njj2MYTnTneoD -XPUT 'http://localhost:9200/_snapshot/snapshots321' -d '{
#       "type": "s3",
#       "settings": {
#          "base_path": "'${index}'"
#}
#}'
	  curl -u admin:Njj2MYTnTneoD -XPUT "http://localhost:9200/_snapshot/$bucket_name/$SNAPSHOT_NAME?wait_for_completion=true" -d '{
		"indices": "'${index}'",
		"ignore_unavailable": "true",
		"include_global_state": false
	}'
          if [ $? -eq 0 ];then
	     echo "Removing $index ...."
             curl -u admin:Njj2MYTnTneoD -XDELETE "http://localhost:9200/$index"
          else
               echo "Unable to form snapshot on s3"
          fi 
	fi
done
