# Hashing module for Real-time data deposition #
In this segment you are going to see one possible way to make your local server hash the data files automatically before pushing them to GitHub. This will make your life easier if your data files contain personal information. Again, this guide is written assuming that you don't need any pre-existing knowledge, apart from our guide. This guide is only good for the hashing of excel files, but most probably we are going to expand it for other extensions later on.

For the hashing we are going to use R, which is a programming language for statistical computing. We have decided to use R, because it is relatively easy to use and learn, handles data really well and so far we haven't found any native Linux packages we could use.

## I. Installing R ##

First we have to install R package. You might still remember how we did this with Rclone and Git. For a detaliled guide, please visit (this)[https://www.digitalocean.com/community/tutorials/how-to-install-r-on-ubuntu-18-04] link.

```
root@DropletRTD:~# sudo apt update
[lot of texts from console]
root@DropletRTD:~# sudo apt install r-base
```

Some additional packages are necessary to make all of our R libraries working. This includes some java packages:

```
root@DropletRTD:~# sudo apt-get install libssl-dev
root@DropletRTD:~# sudo apt-get install -y default-jre
root@DropletRTD:~# sudo apt-get install -y default-jdk
```

Update where R expects to find various Java files:

```
sudo R CMD javareconf
```

Open R:

```
root@DropletRTD:~# R

R version 3.4.4 (2018-03-15) -- "Someone to Lean On"
Copyright (C) 2018 The R Foundation for Statistical Computing
Platform: x86_64-pc-linux-gnu (64-bit)

R is free software and comes with ABSOLUTELY NO WARRANTY.
You are welcome to redistribute it under certain conditions.
Type 'license()' or 'licence()' for distribution details.

R is a collaborative project with many contributors.
Type 'contributors()' for more information and
'citation()' on how to cite R or R packages in publications.

Type 'demo()' for some demos, 'help()' for on-line help, or
'help.start()' for an HTML browser interface to help.
Type 'q()' to quit R.

```

Similarly to Linux, R uses packages, called libraries. Instead of being something of executables, R libraries are collections of functions and data sets developed by the community. We are going to need 4 for the hashing module, so first let's install them. You can install individual packages with the install.package("package_name") command, but we can do this with more than one at a time:

```
>install.packages(c("rJava", "openssl", "readxl", "xlsx", "digest"))
```

This may take a couple of minutes, depending on your server. I won't go into details about why these particular packages have been chosen, but for a detailed description you should search for the documentations of the packages, like [this](https://cran.r-project.org/web/packages/xlsx/xlsx.pdf).

## II. Creating the R script file ##

We don't need to be in R anymore, so exit by typing "q()". We are going to make an executable R file for the hashing, so head back into the scripts folder:

```
root@DropletRTD:/srv# cd /srv/cron_script/
```

Create the script file and open with nano:

```
root@DropletRTD:/srv/cron_script# touch scripter.R
root@DropletRTD:/srv/cron_script# nano scripter.R
```

Text editor opens, paste the following here:

```
#!/usr/bin Rscript
library(openssl)
library(readxl)
library(xlsx)
library(digest)

setwd("/srv/test_git_folder/gdrive")
flz<-list.files("/srv/test_git_folder/gdrive")
my_excel<-flz[grepl(".xlsx", flz)]
for (filenames in my_excel){
	sheetindex<-excel_sheets(filenames)
	wb<-loadWorkbook(filenames)
	sheetlist<-getSheets(wb)
	for (sheetname in sheetindex){
		df<-read_excel(filenames, sheet=sheetname)
		varnum<-grep("[Nname]", df)
		for (varindex in varnum){
			df[,varindex]<-sapply(df[,varindex], digest, algo="md5")
			}
		removeSheet(wb, sheetName=sheetname)
		saveWorkbook(wb, filenames)
		sheet<-createSheet(wb, sheetName=sheetname)
		df<-as.data.frame(df)
		rownames(df)<-NULL
		addDataFrame(df, sheet, row.names=FALSE, byrow=FALSE)
		saveWorkbook(wb, filenames)
		}
}
```

Exit with ctrl+x, y and then enter. Let's break down the contents of this file. It's important to understand what's going on, so you can customize the code later on for your purposes.

```
#!/usr/bin Rscript
library(openssl)
library(readxl)
library(xlsx)
library(digest)
```

The first line of this segment is necessary to make the script ran as an executable code. The following four lines load the libraries we have just installed, propably you have already guessed this.

```
setwd("/srv/test_git_folder/gdrive/")
flz<-list.files("/srv/test_git_folder/gdrive/")
my_excel<-flz[grepl(".xlsx", flz)]
```
The first line sets the working directory to the pushing folder. This is important, so we don't have to do this later every time we want to load in something from directory. The next two lines make a list with all of the files in the folder, and then with the name of the excel files. It's important that the route in the parentheses lead to the pushing folder.

### For loops ###

The rest of the code consists of three for loops nested inside each other. These lines start with "for" and if you look inside the parentheses, there are mainly two important things: the first element is an index file, the last is a list. For loops repeat the content of the loop (things inside the brackets) for every element in the list. So index loads element number 1 from the list, the contents of the loop are executed, list loads element number 2 etc. Why is this important? In our case the index loads in the excel filenames from the list, so the loop executes everything in the brackets for every excel file.

So the first loop looks like this:
```
for (filenames in my_excel){
	sheetindex<-excel_sheets(filenames)
	wb<-loadWorkbook(filenames)
	sheetlist<-getSheets(wb)
```
The next loop is nested within with another loop nested inside. This level (call it first level) goes through every excel file in our list, loads in the file into the "wb" dataframe, loads the number of excel sheets into "sheetindex" and then loads the sheet names into sheetlist.
```
for (sheetname in sheetindex){
		df<-read_excel(filenames, sheet=sheetname)
		varnum<-grep("[Nname]", df)
```
The second level (which will be continuing after the third loop) goes through every sheet of the workbook (which were stored in sheetindex), loads in the sheet and then stores the indices for the columns that contain the expression we are looking for. Let's say we want to hash out every participant's name, then we should look for column names containing "name".

#### How to filter for expressions ####

It's important to understand that this way the code looks for EVERY column name which contains the matching expression. You should be as specific with the column names as you can, so you don't accidentaly hash any extra columns. Let's say, that we know that we have two columns, "Subject Name" and "Scale Name". If we leave the search field as above:

```
varnum<-grep("[Nname]", df)
```
we are going to lose the column under "Scale Name" as well. Either we should change the data dictionary for the study or make the search expression more specific, like
```
"[Subject Name]"
```

It is best to include multiple expressions in the code, so we don't have to use too vague keywords. You can add additional expressions by separating them with a vertical bar: "\[expression1|expression2]".

```
for (varindex in varnum){
			df[,varindex]<-sapply(df[,varindex], digest, algo="md5")
			}
```

The third level goes through every column which should be hashed (we have already loaded their indices into varnum in the second for loop) and hashes them. Notice that the contents of the loop are stretching from bracket to bracket.

```
		removeSheet(wb, sheetName=sheetname)
		saveWorkbook(wb, filenames)
		sheet<-createSheet(wb, sheetName=sheetname)
		df<-as.data.frame(df)
		rownames(df)<-NULL
		addDataFrame(df, sheet, row.names=FALSE, byrow=FALSE)
		saveWorkbook(wb, filenames)
```

This is the end of the second loop. This segment removes the old sheet and then makes a new one with the same name. After this, the data frame with the modified data is being loaded into the sheet, and the workbook (excel file) is saved.

Let's try out the hashing module, before we set up the automatic execution. Upload an excel file into your Google Drive folder. Make sure that at least one column name contains the matching expression. Make scripter.R executable:

```
root@DropletRTD:/srv/cron_script# chmod +x scripter.R
```

Now initiate Rscript to execute the contents of the file:

```
root@DropletRTD:/srv/cron_script# Rscript scripter.R
```

Probably you are going to be greeted with an error message like this:

```
WARNING: An illegal reflective access operation has occurred
WARNING: Illegal reflective access by org.apache.poi.util.SAXHelper (file:/usr/local/lib/R/site-library/xlsxjars/java/poi-ooxml-3.10.1-20140818.jar) to method com.sun.org.apache.xerces.internal.util.SecurityManager.setEntityExpansionLimit(int)
WARNING: Please consider reporting this to the maintainers of org.apache.poi.util.SAXHelper
WARNING: Use --illegal-access=warn to enable warnings of further illegal reflective access operations
```

Ignore this, check the excel file on GitHub (probably you'll have to download it). The contents of the "name" column should be hashed.

If nothing has happened and you didn't receive any error messages (apart from the one above), you should go through the scripter file, as usually this is the result of a typo. Makes sure that you didn't get any errors during the installation of the R libraries and got their names right.

## III. Setting up the automatic hashing process ##

If everything went well, one final thing remains is to make the hashing process automatic. To do this, we are going to use crontabs again. First, we have to make a shell script file, like before.

```
root@DropletRTD:/srv/cron_script# touch hasher.sh
root@DropletRTD:/srv/cron_script# nano hasher.sh
```

Text editor comes up, paste the following inside:

```
#!/bin/bash
cd /srv/cron_script
Rscript scripter.R
```

Exit with saving. Make the file executable:

```
root@DropletRTD:/srv/cron_script# chmod +x hasher.sh
```

Now open crontab:

```
root@DropletRTD:/srv/cron_script# crontab -e
```

Scroll down to the bottom of the page and paste the following between the two jobs we have entered before. If multiple jobs are scheduled in the same time, cron will run them sequentially, so it is important to paste the hashing in between.

```
*  *  *  *  *  /srv/cron_script/hasher.sh > /tmp/cron_job_hasher 2>&1
```

Wait a minute and check your GitHub (you'll have to download the excel file again). If the proper columns have been hashed, the module now works automatically (since the file in your Drive folder is unhashed).

-----------------------------------------------------

This is the end of the hashing module. Hopefully the excel file on your GitHub repository contains gibberish where it should. This part of the guide is still under development. It is entirely possible that a later version of this guide is going to leave R in favor of a better solution. Using R naturally leaves a lot of space for customizability, but ultimately we don't want to exclude those that don't know this language. We are still looking for a native hashing method in Linux, which we think would be the most ideal.

Thank you for using our guide. Again, please do write us if you have any suggestions for the guide.
