WRF_HYDRO_CI_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

##Set variables for each directory for easy change later
testRepoDir=$WRF_HYDRO_CI_DIR/repos/test
refRepoDir=$WRF_HYDRO_CI_DIR/repos/reference
toolboxDir=$WRF_HYDRO_CI_DIR/toolbox
testsDir=$WRF_HYDRO_CI_DIR/tests
domainDir=$WRF_HYDRO_CI_DIR/test_domain

cd $testRepoDir/wrf_hydro_test/trunk/NDHMS/
theBinary=`pwd`/Run/`ls -rt Run | tail -n1`

cd $refRepoDir/wrf_hydro_nwm/trunk/NDHMS/
theRefBinary=`pwd`/Run/`ls -rt Run | tail -n1`

###Source necessary tool scripts
source $toolboxDir/ncoScripts/ncFilters.sh

###Source test scripts
source $testsDir/comp_nco.sh

###################################
## COMPILE test repo
if [[ "${1}" == 'all' ]] || [[ "${1}" == 'compile' ]]; then
	echo
	echo -e "\e[0;49;32m-----------------------------------\e[0m"
	echo -e "\e[7;49;32mCompiling the new binary.\e[0m"

	cd $testRepoDir/wrf_hydro_test/trunk/NDHMS/
	echo
	#cp /root/wrf_hydro_tools/utilities/use_env_compileTag_offline_NoahMP.sh .

	## 2 is gfort  >>>> FRAGILE <<<<
	#./use_env_compileTag_offline_NoahMP.sh 2 || { echo "Compilation failed."; exit 1; }

	#Set environment variables. This will likely need to be hard coded so that people don't change compile time options
	./setEnvar.sh
	./configure 2
	./compile_offline_NoahMP.sh || { echo "Compilation failed."; exit 1; }

	echo -e "\e[5;49;32mCompilation of test fork successful under GNU!\e[0m"
	sleep 2
fi

###################################
## run test repo
if [[ "${1}" == 'all' ]] || [[ "${1}" == 'run' ]]; then

	###################################
	## Test Run = run 1
	echo
	echo -e "\e[0;49;32m-----------------------------------\e[0m"
	echo -e "\e[7;49;32mRunning test fork\e[0m"
	cd $domainDir/run.1.new
	cp $theBinary .
	nCoresFull=2
	ls 
	mpirun -np $nCoresFull ./`basename $theBinary` 1> `date +'%Y-%m-%d_%H-%M-%S.stdout'` 2> `date +'%Y-%m-%d_%H-%M-%S.stderr'` 
	echo foo
	ls
	## did the model finish successfully?
	## This grep is >>>> FRAGILE <<<<. But fortran return codes are un reliable. 
	nSuccess=`grep 'The model finished successfully.......' diag_hydro.* | wc -l`
	if [[ $nSuccess -ne $nCoresFull ]]; then
	    echo Run test fork failed.
	    exit 2
	fi
fi

###################################
## Reference Run = run 2:
## THis requires compiling the old binary, which in theory is not an issue. 
if [[ "${1}" == 'all' ]] || [[ "${1}" == 'compile' ]]; then
	echo
	echo -e "\e[0;49;32m-----------------------------------\e[0m"
	echo -e "\e[7;49;32mCompiling the reference (old) code\e[0m"

	cd $refRepoDir/wrf_hydro_nwm/trunk/NDHMS/
	echo
	#cp /root/wrf_hydro_tools/utilities/use_env_compileTag_offline_NoahMP.sh .

	## 2 is gfort  >>>> FRAGILE <<<<
	#./use_env_compileTag_offline_NoahMP.sh 2 || { echo "Compilation failed."; exit 3; }

	#Set environment variables. This will likely need to be hard coded so that people don't change compile time options
	./setEnvar.sh
	./configure 2
	./compile_offline_NoahMP.sh || { echo "Compilation failed."; exit 1; }

fi

###################################
## run reference repo
if [[ "${1}" == 'all' ]] || [[ "${1}" == 'run' ]]; then

	echo
	echo -e "\e[0;49;32m-----------------------------------\e[0m"
	echo -e "\e[7;49;32mRunning run.2.old\e[0m"
	cd $domainDir/run.2.old
	cp $theRefBinary .
	nCoresFull=2
	mpirun -np $nCoresFull ./`basename $theRefBinary` 1> `date +'%Y-%m-%d_%H-%M-%S.stdout'` 2> `date +'%Y-%m-%d_%H-%M-%S.stderr'` 

	## did the model finish successfully?
	## This grep is >>>> FRAGILE <<<<. But fortran return codes are un reliable. 
	nSuccess=`grep 'The model finished successfully.......' diag_hydro.* | wc -l`
	if [[ $nSuccess -ne $nCoresFull ]]; then
	    echo Run run.2.old failed.
	    exit 4
	fi

	echo
	echo -e "\e[0;49;32m-----------------------------------\e[0m"
	echo -e "\e[7;49;32mComparing the results.\e[0m"


	comp_nco run.2.old run.1.new
fi

###################################
## Run 3: perfect restarts
###################################
## run restart tests
if [[ "${1}" == 'all' ]] || [[ "${1}" == 'restart' ]]; then
	echo
	echo -e "\e[0;49;32m-----------------------------------\e[0m"
	echo -e "\e[7;49;32mRunning run.3.restart_new\e[0m"

	cd $domainDir/run.3.restart_new
	cp $theBinary .
	nCoresFull=2
	mpirun -np $nCoresFull ./`basename $theBinary` 1> `date +'%Y-%m-%d_%H-%M-%S.stdout'` 2> `date +'%Y-%m-%d_%H-%M-%S.stderr'` 

	## did the model finish successfully?
	## This grep is >>>> FRAGILE <<<<. But fortran return codes are un reliable. 
	nSuccess=`grep 'The model finished successfully.......' diag_hydro.* | wc -l`
	if [[ $nSuccess -ne $nCoresFull ]]; then
	    echo Run run.1.new failed.
	    exit 2
	fi

	cd ../
	echo
	echo -e "\e[0;49;32m-----------------------------------\e[0m"
	echo -e "\e[7;49;32mComparing the results.\e[0m"
	comp_nco run.1.new run.3.restart_new
fi

###################################
## Run 4: ncores test
if [[ "${1}" == 'all' ]] || [[ "${1}" == 'ncores' ]]; then
	echo
	echo -e "\e[0;49;32m-----------------------------------\e[0m"
	echo -e "\e[7;49;32mRunning run.4.ncores_new\e[0m"

	cd $domainDir/run.4.ncores_new
	cp $theBinary .
	nCoresTest=3
	mpirun -np $nCoresTest ./`basename $theBinary` 1> `date +'%Y-%m-%d_%H-%M-%S.stdout'` 2> `date +'%Y-%m-%d_%H-%M-%S.stderr'` 

	cd ../
	echo
	echo -e "\e[0;49;32m-----------------------------------\e[0m"
	echo -e "\e[7;49;32mComparing the results.\e[0m"
	comp_nco run.1.new run.4.ncores_new
fi

#exec /bin/bash
echo -e "\e[7;49;32mSuccess. ${1} tests appear successful.\e[0m"

#exec /bin/bash

exit 0