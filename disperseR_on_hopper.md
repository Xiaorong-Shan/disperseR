# Installation for disperseR on hopper
First load the modules for the required dependencies

```
module load  r/4.0.3-hx libxml2/2.9.10-ej doxygen/1.8.20-g6 proj/7.1.0-7x netcdf-cxx4/4.3.1 libjpeg/9d-re gdal/3.2.2-ai geos/3.7.2-2a udunits/2.2.28-mc libiconv/1.16-y3 pcre/8.44-hy libgeotiff/1.6.0-sx libpng/1.6.37-3x curl/7.74.0-4t ffmpeg/4.2.2-ey
```

Next enter R and install with following command

```
devtools::install_github("Xiaorong-Shan/disperseR@dev-sherry", args = c('--library="~/R"'), force = TRUE, build_vignettes = FALSE)
```

# Run disperseR on hopper 
Get into the directory where you installed it

```
cd HAQ_LAB/xshan2/disperseR_sherry/
```

Start a task on hopper

```
srun -p normal --mem 30g -t 0-04:00 -c 1 -N 1 --pty /bin/bash
```

Load necessary modules

```
module load gnu10/10.3.0
module load openmpi
module load netcdf-c netcdf-fortran parallel-netcdf
module load r/4.1.2-dx
```

Enter R to go into R studio, and then set up disperseR running directory

```
library(disperseR)
disperseR::create_dirs('/projects/HAQ_LAB/xshan2/disperseR_sherry')
proc_dir <- '/scratch/xshan2/disperseR_sherry/main/process'
```

Run the code and find disperseR results in correspend directory

# Run Linux version disperseR on hopper
There is a disperseR version which has already been installed on hopper, to run it, you should:
Export the libraries you've download on hopper

```
export R_LIBS_USER=~/R/empty
export R_LIBS_USER=~/R/local-disperseR-packages
```

Load the necessary modules

```
module load gnu9
module load r-disperseR/0.1.0
```

Type R to go into R studio, and then set up directory for disperseR

```
library(disperseR)
disperseR::create_dirs('/projects/HAQ_LAB/xshan2/disperseR_Linux')
proc_dir <- '/scratch/xshan2/disperseR_Linux/main/process'
```

If we need to install new library for R studio, type the install.packages() command in terminal.
For example, to install package "USAboundaries", type

```
install.packages("USAboundaries", repos = "http://packages.ropensci.org", type = "source")
library(USAboundaries)
```
