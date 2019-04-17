#!/bin/bash

# Variables
TIMESTAMP=$(date +%Y%m%d_%H%M) # For logfile / naming csv
DATE=$(date +%Y%m%d) # For ???

RESPONSES=../responses/
ARCHIVE=../archive/
LOG=../convert_xml.log

# Exit script if there are no files to convert
if [ -z "$(ls -A $RESPONSES)" ]; then
  echo "Nothing here!" >> $LOG
  exit 0
fi


# Get the response_xml
#response_xml=./../responses/Orendt_20181109_130002.xml

# Start writing into logfile
echo $TIMESTAMP >> $LOG

# Create Archive for current script run
echo "Creating archive folder ${ARCHIVE}ORENDT_$TIMESTAMP/" >> $LOG
mkdir ${ARCHIVE}ORENDT_$TIMESTAMP/

# Column names for csv file
CSV_HEADER="timestamp,agency,articleno,styleno,colorno,season,year,version,filetimestamp,status"
# Status: declined
CSV_HEADER="${CSV_HEADER},declinecode,declineName"
# filename
CSV_HEADER="${CSV_HEADER},filename"
# Comment values
CSV_HEADER="${CSV_HEADER},username,createdate,comment"

# Create the new csv file
#CSV_NAME=$(echo $response_xml | tr '/' '\n' | grep xml | tr '.xml' '.csv')
CSV_NAME="ORENDT_$TIMESTAMP.csv"
CSV_PATH=../csv/$CSV_NAME

# Remove test files
rm ../csv/*

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
      agency=$(echo $xml_line | tr ' ' '\n' | grep agency | cut -d'=' -f 2 | tr -d '>')

    # --------- PHOTO XML TAGS ------------
    elif echo $xml_line | grep -q "photo articleno"; then
      # Get articleno
      attribute=$(echo $xml_line | tr ' ' '\n' | grep articleno | cut -d'=' -f 2)
      new_line="$timestamp,$agency,$attribute"

      # Get stylno
      attribute=$(echo $xml_line | tr ' ' '\n' | grep styleno | cut -d'=' -f 2)
      new_line="$new_line,$attribute"

      # Get colorno
      attribute=$(echo $xml_line | tr ' ' '\n' | grep colorno | cut -d'=' -f 2)
      new_line="$new_line,$attribute"

      # Get season
      attribute=$(echo $xml_line | tr ' ' '\n' | grep season | cut -d'=' -f 2)
      new_line="$new_line,$attribute"

      # Get year
      attribute=$(echo $xml_line | tr ' ' '\n' | grep year | cut -d'=' -f 2)
      new_line="$new_line,$attribute"

      # Get version
      attribute=$(echo $xml_line | tr ' ' '\n' | grep version | cut -d'=' -f 2)
      new_line="$new_line,$attribute"

      # Get filetimestamp
      attribute=$(echo $xml_line | tr ' ' '\n' | grep filetimestamp | cut -d'=' -f 2 | tr -d '>')
      new_line="$new_line,$attribute"

    # --------- STATUS XML TAGS ------------
    elif echo $xml_line | grep -q "status"; then
      # Get status
      attribute=$(printf $xml_line | sed "s/<status>//" | sed 's/<\/status>//' | tr -d '\r')
      new_line="$new_line,$attribute"

      if [ $attribute = "ACCEPTED" ]; then
        new_line="${new_line},," # if status = accepted, declineCode and declineName will be empty
      fi

    # --------- DECLINECODE XML TAGS ------------
    elif echo $xml_line | grep -q "declineCode"; then
      # Get declineName
      attribute=$(printf $xml_line | sed "s/<declineCode>//" | sed 's/<\/declineCode>//' | tr -d '\r')
      new_line="$new_line,$attribute"

    # --------- DECLINENAME XML TAGS ------------
    elif echo $xml_line | grep -q "declineName"; then
      # Get declineName
      attribute=$(printf $xml_line | sed "s/<declineName>//" | sed 's/<\/declineName>//' | tr -d '\r')
      new_line="${new_line},$attribute"

    # --------- FILENAME XML TAGS ------------
    elif echo $xml_line | grep -q "filename"; then
      # Get filename
      attribute=$(printf $xml_line | sed "s/<filename>//" | sed 's/<\/filename>//')
      new_line="${new_line},$attribute"

    # --------- COMMENT XML TAGS ------------
    elif echo $xml_line | grep -q "comment username"; then
      # Get username
      attribute=$(echo $xml_line | tr ' ' '\n' | tr '>' '\n' | grep username | cut -d'=' -f 2)
      new_line="${new_line},$attribute"

      # Get createdate
      attribute=$(echo $xml_line | tr ' ' '\n' | tr '>' '\n' | grep createdate | cut -d'=' -f 2)
      new_line="${new_line},$attribute"

      # Get comment  (replace '>' with newlines, grep line with comment, remove '</comment', replace comma)
      attribute=$(echo $xml_line | tr '>' '\n' | grep '</comment' | sed 's/<\/comment//' | sed "s/,/ -/")
      new_line="${new_line},$attribute"

    # ------------ Get closing photo tag and wirte row into csv -------------
    elif echo $xml_line | grep -q "/photo"; then
      echo $new_line >> $CSV_PATH # Write new row to csv
    fi

  done < $1 # End while

  echo "Moving $1 into ${ARCHIVE}ORENDT_$TIMESTAMP/" >> $LOG
  mv $1 ${ARCHIVE}ORENDT_$TIMESTAMP/

}


# Loop through all xml files in $RESPONSES
for response_xml in $RESPONSES*
do
  # Count number of lines in xml response
  lines=$(wc -l $response_xml | tr ' ' '\n' | grep -o '[0-9]*') #G rab only the number of lines

  # Disregard responses with only 2 lines (no content)
  if [ "$lines" -gt "2" ]; then
    # Process the xml files for csv conversion
    convert_to_csv $response_xml
  else
    echo "Deleting $response_xml" >> $LOG
    #rm $response_xml
    mv $response_xml ../deleted/
  fi

done # End for

printf "Done!\n\n" >> $LOG

exit 0
