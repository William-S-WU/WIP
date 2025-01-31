#!/bin/bash

# Set PATH variable to include SRA Toolkit
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
  
  # Fetch the raw sequences in SRA format using prefetch
  prefetch $ACCESSION_NUMBER
  echo "Prefetch command exit status: $?"

  # Check if prefetch was successful
  if [ $? -eq 0 ]; then
    # Convert the SRA files to FASTQ format using fasterq-dump
    fasterq-dump --split-files $ACCESSION_NUMBER.sra
    echo "Fasterq-dump command exit status: $?"

    echo "Fetched and converted sequences for accession number: $ACCESSION_NUMBER"
  
    # Check if the output file is empty
    if [ ! -s "${ACCESSION_NUMBER}_1.fastq" ]; then
      echo "Warning: No sequences found for accession number: $ACCESSION_NUMBER"
    fi
  else
    echo "Error: Failed to fetch sequences for accession number: $ACCESSION_NUMBER"
  fi
done

echo "Downloads Complete"
