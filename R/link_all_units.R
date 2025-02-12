#' create a set of directories to run disperseR
#'
#' \code{link_all_units}
#'
#' @description with `link_all_units()` users can link all air parcels to relevant spatial scales by month for specified units with combinations of years and months. `link_all_units()` reads in all the relevant HYSPLIT files (i.e., those that correspond to the provided units) produced by the `run_disperser_parallel()` function and saves them. Then it links them to relevant spatial scales.
#'
#'
#'
#' @param units.run information on unit locations as output from disperseR::units()
#'
#' @param start.date this argument is not necessary, but can be used if the user is interested in specifying a specific date to start the analysis with as opposed to using months. For example `start.date="2005-01-02"` for 2 January 2005. This argument are set to `NULL` by default and the function computes the start and the end dates using the `year.mons` provided.
#'
#' @param start.end this argument is not necessary, but can be used if the user is interested in specifying a specific date to end the analysis with as opposed to using months. For example `start.date="2005-01-02"` for 2 January 2005.This argument are set to `NULL` by default and the function computes the start and the end dates using the `year.mons` provided.
#'
#' @param exp.hour `exp.hour = 1` by default which means start calculating the exposure after 1 hour, exp.hour can be defined starting from 0h 
#'
#' @param by.time this argument is not necessary, but can be used if the user is interested in specifying a time scale other than month for aggregating ("day" is currently the only option besides NULL)
#'
#' @param link.to one of 'zips', 'counties', or 'grids' to denote spatial linkage scale. zips and counties are only for the USA
#'
#' @param year.mons these are the months for which we would like to do the linking. You can use the get_yearmon() function to create a vector that can be an input here.
#'
#' @param pbl.trim logical. Trim parcel locations under monthly PBL heights and take concentration under PBL layer?
#'
#' @param pbl.height monthly boundary layer heights. required if pbl_trim = TRUE
#'
#' @param crosswalk. `crosswalk. = crosswalk` by default but you can change it. See the vignette
#'
#' @param mc.cores `link_all_units()` enables the parallel run by default splitting different months on different cores, but you can make it serial just by setting the `mc.cores` argument to `1`.As mentioned before  `link_all_units()` enables the parallel run by default splitting different months on different cores, but you can make it serial just by setting the `mc.cores` argument to `1`.
#'
#' @param duration.run.hours `duration.run.hours = 240` by default which equals 10 days. 10 days is the maximum (approximately) that sulfur stays in the atmosphere before it deposits to the ground.
#'
#' @param overwrite `overwrite = FALSE` by default. Would you like to overwrite files that already exist?
#'
#' @param res.link Defines the grid resolution (in meters---defaults to 12000m = 12km) for linking. This is important for all link.to values, since parcel locations are first put on this grid before spatially allocating to other spatial domains.
#'
#' @param crop.usa Logical. For grid links, crop the output to only over the lower 48 US states? Ignored for county and ZIP code links.
#'
#' @param crop.usa Logical. For grid links, crop the output to only over the lower 48 US states? Ignored for county and ZIP code links.
#'
#' @return vector of months that you can loop over


#' @export link_all_units


