systemR <- function(command="", ..., verbose=FALSE) {
  # Locate the R executable
  Rbin <- file.path(R.home("bin"), "R")
  cmd <- sprintf('%s %s', shQuote(Rbin), command)
  if (verbose) cat("Command: ", cmd, "\n", sep="")
  system(cmd, ...)
} # systemR()


## Explicitly append 'affxparser' to library path
## Needed for covr::coverage()
pd <- packageDescription("affxparser")
libpath <- dirname(dirname(dirname(attr(pd, "file"))))
cmd <- sprintf(' -e ".libPaths(\'%s\'); affxparser:::.testWriteAndReadEmptyCel()"', libpath)
out <- systemR(cmd, intern=TRUE, wait=TRUE, verbose=TRUE)
cat(out, sep="\n")
res <- any(regexpr("COMPLETE", out) != -1)
cat("Test result: ", res, "\n", sep="")
if (!res) {
  stop("affxparser:::.testWriteAndReadEmptyCel() failed.")
}

############################################################################
# HISTORY:
# 2012-09-26
# o Created from tests/testWriteAndReadEmptyCdf.R.
############################################################################
