#!/bin/bash

## Source this script.
## After informative message: exit on failure with non-zero status.
## Do not exit otherwise.

theHelp='
NCAR/wrf_hydro_tests: config.sh

The following envionrment variables are required:
* GITHUB_USERNAME
* GITHUB_AUTHTOKEN for that user on github (see below for details)

The following environment variables are optional:
[*] testFork,              A named fork on github.         
                           Default = ${GITHUB_USERNAME}/wrf_hydro_nwm
[*] testBranchCommit,      A branch or commit on testFork. 
                           Default = master
[*] referenceFork,         A named fork on github.         
                           Default = NCAR/wrf_hydro_nwm
[*] referenceBranchCommit, A branch or commit on referenceFork. 
                           Default = master   

Example usages: 
TODO JLM
docker run -e GITHUB_USERNAME=$GITHUB_USERNAME \
           -e GITHUB_AUTHTOKEN=$GITHUB_AUTHTOKEN \
           wrfhydro/testing 

TODO JLM
docker run -e GITHUB_USERNAME=$GITHUB_USERNAME \
           -e GITHUB_AUTHTOKEN=$GITHUB_AUTHTOKEN \
           -e testFork=NCAR/wrf_hydro_nwm \
           -e testBranchCommit=4612e9c \  
           -e referenceFork=NCAR/wrf_hydro_nwm \
           -e referenceBranchCommit=f2db0b55c5c9dab60646a38f8536001907952767 \
           wrfhydro/testing local


Here is a suggestion on how to manage the GITHUB environment variables. 
Configure your ~/.bashrc with the following

export GITHUB_AUTHTOKEN=`cat ~/.github_authtoken 2> /dev/null`
export GITHUB_USERNAME=jmccreight


The file ~/.github_authtoken should be READ-ONLY BY OWNER 500. For example:

jamesmcc@chimayo[736]:~/WRF_Hydro/wrf_hydro_docker/testing> ls -l ~/.github_authtoken 
-r--------  1 jamesmcc  rap  40 Nov  3 10:18 /Users/jamesmcc/.github_authtoken

The file contains the user authtoken from github with no carriage return or other 
whitespace in the file. See 

https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/

for information on getting your github authtoken.
'

if [[ "${1}" == '--help' ]]; then echo "$theHelp"; exit 0; fi

###################################
#Setup directory structure where invoked.
export TEST_DIR=`pwd`
##Set variables for each directory for easy change later
export testRepoDir=$TEST_DIR/repos/test
export refRepoDir=$TEST_DIR/repos/reference
export toolboxDir=$TEST_DIR/wrf_hydro_test/toolbox
export questionsDir=$TEST_DIR/wrf_hydro_tests/questions
export domainDir=$TEST_DIR/test_domain

#Make directories that don't exist already
[ -d $testRepoDir ] || mkdir -p $testRepoDir
[ -d $refRepoDir ] || mkdir -p $refRepoDir

#[ -d $domainDir/run.1.new ]        || mkdir -p $domainDir/run.1.new
#[ -d $domainDir/run.2.old ]        || mkdir -p $domainDir/run.2.old
#[ -d $domainDir/run.3.restart ]    || mkdir -p $domainDir/run.3.restart
#[ -d $domainDir/run.4.ncores_new ] || mkdir -p $domainDir/run.4.ncores_new

###################################
##Setup github authitcation
doExit=0
if [[ -z ${GITHUB_USERNAME} ]]; then
    echo "The required environment variable GITHUB_USERNAME has 
          not been passed to the container. Please try 
          'docker run wrfhydro/testing --help' 
          for help. Exiting"
    doExit=1
fi
if [[ -z ${GITHUB_AUTHTOKEN} ]] ; then
    echo "The required environment variable GITHUB_AUTHTOKEN has 
          not been passed to the container. Please try 
          'docker run wrfhydro/testing --help' 
          for help. Exiting"
    doExit=1
fi
if [[ $doExit -eq 1 ]]; then exit 1; fi

authInfo=${GITHUB_USERNAME}:${GITHUB_AUTHTOKEN}
if [[ -z ${testFork} ]]; then testFork=${GITHUB_USERNAME}/wrf_hydro_nwm; fi
if [[ -z ${testBranchCommit} ]]; then testBranchCommit=master; fi
if [[ -z ${referenceFork} ]]; then referenceFork=NCAR/wrf_hydro_nwm; fi
if [[ -z ${referenceBranchCommit} ]]; then referenceBranchCommit=master; fi

###################################
###Clone reference fork into repos directory
cd $refRepoDir
# reference fork
echo -e "\e[0;49;32m-----------------------------------\e[0m"
echo -e "\e[7;49;32mReference fork: $referenceFork\e[0m"
git clone https://${authInfo}@github.com/$referenceFork $refRepoDir    
git checkout $referenceBranchCommit || \
    { echo "Unsuccessful checkout of $referenceBranchCommit from $referenceFork."; exit 1; }
echo -e "\e[0;49;32mRepo in\e[0m `pwd`"
echo -e "\e[0;49;32mReference branch:\e[0m    `git branch`"
echo -e "\e[0;49;32mReference commit:\e[0m"
git log -n1

###################################
## Check if running in circleCI or locally.
## This is specified using environment variables passed to docker
## If running locally, clone specified test fork, otherwise in circleCI the current PR/Commit
## is used as test.
if [[ -z ${CIRCLECI} ]]; then 
    echo
    ##Local 
    cd $testRepoDir    
    # git clone specified test fork
    echo -e "\e[0;49;32m-----------------------------------\e[0m"
    echo -e "\e[7;49;32mTest fork: $testFork\e[0m"
    git clone https://${authInfo}@github.com/$testFork $testRepoDir
    git checkout $testBranchCommit || \
        { echo "Unsuccessful checkout of $testBranchCommit from $testFork."; exit 1; }
    echo -e "\e[0;49;32mRepo moved to\e[0m `pwd`"
    echo -e "\e[0;49;32mTest branch:\e[0m    `git branch`"
    echo -e "\e[0;49;32mTesting commit:\e[0m"
    git log -n1
    
fi

