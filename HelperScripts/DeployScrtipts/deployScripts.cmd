ECHO Hello World!


:: Set GIT paths
SET sourcerepopath=y:\server\site_data\scriptsCentral
SET sourcerepo=y:\server\site_data\scriptsCentral\.git
SET deploypath=y:\server\site_data\scripts\
SET deploy=y:\server\site_data\scripts\.git

:: Paths for log storing before and after fetch
SET gitlogbefore=c:\tmp\InCam\scripts\other\beforecommit
SET gitlogafter=c:\tmp\InCam\scripts\other\aftercommit

:: clone repo id deleted
if not exist %deploy% (
    	git  clone file://%sourcerepopath% %deploypath%
	ECHO Clone new repo
)

:: Swwitch to y, set master branch and do fetch
y:
cd %deploypath%
git checkout master 


git log -1 --name-status > %gitlogbefore%

git fetch --all
git reset --hard origin/master

git log -30 --name-status  > %gitlogafter%

:: If there are some differences in GIT logs send mail to TPV
SET mailscript=SendMailScript.pl
SET curdir=%~dp0
perl %curdir%%mailscript% %gitlogbefore% %gitlogafter%


:: Quit
set /p DUMMY=See results and press ENTER to continue...

