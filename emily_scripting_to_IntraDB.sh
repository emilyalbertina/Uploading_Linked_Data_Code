#!/bin/bash

# Let's hardcode this for now.
PROJECT="CCF_HCA_ITK"
HOST="hcpi-dev-hodge3.nrg.wustl.edu"
#ARCHIVE="/data/intradb/archive/$PROJ/arc001"

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


#MOVE FILEs THAT CONTAIN STRING IN FILE NAME TO NEW SUB-DIRECTORY

EXPERIMENT=$( cat ~/Downloads/EA_TEST_ID2.txt )
for key in $EXPERIMENT; do
 cp ~/Downloads/BOX\ TEST\ DOWNLOAD/*$key* ~/Downloads/TESTSCANSUBDIR/
done


#Update list so that it only includes IDs if we were able to find files of them




##THIS IS MAKING EXPERIMENT VARIABLE I WANT FROM A LIST OF FAILURES FROM INTRADB... I CAN THEN CREATE A FOR LOOP BELOW
#EXPERIMENT=$( cat ~/Downloads/SHORT_EA_TEST_ID2.txt )
SEARCHPATH=/home/emily/Downloads/TESTSCANSUBDIR/ #DIRECTORY FILES ARE LOCATED
#echo "THIS IS SEARCH PATH:"
#echo "$SEARCHPATH"


## GET SERVER-SIDE CACHE SPACE PATH TO BE USED FOR THIS UPLOAD USING LOOP FOR EVERY SESSION ID IN EXPERIMENT
for key in $EXPERIMENT; do

#Make a subject variable (HCA#######) by removing _V*_* from experiment
   #SUBJECT=$(sed -e "s/_V[0-9]_[A-Z][0-9]*//") #* specifies anything BEFORE astrix so need to give it examples of what to expect.   dot matches on anything  any number of any fields .*
  #or
   SUBJECT=$(sed -e "s/_V[123]_[ABCX][0-9]*//" <<< $key) #Hodge recommends this one for clarity (see linux regular expressions)
   #or
   #SUBJECT=$(sed -e "s/_[A-Z0-9_]*//" <<< $key)
   #or
  #SUBJECT=$( sed 's/_V1_A//' <<< $key | sed 's/_V1_B//' | sed 's/_V2_A//' |sed 's/_V2_B//'| sed 's/_V1_X1//' | sed 's/_V2_X1//' )

#Check all variables called are correct
  #echo "$SUBJECT"
  #echo "$key"
  #echo "$HOST"
  #echo "$PROJECT"

#done

#CURL Call to make BUILD PATH
#NOTE: Echoing helps find source much faster. good to echo out statements so you have something you can run from command line to see if problem is curl statement or something else.
#NOTE: in general will want to  need back slash () to make a command want ot excute a command that will produce a standard output that will get written out to variable
  echo "curl -s --cookie JSESSIONID=$JSESSIONID -X POST \"https://$HOST/REST/services/import?import-handler=automation&project=$PROJECT&configuredResource=_CACHE_&subject=$SUBJECT&experiment=$key&returnUrlList=false&importFile=false&process=false\"| sed \"s/\/[^\/]*$//\""
  BUILDPATH=`curl -s --cookie JSESSIONID=$JSESSIONID -X POST "https://$HOST/REST/services/import?import-handler=automation&project=$PROJECT&configuredResource=_CACHE_&subject=$SUBJECT&experiment=$key&returnUrlList=false&importFile=false&process=false"| sed "s/\/[^\/]*$//"`
  echo "BUILDPATH=$BUILDPATH"


#done



##MAKE SURE UPLOAD ALL FILES FOR XX_V2_A BEFORE WE PROCESS, More likely to process correctly with the more files you give it.
  ## UPLOAD EACH FILE TO CACHE SPACE

#find $SEARCHPATH -type f -name '*.$key*.' -print0 | xargs -0 basename
  #find $SEARCHPATH -type f -name "*$key*" -print0 | xargs -0 printf '%s\n'
#find $SEARCHPATH -type f -name '*.HCA6154057*.' -print0 | xargs printf '%s/n'
                   for FPATH in `find $SEARCHPATH -type f -name "*$key*" `; do  #Loop finds files only in our searchpath directory with the experiment name of interest in them

                                  FNAME=`basename $FPATH`

                                  echo "SEND FILE:  FILE PATH=$FPATH, FILE NAME=$FNAME"

                                  curl -s --cookie JSESSIONID=$JSESSIONID --data-binary @$FPATH -X POST "https://$HOST/REST/services/import/$FNAME?import-handler=automation&project=$PROJECT&configuredResource=_CACHE_&subject=$SUBJECT&experiment=$key&buildPath=$BUILDPATH&returnUrlList=false&extract=true&process=false&inbody=true&returnInbodyStatus=true&sendemail=true"

                              done
                            #  echo "$key"



  ## TELL IMPORTER TO PROCESS ALL FILES

  echo "Process uploaded files" "$key"

  curl -s -i --cookie JSESSIONID=$JSESSIONID -X POST "https://$HOST/REST/services/import?import-handler=automation&project=$PROJECT&configuredResource=_CACHE_&subject=$SUBJECT&experiment=$key&buildPath=$BUILDPATH&sendemail=true&format=html&sessionImport=false&process=true&importFile=false&eventHandler=CCF_HCA_LinkedDataImporter-prj_CCF_HCA_ITK-LinkedDataUpload--112114798-0"

done
