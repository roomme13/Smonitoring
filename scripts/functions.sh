#!/usr/bin/env bash

source ./scripts/env.sh > /dev/null 2>&1 || source env.sh > /dev/null 2>&1

# Global functions
function Done() {
    echo -e '==> \E[32m'"\033\done\033[0m"
}

function Skip() {
    echo -e '==> \E[32m'"\033\skipped\033[0m"
}

function Failed() {
    echo -e '==> \E[91m'"\033\ failed\033[0m"
}

function GetConfirmation() {
    while true
    do
    echo -e '\E[96m'"\033\ Do you want to continue (Yes or No): \033[0m \c"
    read  CONFIRMATION
    case $CONFIRMATION in
    Yes|yes|YES|YeS|yeS|yEs) break ;;
    No|no|NO|nO)
    echo "Exiting..."
    sleep 1
    exit
    ;;
    *) echo "" && echo -e '\E[91m'"\033\Please type Yes or No \033[0m"
    esac
    done
    echo "Continue..."
    sleep 1
}

function EchoDash() {
echo "----------------------------------------------------------------"
}

function FinisMessage() {
        echo ""
        echo -e '\E[1m'"\033\Zabbix installation successfuly finished.\033[0m"
        echo "-----------------------------------------------------------------"
        echo ""
        echo -e '\E[1m'"\033\Zabbix UI is accessible at https://ip:8443 \033[0m"
        echo -e '\E[1m'"\033\Username: Admin \033[0m"
        echo -e '\E[1m'"\033\Pasword: zabbix (Don't forget to change it!)\033[0m"
        echo ""
        echo -e '\E[1m'"\033\Grafana UI is accessible at https://ip:3000 \033[0m"
        echo -e '\E[1m'"\033\Username: admin \033[0m"
        echo -e '\E[1m'"\033\Pasword: zabbix (Don't forget to change it too!)\033[0m"
        echo "-----------------------------------------------------------------"
        echo ""
}

function InstallDependenciesCentOS() {
        # Install dependencies for CentOS
        echo -e ""
        echo -e '\E[96m'"\033\- Install dependencies.\033[0m"
        sleep 1
        #check if epel repo installed
        EPEL=$(rpm -qa |egrep epel-release || echo "epel-release is not installed")
        if [[ $EPEL == "epel-release is not installed" ]]; then
            yum install -y epel-release
            echo -n "Enable epel repo:" && \
            echo -ne "\t\t\t\t" && Done
        else
        echo -n "Epel repo is already enabled:" && \
        echo -ne "\t\t\t" && Skip
        fi

        #check if jq installed
        JQ=$(rpm -qa |egrep "^jq" || echo "jq is not installed")
        if [[ $JQ == "jq is not installed" ]]; then
            yum install -y jq
            echo -n "Install jq:" && \
            echo -ne "\t\t\t\t" && Done
            sleep 1
            EchoDash
        else
        echo -n "jq is already installed:" && \
        echo -ne "\t\t\t" && Skip
        sleep 1
        EchoDash
        fi

        #check if openssl installed
        OSSL=$(rpm -qa |egrep "^openssl" || echo "openssl is not installed")
        if [[ $OSSL == "openssl is not installed" ]]; then
            yum install -y openssl
            echo -n "Install openssl:" && \
            echo -ne "\t\t\t\t" && Done
            sleep 1
            EchoDash
        else
        echo -n "openssl is already installed:" && \
        echo -ne "\t\t\t" && Skip
        sleep 1
        EchoDash
        fi

        # Install docker engine if it's not installed
        echo -e ""
        echo -e '\E[96m'"\033\- Install Docker CE. \033[0m"

        check_docker=$(rpm -qa |egrep "docker-ce" || echo "Docker not installed")
        if [[ $check_docker == "Docker not installed" ]]; then
            yum install -y yum-utils device-mapper-persistent-data lvm2
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            yum -y install docker-ce
            systemctl enable docker && systemctl start docker
            echo -n "Docker installation:" && \
            echo -ne "\t\t\t" && Done
            sleep 1
            EchoDash
        else
            echo -n "Docker engine is already installed." && \
            echo -ne "\t\t" && Skip
            sleep 1
            EchoDash
        fi

        # Install docker-compose if it's not installed
        echo -e ""
        echo -e '\E[96m'"\033\- Install Docker Compose. \033[0m"
        if [ ! -x "/usr/local/bin/docker-compose" ]; then
            LATEST_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r '.tag_name')
            curl -L "https://github.com/docker/compose/releases/download/$LATEST_VERSION/docker-compose-$(uname -s)-$(uname -m)" > /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose
            echo -n "Docker Compose installation:" && \
            echo -ne "\t\t\t" && Done
            sleep 1
            EchoDash
        else
            echo -n "Docker compose is already installed." && \
            echo -ne "\t\t" && Skip
            sleep 1
            EchoDash
        fi
    }

