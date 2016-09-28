#!/bin/bash

 exit 0

# You must be root to run this script
if [ "${UID}" -ne 0 ];
then
    log "Script executed without root permissions"
    echo "You must be root to run this program." >&2
    exit 3
fi

#Format the data disk
#D bash vm-disk-utils-0.1.sh -s   # ci devo mettere qalcosa per partizionare il disco


#### Defalt Paramenters ####

# Configure java parameters
export GET_JAVA_SITE="https:///sito"
export GET_JAVA_FILE="jdk-7u75-linux-x64.tar.gz"
export JAVA_TMP_PATH=/opt/jvm/jdk1.7.0_75

#  Configure ActiveMQ parameters
export GET_ACTIVEMQ_SITE="https:///sito"
export GET_ACTIVEMQ_FILE="file"
export ACTIVEMQ_TMP_PATH="/opt/activemq"

#  Configure Identity Server parameters
export GET_IS_SITE="https:///sito"
export GET_IS_FILE="file.tra.gz"
export IS_TMP_PATH="/opt/identityserver"
export IS_USER="ident_usr"


#  Configure Complex Event Processor parameters
export GET_CEP_SITE="https:///sito"
export GET_CEP_FILE="file.tra.gz"
export CEP_TMP_PATH="/opt/identityserver"
export CEP_USER="ident_usr"


#  Configure Comple Event Processor parameters
export GET_ESB_SITE="https:///sito"
export GET_ESB_FILE="file.tra.gz"
export ESB_TMP_PATH="/opt/identityserver"
export ESB_USER="ident_usr"


#############################



# TEMP FIX - Re-evaluate and remove when possible
# This is an interim fix for hostname resolution in current VM (If it does not exist add it)
grep -q "${HOSTNAME}" /etc/hosts
if [ $? == 0 ];
then
  echo "${HOSTNAME}found in /etc/hosts"
else
  echo "${HOSTNAME} not found in /etc/hosts"
  # Append it to the hsots file if not there
  echo "127.0.0.1 ${HOSTNAME}" >> /etc/hosts
fi




# Get today's date into YYYYMMDD format
now=$(date +"%Y%m%d")
 
# Get passed in parameters $1, $2, $3, $4, and others...
MASTERIP=""
SUBNETADDRESS=""
NODETYPE=""
REPLICATORPASSWORD=""   # a capire come viene passata


#Loop through options passed
while getopts :m:s:t:p: optname; do
    log "Option $optname set with value ${OPTARG}"
  case $optname in
    m)
      MASTERIP=${OPTARG}
      ;;
  	s) #Data storage subnet space
      SUBNETADDRESS=${OPTARG}
      ;;
    t) #Type of node (MASTER/SLAVE)
      NODETYPE=${OPTARG}
      ;;
    p) #Replication Password
      REPLICATORPASSWORD=${OPTARG}
      ;;
    h)  #show help
      help
      exit 2
      ;;
    \?) #unrecognized option - show help
      echo -e \\n"Option -${BOLD}$OPTARG${NORM} not allowed."
      help
      exit 2
      ;;
  esac
done



logger "NOW=$now MASTERIP=$MASTERIP SUBNETADDRESS=$SUBNETADDRESS NODETYPE=$NODETYPE"

###### JAVA STEPS

setup_java() {
	logger "Start installing java..."
	
	mkdir -p $JAVA_TMP_PATH 
	cd $JAVA_TMP_PATH 
    wget  $GET_JAVA_SITE$GET_JAVA_FILE
	ln -s $JAVA_TMP_PATH /opt/java
    gzip -dc $GET_JAVA_FILE | tar xf -
	
    #The jvm directory is used to organize all JDK/JVM versions in a single parent directory.	
	echo "export JAVA_HOME="/opt/java"" >> ~/bashrc
    echo "export PATH="$PATH:$JAVA_HOME/bin"" >> ~/bashrc
	
    logger "Done installing Java, javahome is: $JAVA_TMP_PATH linked in /opt/java"	
}



setup_java_repo() {
    add-apt-repository -y ppa:webupd8team/java
    apt-get -q -y update  > /dev/null
    echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
    echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections
    apt-get -q -y install oracle-java8-installer  > /dev/null


#da fare linkare a /opt/java e java7
     echo "export JAVA_HOME="/opt/java"" >> ~/bashrc
    echo "export PATH="$PATH:$JAVA_HOME/bin"" >> ~/bashrc

}



######





###### ACTIVEMQ STEPS


