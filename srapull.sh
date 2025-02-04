#!/bin/bash

# Set PATH variable to include SRA Toolkit this may need to be change if your toolkit is in another directory
export PATH=~/Documents/sratoolkit/bin:${PATH}

# Define the input file containing accession numbers
INPUT_FILE="sra.txt"
echo "Input file: $INPUT_FILE"

# Read the accession numbers from the file into an array, trimming spaces
mapfile -t ACCESSION_NUMBERS < <(awk '{$1=$1};1' "$INPUT_FILE")

# Loop through each accession number
for ACCESSION_NUMBER in "${ACCESSION_NUMBERS[@]}"; do
  # Trim any additional spaces
  ACCESSION_NUMBER=$(echo $ACCESSION_NUMBER | xargs)

  echo "Processing accession number: '$ACCESSION_NUMBER'"
  
  # Define the path to the SRA file
  SRA_FILE="${ACCESSION_NUMBER}/${ACCESSION_NUMBER}.sra"

  # Fetch the raw sequences in SRA format using prefetch
  prefetch $ACCESSION_NUMBER > "${ACCESSION_NUMBER}_prefetch.log" 2>&1
  echo "Prefetch command exit status: $?"

  # Check if prefetch was successful
  if [ $? -eq 0 ]; then
    # Extract metadata using vdb-dump and save it to a file
    vdb-dump --info --output-file ${ACCESSION_NUMBER}_info.txt $ACCESSION_NUMBER
    echo "Metadata extraction command exit status: $?"

    # Determine if the data is single-end or paired-end using sra-stat
    PAIR_INFO=$(sra-stat -x -s $SRA_FILE | grep "Number of spots:")
    PAIRED=$(echo $PAIR_INFO | grep -o "2\|1")

    if [ "$PAIRED" == "2" ]; then
      # Convert the SRA files to FASTQ format for paired-end data
      fasterq-dump --split-files $SRA_FILE > "${ACCESSION_NUMBER}_fasterq-dump.log" 2>&1
      echo "Fasterq-dump (paired-end) command exit status: $?"
    else
      # Convert the SRA files to FASTQ format for single-end data
      fasterq-dump $SRA_FILE > "${ACCESSION_NUMBER}_fasterq-dump.log" 2>&1
      echo "Fasterq-dump (single-end) command exit status: $?"
    fi

    echo "Fetched and converted sequences for accession number: $ACCESSION_NUMBER"
  
    # Check if the output files exist and are not empty
    if [ -s "${ACCESSION_NUMBER}_1.fastq" ] || [ -s "${ACCESSION_NUMBER}.fastq" ]; then
      if [ -s "${ACCESSION_NUMBER}_1.fastq" ]; then
        echo "Paired-end sequences found for accession number: $ACCESSION_NUMBER"
      else
        echo "Single-end sequences found for accession number: $ACCESSION_NUMBER"
      fi
    else
      echo "Warning: No sequences found for accession number: $ACCESSION_NUMBER"
    fi
  else
    echo "Error: Failed to fetch sequences for accession number: $ACCESSION_NUMBER"
  fi
done

echo "Downloads Complete"