function InstallDependenciesUbuntu() {
        # Install dependencies for Ubuntu
        echo -e ""
        echo -e '\E[96m'"\033\- Install dependencies.\033[0m"
        sleep 1
        apt update
        #check if jq installed
        JQ=$(dpkg -l jq > /dev/null 2>&1 || echo "jq is not installed")
        if [[ $JQ == "jq is not installed" ]]; then
            apt install -y jq
            echo -n "Install jq:" && \
            echo -ne "\t\t\t\t" && Done
            sleep 1
            EchoDash
        else
        echo -n "jq is already installed:" && \
        echo -ne "\t\t\t" && Skip
        sleep 1
        EchoDash
        fi

        #check if openssl installed
        OSSL=$(dpkg -l openssl > /dev/null 2>&1 || echo "openssl is not installed")
        if [[ $OSSL == "openssl is not installed" ]]; then
            apt install -y openssl
            echo -n "Install openssl:" && \
            echo -ne "\t\t\t\t" && Done
            sleep 1
            EchoDash
        else
        echo -n "openssl is already installed:" && \
        echo -ne "\t\t\t" && Skip
        sleep 1
        EchoDash
        fi

        # Install docker engine if it's not installed
        echo -e ""
        echo -e '\E[96m'"\033\- Install Docker CE. \033[0m"

        check_docker=$(dpkg -l docker-ce > /dev/null 2>&1 || echo "Docker not installed")
        if [[ $check_docker == "Docker not installed" ]]; then
            apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo \
            "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
            $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            apt-get update
            apt-get install -y docker-ce docker-ce-cli containerd.io
            systemctl enable docker && systemctl start docker
            echo -n "Docker installation:" && \
            echo -ne "\t\t\t" && Done
            sleep 1
            EchoDash
        else
            echo -n "Docker engine is already installed." && \
            echo -ne "\t\t" && Skip
            sleep 1
            EchoDash
        fi

        # Install docker-compose if it's not installed
        echo -e ""
        echo -e '\E[96m'"\033\- Install Docker Compose. \033[0m"
        if [ ! -x "/usr/local/bin/docker-compose" ]; then
            LATEST_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r '.tag_name')
            curl -L "https://github.com/docker/compose/releases/download/$LATEST_VERSION/docker-compose-$(uname -s)-$(uname -m)" > /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose
            echo -n "Docker Compose installation:" && \
            echo -ne "\t\t\t" && Done
            sleep 1
            EchoDash
        else
            echo -n "Docker compose is already installed." && \
            echo -ne "\t\t" && Skip
            sleep 1
            EchoDash
        fi
    }

function CheckZabbix() {
    cd $BASEDIR
    status=$(docker-compose ps |egrep zabbix-server |egrep " Up " || echo "Not deployed")
    }

function GetZabbixAuthToken() {
    ZBX_AUTH_TOKEN=$(curl --insecure -s \
    -H "Accept: application/json" \
    -H "Content-Type:application/json" \
     -X POST -d \
     '{"jsonrpc":"2.0",
     "method":"user.login",
     "params":
     {"user":"Admin",
     "password":"zabbix"},
     "auth":null,"id":0}' \
     $ZBX_SERVER_URL/api_jsonrpc.php |jq .result |tr -d '"')
    }