setup_activeMQ() {
	logger "Start installing ActiveMQ..."
	
	mkdir -p $ACTIVEMQ_TMP_PATH 
	cd $ACTIVEMQ_TMP_PATH 

	wget $GET_ACTIVEMQ_TMP_PATH$GET_ACTIVEMQ_FILE
	tar xvfz $GET_ACTIVEMQ_FILE

	
	ln -s $ACTIVEMQ_TMP_PATH /opt/ActiveMQ
	logger "Done installing ActiveMQ is installed in: $ACTIVEMQ_TMP_PATH  linked in /opt/ActiveMQ"	
	
	}
	
	
post_install_activeMQ() {
	cd 
 
	chmod 755 /opt/ActiveMQ/bin/activemq
    ln -snf /opt/ActiveMQ/bin/activemq /etc/init.d/activemq_service
    update-rc.d is_service defaults
	service activemq_service start
	
	
}


test_activeMQ() {

logger  netstat -an|grep 61616

#INFO  ActiveMQ JMS Message Broker (ID:apple-s-Computer.local-51222-1140729837569-0:0) has started

}


limits_activeMQ() {

#limits

echo "* soft  nofile  999999" >> /etc/security/limits.conf
echo "* hard  nofile  999999" >> /etc/security/limits.conf

echo "* soft  nproc  999999"  >> /etc/security/limits.conf
echo "* hard  nproc  999999"  >> /etc/security/limits.conf

echo "root  soft  nofile 999999" >> /etc/security/limits.conf
echo "root  hard  nofile 999999" >> /etc/security/limits.conf

}


sysctl_activeMQ() {
echo "fs.file-max = 999999                         " > /etc/sysctl.conf
echo "                                             " >> /etc/sysctl.conf
echo "net.core.netdev_max_backlog = 10240          " >> /etc/sysctl.conf
echo "net.core.somaxconn = 10240                   " >> /etc/sysctl.conf
echo "                                             " >> /etc/sysctl.conf
echo "net.ipv4.conf.all.accept_redirects = 0       " >> /etc/sysctl.conf
echo "net.ipv4.conf.all.accept_source_route = 0    " >> /etc/sysctl.conf
echo "net.ipv4.conf.all.rp_filter = 1              " >> /etc/sysctl.conf
echo "net.ipv4.conf.all.secure_redirects = 0       " >> /etc/sysctl.conf
echo "                                             " >> /etc/sysctl.conf
echo "net.ipv4.conf.default.accept_redirects = 0   " >> /etc/sysctl.conf
echo "net.ipv4.conf.default.accept_source_route = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.secure_redirects = 0   " >> /etc/sysctl.conf
echo "net.ipv4.conf.default.rp_filter = 1          " >> /etc/sysctl.conf
echo "                                             " >> /etc/sysctl.conf
echo "net.ipv4.ip_local_port_range = 1024 65535    " >> /etc/sysctl.conf
echo "                                             " >> /etc/sysctl.conf
echo "net.ipv4.icmp_echo_ignore_broadcasts = 1     " >> /etc/sysctl.conf
echo "                                             " >> /etc/sysctl.conf
echo "net.ipv4.tcp_fin_timeout = 15                " >> /etc/sysctl.conf
echo "net.ipv4.tcp_keepalive_probes = 5            " >> /etc/sysctl.conf
echo "net.ipv4.tcp_keepalive_time = 1800           " >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_orphans = 60000             " >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog = 10240         " >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_tw_buckets = 400000         " >> /etc/sysctl.conf
echo "net.ipv4.tcp_rmem = 4096 4096 16777216       " >> /etc/sysctl.conf
echo "net.ipv4.tcp_synack_retries = 3              " >> /etc/sysctl.conf
echo "net.ipv4.tcp_syncookies = 1                  " >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_recycle = 1                  " >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_reuse = 1                    " >> /etc/sysctl.conf
echo "net.ipv4.tcp_wmem = 4096 4096 16777216       " >> /etc/sysctl.conf



#rif https://gist.github.com/Jeraimee/3000974

}
	



#######################WS02 PRODUCT ####################


######   ESB STEPS

setup_ESB() {
	logger "Start installing Enterpris Service Bus..."
	
	mkdir -p $ESB_TMP_PATH 
	cd $ESB_TMP_PATH 

	wget $GET_ESB_TMP_PATH$GET_IS_FILE
	tar xvfz $GET_ESB_FILE

	ln -s $ESB_TMP_PATH /opt/WSO2/esb

 
    logger "Done installing Enterpris Service Bus installed in: $ESB_TMP_PATH   linked in /opt/WSO2/esb "	
	
}





