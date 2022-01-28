#!/bin/bash

#Naming Variables to Be Used in CURL call later

PROJECT="CCF_HCA_ITK" #INTRADB PROJECT OF INTEREST
HOST="hcpi-dev-hodge3.nrg.wustl.edu" #HOST WEBSITE TO COMMUNICATE WITH
EXPERIMENT=$( cat ~/Downloads/LIST_OF_IDS_NEEDING_LINKED_DATA.txt ) #MAKING EXPERIMENT VARIABLE FROM A LIST OF FAILURES FROM INTRADB; CHANGE TO LOCATION OF LIST
SEARCHPATH=/home/emily/Downloads/TESTSCANSUBDIR/ #DIRECTORY FILES TO BE UPLOADED ARE LOCATED


#Check For/Get JSESSION ID
while true; do
    case "$1" in
      --help | -h | -\?)
	printf "\nexample_getsession.sh [options]\n\n"
	printf "   Options\n\n"
	printf "      -u, --user             <user>\n"
	printf "      -p, --pw               <password>\n"
	printf "      -e, --exp              <single experiment label>\n"
	printf "\n\n"
	exit 0
	;;
      --user | -u)
        USR=$2
	shift
	shift
        ;;
      --pw | -p)
        PW=$2
	shift
	shift
        ;;
      --exp | -e)
        EXP=$2
	shift
	shift
        ;;
      -*)
	echo "Invalid parameter ($1)"
	exit 1
        ;;
      *)
	break
        ;;
    esac
done


RENEW_JSESSION_ID () {
	HTTP_CODE=`curl -s -w "%{http_code}\n" --cookie JSESSIONID=$JSESSIONID https://${HOST}/data/projects/$PROJ -o /dev/null`
	if [ "$HTTP_CODE" != "200" ] ; then
        	echo "JSESSIONID is invalid or expired - exiting (HTTP_CODE=$HTTP_CODE)"
		read -p "Enter Username:  " USR;
		echo ""
		read -s -p "Enter Password:  " PW;
		echo ""
	else
		return
	fi
	JSESSIONID=`curl -s -v -u $USR:$PW https://${HOST}/data/JSESSIONID 2> /dev/null`
	echo "JSESSIONID successfully set.  Run the following line in your session to set an environment variable for future runs."
	echo "export JSESSIONID=$JSESSIONID"
	HTTP_CODE=`curl -s -w "%{http_code}\n" --cookie JSESSIONID=$JSESSIONID https://${HOST}/data/projects/$PROJ -o /dev/null`
	if [ "$HTTP_CODE" != "200" ] ; then
        	echo "JSESSIONID is invalid or expired - exiting (HTTP_CODE=$HTTP_CODE)"
       		exit
	fi
}

#Confirm JSESSIONID Has been Made
RENEW_JSESSION_ID



#MOVE FILEs THAT CONTAIN STRING WITH IDs OF INTEREST IN FILE NAME TO NEW SUB-DIRECTORY (so we only upload the files that we want NOT the entire archive)
for key in $EXPERIMENT; do
 cp ~/Downloads/BOX\ TEST\ DOWNLOAD/*$key* ~/Downloads/TESTSCANSUBDIR/
done




## GET SERVER-SIDE CACHE SPACE PATH TO BE USED FOR THIS UPLOAD USING LOOP FOR EVERY SESSION ID IN EXPERIMENT
for key in $EXPERIMENT; do

#Make a subject variable (HCA#######) by removing _V*_* from experiment
   SUBJECT=$(sed -e "s/_V[123]_[ABCX][0-9]*//" <<< $key) #Hodge recommends this one for clarity (see linux regular expressions)
   
#Check all variables called are correct (for first 'TEST' run only)
  echo "$SUBJECT"
  echo "$key"
  echo "$HOST"
  echo "$PROJECT"



#CURL Call to make BUILD PATH
BUILDPATH=`curl -s --cookie JSESSIONID=$JSESSIONID -X POST "https://$HOST/REST/services/import?import-handler=automation&project=$PROJECT&configuredResource=_CACHE_&subject=$SUBJECT&experiment=$key&returnUrlList=false&importFile=false&process=false"| sed "s/\/[^\/]*$//"`
  echo "BUILDPATH=$BUILDPATH"


## UPLOAD EACH FILE TO CACHE SPACE 
### This is a sub for loop so code will upload all files for 1 Experiment (HCA#######_V#_A/B) before processing. 
                   for FPATH in `find $SEARCHPATH -type f -name "*$key*" `; do  #Loop finds files only in our searchpath directory with the experiment name of interest in them

                                  FNAME=`basename $FPATH`

                                  echo "SEND FILE:  FILE PATH=$FPATH, FILE NAME=$FNAME"

                                  curl -s --cookie JSESSIONID=$JSESSIONID --data-binary @$FPATH -X POST "https://$HOST/REST/services/import/$FNAME?import-handler=automation&project=$PROJECT&configuredResource=_CACHE_&subject=$SUBJECT&experiment=$key&buildPath=$BUILDPATH&returnUrlList=false&extract=true&process=false&inbody=true&returnInbodyStatus=true&sendemail=true"

                              done
                         



  ## TELL IMPORTER TO PROCESS ALL FILES

  echo "Process uploaded files" "$key"

  curl -s -i --cookie JSESSIONID=$JSESSIONID -X POST "https://$HOST/REST/services/import?import-handler=automation&project=$PROJECT&configuredResource=_CACHE_&subject=$SUBJECT&experiment=$key&buildPath=$BUILDPATH&sendemail=true&format=html&sessionImport=false&process=true&importFile=false&eventHandler=CCF_HCA_LinkedDataImporter-prj_CCF_HCA_ITK-LinkedDataUpload--112114798-0"

done