# Create a host group for Windows servers
function CreateHostGroups() {

for i in "${HOST_GROUPS[@]}"
do
PD=$(cat <<EOF
{
    "jsonrpc": "2.0",
    "method": "hostgroup.create",
    "params": {
        "name": "$i"
    },
    "auth": "$ZBX_AUTH_TOKEN",
    "id": 0
}
EOF
)

POST=$(curl -s --insecure \
-H "Accept: application/json" \
-H "Content-Type:application/json" \
-X POST --data "$PD" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

if [[ "$POST" == *"error"* ]]; then
    if [[ "$POST" == *"already exists"* ]]; then
        echo -n "$i already exists." && \
        echo -ne "\t\t\t" && Skip
    else
        echo -n "An error occured. Please check the error output." && \
        echo $POST |jq .
        echo -ne "\t\t" && Failed
    fi
else
echo -n "$i:" && \
echo -ne "\t\t\t\t\t" && Done
sleep 1
fi
done
}

# Get host group ids
function HostGroupIDSPD() {
cat <<EOF
{ "jsonrpc": "2.0",
          "method": "hostgroup.get",
          "params": {
            "output": "extend",
            "filter": {
                "name": [
                    "${HOST_GROUPS[0]}",
                    "${HOST_GROUPS[1]}"
                ]
            }
          },
    "auth": "$ZBX_AUTH_TOKEN",
    "id": 0
}
EOF
}

##########  NOTIFICATIOS CONFIGURATIONS ##########

# Email related functions
function GetSMTPNotifAnswer() {
    while true
        do
        echo -e '\E[96m'"\033\ Do you want to enable email notification ? (Yes or No): \033[0m \c"
        read  SMTPEnable
        case $SMTPEnable in
        Yes|yes|YES|YeS|yeS|yEs) break ;;
        No|no|NO|nO) break ;;
        *) echo -e '\E[91m'"\033\ Please type Yes or No \033[0m"
        esac
        done
        if [[ "$SMTPEnable" =~ $yesPattern ]]; then

            # SMTP server configuration to send notifications
            echo -e ""
            echo -e '\E[96m'"\033\- Zabbix SMTP settings. \033[0m"
            echo -e '\E[1m'"\033\ SMTP server settings will be configured to send notifications emails.\033[0m"
            echo -e '\E[1m'"\033\ Please provide your SMTP server IP( or host), Port, sender email\033[0m"
            echo -e '\E[1m'"\033\ security prefrence and auth credentials\033[0m"
            sleep 1
            echo ""
            echo -e '\E[96m'"\033\ Enter SMTP Server Address: \033[0m \c"
            read SMTPServer

            echo -e '\E[96m'"\033\ Enter  SMTP Server Port:\033[0m \c"
            read SMTPServerPort
            Integer='^[0-9]+$'
            if ! [[ $SMTPServerPort =~ $Integer ]] ; then
                while ! [[ "$SMTPServerPort" =~ $Integer ]]
                do
                    echo -e '\E[91m'"\033\ Port number should be a number! Please re-enter: \033[0m \c"
                    read SMTPServerPort
                done
            fi

            echo -e '\E[96m'"\033\ Enter SMTP Hello: \033[0m \c"
            read SMTPHello

            echo -e '\E[96m'"\033\ Enter Sender Email: \033[0m \c"
            read SMTPEmail

            while true
                do
                echo -e '\E[96m'"\033\ Enable connection security ? (Yes or No): \033[0m \c"
                read  SecureConnection
                case $SecureConnection in
                Yes|yes|YES|YeS|yeS|yEs) break ;;
                No|no|NO|nO) break ;;
                *) echo -e '\E[91m'"\033\ Please type Yes or No \033[0m"
                esac
                done
            if [ "$SecureConnection" == "No" ] || [  "$SecureConnection" == "no" ] || [  "$SecureConnection" == "NO" ] || [  "$SecureConnection" == "nO" ]; then
                SecureConnection=0
            else
                while true
                do
                echo -e '\E[96m'"\033\ Enter connection security type? (STARTTLS or SSL/TLS): \033[0m \c"
                read SecurityType
                case $SecurityType in
                STARTTLS) break ;;
                SSL/TLS|SSL|TLS) break ;;
                *) echo -e '\E[91m'"\033\Invalid connection security type. Please type STARTTLS or SSL/TLS.\033[0m"
                esac
                done

                if [ "$SecurityType" == "STARTTLS" ]; then
                    SecureConnection=1
                else
                    SecureConnection=2
                fi
            fi

            while true
            do
            echo -e '\E[96m'"\033\ Enable authentication ? (Yes or No): \033[0m \c"
            read  Authentication
            case $Authentication in
            Yes|yes|YES|YeS|yeS|yEs) break ;;
            No|no|NO|nO) break ;;
            *) echo -e '\E[91m'"\033\Please type Yes or No \033[0m"
            esac
            done

            if [ "$Authentication" == "No" ] || [  "$Authentication" == "no" ] || [  "$Authentication" == "NO" ] || [  "$Authentication" == "nO" ]; then
                Authentication=0
            else
                Authentication=1
                echo -e '\E[96m'"\033\ Enter username for SMTP Auth: \033[0m \c"
                read SMTPUsername
                if [[ -z "$SMTPUsername" ]] ; then
                    while [ -z "$SMTPUsername" ]
                    do
                        echo -e '\E[91m'"\033\ Username required! Please enter the username:\033[0m \c"
                        read SMTPUsername
                    done
                fi

                echo -e '\E[96m'"\033\ Enter password for SMTP Auth: \033[0m \c"
                read SMTPPassword
                if [[ -z "$SMTPPassword" ]] ; then
                    while [ -z "$SMTPPassword" ]
                    do
                        echo -e '\E[91m'"\033\ Password required! Please enter the password: \033[0m \c"
                        read SMTPPassword
                    done
                fi
            fi

            # Set admin email to get notifications
            echo -e ""
            echo -e '\E[96m'"\033\- Admin email notification settings. \033[0m"
            echo -e '\E[1m'"\033\ This will set the admin email address to get zabbix alerts,\033[0m"
            echo -e '\E[1m'"\033\ and enable the trigger action for the notifications...\033[0m"
            echo ""
            echo -e '\E[96m'"\033\ Enter an email address for admin user: \033[0m \c"
            read SentTo

            if [[ -z "$SentTo" ]] ; then
                while [ -z "$SentTo" ]
                do
                    echo -e '\E[91m'"\033\ Email address is required!\033[0m"
                    echo -e '\E[91m'"\033\ Please enter an email:\033[0m \c"
                    read SentTo
                done
            fi
        else
            echo -n "Email notification configuration:" && \
            echo -ne "\t\t" && Skip
            sleep 1
        fi
}

function SMTPConfigPD() {
cat <<EOF
{
    "jsonrpc": "2.0",
    "method": "mediatype.update",
    "params": {
        "mediatypeid": "1",
        "status": 0,
        "smtp_server": "$SMTPServer",
        "smtp_port": "$SMTPServerPort",
        "smtp_helo": "$SMTPHello",
        "smtp_email": "$SMTPEmail",
        "smtp_security": $SecureConnection,
        "smtp_authentication": $Authentication,
        "username": "$SMTPUsername",
        "passwd": "$SMTPPassword"
    },
    "auth": "$ZBX_AUTH_TOKEN",
    "id": 0
}
EOF
}

