#!/bin/bash
########################################################################
#### This script has been written by The__Matty ( mattymatty#9621 ) ####
#### It is under copyrights on GitHub, you cannot share it publicly ####
#### whitout giving credits to the creator                          ####
########################################################################

#the path to the jenkins job ( download page )
jenkins=""

#the path to where to save the file ( if relative is relative to this script location )
savePath="."

#the download channel: ( Stable, Succesfull, Last, Custom ) it's suggested to keep Stable 
channel="Stable"

#the Custom channel/version to use ( typically is the Release channel, but not every Jenkis has it ), modify only if channel is set to "Custom"
custom="Release"

#the artifact list to download ( typically no change is needed, if there are more than one list them)
artifacts=(0)

#the path to the wget executable ( typically no change is needed )
wget=$(which wget)


#the path to the jq executable ( typically needs to install jq )
jq=$(which jq)


#this will keep track of the last downloaded file ( if you delete the file or want to reset it, simply put this value to 0 )
actual=0


#######################################
#### DO NOT MODIFY BEYON THIS LINE ####
#######################################

_exit(){
    cd $old_pwd
    exit $1
}

me=$(realpath $0)
current_path=$(dirname $0)
old_pwd=$(pwd)
cd $current_path

if [ "$wget" == "" ]; then
    >&2 echo missing wget
    _exit 1
fi

if [ "$jq" == "" ]; then
    >&2 echo missing jq
    _exit 2 
fi

if [ "$channel" != "Stable" ] && [ "$channel" != "Succesfull" ] && [ "$channel" 1= "Last" ] && [ "$channel" 1= "Custom" ]; then
    >&2 echo -e "Wrong parameter: channel\nPlease modify this script"
fi

if [ "$channel" == "Stable" ]; then
    channel="lastStableBuild"
else if [ "$channel" == "Succesfull" ]; then
        channel="lastSuccesfullBuild"
    else if [ "$channel" == "Last" ]; then
            channel="lastBuild"
        else if [ "$channel" == "Custom" ]; then
            channel=$custom
        fi
    fi
fi

save_path=$(realpath $savePath)

json=$($wget --check-certificate=quiet -O - $jenkins/$channel/api/json?tree=artifacts[relativePath,fileName],id 2>/dev/null)

if [ "$json" == "" ]; then
    >&2 echo -e "\nError cannot get the download page:\n$jenkins/$channel\nCheck the link you provided\n"
    _exit 3
fi

echo -e "\n$channel:\n"

$jq . <<< $json 

latest_id=$($jq .id <<< $json | tr -d '[[:space:]]"')

if (( $actual < $latest_id )); then
    act_json=$($wget --check-certificate=quiet -O - $jenkins/$actual/api/json?tree=artifacts[relativePath,fileName],id 2>/dev/null)

    if [ "$act_json" == "" ] && [ $actual -ne 0 ]; then
        >&2 echo -e "\nError cannot get the download page:\n$jenkins/$actual\nCheck the link you provided\n"
        _exit 3 
    fi

    echo -e "\nActual:\n"

    $jq . <<< $act_json
    
    for i in ${artifacts[@]}; do
        act_filename=$($jq .artifacts[$i].fileName <<< $act_json | tr -d '"')
        latest_filename=$($jq .artifacts[$i].fileName <<< $json | tr -d '"')
        latest_page=$jenkins/lastStableBuild/artifact/$($jq .artifacts[$i].relativePath <<< $json | tr -d '"')
        if [ "$act_filename" != "" ] && [ -e $savePath/$act_filename ]; then
            if [ -w $savePath/$act_filename ];then
                echo -e "\nremoving $savePath/$act_filename\n"
                rm $save_path/$act_filename
            else
                echo cannot remove $save_path/$act_filename
                _exit 4
            fi
        fi
        echo -e "\ndownloading $latest_filename\nfrom $latest_page\n"
        $wget --check-certificate=quiet -O $save_path/$latest_filename $latest_page
    done
    sed -i "s/actual=[[:digit:]]*$/actual=$latest_id/g" $me
else if (( $actual > $latest_id )); then
        >&2 echo -e "\nSomething is wrong:\n\tActual ID:\t$actual\n\tLast ID:\t$latest_id\nProbably you changed the channel,\nplease reset the \"actual=$actual\" line to \"actual=0\"\nor revert the changes.\n"
        _exit 5
    else 
        for i in ${artifacts[@]}; do
        latest_filename=$($jq .artifacts[$i].fileName <<< $json | tr -d '"')
        if ! [ -e $savePath/$latest_filename ]; then
            >&2 echo -e "\nSomething is wrong:\n\tActual ID:\t$actual\n\tLast ID:\t$latest_id\nBut the file is missing.\nProbably you changed the SavePath, moved the script or deleted/moved the file,\nplease reset the \"actual=$actual\" line to \"actual=0\"\nor revert the changes.\n"
            _exit 6
        fi
    done
        echo -e "\nPlugin is already the newest Version\n"
    fi
fi

_exit 0
