variantBedOverlap
=================

Calculates overlap of variants in LD with BED files.

* GitHub repo: https://github.com/letaylor/variantBedOverlap
* Free software: MIT license


Overview
--------

This package/script was designed to (1) get variants in LD with a tag variant and (2) see what chromatin states these variants fall in across cell/tissue types.

The package contains functions that are incorporated into an command line script that does the following:

1. Gets variants in LD with tag variant (via [proxysnps](https://github.com/slowkow/proxysnps)).

2. Calculates the overlap of all variants with BED files in a directory.

3. Saves the overlaps data.frame.

4. Makes a plot the overlaps.


Quick Start
-----------

Install the R package:

```r
# install the package in R
install.packages("devtools")
options(unzip = "internal") # sometimes this is needed, depending on the R install
devtools::install_github("letaylor/variantBedOverlap")
```

Run the core script from the command line:

```shell
# get the lib dir for variantBedOverlap
install_dir=$(R --slave -e 'cat(find.package("variantBedOverlap"))')

# get the dir for demo bed files
bed_dir="$install_dir/extdata"

# see help options of command line script
Rscript "$install_dir/exec/variant_bed_overlap.R" --help

# run the command line script
Rscript "$install_dir/exec/variant_bed_overlap.R" --rsid rs2072014 \
    --dir $bed_dir --population FIN --col_itemRgb 5 \
    --out_tag variant_bed_overlaps --rsids_line rs2072014,rs35045598 \
    --varshney_chrhmm TRUE --save_data TRUE

# list output files
ls variant_bed_overlaps*
```

Example output plot:

![plot_overlaps](vignettes/variantBedOverlap_files/figure-markdown_github/plot_overlaps-1.png)


Usage
-----

See the [vignettes](vignettes/variantBedOverlap.md) for more usage examples.


Other
-----

This package uses [bumpversion](https://pypi.org/project/bumpversion) for automatic [semantic versioning](https://semver.org).

```bash
# bump the appropriate increment
bumpversion patch --verbose --dry-run
bumpversion minor --verbose --dry-run
bumpversion major --verbose --dry-run

# commit with tags
git push --tags
```