# Slack related functions
function GetSlackNotifAnswer(){
    while true
    do
        echo -e '\E[96m'"\033\ Do you want to enable slack notifications ? (Yes or No): \033[0m \c"
        read  SlackEnable
        case $SlackEnable in
        Yes|yes|YES|YeS|yeS|yEs) break ;;
        No|no|NO|nO) break ;;
        *) echo -e '\E[91m'"\033\ Please type Yes or No \033[0m"
        esac
    done
    if [[ "$SlackEnable" =~ $yesPattern ]]; then
        echo -e ""
        echo -e '\E[96m'"\033\- Slack settings. \033[0m"
        echo -e '\E[1m'"\033\This section, enables slack notification. \033[0m"

        echo -e '\E[1m'"\033\An slack app must be created within your Slack.com workspace \033[0m"
        echo -e '\E[1m'"\033\as explained at https://git.zabbix.com/projects/ZBX/repos/zabbix/browse/templates/media/slack \033[0m"
        echo -e '\E[1m'"\033\Please create the slack app now and provide its Bot User OAuth Access Token, and slack channel name.\033[0m"
        echo ""
        sleep 1

        # Get Bot Token
        echo -e '\E[96m'"\033\ Enter your Bot User OAuth Access Token: \033[0m \c"
        read SlackBotToken
        while [[ -z $SlackBotToken ]]
        do
          echo -e '\E[91m'"\033\ Please enter your Bot User OAuth Access Token:\033[0m \c"
          read SlackBotToken
        done

        # Get slack channel name to send notifications
        echo -e '\E[96m'"\033\ Enter your slack channel: \033[0m \c"
        read SlackChannel
        while [[ -z $SlackChannel ]]
        do
          echo -e '\E[91m'"\033\ Please enter your channel:\033[0m \c"
          read SlackChannel
        done
        SlackChannel="#$SlackChannel"
    else
        echo -n "Slack notification configuration:" && \
        echo -ne "\t\t" && Skip
        sleep 1
    fi
}

# Globl Macro for ZABBIX.URL
function ZabbixUrlGlobalMacroPD(){
cat <<EOF
{
    "jsonrpc": "2.0",
    "method": "usermacro.createglobal",
    "params":  {
        "macro": "{\$ZABBIX.URL}",
        "value": "https://$ZBX_PUBLIC_IP:8443/"
    },
    "auth": "$ZBX_AUTH_TOKEN",
    "id": 1
}
EOF
}

# Slack bot token
function SetSlackBotTokenPD(){
cat <<EOF
{
    "jsonrpc": "2.0",
    "method": "mediatype.update",
    "params": {
        "mediatypeid": "9",
        "status": 0,
        "parameters": [
                {
                    "name": "zabbix_url",
                    "value": "https://$ZBX_PUBLIC_IP:8443"
                },
                {
                    "name": "bot_token",
                    "value": "$SlackBotToken"
                },
                {
                    "name": "channel",
                    "value": "{ALERT.SENDTO}"
                },
                {
                    "name": "slack_mode",
                    "value": "alarm"
                },
                {
                    "name": "slack_as_user",
                    "value": "true"
                },
                {
                    "name": "event_tags",
                    "value": "{EVENT.TAGS}"
                },
                {
                    "name": "event_nseverity",
                    "value": "{EVENT.NSEVERITY}"
                },
                {
                    "name": "event_value",
                    "value": "{EVENT.VALUE}"
                },
                {
                    "name": "event_update_status",
                    "value": "{EVENT.UPDATE.STATUS}"
                },
                {
                    "name": "event_date",
                    "value": "{EVENT.DATE}"
                },
                {
                    "name": "event_time",
                    "value": "{EVENT.TIME}"
                },
                {
                    "name": "event_severity",
                    "value": "{EVENT.SEVERITY}"
                },
                {
                    "name": "event_opdata",
                    "value": "{EVENT.OPDATA}"
                },
                {
                    "name": "event_id",
                    "value": "{EVENT.ID}"
                },
                {
                    "name": "trigger_id",
                    "value": "{TRIGGER.ID}"
                },
                {
                    "name": "trigger_description",
                    "value": "{TRIGGER.DESCRIPTION}"
                },
                {
                    "name": "host_name",
                    "value": "{HOST.HOST}"
                },
                {
                    "name": "event_update_date",
                    "value": "{EVENT.UPDATE.DATE}"
                },
                {
                    "name": "event_update_time",
                    "value": "{EVENT.UPDATE.TIME}"
                },
                {
                    "name": "event_recovery_date",
                    "value": "{EVENT.RECOVERY.DATE}"
                },
                {
                    "name": "event_recovery_time",
                    "value": "{EVENT.RECOVERY.TIME}"
                },
                {
                    "name": "alert_message",
                    "value": "{ALERT.MESSAGE}"
                },
                {
                    "name": "alert_subject",
                    "value": "{ALERT.SUBJECT}"
                },
                {
                    "name": "discovery_host_dns",
                    "value": "{DISCOVERY.DEVICE.DNS}"
                },
                {
                    "name": "discovery_host_ip",
                    "value": "{DISCOVERY.DEVICE.IPADDRESS}"
                },
                {
                    "name": "event_source",
                    "value": "{EVENT.SOURCE}"
                },
                {
                    "name": "host_conn",
                    "value": "{HOST.CONN}"
                }
            ]
    },
    "auth": "$ZBX_AUTH_TOKEN",
    "id": 1
}
EOF
}

