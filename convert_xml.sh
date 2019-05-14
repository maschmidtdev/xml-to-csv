#!/bin/bash

# Variables
TIMESTAMP=$(date +%Y%m%d_%H%M) # For logfile / naming csv
DATE=$(date +%Y%m%d) # For ???

RESPONSES=/root/puma/response/
ARCHIVE=/root/puma/archive/
LOG=/root/puma/convert_xml.log

# Exit script if there are no files to convert
if [ -z "$(ls -A $RESPONSES)" ]; then
  printf "Nothing here!\n\n" >> $LOG
  exit 0
fi

# Start writing into logfile
echo $TIMESTAMP >> $LOG

# Create Archive for current script run
echo "Creating archive folder ${ARCHIVE}REPONSES_$TIMESTAMP/" >> $LOG
mkdir ${ARCHIVE}RESPONSES_$TIMESTAMP/

# Column names for csv file
CSV_HEADER="timestamp,agency,articleno,styleno,colorno,lastchanged,season,year,version,filetimestamp,status"
# Status: declined
CSV_HEADER="${CSV_HEADER},declinecode,declineName"
# filename
CSV_HEADER="${CSV_HEADER},filename"
# Comment values
CSV_HEADER="${CSV_HEADER},username,createdate,comment"

# Create the new csv file
#CSV_NAME="RESPONSES_$TIMESTAMP.csv"
CSV_NAME="puma_response.csv"
CSV_PATH=../csv/$CSV_NAME

# Remove test files
#rm /root/puma/csv/*

# Create new .csv
touch $CSV_PATH

# Write column names into csv
echo $CSV_HEADER >> $CSV_PATH

