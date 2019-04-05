#' Plot overlaps.
#'
#' \code{plot_overlaps} plots the data.frame returned by
#' \code{\link{get_bed_overlaps}}.
#'
#' @param df Data.frame.
#'     Data.frame with at least these columns: CHROM, POS, ID, 'bed.*'.
#'     The 'bed.*' column names define y-axis labels,
#'     'bed.*' column values define the plot colors,
#'     and the ID column values define the x-axis labels.
#' @param xid_solid_line Character vector.
#'      A solid verticle line will be added to the plot at any x-axis value
#'      that is contained within this character vector.
#' @param varshney_chrhmm Logical.
#'      If \code{TRUE}, the function assumes the values of the 'bed.*' columns
#'      are chromatin states from Varsheny et al 2017
#'      (\url{https://doi.org/10.1073/pnas.1621192114}) and will format the
#'      labels to make a more polished plot.
#'
#' @return List.
#'     A list with the following elements:
#'     \describe{
#'         \item{plt}{object from ggplot2}
#'         \item{df}{data.frame of the plot data}
#'     }
#'
#' @import ggplot2
#' @importFrom reshape2 melt
#' @importFrom plyr rename
#' @importFrom stats reorder
#' @export
plot_overlaps <- function(df, xid_solid_line = NULL, varshney_chrhmm = FALSE) {
    # check to make sure the df looks nice
    if (!all(c("POS", "ID") %in% colnames(df))) {
        stop("Columns missing from input data.frame.")
    }
    # get variant ID, variant POS + overlaps from bed files
    bed_file_cols = colnames(df)[grepl("bed", colnames(df))]
    if (length(bed_file_cols) == 0) {
        stop("Columns missing from input data.frame.")
    }
    cols <- c("ID", "POS", bed_file_cols)
    dfplt <- reshape2::melt(df[cols], id.vars = c("ID", "POS"))

    # see if itemRgb values are included what normally would be the name column
    # from get_bed_overlaps() function
    add_itemRgb <- any(grep("::", dfplt[["value"]]))
    if (add_itemRgb) {
        dfplt[["bed_feature"]] <- unlist(
            lapply(dfplt[["value"]], FUN = function(x) {
                return(strsplit(x, "::")[[1]][1])
            })
        )
        dfplt[["color"]] <- unlist(
            lapply(dfplt[["value"]], FUN = function(x) {
                return(variantBedOverlap::rgb2hex(strsplit(x, "::")[[1]][2]))
            })
        )
        dfplt$value = NULL
    }
    # re-name to informative columns
    dfplt <- plyr::rename(dfplt,
        c(variable = "bed_file", value = "bed_feature"),
        warn_missing = FALSE
    )
    # drop the 'bed.' tag get_bed_overlaps() overlaps to the filename
    dfplt[["bed_file"]] <- gsub("bed.", "", dfplt[["bed_file"]])
    if (all(is.na(dfplt[["bed_feature"]]))) {
        stop("No data to plot.")
    }

    # set the colors to chromatin state info from 10.1073/pnas.1621192114
    if (varshney_chrhmm) {
        # change bed feature to a factor where levels are state numbers and the
        # labels are the chromatin state labels
        chrom_levels <- unique(dfplt[["bed_feature"]])
        chrom_labs <- sub("_", ". ", chrom_levels)
        chrom_labs <- gsub("_", " ", chrom_labs)
        dfplt[["bed_feature"]] <- factor(
            as.character(dfplt[["bed_feature"]]),
            levels = as.character(chrom_levels),
            labels = as.character(chrom_labs)
        )
        # sort bed_feature numerically by chr state
        dfplt[["chrhmm_state"]] <- as.numeric(unlist(
            lapply(as.character(dfplt[["bed_feature"]]), FUN = function(x) {
                return(strsplit(x, "\\.")[[1]][1])
            })
        ))
        dfplt$bed_feature <- reorder(dfplt$bed_feature, dfplt$chrhmm_state)

        # below is a hard coded method if dfplt[['bed_feature']] were numeric
        # # plot chromatin states
        # chrom_labs <- c(
        #     '1_Active_TSS',
        #     '2_Weak_TSS',
        #     '3_Flanking_TSS',
        #     '5_Strong_transcription',
        #     '6_Weak_transcription',
        #     '8_Genic_enhancer',
        #     '9_Active_enhancer_1',
        #     '10_Active_enhancer_2',
        #     '11_Weak_enhancer',
        #     '14_Bivalent_poised_TSS',
        #     '16_Repressed_polycomb',
        #     '17_Weak_repressed_polycomb',
        #     '18_Quiescent_low_signal')
        # chrom_labs <- sub('_', '. ', chrom_labs)
        # chrom_labs <- gsub('_', ' ', chrom_labs)
        #
        # # color information (rgb)
        # # 1 255,0,0 #FF0000
        # # 2 255,69,0 #ff4500
        # # 3 255,69,0 #ff4500
        # # 5 0,128,0 #008000
        # # 6 0,100,0 #006400
        # # 8 194,225,5 #c2e105
        # # 9 255,195,77 #ffc34d
        # # 10 255,195,77 #ffc34d
        # # 11 255,255,0 #ffff00
        # # 14 205,92,92 #cd5c5c
        # # 16 128,128,128 #808080
        # # 17 192,192,192 #c0c0c0
        # # 18 255,255,255 #ffffff
        # chrhmm_state <- c(1,2,3,5,6,8,9,10,11,14,16,17,18)
        # chrhmm_color <- c(
        #     '#FF0000',
        #     '#ff4500',
        #     '#ff4500',
        #     '#008000',
        #     '#006400',
        #     '#c2e105',
        #     '#ffc34d',
        #     '#ffc34d',
        #     '#ffff00',
        #     '#cd5c5c',
        #     '#808080',
        #     '#c0c0c0',
        #     '#ffffff')
        # chrhmm_info <- data.frame(
        #     bed_feature=chrhmm_state,
        #     bed_feature_label=chrom_labs,
        #     state_color=chrhmm_color
        # )
        #
        # # change bed feature to a factor where levels are state numbers
        # # and the labels are the chromatin state labels
        # dfplt[['bed_feature']] <- factor(
        #     as.character(dfplt[['bed_feature']]),
        #     levels=as.character(chrhmm_info$bed_feature),
        #     labels=as.character(chrhmm_info$bed_feature_label)
        # )
    }

    # order the variants based on their genomic position
    dfplt$ID <- as.factor(dfplt$ID)
    dfplt$ID <- reorder(dfplt$ID, dfplt$POS)

    # pdf(file=paste(plot_file, '.pdf', sep = ''), height=5, width=10)
    plt <- ggplot(dfplt, aes(x = ID, y = bed_file, fill = bed_feature))
    plt <- plt + theme_bw()
    # plt <- plt + geom_point(shape=15, size=3.5) # be sure color=bed_feature
    plt <- plt + geom_tile(stat = "identity", position = "identity")
    # tilt variant IDs on the x axis
    plt <- plt + theme(axis.text.x = element_text(angle = -45,
        hjust = 0, size = 8))
    # set color scheme from bed file
    if (add_itemRgb) {
        color_scheme <- as.character(dfplt$color)
        names(color_scheme) <- as.character(dfplt$bed_feature)
        # plt <- plt + scale_color_manual(values=color_scheme)
        plt <- plt + scale_fill_manual(values = color_scheme,
            guide = guide_legend(override.aes = list(color = "black")))
    }
    # drop the x and y axis labels
    plt <- plt + labs(x = "", y = "", color = "", fill = "")
    # plt <- plt + guides(fill=guide_legend(color='black'))
    # highlight specific variants in the lot with a solid line
    if (!is.null(xid_solid_line)) {
        # get indices of IDs in xid_solid_line
        xpos <- which(as.character(dfplt$ID) %in% xid_solid_line)
        # but, since x axis is factor (due to sorting variants by genome
        # location), get the factor numeric value of each position to get the
        # correcot position of the x axis in the final plot
        xpos <- as.numeric(unique(dfplt$ID[xpos]))
        if (!is.null(xpos)) {
            plt <- plt + geom_vline(
                data = data.frame(x = xpos),
                aes(xintercept = x),
                linetype = 1,
                color = "black",
                alpha = 0.3
            )
        }
    }
    # print(plt)
    # dev.off()
    return(list(plt = plt, df = dfplt))
}