# User media type configuration
function AdminSmtpMediaTypePD() {
cat <<EOF
{
    "jsonrpc": "2.0",
    "method": "user.update",
    "params": {
        "userid": "1",
        "user_medias": [
            {
                "mediatypeid": "1",
                "sendto": "$SentTo",
                "active": 0,
                "severity": 63,
                "period": "1-7,00:00-24:00"
            }
        ]
    },
    "auth": "$ZBX_AUTH_TOKEN",
    "id": 0
}
EOF
}

function AdminSlackMediaTypePD(){
cat <<EOF
{
    "jsonrpc": "2.0",
    "method": "user.update",
    "params": {
        "userid": "1",
        "user_medias": [
            {
                "mediatypeid": "9",
                "sendto": "$SlackChannel",
                "active": 0,
                "severity": 63,
                "period": "1-7,00:00-24:00"
            }
        ]
    },
    "auth": "$ZBX_AUTH_TOKEN",
    "id": 0
}
EOF
}

function AdminSmtpSlackMediaTypePD(){
cat <<EOF
{
    "jsonrpc": "2.0",
    "method": "user.update",
    "params": {
        "userid": "1",
        "user_medias": [
            {
                "mediatypeid": "9",
                "sendto": "$SlackChannel",
                "active": 0,
                "severity": 63,
                "period": "1-7,00:00-24:00"
            },
            {
                "mediatypeid": "1",
                "sendto": "$SentTo",
                "active": 0,
                "severity": 63,
                "period": "1-7,00:00-24:00"
            }
        ]
    },
    "auth": "$ZBX_AUTH_TOKEN",
    "id": 0
}
EOF
}


# Notification trigger action for administrators
function NotifTriggerPD() {
cat <<EOF
{
    "jsonrpc": "2.0",
    "method": "action.update",
    "params": {
        "actionid": 3,
        "status": 0
    },
    "auth": "$ZBX_AUTH_TOKEN",
    "id": 0
}
EOF
}

