# So that the examples find the departamentos data
globalVariables("departamentos")

# From ggmap::theme_nothing()
theme_map <- theme(axis.text         = element_blank(),
                   axis.title        = element_blank(),
                   panel.background  = element_blank(),
                   panel.grid.major  = element_blank(),
                   panel.grid.minor  = element_blank(),
                   axis.ticks.length = grid::unit(0, "cm"),
                   panel.spacing     = grid::unit(0, "lines"),
                   plot.margin       = grid::unit(c(0, 0, 0, 0), "lines"),
                   complete          = TRUE)

# Define color scales
color_scale <- function(data){
  UseMethod("color_scale")
}

# Default - will work as a factor
color_scale.default <- function(data){
  color_scale(as.factor(data))
}

color_scale.factor <- function(data){
  n <- nlevels(data)
  if (n < 10){
    scale_fill_brewer(type = "qual", palette = "Set1", na.value = "grey50")
  } else {
    scale_fill_manual(values = grDevices::rainbow(n = n, v = 0.3 * sin(seq_len(n)) + 0.7),
                      na.value = "grey50")
  }
}

# For numeric variables
color_scale.numeric <- function(data){
  scale_fill_continuous(low = "#fee8c8", high = "#b30000")
}

# For ordered factors (ordered categorical variables)
color_scale.ordered <- function(data){
  n <- nlevels(data)
  scale_fill_manual(values = grDevices::colorRampPalette(c("#fee8c8", "#b30000"))(n),
                    na.value = "grey50")
}

# For integer values
color_scale.integer <- function(data){
  n <- length(unique(data))
  if (n < 20) color_scale(as.ordered(data)) else color_scale(as.numeric(data))
}

# autocomplete

autocomp <- function(data, map_id, data_id, var){

  data_id_coumn <- data[[data_id]]
  data.frame(
    map_id[which(!map_id %in% data_id_coumn)],
    NA
  ) -> na_data_frame

  stats::setNames(object = na_data_frame, c(data_id, var)) -> na_data_frame
  rbind(data[c(data_id, var)], na_data_frame)
}


#' Colmap
#'
#' colmap - for colombian map (or in general color map) - is a wrapper of
#' ggplot and its geom_map so that its easy to make a quick choropleth map. You
#' can get further control with ggplot.
#'
#' @param map a \code{\link{fortify}}able object sucha as a
#' \code{\linkS4class{SpatialPolygonsDataFrame}} resulting in a
#' data.frame with columns \code{x} or \code{long}, \code{y} or \code{lat} and
#' \code{region} or \code{id}.
#'
#' @param data a data.frame that contains an id variable to match the map
#' regions and the variable to plot over the map. By default no data is needed
#' in which case only the map is represented coloring the regions with ggplot's
#' default pallete.
#'
#' @param var character, the name of the variable in data to be represented in
#' the map. By default it will take the first non id variable.
#'
#' @param map_id character, name of the map id variable. By default \code{"id"}
#' which is how the region id is set on the spatial objects through
#' \code{fortify}.
#'
#' @param data_id character, name of the data variable to match the map
#' id.
#'
#' @param legend logical, include legend (color guide) in the plot? No legend
#' is included if only the map is ploted.
#'
#' @param autocomplete logical, if there are any map regions without
#' corresponding data values and autocomplete is true then the data will be
#' auto-completed with missing values to plot all the regions instead of having
#' void portions in the map.
#'
#' @return a ggplot object.
#'
#' @examples
#' colmap() # Plot default map: Colombia departments.
#'
#' @export
colmap <- function(map = departamentos, data = NULL, var = NULL, map_id = "id",
                   data_id = map_id, legend = TRUE, autocomplete = FALSE){

  map_df <- suppressMessages(fortify(map))
  data <- as.data.frame(data)

  if (dim(data)[2] < 2){
    data <- if (methods::is(map, "SpatialPolygonsDataFrame")){
              sapply(methods::slot(map, "polygons"), methods::slot, "ID")
            } else{
              unique(map_df[, map_id, drop = TRUE])
            }
    data <- data.frame(stats::setNames(list(data), map_id),
                       stringsAsFactors = FALSE)
    var <- map_id
    legend <- FALSE
  } else if (is.null(var)){
    var <- setdiff(names(data), data_id)[[1]]
  } else if (!var %in% names(data)){
    stop(var, " not found in data.")
  }

  if (!data_id %in% names(data))
    stop(data_id, " not found in data.")

  if(autocomplete && any(!map[[map_id]] %in% data[[data_id]])){
    data <- autocomp(data, map[[map_id]], data_id, var)
  }

  gg <- ggplot(data, aes_string(map_id = data_id)) +
    geom_map(aes_string(fill = var), map = map_df, color = "white",
             size = 0.1) +
    expand_limits(x = map_df$long, y = map_df$lat) +
    coord_quickmap() +
    theme_map +
    color_scale(data[[var]])

  if (legend) gg else gg + theme(legend.position = "none")
}
