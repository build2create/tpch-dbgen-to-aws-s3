#!/bin/bash

# Size, in GBs, of the total dataset to be created
SIZE=

# For each table, how many files should it be split into?
CHUNKS=

# The S3 bucket to which the TPC-H files will be sent
S3_BUCKET=

# The top-level working directory (should be one dir above tpch-dbgen)
ROOT_PATH=

# Directory to which you've cloned tpch-dbgen from github
DBGEN_PATH=$ROOT_PATH/tpch-dbgen

#########################################
# Should not need to edit below this line
#########################################

DIR_NAME=tpc-h-${SIZE}gb
OUTPUT_DIR=$ROOT_PATH/$DIR_NAME
mkdir $OUTPUT_DIR -p
export DSS_PATH=$OUTPUT_DIR
cd $DBGEN_PATH

# Generate output files
for ((i=1; i<=CHUNKS; i++)); do
    echo ./dbgen -v -s $SIZE -C $CHUNKS -S $i -f
    ./dbgen -v -s $SIZE -C $CHUNKS -S $i -f
    cd $OUTPUT_DIR
    for j in `ls *.tbl.$i`; do
      sed 's/|$//' $j > ${j/tbl/csv};
      echo $j;
      table_name="$( cut -d '.' -f 1 <<< "$j" )"
      mv $table_name.csv.$i $table_name.$i.csv
      aws s3 cp $table_name.$i.csv s3://$S3_BUCKET/warehouse/tpc-h-${SIZE}/$table_name/
      #In case the file is small enough to divde in chunks copy the file completely
      if [ ! -f $table_name.csv];
      then
      aws s3 cp $table_name.csv s3://$S3_BUCKET/warehouse/tpc-h-${SIZE}/$table_name/
      rm -rf $table_name.csv
      fi
      echo "Done copying the s3 chunk $table_name.$i.csv"
      rm -rf $j
      rm -rf $table_name.$i.csv
      echo "Completed cleaning up the chunks"
    done;
    echo "Completed the iteration # $i"
    cd $DBGEN_PATH
done