function AddEdgeTemmplate() {
cat <<EOF
{
    "jsonrpc": "2.0",
    "method": "configuration.import",
    "params": {
        "format": "json",
        "rules": {
            "discoverRules": {
                "createMissing": true,
                "updateExisting": true
            },
            "hosts": {
                "createMissing": true,
                "updateExisting": true
            },
            "items": {
                "createMissing": true,
                "updateExisting": true
            },
            "templates": {
                "createMissing": true,
                "updateExisting": true
            },
            "groups": {
                "createMissing": true,
                "updateExisting": true
            }
        },
        "source": "{\"zabbix_export\":{\"version\":\"5.4\",\"date\":\"2021-07-21T14:23:20Z\",\"groups\":[{\"uuid\":\"a0fac18b824e454c8f3a546cdfea2455\",\"name\":\"SafousEdge\"}],\"templates\":[{\"uuid\":\"0bd17bb796f040c88f26db88c5354d4e\",\"template\":\"SafousEdgeMonitoringEdge\",\"name\":\"SafousEdgeMonitoringEdge\",\"groups\":[{\"name\":\"SafousEdge\"}],\"items\":[{\"uuid\":\"28c7738ec9fb4856aae92e054f8b6b87\",\"name\":\"TotalCPUProcessSeconds\",\"type\":\"DEPENDENT\",\"key\":\"cpu.total.s\",\"delay\":\"0\",\"value_type\":\"FLOAT\",\"units\":\"s\",\"preprocessing\":[{\"type\":\"PROMETHEUS_PATTERN\",\"parameters\":[\"process_cpu_seconds_total\",\"\"]}],\"master_item\":{\"key\":\"edge.metrics\"},\"tags\":[{\"tag\":\"Components\",\"value\":\"Edge\"},{\"tag\":\"Section\",\"value\":\"Process\"},{\"tag\":\"Zabbix_Type\",\"value\":\"Items\"}]},{\"uuid\":\"0ae81d55232b441db114421226bd18bf\",\"name\":\"EdgeMetrics\",\"type\":\"HTTP_AGENT\",\"key\":\"edge.metrics\",\"delay\":\"5s\",\"history\":\"0\",\"trends\":\"0\",\"value_type\":\"TEXT\",\"timeout\":\"30s\",\"url\":\"{$EDGE_DOMAIN}\",\"tags\":[{\"tag\":\"Components\",\"value\":\"Edge\"},{\"tag\":\"Zabbix_Type\",\"value\":\"Items\"}]},{\"uuid\":\"ad27c2a4625a4a5b9c28d85e3289a101\",\"name\":\"MaxFileDescriptor\",\"type\":\"DEPENDENT\",\"key\":\"fds.max\",\"delay\":\"0\",\"preprocessing\":[{\"type\":\"PROMETHEUS_PATTERN\",\"parameters\":[\"process_max_fds\",\"\"]}],\"master_item\":{\"key\":\"edge.metrics\"},\"tags\":[{\"tag\":\"Components\",\"value\":\"Edge\"},{\"tag\":\"Section\",\"value\":\"Process\"},{\"tag\":\"Zabbix_Type\",\"value\":\"Items\"}]},{\"uuid\":\"bbf51b6aa3ef431e85173c4b0c1e86da\",\"name\":\"ProcessStartTime\",\"type\":\"DEPENDENT\",\"key\":\"start.time\",\"delay\":\"0\",\"trends\":\"0\",\"value_type\":\"TEXT\",\"preprocessing\":[{\"type\":\"PROMETHEUS_PATTERN\",\"parameters\":[\"process_start_time_seconds\",\"\"]}],\"master_item\":{\"key\":\"edge.metrics\"},\"tags\":[{\"tag\":\"Components\",\"value\":\"Edge\"},{\"tag\":\"Section\",\"value\":\"Process\"},{\"tag\":\"Zabbix_Type\",\"value\":\"Items\"}]},{\"uuid\":\"b82d2b7ec853479ab3a22d99cd14c2df\",\"name\":\"VirtualMemory\",\"type\":\"DEPENDENT\",\"key\":\"vm.byte\",\"delay\":\"0\",\"trends\":\"0\",\"value_type\":\"TEXT\",\"preprocessing\":[{\"type\":\"PROMETHEUS_PATTERN\",\"parameters\":[\"process_virtual_memory_bytes\",\"\"]}],\"master_item\":{\"key\":\"edge.metrics\"},\"tags\":[{\"tag\":\"Components\",\"value\":\"Edge\"},{\"tag\":\"Section\",\"value\":\"Process\"},{\"tag\":\"Zabbix_Type\",\"value\":\"Items\"}]},{\"uuid\":\"4793b77c1bf74be8a5a9fd2f4314b4db\",\"name\":\"VirtualMemoryMax\",\"type\":\"DEPENDENT\",\"key\":\"vm.max\",\"delay\":\"0\",\"trends\":\"0\",\"value_type\":\"TEXT\",\"preprocessing\":[{\"type\":\"PROMETHEUS_PATTERN\",\"parameters\":[\"process_virtual_memory_max_bytes\",\"\"]}],\"master_item\":{\"key\":\"edge.metrics\"},\"tags\":[{\"tag\":\"Components\",\"value\":\"Edge\"},{\"tag\":\"Section\",\"value\":\"Process\"},{\"tag\":\"Zabbix_Type\",\"value\":\"Items\"}]},{\"uuid\":\"cb517c9642784a678eddbd8ed80a81e5\",\"name\":\"MemoryResident\",\"type\":\"DEPENDENT\",\"key\":\"vm.res\",\"delay\":\"0\",\"trends\":\"0\",\"value_type\":\"TEXT\",\"preprocessing\":[{\"type\":\"PROMETHEUS_PATTERN\",\"parameters\":[\"process_resident_memory_bytes\",\"\"]}],\"master_item\":{\"key\":\"edge.metrics\"},\"tags\":[{\"tag\":\"Components\",\"value\":\"Edge\"},{\"tag\":\"Section\",\"value\":\"Process\"},{\"tag\":\"Zabbix_Type\",\"value\":\"Items\"}]}],\"discovery_rules\":[{\"uuid\":\"30159eb2d1c14a2baca166daf9ff9a5f\",\"name\":\"RouterConnDiscover\",\"type\":\"DEPENDENT\",\"key\":\"lld.connup\",\"delay\":\"0\",\"lifetime\":\"7d\",\"item_prototypes\":[{\"uuid\":\"6db231c0081447e9bf28f0073056a71e\",\"name\":\"{#TYPE}connectionupon{#TENANT}\",\"type\":\"DEPENDENT\",\"key\":\"conn.up.[{#TYPE}.{#TENANT}]\",\"delay\":\"0\",\"trends\":\"0\",\"value_type\":\"TEXT\",\"description\":\"{#HELP}\",\"preprocessing\":[{\"type\":\"PROMETHEUS_PATTERN\",\"parameters\":[\"{#METRIC}{tenant=\\\"{#TENANT}\\\",type=\\\"{#TYPE}\\\"}\",\"\"]}],\"master_item\":{\"key\":\"edge.metrics\"},\"tags\":[{\"tag\":\"Components\",\"value\":\"Edge\"},{\"tag\":\"Section\",\"value\":\"Router\"},{\"tag\":\"Zabbix_Type\",\"value\":\"Items\"}]}],\"master_item\":{\"key\":\"edge.metrics\"},\"lld_macro_paths\":[{\"lld_macro\":\"{#HELP}\",\"path\":\"$['help']\"},{\"lld_macro\":\"{#METRIC}\",\"path\":\"$['name']\"},{\"lld_macro\":\"{#TENANT}\",\"path\":\"$.labels['tenant']\"},{\"lld_macro\":\"{#TYPE}\",\"path\":\"$.labels['type']\"}],\"preprocessing\":[{\"type\":\"PROMETHEUS_TO_JSON\",\"parameters\":[\"router_conn_open{tenant=~\\\".*\\\",type=~\\\".*\\\"}\"]}]},{\"uuid\":\"28d7fc01843d468fa705cc0609d78f1a\",\"name\":\"RouterLifetimeDiscover\",\"type\":\"DEPENDENT\",\"key\":\"lld.lifetime\",\"delay\":\"0\",\"lifetime\":\"7d\",\"item_prototypes\":[{\"uuid\":\"3a6164ca3ee24d7a9795c26b1a292048\",\"name\":\"{#TYPE}lifetimeon{#TENANT}by{#LE}s\",\"type\":\"DEPENDENT\",\"key\":\"lifetime.[{#TYPE}.{#TENANT}.{#LE}]\",\"delay\":\"0\",\"units\":\"s\",\"preprocessing\":[{\"type\":\"PROMETHEUS_PATTERN\",\"parameters\":[\"{#METRIC}{tenant=\\\"{#TENANT}\\\",type=\\\"{#TYPE}\\\",le=\\\"{#LE}\\\"}\",\"\"]}],\"master_item\":{\"key\":\"edge.metrics\"},\"tags\":[{\"tag\":\"Components\",\"value\":\"Edge\"},{\"tag\":\"Section\",\"value\":\"Router\"},{\"tag\":\"Zabbix_Type\",\"value\":\"Items\"}]}],\"master_item\":{\"key\":\"edge.metrics\"},\"lld_macro_paths\":[{\"lld_macro\":\"{#HELP}\",\"path\":\"$['help']\"},{\"lld_macro\":\"{#LE}\",\"path\":\"$.labels['le']\"},{\"lld_macro\":\"{#METRIC}\",\"path\":\"$['name']\"},{\"lld_macro\":\"{#TENANT}\",\"path\":\"$.labels['tenant']\"},{\"lld_macro\":\"{#TYPE}\",\"path\":\"$.labels['type']\"}],\"preprocessing\":[{\"type\":\"PROMETHEUS_TO_JSON\",\"parameters\":[\"router_conn_lifetime_seconds_bucket{tenant=~\\\".*\\\",type=~\\\".*\\\",le=~\\\".*\\\"}\"]}]},{\"uuid\":\"1e4a2e8d257d4c85a80d778b50db2ef7\",\"name\":\"RouterReadThroughputDiscover\",\"type\":\"DEPENDENT\",\"key\":\"lld.thrput.r\",\"delay\":\"0\",\"lifetime\":\"7d\",\"item_prototypes\":[{\"uuid\":\"22721237f3f4426bbbb6c8bf40552b60\",\"name\":\"{#TYPE}readthroughputon{#TENANT}\",\"type\":\"DEPENDENT\",\"key\":\"thrgpt.r.[{#TYPE}.{#TENANT}]\",\"delay\":\"0\",\"trends\":\"0\",\"value_type\":\"TEXT\",\"preprocessing\":[{\"type\":\"PROMETHEUS_PATTERN\",\"parameters\":[\"{#METRIC}{tenant=\\\"{#TENANT}\\\",type=\\\"{#TYPE}\\\"}\",\"\"]}],\"master_item\":{\"key\":\"edge.metrics\"},\"tags\":[{\"tag\":\"Components\",\"value\":\"Edge\"},{\"tag\":\"Section\",\"value\":\"Router\"},{\"tag\":\"Zabbix_Type\",\"value\":\"Items\"}]}],\"master_item\":{\"key\":\"edge.metrics\"},\"lld_macro_paths\":[{\"lld_macro\":\"{#HELP}\",\"path\":\"$['help']\"},{\"lld_macro\":\"{#METRIC}\",\"path\":\"$['name']\"},{\"lld_macro\":\"{#TENANT}\",\"path\":\"$.labels['tenant']\"},{\"lld_macro\":\"{#TYPE}\",\"path\":\"$.labels['type']\"}],\"preprocessing\":[{\"type\":\"PROMETHEUS_TO_JSON\",\"parameters\":[\"router_conn_throughput_read{tenant=~\\\".*\\\",type=~\\\".*\\\"}\"]}]},{\"uuid\":\"0558bf93f89e466c8d26c91970d92f67\",\"name\":\"RouterWriteThroughputDiscover\",\"type\":\"DEPENDENT\",\"key\":\"lld.thrput.w\",\"delay\":\"0\",\"lifetime\":\"7d\",\"item_prototypes\":[{\"uuid\":\"4f4e66f194df4507beada9a3671bb581\",\"name\":\"{#TYPE}writethroughputon{#TENANT}\",\"type\":\"DEPENDENT\",\"key\":\"thrgpt.w.[{#TYPE}.{#TENANT}]\",\"delay\":\"0\",\"trends\":\"0\",\"value_type\":\"TEXT\",\"preprocessing\":[{\"type\":\"PROMETHEUS_PATTERN\",\"parameters\":[\"{#METRIC}{tenant=\\\"{#TENANT}\\\",type=\\\"{#TYPE}\\\"}\",\"\"]}],\"master_item\":{\"key\":\"edge.metrics\"},\"tags\":[{\"tag\":\"Components\",\"value\":\"Edge\"},{\"tag\":\"Section\",\"value\":\"Router\"},{\"tag\":\"Zabbix_Type\",\"value\":\"Items\"}]}],\"master_item\":{\"key\":\"edge.metrics\"},\"lld_macro_paths\":[{\"lld_macro\":\"{#HELP}\",\"path\":\"$['help']\"},{\"lld_macro\":\"{#METRIC}\",\"path\":\"$['name']\"},{\"lld_macro\":\"{#TENANT}\",\"path\":\"$.labels['tenant']\"},{\"lld_macro\":\"{#TYPE}\",\"path\":\"$.labels['type']\"}],\"preprocessing\":[{\"type\":\"PROMETHEUS_TO_JSON\",\"parameters\":[\"router_conn_throughput_write{tenant=~\\\".*\\\",type=~\\\".*\\\"}\"]}]}],\"tags\":[{\"tag\":\"Component\",\"value\":\"Edge\"},{\"tag\":\"Service\",\"value\":\"Safous\"},{\"tag\":\"Type\",\"value\":\"Template\"}],\"macros\":[{\"macro\":\"{$EDGE_DOMAIN}\"}]}]}}"
    },
    "auth": "$ZBX_AUTH_TOKEN",
    "id": 1
}
EOF
}