link_all_units<- function(units.run,
                          link.to = 'zips',
                          mc.cores = detectCores(),
                          year.mons = NULL,
                          start.date = NULL,
                          end.date = NULL,
                          exp.hour = 1, 
                          by.time = "month",
                          pbl.trim = TRUE,
                          pbl.height = NULL,
                          crosswalk. = NULL,
                          counties. = NULL,
                          duration.run.hours = 240,
                          res.link = 12000,
                          overwrite = FALSE,
                          crop.usa = FALSE,
                          return.linked.data = TRUE) {

  if ((is.null(start.date) |
       is.null(end.date)) & is.null(year.mons)) {
    stop("Define either a start.date and an end.date OR a year.mons")
  }
  if ( length( link.to) != 1 | !(link.to %in% c( 'zips', 'counties', 'grids')) )
    stop( "link.to should be one of 'zips', 'counties', 'or 'grids'")
  if (link.to == 'zips' & is.null(crosswalk.))
    stop( "crosswalk. must be provided if link.to == 'zips'")
  if (link.to == 'counties' & is.null(counties.))
    stop( "counties. must be provided if link.to == 'counties'")
  if( pbl.trim & is.null( pbl.height))
    stop( "pbl.height must be provided if pbl_trim == TRUE")
  if ((is.null(exp.hour)))
    stop("please define a value for starting exposure hour")
  if (exp.hour < 0){
    stop("Please define a value bigger than 0 for starting exposure hour")
  }else{
    exp.hour = as.numeric(exp.hour)
  }

  # define start and end dates as a list
  if (is.null(start.date) | is.null(end.date)) {
    start.date <-
      as.Date(paste(
        substr(year.mons, 1, 4),
        substr(year.mons, 5, 6),
        '01',
        sep = '-'
      ))#length=12
    end.date <-
      as.Date(
        sapply(
          start.date,
          function( d) seq( d,#create a sequence of variables
                            by = paste (1, 'month'),#by = '1 month'
                            # by = paste (1, by.time),#by = '1 day'
                            length.out = 2)[2] - 1#['2007-01-01','2007-02-01']
        ),#e.g.,"2007-01-31"
        origin = '1970-01-01')
    if(by.time == 'day'){
      headdate = start.date[1]
      taildate = tail(end.date,n=1)
      start.date = seq(from=headdate,to=taildate-1,by='day')
      end.date = seq(from=headdate+1,to=taildate,by='day')
    }
    else if(by.time == 'week'){
      headdate = start.date[1]
      taildate = tail(end.date,n=1)
      start.date = seq(from=headdate,to=taildate-1,by='week')
      end.date = seq(from=headdate+6,to=taildate,by='week')
    }
    
  }

  # create list of dates to link
  link_dates <- lapply( seq_along( start.date),#[1,2,...,12]
                        function (n)
                          list( start.date = start.date[n],
                                end.date = end.date[n]))
  #link_dates[[1]]==[start.date='2007-01-01',end.date='2007-01-31']

  # run the link functions
  zips_link_parallel <- function(u) {
    linked_zips <- parallel::mclapply(
      link_dates,
      disperser_link_zips, #disperseR::
      unit = u,
      pbl.height = pbl.height,
      crosswalk. = crosswalk.,
      exp.hour = exp.hour,
      duration.run.hours = duration.run.hours,
      overwrite = overwrite,
      res.link. = res.link,
      mc.cores = mc.cores,
      pbl. = pbl.trim,
      return.linked.data. = return.linked.data
    )
    linked_zips <- data.table::rbindlist(Filter(is.data.table, linked_zips))
    message(paste("processed unit", u$ID, ""))
    
    if( nrow( linked_zips) > 0)
      linked_zips[, month := as( month, 'character')]
    return(linked_zips)
  }

  counties_link_parallel <- function(u) {
    linked_counties <- parallel::mclapply(
      link_dates,
      disperseR::disperser_link_counties,
      unit = u,
      pbl.height = pbl.height,
      counties = counties.,
      exp.hour = exp.hour,
      duration.run.hours = duration.run.hours,
      overwrite = overwrite,
      res.link. = res.link,
      mc.cores = mc.cores,
      pbl. = pbl.trim,
      return.linked.data. = return.linked.data
    )

    linked_counties <- data.table::rbindlist(Filter(is.data.table, linked_counties))
    message(paste("processed unit", u$ID, ""))

    if( nrow( linked_counties) > 0)
      linked_counties[, month := as( month, 'character')]
    return(linked_counties)
  }

  grids_link_parallel <- function(u) {
    linked_grids <- parallel::mclapply(
      link_dates,
      disperseR::disperser_link_grids,
      unit = u,
      pbl.height = pbl.height,
      exp.hour = exp.hour,
      duration.run.hours = duration.run.hours,
      overwrite = overwrite,
      res.link. = res.link,
      mc.cores = mc.cores,
      pbl. = pbl.trim,
      crop.usa = crop.usa,
      return.linked.data. = return.linked.data
    )
    linked_grids <- data.table::rbindlist(Filter(is.data.table, linked_grids))
    message(paste("processed unit", u$ID, ""))

    if( nrow( linked_grids) > 0)
      linked_grids[, month := as( month, 'character')]
    return(linked_grids)
  }

  units.run <- unique( units.run[, .( uID, ID)])

  if( link.to == 'zips')
    out <- units.run[, zips_link_parallel(.SD), by = seq_len(nrow(units.run))]
  if( link.to == 'counties')
    out <- units.run[, counties_link_parallel(.SD), by = seq_len(nrow(units.run))]
  if( link.to == 'grids')
    out <- units.run[, grids_link_parallel(.SD), by = seq_len(nrow(units.run))]

  out[, comb := paste("month: ", out[, month], " unitID :", out[, ID], sep = "")]
  out[, seq_len := NULL]
  return(out)
}
