
# Contributing to the 'affxparser' package

This Git repository uses the [Git Flow](https://nvie.com/posts/a-successful-git-branching-model/) branching model (the [`git flow`](https://github.com/petervanderdoes/gitflow-avh) extension is useful for this).  The [`develop`](https://github.com/HenrikBengtsson/affxparser/tree/develop) branch contains the latest contributions and other code that will appear in the next release, and the [`master`](https://github.com/HenrikBengtsson/affxparser) branch contains the code of the latest release, which is exactly what is currently on [Bioconductor](https://www.bioconductor.org/packages/devel/bioc/html/affxparser.html).

Contributing to this package is easy.  Just send a [pull request](https://help.github.com/articles/using-pull-requests/).  When you send your PR, make sure `develop` is the destination branch on the [affxparser repository](https://github.com/HenrikBengtsson/affxparser).  Your PR should pass `R CMD check --as-cran`, which will also be checked by  <a href="https://github.com/HenrikBengtsson/affxparser/actions?query=workflow%3AR-CMD-check">GitHub Actions</a> and <a href="https://ci.appveyor.com/project/HenrikBengtsson/affxparser">AppVeyor CI</a> when the PR is submitted.

We abide to the [Code of Conduct](https://www.contributor-covenant.org/version/2/0/code_of_conduct/) of Contributor Covenant.