# API related
function GetAPIUserGroupIDPD() {
cat <<EOF
{
    "jsonrpc": "2.0",
    "method": "usergroup.get",
    "params": {
        "output": "extend",
        "status": 0
    },
    "auth": "$ZBX_AUTH_TOKEN",
    "id": 1
}
EOF
}

# Add user group for zabbix api user
function CreateAPIUserGroupPD() {
cat <<EOF
{
    "jsonrpc": "2.0",
    "method": "usergroup.create",
    "params": {
        "name": "API Users",
        "gui_access": 3,
		"users_status": 0,
		"rights": [
			{
				"permission": 2,
		    	"id": "2"
		    },
		    {
				"permission": 2,
		    	"id": "4"
		    },
			{
				"permission": 2,
		    	"id": "5"
		    },
			{
				"permission": 2,
		    	"id": "6"
		    },
			{
				"permission": 2,
		    	"id": "7"
		    },
		    {
		    	"permission": 2,
		    	"id": "${GRP_IDS_ARRAY[0]}"
		    },
		    {
		    	"permission": 2,
		    	"id": "${GRP_IDS_ARRAY[1]}"
		    }
		]
    },
    "auth": "$ZBX_AUTH_TOKEN",
    "id": 0
}
EOF
}

function CreateAPIUserPD() {
cat <<EOF
{
    "jsonrpc": "2.0",
    "method": "user.create",
    "params": {
        "alias": "apiuser",
        "passwd": "zabbix",
        "roleid": "1",
        "usrgrps": [
            {
                "usrgrpid": "$API_USERS_GROUP_ID"
            }
        ]
    },
    "auth": "$ZBX_AUTH_TOKEN",
    "id": 0
}
EOF
}

