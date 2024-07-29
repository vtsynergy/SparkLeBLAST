#!/bin/bash

INPUT_FILE=${1}
INPUT_FILE_PREFIX=${INPUT_FILE%.*}
FASTP_OUT="${INPUT_FILE_PREFIX}_fastp"
KZ_OUT="${FASTP_OUT}_kz"
BMTAGGER_OUT="${KZ_OUT}_bmtagger"
FINAL_OUT="${INPUT_FILE_PREFIX}_sortmerna"
EXTENSION="fq"

time fastp -i ${INPUT_FILE} -o "${FASTP_OUT}.${EXTENSION}" -l 70 -x 1 --cut_tail --cut_tail_mean_quality 20

time cat "${FASTP_OUT}.${EXTENSION}" | kz -F -k 8 -t 0.2 > "${KZ_OUT}.${EXTENSION}"

# NOTE: The next command may require a step before it:
# kneaddata_database --download human_genome bmtagger $DIR

time kneaddata --unpaired "${KZ_OUT}.${EXTENSION}" --reference-db human_bmtagger --run-bmtagger -o "${BMTAGGER_OUT}.${EXTENSION}" --trimmomatic Trimmomatic-0.39

# sortmerna command goes here (please run sortmerna -h for help, it requires some paths options along with the input file)
# Note: use ${FINAL_OUT} as the output file name