post_install_ESB() {


# da verificare ssl
#/repository/conf/carbon.xml


#Crea Utente 
groupadd -g 1010 $ESB_USE	
useradd -u 1010 -g 1010 $ESB_USER

echo "#! /bin/sh                                                                 " > /opt/WSO2/esb/esb_service
echo "export JAVA_HOME="/opt/java/"                                              " >> /opt/WSO2/esb/esb_service
echo "                                                                           " >> /opt/WSO2/esb/esb_service
echo "startcmd='/opt/WSO2/esb/bin/wso2server.sh start > /dev/null &'             " >> /opt/WSO2/esb/esb_service
echo "restartcmd='/opt/WSO2/esb/bin/wso2server.sh restart > /dev/null &'         " >> /opt/WSO2/esb/esb_service
echo "stopcmd='/opt/WSO2/esb/bin/wso2server.sh stop > /dev/null &'               " >> /opt/WSO2/esb/esb_service
echo "                                                                           " >> /opt/WSO2/esb/esb_service
echo "case "$1" in                                                               " >> /opt/WSO2/esb/esb_service
echo "start)                                                                     " >> /opt/WSO2/esb/esb_service
echo "   echo "Starting WSO2 Application Server ..."                             " >> /opt/WSO2/esb/esb_service
echo "   su -c "${startcmd}" $ESB_USER                                           " >> /opt/WSO2/esb/esb_service
echo ";;                                                                         " >> /opt/WSO2/esb/esb_service
echo "restart)                                                                   " >> /opt/WSO2/esb/esb_service
echo "   echo "Re-starting WSO2 Application Server ..."                          " >> /opt/WSO2/esb/esb_service
echo "   su -c "${restartcmd}" $ESB_USER                                         " >> /opt/WSO2/esb/esb_service
echo ";;                                                                         " >> /opt/WSO2/esb/esb_service
echo "stop)                                                                      " >> /opt/WSO2/esb/esb_service
echo "   echo "Stopping WSO2 Application Server ..."                             " >> /opt/WSO2/esb/esb_service
echo "   su -c "${stopcmd}" $ESB_USER                                            " >> /opt/WSO2/esb/esb_service
echo ";;                                                                         " >> /opt/WSO2/esb/esb_service
echo "*)                                                                         " >> /opt/WSO2/esb/esb_service
echo "   echo "Usage: $0 {start|stop|restart}"                                   " >> /opt/WSO2/esb/esb_service
echo "exit 1                                                                     " >> /opt/WSO2/esb/esb_service
echo "esac                                                                       " >> /opt/WSO2/esb/esb_service



 
chmod a+x /opt/WSO2/esb/esb_service
ln -snf /opt/WSO2/esb/esb_service /etc/init.d/esb_service
update-rc.d esb_service defaults


service esb_service start
}



######   CEP STEPS

setup_CEP() {
	logger "Start installing Complex Event Processor..."
	
	mkdir -p $CEP_TMP_PATH 
	cd $CEP_TMP_PATH 

	wget $GET_CET_TMP_PATH$GET_IS_FILE
	tar xvfz $GET_CEP_FILE

	ln -s $CEP_TMP_PATH /opt/WSO2/cep

 
    logger "Done installing WSO2 Complex Event Processor installed in: $CEP_TMP_PATH   linked in /opt/WSO2/cep"	
	
}



