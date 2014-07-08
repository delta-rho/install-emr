
buildingR <- function(excludeLibs=c(),exclude=NULL,iterate=TRUE,verbose=1,nameof="Rfolder-test",destpath=sprintf("/user/%s/",USER)){
  library(Rhipe)
  rhinit()
  local({
    tfolder <- sprintf("%s/Rdist",tempdir())
    ## delete folder if it exists!
    dir.create(tfolder)
    execu <- if ("package:Rhipe" %in% search()) rhoptions()$RhipeMapReduce else sprintf("/home/%s/software/R_LIBS/Rhipe/bin/RhipeMapReduce",USER)
    ## execu <- if ("package:Rhipe" %in% search()) rhoptions()$Rhipe else sprintf("/home/%s/software/R_LIBS/Rhipe/libs/Rhipe.so",USER)
    getLB <- function(n){
        a <- system(sprintf("ldd  %s",n),intern=TRUE)
        b <- lapply(strsplit(a,"=>"), function(r) if (length(r)>=2) r[2] else NULL)
        b <- b[unlist(lapply(b, function(bs){!grepl("(not found)",bs)}))]
        if(length(b)==0) return()
        b <- strsplit(unlist(b)," ")
        b <- unlist(lapply(b,"[[",2))
        b <- unique(unlist( sapply(b, function(r) if(nchar(r)>1) r else NULL)))
        names(b) <- NULL
        if(verbose>=1){
            cat(sprintf("\n%s depends on:\n",n))
            cat(paste(b,sep=":",collapse=" "))
            cat(sprintf("\n---------------\n"))
            if(verbose>10) print(a)
        }
      b
    }
    b <- getLB(execu)
    ## b <- unique(b[!grepl("(libc.so)",b)])
    for(x in b) {
      cat(sprintf("Copying %s to %s\n",x,tfolder))
      file.copy(x,tfolder) ##copies the linked .so files
    }
    file.copy(execu,tfolder,overwrite=TRUE)  ## copies the RHIPE C engine
    file.copy(R.home(),tfolder,recursive=TRUE)
    ## R_LIBS
    x <- .libPaths() ##Sys.getenv("R_LIBS")
    if(TRUE){
      for(y in list.files(x,full.names=TRUE)){
        if(all( sapply(excludeLibs,function(h) !grepl(h,y))))
          file.copy(y,sprintf("%s/R/library/",tfolder), recursive=TRUE)
      }
      allfiles <- list.files(x,full.names=TRUE,rec=TRUE)
      allsofiles <- allfiles[grepl(".so$",allfiles)]
      alldeps <- sort(unique(unlist(sapply(allsofiles, getLB))))
      id <- 1
      if(iterate){
        while(TRUE){
          message(sprintf("iteration %s", id))
          alldeps2 <- sort(unique(unlist(sapply(alldeps, getLB))))
          newones <- sum(!(alldeps2 %in% alldeps))
          if(newones>0){
            message(sprintf("There were %s additions(total=%s), iterating till this becomes zero", length(newones), length(alldeps2)))
            id=id+1
            alldeps=alldeps2
          }else  break
        }
      }
      if(!is.null(exclude)) alldeps <- alldeps[!grepl(exclude,alldeps)]
      for(x in alldeps) {
        cat(sprintf("Copying %s to %s\n",x,tfolder))
        file.copy(x,tfolder) ##copies the linked .so files
      }
    }
  })
  cat(sprintf("Building a gzipped tar archive at %s/%s.tar.gz\n",tempdir(),nameof))
  system (sprintf("tar z --create --file=%s/%s.tar.gz -C %s/Rdist .",tempdir(),nameof, tempdir()))
  cat(sprintf("Copying gzipped tar archive to HDFS (see %s) in user folder\n",sprintf("%s.tar.gz",nameof)))
  if ("package:Rhipe" %in% search()) rhput(sprintf("%s/%s.tar.gz",tempdir(),nameof),destpath)
}



Sys.setenv("RHIPE_DEBUG_LEVEL"=2L)
library(Rhipe)
rhinit()
options(width=200)
if(!any(grepl("Remr", rhls("/")$file)))
    buildingR(nameof="Remr", dest="/",verbose=100)
RDIST <- "Remr"
m <- rhoptions()$mropts
m$R_ENABLE_JIT        = 2
m$R_HOME              = sprintf("%s/R",RDIST)
m$R_HOME_DIR          = sprintf("./%s/R",RDIST)
m$R_SHARE_DIR         = sprintf("./%s/R/share",RDIST)
m$R_INCLUDE_DIR       = sprintf("./%s/R/include",RDIST)
m$R_DOC_DIR           = sprintf("./%s/R/doc",RDIST)
m$PATH                = sprintf("./%s/R/bin:./%s/:$PATH",RDIST,RDIST)
m$LD_LIBRARY_PATH     = sprintf("./%s/:./%s/R/lib:/usr/lib64",RDIST,RDIST)

rhoptions(runner            = sprintf("./%s/RhipeMapReduce --silent --vanilla",RDIST),
          zips              = sprintf("/%s.tar.gz",RDIST),
          HADOOP.TMP.FOLDER = sprintf("/tmp/"),
          mropts            = m,
          job.status.overprint =TRUE,
          write.job.info    =TRUE)
rm(m);
summer <- Rhipe::rhoptions()$templates$scalarsummer

## I forgot to install R packages in the bootup script and so either i
## shut it all down or start R like this ...  i.e. install packages on
## main node and create an R bundle as shown above
x <- rhwatch(map=function(a,b){
    library(rjson)
    suppressPackageStartupMessages(library(data.table))
    rhcollect(1, data.table(x=runif(10)))
}, reduce=0, input=c(10,10))
