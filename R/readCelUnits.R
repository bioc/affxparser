#########################################################################/**
# @RdocFunction readCelUnits
#
# @title "Reads probe-level data ordered as units (probesets) from one or several Affymetrix CEL files"
#
# @synopsis 
# 
# \description{
#   @get "title" by using the unit and group definitions in the 
#   corresponding Affymetrix CDF file.
# }
# 
# \arguments{
#   \item{filenames}{The filenames of the CEL files.}
#   \item{units}{An @integer @vector of unit indices specifying which
#     units to be read.  If @NULL, all units are read.}
#   \item{...}{Arguments passed to low-level method 
#     @see "affxparser::readCel", e.g. \code{readXY} and \code{readStdvs}.}
#   \item{transforms}{A @list of exactly \code{length(filenames)}
#     @functions.  If @NULL, no transformation is performed.
#     Intensities read are passed through the corresponding transform
#     function before being returned.}
#   \item{cdf}{A @character filename of a CDF file, or a CDF @list
#     structure.  If @NULL, the CDF file is searched for by
#     @see "findCdf" first starting from the current directory and
#     then from the directory where the first CEL file is.}
#   \item{stratifyBy}{Argument passed to low-level method 
#     @see "affxparser::readCdfUnits".}
#   \item{addDimnames}{If @TRUE, dimension names are added to arrays,
#     otherwise not.  The size of the returned CEL structure in bytes 
#     increases by 30-40\% with dimension names.}
#   \item{readMap}{A @vector remapping cell indices to file indices.  
#     If @NULL, no mapping is used.}
#   \item{reorder}{If @TRUE, cell indices are read in order to speed up the
#     reading.  If @FALSE, cells are read in the order as given.  For
#     more details, see help on the same argument in @see "readCel".}
#   \item{dropArrayDim}{If @TRUE and only one array is read, the elements of
#     the group field do \emph{not} have an array dimension.}
#   \item{verbose}{Either a @logical, a @numeric, or a @see "R.utils::Verbose"
#     object specifying how much verbose/debug information is written to
#     standard output. If a Verbose object, how detailed the information is
#     is specified by the threshold level of the object. If a numeric, the
#     value is used to set the threshold of a new Verbose object. If @TRUE, 
#     the threshold is set to -1 (minimal). If @FALSE, no output is written
#     (and neither is the \pkg{R.utils} package required).
#   }
# }
# 
# \value{
#   A named @list with one element for each unit read.  The names
#   corresponds to the names of the units read.  
#   Each unit element is in
#   turn a @list structure with groups (aka blocks).  
#   Each group contains requested fields, e.g. \code{intensities}, 
#   \code{stdvs}, and \code{pixels}.
#   If more than one CEL file is read, an extra dimension is added
#   to each of the fields corresponding, which can be used to subset
#   by CEL file.
#
#   Note that neither CEL headers nor information about outliers and
#   masked cells are returned.  To access these, use @see "readCelHeader"
#   and @see "readCel".
# }
#
# @author
# 
# @examples "../incl/readCelUnits.Rex"
# 
# \seealso{
#   Internally, @see "readCelHeader", @see "readCdfUnits" and 
#   @see "readCel" are used.
# }
# 
# \references{
#   [1] Affymetrix Inc, Affymetrix GCOS 1.x compatible file formats,
#       June 14, 2005.
#       \url{http://www.affymetrix.com/support/developer/}
# }
#
# @keyword "file"
# @keyword "IO"
#*/######################################################################### 
readCelUnits <- function(filenames, units=NULL, ..., transforms=NULL, cdf=NULL, stratifyBy=c("nothing", "pmmm", "pm", "mm"), addDimnames=FALSE, readMap=NULL, dropArrayDim=TRUE, reorder=TRUE, verbose=FALSE) {
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
  # Validate arguments
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
  # Argument 'filenames':
  filenames <- file.path(dirname(filenames), basename(filenames));
  missing <- filenames[!file.exists(filenames)];
  if (length(missing)) {
    stop("File(s) not found: ", paste(missing, collapse=", "));
  }

  # Argument 'units' and 'cdf':
  if (is.list(cdf) && !is.null(units)) {
    stop("Arguments 'units' must not be specified if argument 'cdf' is a CDF list structure.");
  }

  # Argument 'units':
  if (is.null(units)) {
  } else if (is.numeric(units)) {
    units <- as.integer(units);
    # Unit indices are one-based in R
    if (any(units < 1))
      stop("Argument 'units' contains non-positive indices.");
  } else {
    stop("Argument 'units' must be numeric or NULL: ", class(units)[1]);
  }

  # Argument 'cdf':
  searchForCdf <- FALSE;
  if (is.null(cdf)) {
    searchForCdf <- TRUE;
  } else if (is.character(cdf)) {
    cdfFile <- file.path(dirname(cdf), basename(cdf));
    if (!file.exists(cdfFile))
      stop("File not found: ", cdfFile);
    cdf <- NULL;
  } else if (is.list(cdf)) {
    aUnit <- cdf[[1]];
    if (!is.list(aUnit))
      stop("Argument 'cdf' is of unknown format: First unit is not a list.");

    groups <- aUnit$groups;
    if (!is.list(groups))
      stop("Argument 'cdf' is of unknown format: Units Does not contain the list 'groups'.");

    # Check for group fields 'indices' or 'x' & 'y' in one of the groups.
    aGroup <- groups[[1]];

    fields <- names(aGroup);
    if ("indices" %in% fields) {
      cdfType <- "indices";
    } else if (all(c("x", "y") %in% fields)) {
      cdfType <- "x";
      searchForCdf <- TRUE;
    } else {
      stop("Argument 'cdf' is of unknown format: The groups contains neither the fields 'indices' nor ('x' and 'y').");
    }
    rm(aUnit, groups, aGroup);
  } else {
    stop("Argument 'cdf' must be a filename, a CDF list structure or NULL: ", mode(cdf));
  }

  # Argument 'readMap':
  if (!is.null(readMap)) {
    # Cannot check map indices without knowing the array.  Is it worth 
    # reading such details already here?
  }

  # Argument 'dropArrayDim':
  dropArrayDim <- as.logical(dropArrayDim);

  # Argument 'addDimnames':
  addDimnames <- as.logical(addDimnames);

  nbrOfArrays <- length(filenames);

  # Argument 'transforms':
  if (is.null(transforms)) {
    hasTransforms <- FALSE;
  } else if (is.list(transforms)) {
    if (length(transforms) != nbrOfArrays) {
      stop("Length of argument 'transforms' does not match the number of arrays: ", 
                                   length(transforms), " != ", nbrOfArrays);
    }
    for (transform in transforms) {
      if (!is.function(transform))
        stop("Argument 'transforms' must be a list of functions.");
    }
    hasTransforms <- TRUE;
  } else {
    stop("Argument 'transforms' must be a list of functions or NULL.");
  }

  # Argument 'stratifyBy':
  stratifyBy <- match.arg(stratifyBy);


  # Argument 'verbose': (Utilized the Verbose class in R.utils if available)
  if (!identical(verbose, FALSE)) {
    require(R.utils) || stop("Package not available: R.utils");
    verbose <- Arguments$getVerbose(verbose);
  }
  cVerbose <- -(as.numeric(verbose) + 2);


  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # 0. Search for CDF file?
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  if (searchForCdf) {
    verbose && enter(verbose, "Searching for CDF file");

    verbose && enter(verbose, "Reading chip type from first CEL file");
    celHeader <- readCelHeader(filenames[1]);
    chipType <- celHeader$chiptype;
    verbose && exit(verbose);

    verbose && enter(verbose, "Searching for chip type '", chipType, "'");
    cdfFile <- findCdf(chipType=chipType);
    if (length(cdfFile) == 0) {
      # If not found, try also where the first CEL file is
      opwd <- getwd();
      on.exit(setwd(opwd));
      setwd(dirname(filenames[1]));
      cdfFile <- findCdf(chipType=chipType);
      setwd(opwd);
    }
    verbose && exit(verbose);
    if (length(cdfFile) == 0)
      stop("No CDF file for chip type found: ", chipType);

    verbose && exit(verbose);
  }


  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # 1. Read cell indices for units of interest from the CDF file?
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  if (is.null(cdf)) {
    verbose && enter(verbose, "Reading cell indices from CDF file");
    cdf <- readCdfCellIndices(cdfFile, units=units, stratifyBy=stratifyBy, verbose=FALSE);
    verbose && exit(verbose);

    # Assume 'cdf' contains only "indices" fields.
    indices <- unlist(cdf, use.names=FALSE);
  } else {
    if (cdfType == "indices") {
      # Clean up CDF list structure from other fields than "indices".
      cdf <- applyCdfGroups(cdf, cdfGetFields, fields="indices");
      indices <- unlist(cdf, use.names=FALSE);
    } else {
      verbose && enter(verbose, "Calculating cell indices from (x,y) positions");
      verbose && enter(verbose, "Reading chip layout from CDF file");
      cdfHeader <- readCdfHeader(cdfFile);
      ncol <- cdfHeader$cols;
      verbose && exit(verbose);
      x <- unlist(applyCdfGroups(cdf, cdfGetFields, "x"), use.names=FALSE);
      y <- unlist(applyCdfGroups(cdf, cdfGetFields, "y"), use.names=FALSE);
      # Cell indices are one-based in R
      indices <- as.integer(y * ncol + x + 1);
      rm(x,y);
      verbose && exit(verbose);
    }
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # 2. Remapping cell indices?
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  if (!is.null(readMap)) {
    verbose && enter(verbose, "Remapping cell indices");
    indices <- readMap[indices];
    verbose && exit(verbose);
  }


  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # 2b. Order cell indices for optimal speed when reading, i.e. minimal
  #     jumping around in the file.
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  if (reorder) {
    verbose && enter(verbose, "Reordering cell indices to optimize speed");
    # About 10-15 times faster than using order()!
    o <- .Internal(qsort(indices, TRUE));
    indices <- o$x;
    o <- .Internal(qsort(o$ix, TRUE))$ix;
    verbose && exit(verbose);
  }


  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # 3. Read signals of the cells of interest from the CEL file(s)
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  # Comment: We assign elements of CEL list structure to local environment, 
  # because calling cel[[field]][idxs,] multiple (=nbrOfUnits) times is very
  # slow whereas get(field) is much faster (about 4-6 times actually!)
  # /HB 2006-03-24

  nbrOfCells <- length(indices);
  nbrOfUnits <- length(cdf);

  verbose && enter(verbose, "Reading ", nbrOfUnits, "*", nbrOfCells/nbrOfUnits, "=", nbrOfCells, " cells from ", nbrOfArrays, " CEL files");

  # Cell-value elements
  cellValueFields <- c("x", "y", "intensities", "stdvs", "pixels");
  integerFields <- "pixels";
  doubleFields <- setdiff(cellValueFields, integerFields);

  for (kk in seq(length=nbrOfArrays)) {
    filename <- filenames[kk];

    verbose && enter(verbose, "Reading CEL data for array #", kk);
    celTmp <- readCel(filename, indices=indices, readHeader=FALSE, readOutliers=FALSE, readMasked=FALSE, ..., readMap=NULL, reorder=FALSE, verbose=cVerbose, .checkArgs=FALSE);
    verbose && exit(verbose);

    if (kk == 1) {
      verbose && enter(verbose, "Allocating return structure");
      # Allocate the return list structure
#      celTmp$header <- NULL;
      celFields <- names(celTmp);

      # Update list of special fields
      cellValueFields <- intersect(celFields, cellValueFields);
      doubleFields <- intersect(cellValueFields, doubleFields);
      integerFields <- intersect(cellValueFields, integerFields);

      # Allocate all field variables
      dim <- c(nbrOfCells, nbrOfArrays);
      value <- vector("double", nbrOfCells*nbrOfArrays);
      dim(value) <- dim;
      for (name in doubleFields)
        assign(name, value);

      value <- vector("integer", nbrOfCells*nbrOfArrays);
      dim(value) <- dim;
      for (name in integerFields)
        assign(name, value);

      verbose && exit(verbose);
    }

    for (name in cellValueFields) {
      # Extract field values and re-order them again
      value <- celTmp[[name]];
      if (is.null(value))
        next;

      # "Re-reorder" cells read
      if (reorder)
        value <- value[o];

      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      # Transform signals?
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      if (hasTransforms && name == "intensities") {
        verbose && enter(verbose, "Transform signals for array #", kk);
        value <- transforms[[kk]](value);
        verbose && exit(verbose);
      }

      eval(substitute(name[,kk] <- value, list=list(name=as.name(name))));
    }

    rm(celTmp);
  }
  verbose && exit(verbose);

  rm(indices);


  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # 3. Structure CEL data in units and groups according to the CDF file
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  verbose && enter(verbose, "Structuring data by units and groups");

  fields <- vector("list", length(cellValueFields));
  names(fields) <- cellValueFields;

  # Add a dimension for the arrays, unless only one array is read
  # and the array dimension is not wanted.
  addArrayDim <- (nbrOfArrays >= 2 || !dropArrayDim);

  seqOfArrays <- list(1:nbrOfArrays);
  offset <- 0;
  res <- lapply(cdf, FUN=function(u) {
    lapply(u$groups, FUN=function(g) {
      # Same dimensions of all fields
      field <- .subset2(g, 1);  # Faster than g[[1]]
      ncells <- length(field);
      idxs <- offset + 1:ncells;
      offset <<- offset + ncells;

      # Get the target dimension
      dim <- dim(field);
      if (is.null(dim))
        dim <- ncells;

      if (addDimnames) {
        dimnames <- dimnames(field);
        if (is.null(dimnames))
          dimnames <- list(seq(length=dim));

        # Add an extra dimension for arrays?
        if (addArrayDim) {
          dim <- c(dim, nbrOfArrays);
          dimnames <- c(dimnames, seqOfArrays);
        }

        # Update all fields with dimensions
        setDim <- (length(dim) > 1);
        for (name in cellValueFields) {
          # Faster to drop dimensions.
          values <- get(name)[idxs,,drop=TRUE];
          if (setDim) {
            dim(values) <- dim;
            dimnames(values) <- dimnames;
          } else {
            names(values) <- dimnames;
          }
          fields[[name]] <- values;
        }
      } else {
       # Add an extra dimension for arrays?
        if (addArrayDim)
          dim <- c(dim, nbrOfArrays);

        # Update all fields with dimensions
        setDim <- (length(dim) > 1);
        for (name in cellValueFields) {
          # Faster to drop dimensions.
          values <- get(name)[idxs,,drop=TRUE];
          if (setDim)
            dim(values) <- dim;
          fields[[name]] <- values;
        }
      } # if (addDimnames)

      fields;
    });
  })

  verbose && exit(verbose);

  res;
}


############################################################################
# HISTORY:
# 2006-04-15 [HB]
# o BUG FIX: Passed '...' to both readCdfCellIndices() and readCel(), but
#   should only be passed to the latter.
# 2006-04-01 [HB]
# o Using readCdfCellIndices() instead of readCdfUnits().  Faster!
# o Added argument 'reorder'.  If TRUE, all cells are read in order to 
#   minimize the jumping around in the file.  This speeds things up a lot!
#   I tried this last week, but for some reason I did not see a difference.
# 2006-03-29 [HB]
# o Renamed argument 'map' to 'readMap'.
# 2006-03-28 [HB]
# o Unit and cell indices are now one-based.
# o Renamed argument 'readCells' to 'readIndices' and same with the name of
#   the returned group field.
# 2006-03-26 [HB]
# o Now only "x", "y", "intensities", "pixels", and "stdvs" values are
#   returned.
# 2006-03-24 [HB]
# o Made the creation of the final CEL structure according to the CDF much
#   faster.  Now it is about 4-6 times faster utilizing get(field) instead
#   of cel[[field]].
# o Tried to reorder cell indices in order to minimize jumping around in the
#   file, but there seems to be no speed up at all doing this. Strange!
# 2006-03-14
# o Updated code to make use of package R.utils only if it is available.
# 2006-03-08
# o Removed the usage of Arguments of R.utils.  This is because we might
#   move this function to the affxparser package.  Still to be removed is
#   the use of the Verbose class.
# 2006-03-04
# o Added argument 'map'.
# o Removed all gc(). They slow down quite a bit.
# 2006-02-27 [HB]
# o BUG FIX: It was only stratifyBy="pmmm" that worked if more than one
#   array was read.
# 2006-02-23 [HB]
# o The restructuring code is now more generic, e.g. it does not require
#   the 'stratifyBy' argument and can append multiple arrays of any 
#   dimensions.
# o Now the CDF file is search for where the CEL files lives too.
# 2006-02-22 [HB]
# o First test where argument 'cdf' is a CDF structure.  Fixed some bugs,
#   but it works now.
# o Simple redundancy test: The new code and the updated affxparser package
#   works with the new aroma.affymetrix/rsp/ GUI.
# o Now argument 'cdf' is checked to contain either 'cells' or 'x' & 'y'
#   group fields.  If 'x' and 'y', the cell indices are calculated from 
#   (x,y) and the chip layout obtained from the header of CDF file, which 
#   has been searched for.
# 2006-02-21 [HB]
# o TO DO: Re implement all of this in a C function to speed things up
#   further; it is better to put values in the right position from the
#   beginning.
# o Added arguments 'transforms' to be able to transform all probe signals
#   at once.  This improves the speed further.
# o Removed annotation of PM/MM dimension when 'stratifyBy="pmmm", because
#   the resulting object increases ~33% in size.
# o Improved speed for restructuring cell data about 20-25%.
# o Now it is possible to read multiple CEL files.
# o Making use of new 'readCells' in readCdfUnits(), which is much faster.
# o Replaced argument 'splitPmMm' with 'stratifyBy'.  This speeds up if 
#   reading PM (or MM) only.
# o BUG FIX: 'splitPmMm=TRUE' allocated PMs and MMs incorrectly.  The reason
#   was that the indices are already in the correct PM/MM order from the
#   splitPmMm in readCdfUnits() from which the (x,y) to cell indices are
#   calculated.
# o Updated to make use of the latest affxparser.
# 2006-01-24 [HB]
# o BUG FIX: Made some modifications a few days ago that introduced missing
#   variables etc.
# 2006-01-21 [HB]
# o Added Rdoc comments.
# 2006-01-16 [HB]
# o Created by HB.
############################################################################  