post_install_CEP() {


# da verificare ssl
#/repository/conf/carbon.xml


#Crea Utente 
groupadd -g 1020 $CEP_USER	
useradd -u 1020 -g 1020 $CEP_USER

#Crea servizio
echo " #! /bin/sh                                                       " >  /opt/WSO2/cep/cep_service
echo "export JAVA_HOME="/opt/java/"                                     " >> /opt/WSO2/cep/cep_service
echo "                                                                  " >> /opt/WSO2/cep/cep_service
echo "startcmd='/opt/WSO2/cep/bin/wso2server.sh start > /dev/null &'    " >> /opt/WSO2/cep/cep_service
echo "restartcmd='/opt/WSO2/cep/bin/wso2server.sh restart > /dev/null &'" >> /opt/WSO2/cep/cep_service
echo "stopcmd='/opt/WSO2/cep/bin/wso2server.sh stop > /dev/null &'      " >> /opt/WSO2/cep/cep_service
echo "                                                                  " >> /opt/WSO2/cep/cep_service
echo "case "$1" in                                                      " >> /opt/WSO2/cep/cep_service
echo "start)                                                            " >> /opt/WSO2/cep/cep_service
echo "   echo "Starting WSO2 Complex Event Processor ..."               " >> /opt/WSO2/cep/cep_service
echo "   su -c "${startcmd}" $CEP_USER                                  " >> /opt/WSO2/cep/cep_service
echo ";;                                                                " >> /opt/WSO2/cep/cep_service
echo "restart)                                                          " >> /opt/WSO2/cep/cep_service
echo "   echo "Re-starting WSO2 Complex Event Processor ..."            " >> /opt/WSO2/cep/cep_service
echo "   su -c "${restartcmd}" $CEP_USER                                " >> /opt/WSO2/cep/cep_service
echo ";;                                                                " >> /opt/WSO2/cep/cep_service
echo "stop)                                                             " >> /opt/WSO2/cep/cep_service
echo "   echo "Stopping WSO2 Complex Event Processor ..."               " >> /opt/WSO2/cep/cep_service
echo "   su -c "${stopcmd}" $CEP_USER                                   " >> /opt/WSO2/cep/cep_service
echo ";;                                                                " >> /opt/WSO2/cep/cep_service
echo "*)                                                                " >> /opt/WSO2/cep/cep_service
echo "   echo "Usage: $0 {start|stop|restart}"                          " >> /opt/WSO2/cep/cep_service
echo "exit 1                                                            " >> /opt/WSO2/cep/cep_service
echo "esac                                                              " >> /opt/WSO2/cep/cep_service


 
chmod a+x /opt/WSO2/cep/cep_service
ln -snf /opt/WSO2/cep/cep_service /etc/init.d/cep_service
update-rc.d cep_service defaults


service cep_service start
}




#####




###### IS STEPS

setup_IS() {
	logger "Start installing java..."
	
	mkdir -p $IS_TMP_PATH 
	cd $IS_TMP_PATH 

	wget $GET_IS_TMP_PATH$GET_IS_FILE
	tar xvfz $GET_IS_FILE

	
	ln -s $IS_TMP_PATH /opt/WSO2/IdentityServer

 
    logger "Done installing Identiy Server installed in: $IS_TMP_PATH  linked in /opt/WSO2/IdentityServer"
	
}


post_install_IS() {


# da verificare ssl
#/repository/conf/carbon.xml


#Crea Utente 
groupadd -g 1030 $IS_USER	
useradd -u 1030 -g 1030 $IS_USER


#Crea servizio
echo " #! /bin/sh                                                                   " >> /opt/WSO2/IdentityServer/is_service
echo " export JAVA_HOME="/opt/java"                                                 " >> /opt/WSO2/IdentityServer/is_service
echo "                                                                              " >> /opt/WSO2/IdentityServer/is_service
echo " startcmd='/opt/WSO2/IdentityServer/bin/wso2server.sh start > /dev/null &'    " >> /opt/WSO2/IdentityServer/is_service
echo " restartcmd='/opt/WSO2/IdentityServer/bin/wso2server.sh restart > /dev/null &'" >> /opt/WSO2/IdentityServer/is_service
echo " stopcmd='/opt/WSO2/IdentityServer/bin/wso2server.sh stop > /dev/null &'      " >> /opt/WSO2/IdentityServer/is_service
echo "                                                                              " >> /opt/WSO2/IdentityServer/is_service
echo " case "$1" in                                                                 " >> /opt/WSO2/IdentityServer/is_service
echo " start)                                                                       " >> /opt/WSO2/IdentityServer/is_service
echo "    echo "Starting WSO2 Application Server ..."                               " >> /opt/WSO2/IdentityServer/is_service
echo "    su -c "${startcmd}" $IS_USER                                              " >> /opt/WSO2/IdentityServer/is_service
echo " ;;                                                                           " >> /opt/WSO2/IdentityServer/is_service
echo " restart)                                                                     " >> /opt/WSO2/IdentityServer/is_service
echo "    echo "Re-starting WSO2 Application Server ..."                            " >> /opt/WSO2/IdentityServer/is_service
echo "    su -c "${restartcmd}" $IS_USER                                            " >> /opt/WSO2/IdentityServer/is_service
echo " ;;                                                                           " >> /opt/WSO2/IdentityServer/is_service
echo " stop)                                                                        " >> /opt/WSO2/IdentityServer/is_service
echo "    echo "Stopping WSO2 Application Server ..."                               " >> /opt/WSO2/IdentityServer/is_service
echo "    su -c "${stopcmd}" $IS_USER                                               " >> /opt/WSO2/IdentityServer/is_service
echo " ;;                                                                           " >> /opt/WSO2/IdentityServer/is_service
echo " *)                                                                           " >> /opt/WSO2/IdentityServer/is_service
echo "    echo "Usage: $0 {start|stop|restart}"                                     " >> /opt/WSO2/IdentityServer/is_service
echo " exit 1                                                                       " >> /opt/WSO2/IdentityServer/is_service
echo " esac                                                                         " >> /opt/WSO2/IdentityServer/is_service
 
chmod a+x /opt/WSO2/IdentityServer/is_service
ln -snf /opt/WSO2/IdentityServer/is_service /etc/init.d/is_service
update-rc.d is_service defaults


service is_service start
}