# csv converter function
convert_to_csv(){

  echo "Processing $1 ..." >> $LOG

  # read each line of the $1 argument and do:
  while read xml_line
  do

    # --------- PHOTOS XML TAG ------------
    if echo $xml_line | grep -q "photos timestamp"; then
      # Get timestamp
      timestamp=$(echo $xml_line | tr ' ' '\n' | grep timestamp | cut -d'=' -f 2)

      # Get agency
      agency=$(echo $xml_line | tr ' ' '\n' | grep agency | cut -d'=' -f 2 | tr -d '>' | tr -d '\r' )

    # --------- PHOTO XML TAGS ------------
    elif echo $xml_line | grep -q "photo articleno"; then
      # Get articleno
      articleno=$(echo $xml_line | tr ' ' '\n' | grep articleno | cut -d'=' -f 2 | tr -d '\r' )
      new_line="$timestamp,$agency,$articleno"

      # Get styleno
      styleno=$(echo $xml_line | tr ' ' '\n' | grep styleno | cut -d'=' -f 2 | tr -d '\r' )
      new_line="$new_line,$styleno"

      # Get colorno
      colorno=$(echo $xml_line | tr ' ' '\n' | grep colorno | cut -d'=' -f 2 | tr -d '\r' )
      new_line="$new_line,$colorno"

      # Get lastchanged
      lastchanged=$(echo $xml_line | tr ' ' '\n' | grep lastchanged | cut -d'=' -f 2 | tr -d '\r' )
      new_line="$new_line,$lastchanged"

      # Get season
      season=$(echo $xml_line | tr ' ' '\n' | grep season | cut -d'=' -f 2 | tr -d '\r' )
      new_line="$new_line,$season"

      # Get year
      year=$(echo $xml_line | tr ' ' '\n' | grep year | cut -d'=' -f 2 | tr -d '\r' )
      new_line="$new_line,$year"

      # Get version
      version=$(echo $xml_line | tr ' ' '\n' | grep version | cut -d'=' -f 2 | tr -d '\r' )
      new_line="$new_line,$version"

      # Get filetimestamp
      filetimestamp=$(echo $xml_line | tr ' ' '\n' | grep filetimestamp | cut -d'=' -f 2 | tr -d '>' | tr -d '\r' )
      new_line="$new_line,$filetimestamp"

    # --------- STATUS XML TAGS ------------
    elif echo $xml_line | grep -q "status"; then
      # Get status
      status=$(printf $xml_line | sed "s/<status>//" | sed 's/<\/status>//' | tr -d '\r')
      new_line="$new_line,$status"
      # Prepare information about declineCode/declineName
      declineCodes="0"
      declineNames="0"

    # --------- DECLINECODE XML TAGS ------------
    elif echo $xml_line | grep -q "declineCode"; then
      # Get declineCode
      declineCode=$(printf $xml_line | sed "s/<declineCode>//" | sed 's/<\/declineCode>//' | tr -d '\r')
      new_line="$new_line,$declineCode"
      declineCodes="1"

    # --------- DECLINENAME XML TAGS ------------
    elif echo $xml_line | grep -q "declineName"; then
      # Get declineName
      declineName=$(echo -e $xml_line | sed "s/<declineName>//" | sed 's/<\/declineName>//' | tr -d '\r')
      new_line="${new_line},$declineName"
      declineNames="1"

    # --------- FILENAME XML TAGS ------------
    elif echo $xml_line | grep -q "filename"; then
      # Add empty columns for missing declineName/declineCode
      if [ $declineNames -eq "0" ]; then
        new_line="$new_line,"
      fi
      if [ $declineCodes -eq "0" ]; then
        new_line="$new_line,"
      fi
      # Get filename
      filename=$(printf $xml_line | sed "s/<filename>//" | sed 's/<\/filename>//' | tr -d '\r' )
      new_line="${new_line},$filename"

      # Prepare for comments
      comments=0 # Reset comment count

    # --------- COMMENT XML TAGS ------------
    elif echo $xml_line | grep -q "comment username"; then

      # There can be multiple comments
      # For each comment, there will be a new record in the csv with the same data except for:
      #   username, createdate and comment

      # Get username
      username=$(echo $xml_line | tr ' ' '\n' | tr '>' '\n' | grep username | cut -d'=' -f 2 | tr -d '\r' )
      new_line_and_comment="${new_line},$username"

      # Get createdate
      createdate=$(echo $xml_line | tr ' ' '\n' | tr '>' '\n' | grep createdate | cut -d'=' -f 2 | tr -d '\r' )
      new_line_and_comment="${new_line_and_comment},$createdate"

      # Get comment
      export LC_CTYPE=C
      comment=$(echo $xml_line | tr '>' '\n' | grep '</comment' | sed 's/<\/comment//' | sed "s/,/ -/g" | tr -d '\r' )
      new_line_and_comment="${new_line_and_comment},$comment"

      echo "COMMENT:"
      echo $comment

      echo $new_line_and_comment >> $CSV_PATH



    # --------- AFTER COMMENTS ------------
    elif echo $xml_line | grep -q "</comments>"; then
      echo "</comments"

    # --------- NO COMMENTS ------------
    elif echo $xml_line | grep -q "<comments/>"; then
      echo $new_line >> $CSV_PATH



    # ------------ Get closing photo tag and write row into csv -------------
    elif echo $xml_line | grep -q "/photo>"; then
      echo "</photo>"
      #echo $new_line >> $CSV_PATH # Write new row to csv
    fi

  done < $1 # End while

  echo "Moving $1 into ${ARCHIVE}RESPONSES_$TIMESTAMP/" >> $LOG
  mv $1 ${ARCHIVE}RESPONSES_$TIMESTAMP/

} # End convert_to_csv()


# Loop through all xml files in $RESPONSES
for response_xml in $RESPONSES*
do
  # Count number of lines in xml response
  lines=$(wc -l < $response_xml)

  # Disregard responses with only 2 lines (no content)
  if [ $lines -gt 2 ]; then
    # Process the xml files for csv conversion
    convert_to_csv $response_xml
  else
    echo "Deleting $response_xml" >> $LOG
    #rm $response_xml
    mv $response_xml /root/puma/delete/
  fi

done # End for

printf "Done!\n\n" >> $LOG

exit 0
