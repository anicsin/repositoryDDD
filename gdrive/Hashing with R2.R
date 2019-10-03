#Hashing for real time data deposition project#

#Packages needed for this:
#openssl, readxl, digest, xlsx

#1. loading the libraries

library(openssl)
library(readxl)
library(xlsx)
library(digest)

#2. Setting the working directory in the right place.

setwd("C:/Users/WIN10/Desktop/testfolder")

#3. constructing the for loop for the files

#get the name of all files
flz <- list.files("C:/Users/WIN10/Desktop/testfolder")
#get the ones that have xlsx extension
my_excel <- flz[grepl(".xlsx", flz)]
###1. first loop to load in every file
for (filenames in my_excel){
  #List with the sheet names
  sheetindex <- excel_sheets(filenames)
  #Load the excel into a workbook object
  wb <- loadWorkbook(filenames)
  #load the sheets into an object
  sheetlist <- getSheets(wb)
###2. loop to load in every sheet
  for (sheetname in sheetindex){
    #now we load in the excel sheet into a data frame
    df <- read_excel(filenames, sheet=sheetname)
  #get the list of variables that should be hashed. This function is going to load the indices of the matches into the variable.
    varnum <- grep("[Nname]", df)
###3. loop to hash every matching column
    for (varindex in varnum){
      #and now we hash each column with the given indices
      df[,varindex] <- sapply(df[,varindex], digest, algo="md5")
    }
    #Time to save the progress. Remove the old sheet and create a new one with the same name.
    removeSheet(wb, sheetName = sheetname)
    saveWorkbook(wb, filenames)
    sheet <- createSheet(wb, sheetName = sheetname)
    #We have to set the type of our data frame object, in order to be able to get rid of the row names.
    df <- as.data.frame(df)
    rownames(df) <- NULL
    #add the data frame to the new sheet and save the workbook
    addDataFrame(df, sheet, row.names = FALSE, byrow = FALSE)
    saveWorkbook(wb, filenames)
  }
}
