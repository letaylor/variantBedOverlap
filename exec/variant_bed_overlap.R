#!/usr/bin/env Rscript

suppressMessages(library(optparse))
suppressMessages(library(myvariant))
suppressMessages(library(proxysnps))
suppressMessages(library(variantBedOverlap))

main <- function() {
    optionList <- list(
        optparse::make_option(c("-r", "--rsid"),
            type = "character",
            help = paste0(
                "rsid for query using proxysnps."
            )
        ),

        optparse::make_option(c("-d", "--dir"),
            type = "character", default = ".",
            help = paste0(
                "Directory with BED files to calculate overlaps with ",
                "variants. ",
                "[default %default]"
            )
        ),

        optparse::make_option(c("-p", "--population"),
            type = "character", default = "NA",
            help = paste0(
                "The name of a 1000 Genomes population ",
                "(AMR,AFR,ASN,EUR,FIN...). ",
                "Set this to NA to use all populations. [default %default]"
            )
        ),

        optparse::make_option(c("-r2", "--R2"),
            type = "numeric", default = 0.8,
            help = paste0(
                "R2 cutoff (variants with R.squared < will be dropped). ",
                "[default %default]"
            )
        ),

        optparse::make_option(c("-rgb", "--col_itemRgb"),
            type = "numeric", default = 0,
            help = paste0(
                "Column with RGB value in the BED file. ",
                "In extended BED format, this would be column 9. ",
                "If 0, in the final plots, colors will be from R defaults. ",
                "[default %default]"
            )
        ),

        optparse::make_option(c("-out", "--out_tag"),
            type = "character", default = "variant_bed_overlaps",
            help = paste0(
                "Tag name for output files. ",
                "[default %default]"
            )
        ),

        optparse::make_option(c("-rl", "--rsids_line"),
            type = "character", default = NULL,
            help = paste0(
                "List of variant ids (e.g., rs516946,rs508419) .",
                "In the final plot, if the variant id occurs, there will be a ",
                "vertical line highlighting each variant listed here. ",
                "[default %default]"
            )
        ),

        optparse::make_option(c("-v", "--varshney_chrhmm"),
            type = "logical", default = FALSE,
            help = paste0(
                "If TRUE, run extra chromatin state name processing for the ",
                "chromatin states from Varshney et al 2017 ",
                "(10.1073/pnas.1621192114). ",
                "[default %default]"
            )
        ),

        optparse::make_option(c("--verbose"),
            type = "logical", default = FALSE,
            help = paste0(
                "Extra output. ",
                "[default %default]"
            )
        ),

        optparse::make_option(c("-s", "--save_data"),
            type = "logical", default = FALSE,
            help = paste0(
                "If TRUE, saves the data used to generate the plot. ",
                "[default %default]"
            )
        )

    )

    parser <- optparse::OptionParser(
        usage = "%prog",
        option_list = optionList,
        description = paste0(
            "Gets variants in LD with tag variant. ",
            "Calculates the overlap of all variants with all bed files in a ",
            "directory. ",
            "Saves the overlaps dataframe. ",
            "Plots the overlaps."
        )
    )

    # a hack to fix a bug in optparse that won"t let you use positional args
    # if you also have non-boolean optional args:
    getOptionStrings <- function(parserObj) {
        optionStrings <- character()
        for(item in parserObj@options) {
          optionStrings <- append(optionStrings,
              c(item@short_flag, item@long_flag))
        }
        optionStrings
    }
    optStrings <- getOptionStrings(parser)
    arguments <- optparse::parse_args(parser, positional_arguments=T)

    # set the output file tag
    out_tag <- arguments$options$out_tag

    # get proxies
    if (arguments$options$population == "NA") {
        snps_q <- proxysnps::get_proxies(
            query = arguments$options$rsid,
            window_size = 1e+05
        )
    } else {
        snps_q <- proxysnps::get_proxies(
            query = arguments$options$rsid,
            window_size = 1e+05,
            pop = arguments$options$population
        )
    }

    # drop proxies not in ld
    r2_cutoff <- arguments$options$R2
    snps <- subset(snps_q, R.squared >= r2_cutoff)
    cat(nrow(snps), "/", nrow(snps_q),
        " variants in LD (R2 >= ", r2_cutoff, ").\n", sep = "")

    # get overlaps with all bed files in directory
    # add information to the output datafame on the
    snps_overlap <- variantBedOverlap::get_bed_overlaps(
        df = snps,
        dir = arguments$options$dir,
        col_itemRgb = arguments$options$col_itemRgb,
        verbose = arguments$options$verbose
    )

    # save this data
    snps_overlap_clean <- snps_overlap
    # if we need to remove RGB tags, then do that
    if (arguments$options$col_itemRgb != 0) {
        cols <- colnames(snps_overlap_clean)[grepl("bed",
            colnames(snps_overlap_clean))]
        for (i in cols) {
            snps_overlap_clean[[i]] <- unlist(
                lapply(snps_overlap_clean[[i]],
                    FUN = function(x) { return(strsplit(x, "::")[[1]][1]) }
                )
            )
        }
    }
    write.table(snps_overlap_clean, paste0(out_tag, ".tsv"),
        row.names = FALSE, sep = "\t")

    # make the final plot
    xid_solid_line <- NULL
    if (!is.null(arguments$options$rsids_line)) {
        xid_solid_line <- unlist(strsplit(arguments$options$rsids_line, ","))
    }
    pdf(file = paste0(out_tag, ".pdf"), height=5, width=10)
        lst <- variantBedOverlap::plot_overlaps(
            df = snps_overlap,
            xid_solid_line = xid_solid_line,
            varshney_chrhmm = arguments$options$varshney_chrhmm
        )
        print(lst$plt)
    dev.off()

    # save output data
    out_file = paste0(out_tag, "-plt.tsv")
    if (arguments$options$save_data) {
        write.table(lst$df, out_file, row.names = FALSE, sep = "\t")
    }
}

