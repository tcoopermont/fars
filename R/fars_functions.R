#' Load data from the "Highway Fatality Analysis Reporting System" 
#' 
#' This is a function that reads a data file from 
#' the "US National Highway Traffic Safety Administration's Fatality Analysis Reporting System"
#'

#' @param filename A character string giving the file name/path to load the data from. This can be a local file or url to remote file. More details can be found at \code{\link{read_csv}}.
#' 
#' @details The file/path/url specified in \code{filename} must be accessable or a error is thrown.
#'
#' @return This function returns the contents of filename as a tbl_df
#'
#' @examples
#' \dontrun{
#' fars_read("fars_data.zip")
#' fars_read("/home/user1/Download/fars_data.zip")
#' }
#'
#' @importFrom readr read_csv
#'
#' @importFrom dplyr tbl_df
#'
#' @export
fars_read <- function(filename) {
        if(!file.exists(filename))
                stop("file '", filename, "' does not exist")
        data <- suppressMessages({
                readr::read_csv(filename, progress = FALSE)
        })
        dplyr::tbl_df(data)
}
#' Create a accident file name with extensions
#'
#' This is a function that builds a filename in the standard file format for
#' "Highway Fatality Report", given a year.
#'
#'
#' @param year A numeric or string giving the year for the filename
#'
#' @details If the provided \code{year} is not a integer, the value is truncated. If the provided \code{year} can't be converted to a numeric, a warning about N/A's is printed. 
#' 
#' @return This function returns a character vector with a year preceded by "accident_"
#' and followed by ".csv.bz2"
#'
#' @examples
#' make_filename(1984)
#' make_filename("1984")
#'
#' @export
make_filename <- function(year) {
        year <- as.integer(year)
        sprintf("accident_%d.csv.bz2", year)
}

#' Load data from accident files given a list of years
#'
#' This is a function that loads data from highway accident files with names in a specific format
#' and returns a data_tbl with the month and year of each accident.
#'
#' @param years A vector of strings or integers giving the years to retrieve
#' 
#' @details The highway accident files for the years given in \code{years} must be in the current working directory or an error is thrown.
#'
#' @return a list of data_tbl with columns named MONTH and year and a row for each accident.
#' 
#' @examples
#' \dontrun{
#' fars_read_years(c(1984,1986,1988))
#' fars_read_years(1984:1988)
#' fars_read_years(c("1984","1986","1988"))
#' }
#'
#' @importFrom dplyr mutate
#' @importFrom magrittr %>%
#'
#' @export
fars_read_years <- function(years) {
        lapply(years, function(year) {
                file <- make_filename(year)
                tryCatch({
                        dat <- fars_read(file)
                        dplyr::mutate(dat, year = year) %>% 
                                dplyr::select_(.dots = c('MONTH', 'year'))
                }, error = function(e) {
                        warning("invalid year: ", year)
                        return(NULL)
                })
        })
}
#' Load data from accident files and summarize by year and month
#'
#' This is a function that loads data for a list of years and summarizes the data
#' by year and month and returns the data in a tidy data format.
#' 
#' @param years A vector of strings or integers giving the years to retrieve
#'
#' @details If a accident file with standard naming convention is not in currect working, a "invalid year" warning is generated. 
#' 
#' @return a data_tbl with a row for each month of a year and a column with the number of accidents
#'
#' @examples
#' \dontrun{
#' fars_summarize_years(c(1999,2000,2001)) 
#' fars_summarize_years(c("1999","2000","2001")) 
#' }
#'
#' @importFrom dplyr group_by summarize n %>%
#' @importFrom tidyr spread
#'
#' @export
fars_summarize_years <- function(years) {
        dat_list <- fars_read_years(years)
        dplyr::bind_rows(dat_list) %>% 
                dplyr::group_by_(~ year, ~ MONTH) %>% 
                dplyr::summarize_(n = ~ n()) %>%
                tidyr::spread_(~ year,~ n)
}
#' Generate a graphical map of accident data for a U.S. state
#'
#' This is a function that creates a graphical map of highway accidents given a state number and year
#'
#' @param state.num a string or integer representing the position of a state in alphabetical order. One of the states in the R standard dataset state.names
#' @param year a string or integer representing the year for which to load highway accidents.
#'
#' @details  If a accident file with standard naming convention is not in currect working, a "invalid year" warning is generated. If state.num is not between 0 and 50, a "invalid STATE number" error is thrown. If a particular state had 0 accident records for a given year, a "invalid STATE number" error is thrown.
#'
#' @return a graphical map with points for individual highway accidents
#'
#'
#' @examples
#' \dontrun{
#' fars_map_state(1,1990)
#' fars_map_state("1","1990")
#' }
#' 
#' @importFrom dplyr filter 
#' @importFrom  maps map
#'
#' @export
fars_map_state <- function(state.num, year) {
        filename <- make_filename(year)
        data <- fars_read(filename)
        state.num <- as.integer(state.num)

        if(!(state.num %in% unique(data$STATE)))
                stop("invalid STATE number: ", state.num)
        data.sub <- dplyr::filter_(data, ~ STATE == state.num)
        if(nrow(data.sub) == 0L) {
                message("no accidents to plot")
                return(invisible(NULL))
        }
        is.na(data.sub$LONGITUD) <- data.sub$LONGITUD > 900
        is.na(data.sub$LATITUDE) <- data.sub$LATITUDE > 90
        with(data.sub, {
                maps::map("state", ylim = range(LATITUDE, na.rm = TRUE),
                          xlim = range(LONGITUD, na.rm = TRUE))
                graphics::points(LONGITUD, LATITUDE, pch = 46)
        })
}
