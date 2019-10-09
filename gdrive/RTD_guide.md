# Guide to set up Direct Data Deposition from Google Drive to GitHub #
This guide will help you to make your own server which runs on Linux and automatically synchronizes data from Google Drive to GitHub repository. If you won't encounter any errors, the procedure should take about 2-3 hours. The guide consist of 3 parts: creating a Linux server, synchronizing with a Google Drive folder and finally setting up an auto-sync between GitHub and Drive through the server. To complete the guide you are going to need a [GitHub](https://github.com/) and a Google account.

The guide is written up in a way that no prior expertise is needed with Linux or using remote servers. For the more experienced users a large portion of the explanations are going to be familiar.

If you are stuck and cannot solve the problem with our guide, check the Troubleshooting section at the end of this document before trying to search the web for an answer.


## Authors
Zoltan Kekecs - ELTE and Lund University

Pietro Rizzo - Lund University

Endre Csikós - ELTE

## Correspondance
Contact Zoltan Kekecs via kekecs.zoltan@gmail.com

## I. Setting up a remote server with Ubuntu Linux ##
This guide is written presuming that you will use a DigitalOcen Droplet with Ubuntu Linux running on the server. Most of this guide should work on other types of servers as well, as long as the server runs Ubuntu Linux, but we only tested the guide so far with DigitalOcen Droplet. You can get a free 60 day trial by clicking on the following referral code. Disclosure: if you spend 25 USD after setting up your server using this link, Zoltan Kekecs (one of the authors of the guide) would get a one time 25 USD credit on his DigitalOcean account. https://m.do.co/c/9f9d58f02cb0 (Or, if you don’t want to use our referral link for some reason, you can use the following link for the same free trial: https://try.digitalocean.com/performance/)

After confirming your email address, proceed and finalize the registration. You'll have to provide some billing information, including credit card number. Assuming you've followed our referral link, the first two months are going to be free of charge. You can deactivate your account at any time.
Be aware that prepaid and probably some other types of cards are not accepted. Also you should make sure that your billing info has been accepted. I suggest double-checking it in the Billing section, under "Account".

### Setting up the droplet ###

