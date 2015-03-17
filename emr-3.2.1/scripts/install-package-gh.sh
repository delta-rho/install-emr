#!/bin/bash

sudo -E R -e "options(unzip = 'unzip', repos = 'http://cran.rstudio.com/'); library(devtools); install_github('$1')"