######### GENERAL FO WSO2

sysctl_install_IS_CEP_ESB() {
echo "net.ipv4.tcp_fin_timeout = 30  " >> /etc/sysctl.conf
echo "fs.file-max = 2097152                    ">> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_recycle = 1              ">> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_reuse = 1                ">> /etc/sysctl.conf
echo "net.core.rmem_default = 524288           ">> /etc/sysctl.conf
echo "net.core.wmem_default = 524288           ">> /etc/sysctl.conf
echo "net.core.rmem_max = 67108864             ">> /etc/sysctl.conf
echo "net.core.wmem_max = 67108864             ">> /etc/sysctl.conf
echo "net.ipv4.tcp_rmem = 4096 87380 16777216  ">> /etc/sysctl.conf
echo "net.ipv4.tcp_wmem = 4096 65536 16777216  ">> /etc/sysctl.conf
echo "net.ipv4.ip_local_port_range = 1024 65535">> /etc/sysctl.conf
}


limits_IS_CEP_ESB() {
#limits

echo "* soft nofile 4096" >> /etc/security/limits.conf
echo "* hard nofile 65535" >> /etc/security/limits.conf

echo "* soft nproc 20000" >> /etc/security/limits.conf
echo "* hard nproc 20000" >> /etc/security/limits.conf

}



######





#setup_datadisks() {
#
#	MOUNTPOINT="/datadisks/disk1"
#
#	# Move database files to the striped disk
#	if [ -L /var/lib/kafkadir ];
#	then
#		logger "Symbolic link from /var/lib/kafkadir already exists"
#		echo "Symbolic link from /var/lib/kafkadir already exists"
#	else
#		logger "Moving  data to the $MOUNTPOINT/kafkadir"
#		echo "Moving PostgreSQL data to the $MOUNTPOINT/kafkadir"
#		service postgresql stop
#		mkdir $MOUNTPOINT/kafkadir
#		mv -f /var/lib/kafkadir $MOUNTPOINT/kafkadir
#
#		# Create symbolic link so that configuration files continue to use the default folders
#		logger "Create symbolic link from /var/lib/kafkadir to $MOUNTPOINT/kafkadir"
#		ln -s $MOUNTPOINT/kafkadir /var/lib/kafkadir
#	fi
#}



setup_product() {

	if [ "$NODETYPE" == "ACTIVEMQ" ];
	then
	 logger "------Start Install ActiveMQ------"
	 #Impostazione base di sistema
     limits_activeMQ
     sysctl_activeMQ
     
     #setup of ActiveMQ
     setup_activeMQ
	 post_install_activeMQ
     test_activeMQ
	fi
	logger "------Done configuring ACTIVEMQ-------"
	
	
	if [ "$NODETYPE" == "IS" ];
	then
	 sysctl_install_IS_CEP_ESB
	 limits_IS_CEP_ESB
	 setup_IS
	 post_install_IS
	
	fi
	logger "------Done configuring IS-------"

	
		
    if [ "$NODETYPE" == "CEP" ];
	then
	 sysctl_install_IS_CEP_ESB
	 limits_IS_CEP_ESB
	 setup_CEP
	 post_install_CEP
	fi
	logger "------Done configuring CEP -------"   # per la cluster conviene usare puppet
	
			
    if [ "$NODETYPE" == "ESB" ];
	then
	 sysctl_install_IS_CEP_ESB
	 limits_IS_CEP_ESB
	 setup_ESB
	 post_install_ESB
	fi
	logger "------Done configuring CEP -------"
	
	
}



# MAIN ROUTINE
#aggiorna i repo
apt-get -y update

#Setup Java
setup_java
setup_product