For a more detailed and visual guide [this](https://www.digitalocean.com/docs/droplets/how-to/create/) link, otherwise:

1. On your DigitalOcean page, select the green "Create" button in the top right and choose "Droplets". We are going to specify what kind of droplet are we going to use.
2. "Choose an Image" -> Ubuntu 16.04.6 x64. (The version number will probably be higher by the time you read this guide) Updates happen.
3. "Plan option" -> **Standard**. $5/month, $0.007/hour, 1 GB/1 CPU, 25 GB SSD disk, 1000 GB transfer
4. Bakcups are not necessary.
5. Block storage is not necessary.
6. "Choose a datacenter region": Whatever works best for you. Consider distance (affecting the data transfer speed) and ethical/legal issues related to sensible data storage (servers located in certain countries might be okay or not depending on your country/university/journal policy on the matter).
7. "Select additional options": Nothing esle is required for the guide to work.
8. "Add your SSH keys": You can ignore this step.
9. "How many droplets"? One is enough.
10. "Choose a hostname". Choose a host name that you will remember later.


Write down some basic information for your own future reference. Your username and password will also be mailed to you. You will need the following information later:

```
	Droplet Name: 
	IP Address: 
	Username: 
	Password: 
```
Your Droplet is up and running. Working around in the droplet console window is anything but comfortable, so first we're going to install Putty, a terminal emulator.

#### Putty ####

Working around in the console is not an easy thing, especially when you have to copy and paste several lines of text. You may have noticed before that things are kind of lumpish, so we have to upgrade our toolkit a little bit. In PuTTY you can do the same things you would do in the Droplet console, but in a bigger, better, uncut version.

To install PuTTY, head over to [PUTTY webpage](https://www.putty.org) and download the 64 bit version.

1. After the installation, go to your droplet's page on the DigitalOcean website (on the left side select Droplets and then click on your droplet). Find ipv4 - the adress of your droplet - and copy it.
2. Open Putty and select "Session". Paste the adress in the "Host Name" line. 
3. Name your session in the "Saved Sessions" line  (It doesn't really matter what name you put here, but it helps if its a name you will recognize later as your direct data deposition server)
4. hit "save"
5. Now select the saved session and open it
6. Reply "yes" to Security Alert.

Your Droplet is going to ask for your credentials every time you open the session in Putty. If you haven't written these down before, DigitalOcean has also mailed them to you. For those that are unfamiliar with Linux: asterisks won't appear as you're entering your password. This is just a security measure, enter the password and hit enter.

##### General Putty advice #####

ctrl+c and ctrl+v does not work in the console. However, when using PuTTY, you can copy and paste things using other hotkeys:

You can **copy text** from the console by selecting it with your mouse, move your cursor to the very end of selection (not before, not after! Exactly where the highlighted portion of text ends) and press the middle mouse button. This will copy the selected text onto your computer clipboard when using Windows. You can also do this with the ctrl+instert buttons (for smaller notebooks I highly recommend the usage of a mouse, probably you don't even have insert).

In order to **paste text** from your clipboard into the PuTTY console, press the right mouse button of your mouse.

### Rclone installation ###

Update the list of packages using the "apt update" command:
Important disclaimer: lines beginning with User are the lines we enter and those beginning with Console are the answers of the system. "root@[Droplet_Name]" is just there for illustration, to help you follow the process (you don't actually have to enter this part of the line, just the code after).

```
User:	root@[Droplet_Name]:~# apt update
```
Now we are going to install two packages. The first is Unzip, it's name is quite self-explanatory. Afterwards we are going to use it to install Rclone, which is a package used to transfer files to and from spaces like Google Drive and DigitalOcean droplets - this package is a major motor in the project. We are going to scoop the package installer from the Rclone website using the curl command.
Use the "apt install" command below to install Unzip:
```
User:	root@[Droplet_Name]:~# apt install unzip
```
Now we can use the "curl" command to download the Rclone installer (the -O option saves the file with the name in the URL).
```
User:	root@[Droplet_Name]:~# curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip
```
Now use Unzip to unpack the installer:
```
User:	root@[Droplet_Name]:~# unzip rclone-current-linux-amd64.zip
```
Head into the folder in which Rclone has been downloaded, use the "cd" command (change directory):
```
User:	root@[Droplet_Name]:~# cd rclone-*-linux-amd64
```
Copy the Rclone binary file using the "cp" command:
```
User:	root@[Droplet_Name]:~/rclone-v1.47.0-linux-amd64#  cp rclone /usr/bin/
```
For Rclone to work properly, we have to make it executable:
```
User:	root@[Droplet_Name]:~/rclone-v1.47.0-linux-amd64#  chown root:root /usr/bin/rclone
User:	root@[Droplet_Name]:~/rclone-v1.47.0-linux-amd64#  chmod 755 /usr/bin/rclone
```
We've changed the ownership to "root" with "chown", then used the "chmod" to give permissions. Finally, install the Rclone manual pages using the commands below (mkdir creates new directories, we can make more than one at the same time with the -p option):
```
User:	root@[Droplet_Name]:~/rclone-v1.47.0-linux-amd64#  mkdir -p /usr/local/share/man/man1
User:	root@[Droplet_Name]:~/rclone-v1.47.0-linux-amd64#  cp rclone.1 /usr/local/share/man/man1/
User:	root@[Droplet_Name]:~/rclone-v1.47.0-linux-amd64#  mandb
```

## II. Setting up the Google Drive Sync ##

### Pulling from Drive ###

In this section we are going to use Rclone to transfer data from a Drive folder to our server. Assuming that you already have a Google account, go into the root/main folder of your Drive and create a folder. I recommend that you name it something simple like "testfolder". Make sure that the name doesn't contain any spaces or unintentionally entered characters.

The idea is to sync the contents of your Google Drive folder with the contents of your local folder in your Droplet. We are going to create a folder called "test_git_folder" on the Droplet, and within this folder we will create another folder called "gdrive". (You can use other folder names if you want).
Use the following commands in Putty to create these two folders ("cd" command is already familiar, if you give two dots as a destination it will take you to the parental folder):
```
User:	root@[Droplet_Name]:~# cd ..
User:	root@[Droplet_Name]:/#
User:	root@[Droplet_Name]:/# cd srv
User:	root@[Droplet_Name]:/srv# mkdir test_git_folder
User:	root@[Droplet_Name]:/srv# cd test_git_folder
User:	root@[Droplet_Name]:/srv/test_git_folder#
User:	root@[Droplet_Name]:/srv/test_git_folder# mkdir gdrive
User:	root@[Droplet_Name]:/srv/test_git_folder# cd gdrive
```
*gdrive* is the local folder which we are going to sync the Google Drive folder with. 

It's very important that the Drive pulling and the GitHub pushing folder cannot be the same. Otherwise the connection between GitHub and the pushing folder would break every time Rclone pulls. This will be explained in a bit more detail later, but in a nutshell the idea is that Rclone will pull contents from the "testfolder" in Drive to the local folder called "gdrive", which is a sub-folder of "test_git_folder". The contents of "test_git_folder" (including the folder "gdrive") will be then pushed to GitHub.

We initate Rclone setup with the "rclone config" command line.

```
User:	root@[Droplet_Name]:/srv/test_git_folder/gdrive# rclone config
Console:
	[yyyy/mm/dd hh:mm:ss] NOTICE: Config file "/root/.config/rclone/rclone.conf" not found - using defaults
	No remotes found - make a new one
	n) New remote
	s) Set configuration password
	q) Quit config
User:	n/s/q> n
```
Select "New remote" and give it a name for which I recommend "RemoteProjectname". For the storage type choose Google Drive "drive":
```
Console:Type of storage to configure.
	Choose a number from below, or type in your own value
	[long list of options]
User:	Storage> drive
```
Client id and secret can be skipped (just hit enter):
```
Console:[...]
User:	client_id> [Enter]
Console:[...]
User:	client_secret> [Enter]
```
For the scope type "drive" and skip the next two options with enter:
```
Console:[...]
User:	scope> drive
Console:[...]
User:	root_folder_id> [Enter] 
User:	service_account_file> [Enter]
```
We don't want to edit the advanced config and we don't want to use the auto config (since we are working from a remote machine):
```
Console:Edit advanced config? (y/n)
	y) Yes
	n) No
User:	y/n> n
Console:Remote config
	Use auto config?
	 * Say Y if not sure
	 * Say N if you are working on a remote or headless machine or Y didn't work
	y) Yes
	n) No
User:	y/n> n
Console:If your browser doesn't open automatically go to the following link: https://accounts.google.com/o/oauth2/auth?access_type=offline&client_ [...etc.]
```
Follow the link in your browser, which is going to take you to the Drive authorization site. Be aware that when you paste the text the line breakes are going to appear as spaces (if your browser can't find the site probably this is why). Log in and authorize Rclone for access. Copy the verification code and paste it in Putty:
```
User:	Enter verification code> \[paste code here]
Console:
	--------------------
	[[Remote_Name]]
	type = drive
	scope = drive
	token = {"access_token":"ya29.Gl[...long string of characters...]ah","token_type":"Bearer","refresh_token":"1/hyDJZAgL9WucRbdgaWtSTMnsU7YD2mxsHgv62T-HIIM","expiry":"2019-05-14T16:22:28.152944127Z"}
	--------------------
	y) Yes this is OK
	e) Edit this remote
	d) Delete this remote
```
We don't want to configure this as team drive. Answer yes "y", everything should be okay:
```
User:	y/e/d> y
```
We have just connected Drive with the server via Rclone. Time to test it out. If everyting works, "rclone ls" will list every object that is in the specified Drive folder. Before we move on, upload a file into the Drive folder (it can be of any type, I recommend a simple text file).
Quit Rclone config by typing "q" and use the following command to list the objects of the Drive folder (Remote_Name in the square brackets is the name you have just configured in Rclone (which is something like Remote:ProjectName in our instructions)):

```
User:	root@[Droplet_Name]:/srv/test_git_folder/gdrive# rclone ls [Remote_Name]:testfolder
Console:
       [list of files in the Drive folder]
```
The console returns the correct list of the files present in the testfolder. Finally, for the synchronization itself we have to use the "rclone sync [source:path] [dest:path]" command, like so:
```
User:	root@[Droplet_Name]:/srv/test_git_folder/gdrive# rclone sync \[Remote_Name]:testfolder /srv/test_git_folder/gdrive/
```
Rclone should have now synchronized the two folders. Check if the files listed in the gdrive local folder on the Droplet match that of the Google Drive testfolder. If they match that means that the Goodle Drive is successfully linked with the local folder on the Droplet.

Do keep in mind that this process makes the source and the destination identical, modifying the destination only.

```
User:	root@[Droplet_Name]:/srv/test_git_folder/gdrive# ls
Console:
       [list of files in the gdrive folder appear]
```


### Synchronizing the Drive folder with your local folder: ###

We have succesfully initiated a synchronization with Rclone. Now we just have to make this process happen regularly in an automated fashion. For this we are going to use cron, which is a time-based job scheduler in Linux. Since cron really only schedules the jobs, we are going to need something to execute first, ie. a script file. Navigate back to root and create a folder for this with the already familiar mkdir command:

```
User:	root@[Droplet_Name]:/srv/test_git_folder/gdrive# cd ..
User:	root@[Droplet_Name]:/srv/test_git_folder# cd ..
User:	root@[Droplet_Name]:/srv# 
User:	root@[Droplet_Name]:/srv# mkdir cron_script
User:	root@[Droplet_Name]:/srv# cd cron_script
```

For the script file we are going to use nano, which is a text editor. To create a file with nano simply write "nano [filename]". We are going to name this file rclone-cron.sh (.sh is a shell script, the program itself):
```
User:	root@[Droplet_Name]:/srv/cron_script# nano /srv/cron_script/rclone-cron.sh
```
The nano text editor appears. Enter the following text into the editor (again, you have to enter your own informations in the square brackets):
```	
	#!/bin/bash
	if pidof -o %PPID -x “rclone-cron.sh”; then 
	exit 1
	fi
	rclone sync [Remote_Name]:[drive_folder_name] /srv/test_git_folder/gdrive/
	exit
```
Exit nano text editor by pressing Ctrl+x, then y, then [Enter]. 

Now we need to make the shell script executable and tell cron to run it periodically. The first part could sound familiar, we already did this before when we installed Rclone. In the options field we are going to use "a+x" ("a" means for all users, "x" means executable) Follow these command line to navigate back to root and make the script executable:


```
User:	root@[Droplet_Name]:/srv/cron_script# cd ..
User:	root@[Droplet_Name]:/srv# cd ..
User:	root@[Droplet_Name]:/# chmod a+x /srv/cron_script/rclone-cron.sh
```
To open the time table of cron, use the crontab command with the -e option (edit the current crontab):
```
User:	root@[Droplet_Name]:/# crontab -e
Console:
	no crontab for root - using an empty one

	Select an editor.  To change later, run 'select-editor'.
	  1. /bin/ed
	  2. /bin/nano        <---- easiest
	  3. /usr/bin/vim.basic
	  4. /usr/bin/vim.tiny

	Choose 1-4 [2]:
```
Select nano, which was the second option for me (this varies, so make sure that you select nano). Another text editor will pop up. Scroll down to the bottom of the text and paste the following text there:
``` 
	*  *  *  *  *  /srv/cron_script/rclone-cron.sh > /tmp/cron_job_rclone.log 2>&1
```
Exit (Ctrl+x) and proceed to save it without altering the default name. This is going to execute our shell file at every minute. If you would like to set different time periods, you can use [this](https://crontab.guru/#*_*_*_*_*) crontab time calculator.

```
Console:
	crontab: installing new crontab
```
Restart crontab to make sure that the new part work:
```
User:	root@[Droplet_Name]:/# service cron restart
```

You should test whether the auto-sync between your Drive and your local folder works by putting a new text file in your google drive folder. Wait a minute and list the contents of your local folder like this:

```
User:	root@[Droplet_Name]:/# cd /srv/test_git_folder/gdrive
User:	root@[Droplet_Name]:/srv/test_git_folder/gdrive# ls
Console:
  [file names will be listed here]
```

Ideally, the list of files in the local folder should match that in your Google Drive folder. 

IMPORTANT NOTE: rclone does not directly sync gdoc files. These google documents are converted into another file format. By default this is word .docx format for google text files and excel .xlsx format for google spreadsheets. Unfortunately rclone does not sync google forms, so google forms will nto appear in your local folder (and they will not be pushed to GitHub either). 

If you have verified that all the above works, proceed to the next step. 

(If you encountered some error or the drive folder contents do not seem to match the local folder contents, you need to first investigate the source of the problem and make sure that you can set up auto-sync with drive before you move forward. There are many things that could go wrong, so we do not provide troubleshooting tips here.)

## III. Setting up sync between GitHub and Drive ##

### Pushing to GitHub ###

The contents of your Drive folder are now repeatedly synchronized with the local folder every minute. We have completed the pulling process, that means you are already halfway through the whole guide. Now we are going to leave Rclone and Drive behind and focus on Git and GitHub. 

The second major motor of our project is Git. Git is a version-control system for tracking changes in source code during software developement. We are going to use it to connect the pulling folder called test_git_folder (which is the parental folder of the gdrive), to GitHub, a version controlled repository often used by researchers and software developers.

First, visit [GitHub](https://github.com) in your internet browser. [Create a GitHub account](https://m.wikihow.com/Create-an-Account-on-GitHub) if you don't have one already. You should create a GitHub repository if you haven't got one already. 

1. Log into GitHub in your browser and click on the cross in the upper-right corner. 
2. Select "New repository". 
3. Set the repository name (any name will do)
4. Make the repository public. 
5. Do not "Initialize this repository with a README". 
6. Hit create.

Next, install git on the Droplet using the "apt install command":

```
User:	root@[Droplet_Name]:/# apt install git
```
Use "cd" to navigate into the pushing folder. While you are there, initiate git with the "git init" command, which is going to create an empty local git repository in the folder:
```
User:	root@[Droplet_Name]:/# cd /srv/test_git_folder
User:	root@[Droplet_Name]:/srv/test_git_folder#
User:	root@[Droplet_Name]:/srv/test_git_folder# git init
Console:Initialized empty Git repository in /srv/test_git_folder/.git/
```
To connect the folder with GitHub, we are going to add the GitHub repository as a remote destination with the "git remote add origin" command (we have to do this as the superuser):
```
User:	root@[Droplet_Name]:/srv/test_git_folder#  git remote add origin https://github.com/[Github_Username]/[Repository_Name]
```
To test if we can push into the remote, we are going to push the gdrive folder. Add the folder to the staging area:
```
User:	root@[Droplet_Name]:/srv/test_git_folder#  git add *
```
We've added all files and folders, but we can always add them one-by-one, like "git add README.md". Configure GitHub username and email:
```
User:	root@[Droplet_Name]:/srv/test_git_folder# git config --global user.name "[Github_Username]"
User:	root@[Droplet_Name]:/srv/test_git_folder# git config --global user.email "[Github_Email]"
```
Add a commit message. These are messages which appear next to the files to inform the viewers what has changed during the last push. Use the " git commit -m "[message]"" command:
```
User:	root@[Droplet_Name]:/srv/test_git_folder#  git commit -m "test commit message"
```
Push the local content (ie. everything added to the staging area), you'll have to enter the GitHub username and password:
```
User:	root@[Droplet_Name]:/srv/test_git_folder# git push -u origin master
```
Enter username and password:
```
User:	Username for 'https://github.com': [Github_Username]
User:	Password for 'https://[Github_Username]@github.com':
Console:
	Counting objects: 3, done.
	Writing objects: 100% (3/3), 228 bytes | 0 bytes/s, done.
	Total 3 (delta 0), reused 0 (delta 0)
	To https://github.com/[Github_Username]/[Repository_Name]
	 * [new branch]      master -> master
	Branch master set up to track remote branch master from origin.
```

Wait a few minutes and check your GitHub repository in your internet browser. The gdrive folder should have appeared by now. It is important to understand that this is more like a synchronization, than just a simple upload. Git makes the destination identical to source, thus if destination contains newer or more files, the command won't force push the contents of origin (data loss is prevented this way). Check the Troubleshooting section at the end of the document if you encounter this problem.

### Switch from Https to SSH-key authentication ###

Notice that you had to enter your credentials for GitHub when you pushed the local folder content to the repository. This is fine when you amnually push, but if you want to set up auto-sync the same would not work. To overcome this, you will have to set up using SSH-key authentication with GitHub. You will first need to enable this in your Linux server and create a public SSH-key.

First we have to check the sshd config of the server:

```
User:	root@[Droplet_Name]:/srv/test_git_folder# cd ..
User:	root@[Droplet_Name]:/srv# cd ..
User:	root@[Droplet_Name]:/# nano /etc/ssh/sshd_config
Console:
	[nano text editor appears]
```
Make sure that the following options are changed to "yes":

```
User:	[perform the following in nano text editor]	
		set "PermitRootLogin" to "PermitRootLogin yes"
		set "PermitEmptyPasswords" to "PermitEmptyPasswords yes"
		set "PasswordAuthentication" to "PasswordAuthentication yes"
	[exit nano text editor by pressing Ctrl+x, then y, then Enter]
```

SSH (Secure Shell) keys can be thought of as access credentials. Similarly to a username and password combo they allow identification but offer a good alternative. Our user key is going to consist of a private key (which the server is going to use to access the remote content) and a public one (this will be used to decrypt information coming from the remote place). First we have to check if there is already an SSH key in the server:
```
User:	root@[Droplet_Name]:/# ls -al /root/.ssh
Console:
	total 8
	drwx------ 2 root root 4096 May 14 14:13 .
	drwx------ 8 root root 4096 May 14 16:35 ..
	-rw------- 1 root root    0 May 14 14:13 authorized_keys
```
Since none of the listed keys end in .pub, that means no public keys are present. We'll need to create one.
```
User:	ssh-keygen -t rsa -b 4096 -C "[Github_Email]"
Console:Enter file in which to save the key (/root/.ssh/id_rsa):
User:	[Enter]
Console:Enter passphrase (empty for no passphrase):
User:	[Enter]
Console:Enter same passphrase again:
User:	[Enter]
Console:
	Your identification has been saved in /root/.ssh/id_rsa.
	Your public key has been saved in /root/.ssh/id_rsa.pub.
	The key fingerprint is:
	[a lot of text appears]
```
Now we add the keys to ssh agent. First we have to make sure that it runs:
```
User:	root@[Droplet_Name]:/# eval $(ssh-agent -s)
Console:Agent pid 12740
```
Now add the key to ssh agent:
```
User:	root@[Droplet_Name]:/# ssh-add /root/.ssh/id_rsa
Console:Identity added: root/.ssh/id_rsa (root/.ssh/id_rsa)
```
Pull up the public key and copy it:
```
User:	root@[Droplet_Name]:/# cat /root/.ssh/id_rsa.pub
Console:
	ssh-rsa AA...[Extremely long string of characters were ommited here]...Rw== [Github_Email]
```
This long string of text is the SHH key. 

To set up the remote side of the SSH key, open GitHub in your browser.

1. Go to GitHub in your web browser and [create a new SHH key](https://github.com/settings/ssh/new) 
2. I recommend something convenient like "SSHkey/project name".
3. Paste the SSH key into the 'Key' box. (you need to copy the whole string starting with ssh-rsa and ending with your GitHub emial.)
4. Enter your GitHub password when prompted



An SHH key has now been added to your GitHub account and can be found inside [settings, keys](https://github.com/settings/keys).
Now let's switch from https to SHH authentication in git on your remote server as well.

First, you can check your current git remote in PuTTY

```
User:	root@[Droplet_Name]:/# cd /srv/test_git_folder
User:	root@[Droplet_Name]:/srv/test_git_folder# git remote -v
Console:origin  https://github.com/[Github_Username]/[Repository_Name] (fetch)
Console:origin  https://github.com/[Github_Username]/[Repository_Name] (push)
```

The fact that the git remome is https://github.com/... means that you are using https authentication.

You need to switch the remote URL to git@github.com:[Github_Username]/[Repository_Name].git for the SSH authentication to take effect. You can do this by:

```
User:	root@[Droplet_Name]:/srv/test_git_folder# git remote set-url origin git@github.com:[Github_Username]/[Repository_Name].git
```
Check the remotes again:
```
User:	root@[Droplet_Name]:/srv/test_git_folder# git remote -v
Console:origin  git@github.com:[Github_Username]/[Repository_Name].git (fetch)
Console:origin  git@github.com:[Github_Username]/[Repository_Name].git (push)
```
Now we can check if this works by executing the following command on the server. Basically this is going to test the connection for which we are going to have to authenticate ourselves (but this time with the ssh key we have just created):
```
User:	root@[Droplet_Name]:/srv/test_git_folder# ssh -vT git@github.com
```
*texts pouring in* ...in the end you should see something like this:
```
Console:Hi [Github_Username]! You've successfully authenticated, but GitHub does not provide shell access.
debug1: client_input_channel_req: channel 0 rtype exit-status reply 0
debug1: channel 0: free: client-session, nchannels 1
Transferred: sent 3412, received 2484 bytes, in 0.2 seconds
Bytes per second: sent 18018.5, received 13117.8
debug1: Exit status 1
```
If you see permission denied instead, [this guide](https://help.github.com/en/enterprise/2.16/user/articles/error-permission-denied-publickey) can help you to resolve the issue.

Now let's test whether switching to SSH authentication worked. In PuTTY create a new text file named testfile2.txt and see if you can push it to your GitHub repository.


```
User:	root@[Droplet_Name]:/srv/test_git_folder# nano testfile2.txt
```
Enter some text, then commit the push:
```
User:	root@[Droplet_Name]:/srv/test_git_folder# git add testfile2.txt
User:	root@[Droplet_Name]:/srv/test_git_folder# git commit -m "test push"
Console:[master 0f5b652] test push
 1 file changed, 1 insertion(+)
 create mode 100644 testfile2.txt

User:	root@[Droplet_Name]:/srv/test_git_folder# git push -u origin master
Console:Counting objects: 3, done.
Delta compression using up to 4 threads.
Compressing objects: 100% (2/2), done.
Writing objects: 100% (3/3), 316 bytes | 316.00 KiB/s, done.
Total 3 (delta 0), reused 0 (delta 0)
To github.com:[Github_Username]/[Repository_Name].git
   288f134..84be1d6  master -> master
Branch 'master' set up to track remote branch 'master' from 'origin'.
```
Go ahead and check if the file has appeared in GitHub.

(If you don't see this, you need to investigate the source of the issue and fix it before moving forward, because if a single push does not work, auto-push will not work either.)


### Set up periodic auto-push from the local folder to the GitHub repository  ###

The last step is to set up automatic push from the local folder to GitHub. Similarly to the auto-sync with Google Drive, the idea is to set up a cron job, where cron would periodically execute a script that will do the git push.

Let's create a script as a text file named sync.sh and save it to the folder /srv/cron_script.

```
User:	root@[Droplet_Name]:/srv/test_git_folder# cd /srv/cron_script
User:	root@[Droplet_Name]:/srv/cron_script#  touch sync.sh
User:	root@[Droplet_Name]:/srv/cron_script#  nano sync.sh
```
Paste the following in the text editor:
```
#!/bin/bash
cd /srv/test_git_folder
git add *
git commit -am "Scheduled update `date`"
git push -u origin master
```
Exit via Ctrl+X,Y,\[enter]. We make the script executable and add it into crontab:
```
User:	root@[Droplet_Name]:/srv/cron_script#  chmod +x sync.sh
User:	root@[Droplet_Name]:/srv/cron_script#  chmod 765 sync.sh
User:	root@[Droplet_Name]:/srv/cron_script#  -s
User:	root@[Droplet_Name]:/srv/cron_script# crontab -e
```
Insert the following line to the end in the text editor:
```
*  *  *  *  *  /srv/cron_script/sync.sh > /tmp/job.log 2>&1
```
Save end exit via Control+X,Y,\[enter]
```
Console:crontab: installing new crontab
User:	root@[Droplet_Name]:/srv/cron_script#  service cron restart
```
To test if the auto-sync really works, add any file into the Drive folder and wait for it to appear on GitHub (if you haven't set a different time interval than ours, it should only take a minute).

## IV. Concluding remarks ##

I hope that you've enjoyed our guide and managed to set up your working connection between Drive and GitHub. Real time data routing could be a small milestone in the way towards a more credible science by making sure some recordings cannot be altered after they have been uploaded. This guide is the fruit of some heavy Googling and sweaty trial and error processes. Altough we have succesfully tested it several times before it is entirely possible that you may run into a problem wich hasn't been accounted for in this guide. Please do contact us if you have any notes or reflections on our guide.
Below you can see the dynamically evolving Troubleshoot section with some common errors we have encountered during the process. Should you something that is not mentioned here (and you weren't able to fix it using the guide) please let us know, so we can expand the troubleshooting section.

## V. Troubleshooting ##

Here are some common errors we have encountered during the process.

---

1. Rclone can't list the files in my drive folder
First you should go through every information you have entered in the rclone config and the rclone sync process. Make sure that you entered the name of the drive folder correctly etc. This solves the problem most of the time.

2. I have entered faulty information when configuring Git, but now I can't overwrite the origin and destination information.
You have to remove the old remote and do the configuration again. Use [this link](https://help.github.com/en/articles/removing-a-remote) to remove the wrong repository.

3. Git says that I can't push, because there is a mismatch in the repository and the local version.
This looks something like this:
```
hint: Updates were rejected because the remote contains work that you do
hint: not have locally. This is usually caused by another repository pushing
hint: to the same ref. You may want to first integrate the remote changes
hint: (e.g., 'git pull ...') before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
```
The source of the problem is a mismatch between the contents of your repository and local. Usually the command refuses to update the contents of the repository if the local content seems to be older. To solve this you can either force push (use the -f option with git-pull), which could result in data loss if the repo's version is indeed newer, or you can pull the contents of the repository first with git-pull.

4. I get a permission denied when I'm trying to convert to ssh keys.
Use [this guide](https://help.github.com/en/enterprise/2.16/user/articles/error-permission-denied-publickey) to solve this problem.
