#!/bin/bash

# Get the xml_file
xml_file=./../Response/Orendt_20181109_130002.xml

# Create the new csv file
csv_name=$(echo $xml_file | tr '/' '\n' | grep xml | tr '.xml' '.csv')
csv_path=../CSV/$csv_name

# Remove test file
rm $csv_path

# New .csv
touch $csv_path

# Column names for csv file
csv_header="timestamp,agency,articleno,styleno,colorno,season,year,version,filetimestamp,status"
# Status: declined
csv_header="${csv_header},declinecode,declineName"
# filename
csv_header="${csv_header},filename"
# Comment values
csv_header="${csv_header},username,createdate,comment"

# Write column names into csv
echo $csv_header >> $csv_path


# Process the xml file for csv conversion
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
    echo $new_line >> $csv_path # Write new row to csv
  fi

done < $xml_file

exit 0
