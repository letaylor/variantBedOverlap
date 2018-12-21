#' RGB to HEX.
#'
#' \code{rgb2hex} converts RGB values to HEX values.
#'
#' @param x Character.
#'     RGB string separated by commas.
#'
#' @return Character.
#'     A HEX value string.
#'
#' @examples
#' rgb2hex('255,195,77')
#'
#' @importFrom grDevices rgb
#' @export
rgb2hex <- function(x) {
    hex <- sapply(strsplit(x, ","), function(x) {
        return(rgb(x[1], x[2], x[3], maxColorValue = 255))
    })
    return(hex)
}
