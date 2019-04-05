#!/bin/sh

# Filters BED file to only keep chr22 to keep a small footprint of data
# to be included in the package.

in_file=$1
out_file=$(basename $in_file '.chromatinStates.bed.gz')
repo='https://theparkerlab.med.umich.edu/data/papers/doi/10.1073/pnas.1621192114/chromatin_states'

wget "$repo/$in_file"
gunzip -c $in_file | grep 'chr22' | gzip -9 -c > "$out_file.bed.gz"
rm $in_file