demo <- function() {
    snps_q <- proxysnps::get_proxies(query = "rs2072014", pop = "FIN")
    snps <- subset(snps_q, R.squared >= 0.8)

    # dowload bed files
    # bed_files <- "https://theparkerlab.med.umich.edu/data/papers/doi/10.1073/pnas.1621192114/chromatin_states/"
    # cmd <- paste0('wget -r -np -nd -R "index.html*" ', bed_files)
    # system("mkdir -p bed_files")
    # setwd("bed_files")
    # system(cmd)
    # setwd("..")
    # dir <- file.path(getwd(), "bed_files")
    dir <- system.file(
        "extdata", package = "variantBedOverlap", mustWork = TRUE
    )
    print(dir)

    # get overlaps with all bed files in directory
    snps_overlap <- variantBedOverlap::get_bed_overlaps(
        df = snps, dir = dir, col_itemRgb = 5)

    # plot
    pdf_file <- "bed_overlaps_with_color"
    pdf(file = paste0(pdf_file, ".pdf"), height = 5, width = 10)
        lst <- variantBedOverlap::plot_overlaps(
            df = snps_overlap,
            xid_solid_line = c("rs8717") # variant not in LD at with target
        )
        print(lst$plt)
    dev.off()

    pdf_file <- "bed_overlaps_with_color_and_varshney_chrhmm"
    pdf(file = paste0(pdf_file, ".pdf"), height = 5, width = 10)
        lst <- variantBedOverlap::plot_overlaps(
            df = snps_overlap,
            xid_solid_line = c("rs2072014", "rs35045598"),
            varshney_chrhmm = TRUE
        )
        print(lst$plt)
    dev.off()

    # get overlaps with all bed files in directory
    snps_overlap <- variantBedOverlap::get_bed_overlaps(df = snps, dir = dir)
    pdf_file <- "bed_overlaps_no_color"
    pdf(file = paste0(pdf_file, ".pdf"), height = 5, width = 10)
        lst <- variantBedOverlap::plot_overlaps(
            df=snps_overlap
        )
        print(lst$plt)
    dev.off()
}

main()
#demo()
