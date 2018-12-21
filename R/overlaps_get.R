# disable strings as factors, but re-enable upon exit
old <- options(stringsAsFactors = FALSE)
on.exit(options(old), add = TRUE)

#' Get overlaps of data.frame rows and BED files.
#'
#' \code{get_bed_overlaps} finds overlaps between the rows of a data.frame and
#' every BED file within a directory. If one row does not overlap anything in
#' the BED files, it is still returned.
#'
#' @param df Data.frame.
#'     Data.frame with at least these columns: CHROM, POS, ID.
#' @param dir Character.
#'     String specifying the directory with BED files. This method assumes
#'     there is not header to the BED files that must be removed.
#' @param col_itemRgb Numeric.
#'     Specifies the column of itemRgb values within a BED file.
#'     In a strict BED file, this would be column 9
#'         (see \url{https://genome.ucsc.edu/FAQ/FAQformat.html#format1}).
#'     If \code{col_itemRgb == 0}, RGB values will not be appended to the
#'     output, as described below in the return documentation of this function.
#' @param verbose Logical.
#'     If true, print extra output (e.g., on bed files being read).
#'
#' @return Data.frame.
#'     The input data.frame with additional bed* columns named for each BED
#'     file in the input directory (e.g., bed.<file_name1>). The value of each
#'     column is the 'name' entry of the BED file (column 4) corresponding to
#'     the genomic segment that overlaps the input data.
#'     If \code{col_itemRgb != 0}, then the output values will have the RGB
#'     values from the BED file appended to them using a '::' character (e.g,
#'     <bed_file.name_value> \code{->}
#'     <bed_file.name_value>::<bed_file.RGB_value>).
#'
#' @importFrom GenomicRanges GRanges
#' @importFrom IRanges IRanges
#' @importFrom IRanges findOverlaps
#' @importFrom S4Vectors queryHits
#' @importFrom S4Vectors subjectHits
#' @importFrom plyr rename
#' @importFrom utils read.table
#' @export
get_bed_overlaps <- function(df, dir = ".", col_itemRgb = 0, verbose = F) {
    # check to make sure the df looks nice
    if (!all(c("CHROM", "POS", "ID") %in% colnames(df))) {
        stop("Columns missing from input data.frame.")
    }
    df_out <- df

    # make granges object for overlap calculations #paste0('chr',CHROM),
    df_ranges <- with(df,
        GenomicRanges::GRanges(
            gsub("chr", "", CHROM),
            IRanges::IRanges(POS, POS + 1, names = as.character(ID))
        )
    )

    # get all *.bed or .bed.gz files
    files <- Sys.glob(file.path(dir, "*.bed"))
    files <- c(files, Sys.glob(file.path(dir, "*.bed.gz")))
    if (length(files) == 0) {
        stop("Found no *bed or *bed.gz files.")
    }

    for (f in files) {
        fname <- strsplit(basename(f), ".bed")[[1]][1]
        if (verbose) {
            cat("processing file:\t", fname, "\n", sep = "")
        }

        # loadNamespace throws error and requireNamespace will return FALSE
        # requireNamespace loads the package vs attatching it
        # If data.tables installed, then use fread.  Otherwise use read.table.
        if (requireNamespace("data.table", quietly = TRUE)) {
            if (grepl(".gz$", f)) {
                anno <- data.table::fread(paste("gunzip -c", f),
                    sep = "\t", header = FALSE, stringsAsFactors = FALSE)
            } else {
                anno <- data.table::fread(f,
                    sep = "\t", header = FALSE, stringsAsFactors = FALSE)
            }
        } else {
            anno <- read.table(f,
                sep = "\t", header = FALSE, stringsAsFactors = FALSE)
        }
        anno <- plyr::rename(
            anno,
            c(V1 = "chr", V2 = "start", V3 = "end", V4 = "name"),
            warn_missing = F
        )
        colnames(anno) <- gsub(paste0("V", col_itemRgb),
            "itemRgb", colnames(anno))
        # if chr1, drop the chr part
        anno[["chr"]] <- gsub("chr", "", anno[["chr"]])
        # add itemRgb to name to carry over subsequently
        if (col_itemRgb != 0) {
            anno[["name"]] <- with(anno, paste(name, itemRgb, sep = "::"))
        }
        # make grange oobject
        anno_range <- with(anno,
            GenomicRanges::GRanges(
                chr,
                IRanges::IRanges(start, end, names = name)
            )
        )

        # see http://davetang.org/muse/2013/01/02/iranges-and-genomicranges/
        overlaps <- IRanges::findOverlaps(df_ranges, anno_range,
            maxgap = 0, minoverlap = 1,
            ignore.strand = TRUE, type = "within")
        match_hit <- data.frame(
            names(df_ranges)[S4Vectors::queryHits(overlaps)],
            names(anno_range)[S4Vectors::subjectHits(overlaps)],
            stringsAsFactors = FALSE)

        # merge the match dataframe back with the parent df an alternative
        # method would be to make a list that we later cbind
        colnames(match_hit) <- c("ID", paste("bed", fname, sep = "."))
        # colnames(match_hit) <- c('ID', fname)
        match_hit$ID <- as.character(match_hit$ID)
        # if there are no matches this will fill in NA under the column
        df_out <- merge(df_out, match_hit,
            by = c("ID"), all.x = TRUE, all.y = FALSE)
        df_out$ID <- as.character(df_out$ID)
        anno <- NULL
        anno_range <- NULL
        overlaps <- NULL
        match_hit <- NULL
    }

    return(df_out)
}