# Zabbix server Host ID
function GetHostIDPD() {
cat <<EOF
{
    "jsonrpc": "2.0",
    "method": "host.get",
    "params": {
        "output": "extend"
    },
    "auth": "$ZBX_AUTH_TOKEN",
    "id": 0
}
EOF
}

function UpdateHostInterfacePD() {
cat <<EOF
{
    "jsonrpc": "2.0",
    "method": "hostinterface.update",
    "params": {
        "interfaceid": "1",
        "hostids": "$ZBX_AGENT_HOST_ID",
        "type": 1,
        "useip": 0,
        "dns": "zabbix-agent",
        "port": 10050,
        "main": 1
    },
    "auth": "$ZBX_AUTH_TOKEN",
    "id": 0
}
EOF
}

function EnableZbxAgentonServerPD() {
cat <<EOF
{
    "jsonrpc": "2.0",
    "method": "host.update",
    "params": {
        "hostid": "$ZBX_AGENT_HOST_ID",
        "host": "$ZBX_AGENT_CONTAINER_ID",
        "name": "Zabbix server",
        "status": 0
    },
    "auth": "$ZBX_AUTH_TOKEN",
    "id": 0
}
EOF
}

### Grafana related
function CreateGRFAPIKey() {
    GRF_API_KEY=$(curl --insecure -s \
    -H "Accept: application/json" \
    -H "Content-Type:application/json" \
    -X POST -d \
     '{
	    "name":"zabbix-api-key",
	    "role": "Admin"
      }' \
     $GRF_SERVER_URL/api/auth/keys |jq .key |tr -d '"')
}

function CreateZbxDataSourcePD() {
cat <<EOF
{
        "orgId": 1,
        "name": "zabbix",
        "type": "alexanderzobnin-zabbix-datasource",
        "typeLogoUrl": "public/plugins/alexanderzobnin-zabbix-datasource/img/zabbix_app_logo.svg",
        "access": "proxy",
        "url": "https://zabbix-web-nginx-mysql:8443/api_jsonrpc.php",
        "password": "zabbix",
        "user": "apiuser",
        "database": "",
        "basicAuth": false,
        "isDefault": true,
        "jsonData": {
            "dbConnection": {
                "enable": false
            },
            "keepCookies": [],
            "password": "zabbix",
            "tlsSkipVerify": true,
            "username": "apiuser",
            "cacheTTL": "5m"
        },
        "readOnly": false
}
EOF
}

