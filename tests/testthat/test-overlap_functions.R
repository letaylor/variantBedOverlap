context('overlap functions')

# dummy data
CHROM <- c('8', '8', '8')
POS <- c(41519248, 41519462, 41522991)
ID <- c('rs516946', 'rs515071', 'rs508419')
df <- data.frame(CHROM, POS, ID)

test_that('get_bed_overlaps checks for a proper data.frame.', {
    for (i in c('CHROM', 'POS', 'ID')) {
        df_test <- df
        df_test[i] <- NULL
        expect_error(get_bed_overlaps(df_test),
                     'Columns missing from input data.frame.')
    }
})

test_that('get_bed_overlaps dies if no BED files.', {
    expect_error(get_bed_overlaps(df),
                'Found no *bed or *bed.gz files.', fixed=TRUE)
})

test_that('get_bed_overlaps checks for a proper data.frame.', {
    for (i in c('POS', 'ID')) {
        df_test <- df
        df_test[i] <- NULL
        expect_error(plot_overlaps(df_test),
                     'Columns missing from input data.frame.')
    }
})

