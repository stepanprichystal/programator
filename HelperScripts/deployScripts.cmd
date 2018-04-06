ECHO Hello World!



SET sourcerepopath=y:\server\site_data\scriptsCentral
SET sourcerepo=y:\server\site_data\scriptsCentral\.git
SET deploypath=y:\server\site_data\scriptsDeploy\
SET deploy=y:\server\site_data\scriptsDeploy\.git


if not exist %deploy% (
    	git  clone file://%sourcerepopath% %deploypath%
	ECHO Clone new repo
)



y:
cd %deploypath%
git checkout master 
git pull 


set /p DUMMY=See results and press ENTER to continue...