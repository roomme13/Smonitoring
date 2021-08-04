#!/usr/bin/env bash

PATH=$PATH:/usr/local/bin

source ./scripts/env.sh > /dev/null 2>&1 || source env.sh > /dev/null 2>&1
source ./scripts/functions.sh > /dev/null 2>&1 || source functions.sh > /dev/null 2>&1

case "$1" in
    init)
        ########## ZABBIX DEPLOYMENT ##########
        echo ""
        echo -e '\E[1m'"\033\DOCKERIZED ZABBIX DEPLOYMENT AND CONFIGURATION SCRIPT \033[0m"
        echo -e '\E[1m'"\033\Version: 3.0.0"
        echo ""
        echo -e '\E[1m'"\033\By this script, the steps listed below will be done: \033[0m"
        echo ""
        echo -e '\E[1m'"\033\- Latest Docker(CE) engine and docker-compose installation. \033[0m"
        echo -e '\E[1m'"\033\- Dockerized zabbix server deployment by using the official zabbix docker images and compose file. \033[0m"
        echo -e '\E[1m'"\033\- Required packages installation like epel-repo and jq.\033[0m"
        echo -e '\E[1m'"\033\- Import template. \033[0m"
        echo -e '\E[1m'"\033\- Grafana integration and deployment of some useful custom dashboards. \033[0m"
        echo -e '\E[1m'"\033\- SMTP settings and admin email configurations. (Optional) \033[0m"
        echo -e '\E[1m'"\033\- Slack integration. (Optional) \033[0m"
        echo ""
        echo -e '\E[1m'"\033\NOTE: Any deployed zabbix server containers will be taken down and re-created.\033[0m"
        GetConfirmation

        # Detect Linux Distribution
        DIST=$(awk -F= '/^PRETTY_NAME/{print $2}' /etc/os-release)
        if [[ $DIST == *"Ubuntu"* ]]; then
            InstallDependenciesUbuntu
        elif [[ $DIST == *"CentOS Linux 7"* ]]; then
            InstallDependenciesCentOS
        else
            echo "This installation script supports Ubuntu Server or CentOS 7..."
            exit 1
        fi

        # Create a self signed SSL cert for zabbix frontend.
        echo -e ""
        echo -e '\E[96m'"\033\- Deploy self signed SSL cert for Zabbix UI. \033[0m"
        sleep 1
        if [ ! -e $BASEDIR/../zbx_env/etc/ssl/nginx/ssl.crt ] && [ ! -e $BASEDIR/../zbx_env/etc/ssl/nginx/ssl.key ]; then
            openssl req -x509 -nodes -newkey rsa:2048 -days 1365 \
              -out $BASEDIR/../zbx_env/etc/ssl/nginx/ssl.crt \
              -keyout $BASEDIR/../zbx_env/etc/ssl/nginx/ssl.key \
              -subj "/C=RO/ST=TR/L=IST/O=IT/CN=zabbix-server.local"
            openssl dhparam -out $BASEDIR/../zbx_env/etc/ssl/nginx/dhparam.pem 2048
            chmod 644 $BASEDIR/../zbx_env/etc/ssl/nginx/ssl.key
            echo -n "Self signed SSL deployment for zabbix:" && \
            echo -ne "\t\t\t" && Done
            sleep 1
            EchoDash
        else
            echo -n "Zabbix UI SSL cert is already deployed" && \
            echo -ne "\t\t" && Skip
            sleep 1
            EchoDash
        fi

        # Create a self signed SSL cert for grafana frontend.
        echo -e ""
        echo -e '\E[96m'"\033\- Deploy self signed SSL cert for Grafana UI. \033[0m"
        sleep 1
        if [ ! -e $BASEDIR/../zbx_env/etc/ssl/grafana/ssl.crt ] && [ ! -e $BASEDIR/../zbx_env/etc/ssl/grafana/ssl.key ]; then
            openssl req -x509 -nodes -newkey rsa:2048 -days 1365 \
              -out $BASEDIR/../zbx_env/etc/ssl/grafana/ssl.crt \
              -keyout $BASEDIR/../zbx_env/etc/ssl/grafana/ssl.key \
              -subj "/C=RO/ST=TR/L=IST/O=IT/CN=grafana-server.local"
            openssl dhparam -out $BASEDIR/../zbx_env/etc/ssl/grafana/dhparam.pem 2048
            echo -n "Self signed SSL deployment for grafana:" && \
            echo -ne "\t\t\t" && Done
            sleep 1
            EchoDash
        else
            echo -n "Grafana UI SSL cert is already deployed" && \
            echo -ne "\t\t" && Skip
            sleep 1
            EchoDash
        fi

        # Generate random password for Mysql root and zabbix users
        openssl rand -base64 18 > $BASEDIR/../.MYSQL_PASSWORD
        openssl rand -base64 18 > $BASEDIR/../.MYSQL_ROOT_PASSWORD

        # Check if zabbix-server is already up
        CheckZabbix
        if [[ "$status" == "Not deployed" ]]; then
            echo -e ""
            echo -e '\E[96m'"\033\- Dockerized zabbix server deployment. \033[0m"
            sleep 1
            EchoDash
            docker-compose up -d

            # Wait until zabbix getting up
            for (( i=0; i<23; ++i)); do
                GetZabbixAuthToken
                [[ "$ZBX_AUTH_TOKEN" != "null" ]] && [[ -n "$ZBX_AUTH_TOKEN" ]] && break
                echo -e '\E[1m'"\033\- Waiting for 5 seconds to zabbix server getting be ready... ( $(expr $(echo 23) - $i) retries left ) \033[0m"
                sleep 5
            done
            if [[ "$ZBX_AUTH_TOKEN" == "null" ]] || [[ -z "$ZBX_AUTH_TOKEN" ]]; then
                echo -e "\e[91m- [ERROR]: Zabbix server still not ready after 2 minutes. Please check zabbix server container.\e[0m"
                exit 1
            fi

            echo ""
            echo -n "Zabbix deployment:" && \
            echo -ne "\t\t\t\t" && Done
            sleep 1
            EchoDash
        else
            echo -e ""
            echo -e '\E[91m'"\033\WARNING:\033[0m"
            echo -e '\E[91m'"\033\Zabbix server is already running. It will be taken down and recreated!\033[0m"
            echo -e '\E[91m'"\033\Note: Your persistent data won't be deleted.\033[0m"
            echo ""
            GetConfirmation
            docker-compose down && docker-compose up -d
            # Wait until zabbix getting up
            GetZabbixAuthToken
            echo -e '\E[1m'"\033\- Waiting for Zabbix server getting ready... \033[0m"
            while [ "$ZBX_AUTH_TOKEN" == "null" ] || [ -z "$ZBX_AUTH_TOKEN" ]
            do
                sleep 2
                GetZabbixAuthToken
                echo -e '\E[1m'"\033\- Waiting for Zabbix server getting ready... \033[0m"
            done
            echo ""
            echo -n "Zabbix deployment:" && \
            echo -ne "\t\t\t" && Done
            sleep 1
            EchoDash
        fi

        ########## TEMPLATE CONFIGURATIONS ##########
        echo -e ""
        echo -e '\E[96m'"\033\- Add Safous Edge Template.\033[0m"
        sleep 1

        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data @$BASEDIR/../zabbix_templates/edge.json "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

        if [[ "$POST" == *"error"* ]]; then
            if [[ "$POST" == *"already exists"* ]]; then
                echo -n "Safous Edge Template already imported."
                echo -ne "\t\t" && Skip
            else
                echo ""
                echo -n "Import Safous Edge Template"
                echo -ne "\t\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo $POST |jq .
                sleep 1
            fi
        else
            echo -n "Import Safous Edge Template" && \
            echo -ne "\t\t" && Done
            sleep 1
        fi

        sleep 1
        EchoDash

        ########## HOST GROUPS CONFIGURATIONS ##########
        # This creates all defined host groups in environment file
        echo -e ""
        echo -e '\E[96m'"\033\- Create hosts groups.\033[0m"
        sleep 1
        CreateHostGroups
        sleep 1
        EchoDash

        ########## ZABBIX API USER CONFIGURATIONS ##########
        echo -e ""
        echo -e '\E[96m'"\033\- Create a read-only user for Zabbix API.\033[0m"
        sleep 1

        # Generate an array variable and fill it with created group IDs for API user read permission
        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$(HostGroupIDSPD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)
        GRP_IDS=$(echo $POST |jq .result[].groupid |tr -d '"' |sed ':a;N;$!ba;s/\n/ /g')
        unset IFS
        GRP_IDS_ARRAY=( $GRP_IDS )

        # Create a group for API user
        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$(CreateAPIUserGroupPD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

        if [[ "$POST" == *"error"* ]]; then
            if [[ "$POST" == *"already exists"* ]]; then
                echo -n "API user group is already exists"
                echo -ne "\t" && Skip
            else
                echo ""
                echo -n "Create API user group:"
                echo -ne "\t\t\t\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo $POST |jq .
                sleep 1
            fi
        else
            echo -n "Create API user group:"
            echo -ne "\t\t\t\t" && Done
            sleep 1
        fi

        # Get API User Group ID
        API_USERS_GROUP_ID=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$(GetAPIUserGroupIDPD)" "$ZBX_SERVER_URL/api_jsonrpc.php" \
        |jq '.result[] | select(.name == "API Users") | .usrgrpid' | tr -d '"')

        # Create an user for API
        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$(CreateAPIUserPD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

        if [[ "$POST" == *"error"* ]]; then
            if [[ "$POST" == *"already exists"* ]]; then
                echo -n "API user is already exists"
                echo -ne "\t\t\t" && Skip
            else
                echo ""
                echo -n "Create API user:"
                echo -ne "\t\t\t\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo $POST |jq .
                sleep 1
            fi
        else
            echo -n "Create API user:"
            echo -ne "\t\t\t\t" && Done
            sleep 1
            EchoDash
        fi

        ########## ZABBIX AGENT CONFIGURATIONS ##########
        echo -e ""
        echo -e '\E[96m'"\033\- Monitor Zabbix Server itself.\033[0m"
        sleep 1

        # Get Zabbix server Host ID
        GetZabbixAuthToken
        ZBX_AGENT_HOST_ID=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$(GetHostIDPD)" "$ZBX_SERVER_URL/api_jsonrpc.php" \
        |jq '.result[] | select(.name == "Zabbix server") | .hostid' | tr -d '"')

        # Change zabbix server's host interface to use DNS instead of IP
        # in order to connect dockerized zabbix-agent.
        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$(UpdateHostInterfacePD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

        if [[ "$POST" == *"error"* ]]; then
                echo ""
                echo -n "Update Zabbix host interface:"
                echo -ne "\t\t\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo $POST |jq .
                sleep 1
        else
            echo -n "Update Zabbix host interface:"
            echo -ne "\t\t\t" && Done
            sleep 1
        fi

        # Get zabbix-agent container ID and enable it to become a monitored host.
        ZBX_AGENT_CONTAINER_ID=$(docker ps |egrep zabbix-agent |awk '{print $1}')

        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$(EnableZbxAgentonServerPD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

        if [[ "$POST" == *"error"* ]]; then
                echo ""
                echo -n "Enable Zabbix agent:"
                echo -ne "\t\t\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo $POST |jq .
                sleep 1
        else
            echo -n "Enable Zabbix agent:"
            echo -ne "\t\t\t\t" && Done
            sleep 1
            EchoDash
        fi

        ########## GRAFANA CONFIGURATIONS ##########
        echo -e ""
        echo -e '\E[96m'"\033\- Grafana configurations.\033[0m"
        sleep 1
        # Wait for grafana server to be ready
        for (( i=0; i<23; ++i)); do
            GRAFANA_HEALTH=$(curl -s --insecure https://localhost:3000/healthz)
            [ "$GRAFANA_HEALTH" == "Ok" ] && break
            echo -e '\E[1m'"\033\- Waiting for 5 seconds to grafana server getting be ready... ( $(expr $(echo 23) - $i) retries left ) \033[0m"
            sleep 5
        done

        if [[ "$GRAFANA_HEALTH" != "Ok" ]]; then
                echo -e "\e[91m- [ERROR]: Grafana server still not ready after 2 minutes. Please check grafana container.\e[0m"
                exit 1
        fi
        # Enable zabbix datasource plugin
        POST=$(curl --insecure -s \
        -H "Content-Type:application/x-www-form-urlencoded" \
        -X POST $GRF_SERVER_URL/api/plugins/alexanderzobnin-zabbix-app/settings?enabled=true)

        if [[ "$POST" == *"error"* ]]; then
                echo ""
                echo -n "Enable grafana zabbix plugin:"
                echo -ne "\t\t\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo $POST |jq .
                sleep 1
        else
            echo -n "Enable grafana zabbix plugin:"
            echo -ne "\t\t\t" && Done
            sleep 1
        fi

        # Create a grafana API key
        CreateGRFAPIKey
        if [[ "$GRF_API_KEY" == "null" ]]; then
            # Delete existing key
            GRF_API_KEY_ID=$(curl -s --insecure -XGET $GRF_SERVER_URL/api/auth/keys |jq .[].id)
            curl -s --insecure -XDELETE $GRF_SERVER_URL/api/auth/keys/$GRF_API_KEY_ID >/dev/null
            # and recreate
            CreateGRFAPIKey
        fi
        echo -n "Create a grafana API key:" && \
        echo -ne "\t\t\t" && Done
        sleep 1

        # Create Zabbix Datasource
        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -H "Authorization:Bearer $GRF_API_KEY" \
        -X POST --data "$(CreateZbxDataSourcePD)" "$GRF_SERVER_URL/api/datasources"  |jq .)

        if [[ "$POST" == *"error"* ]]; then
            if [[ "$POST" == *"already exists"* ]]; then
                echo -n "Grafana datasource is already exists" && \
                echo -ne "\t\t\t" && Skip
            else
                echo ""
                echo -n "Create Grafana datasource for zabbix:"
                echo -ne "\t\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo $POST |jq .
                sleep 1
            fi
        else
            echo -n "Create Grafana datasource for zabbix:"
            echo -ne "\t\t" && Done
            sleep 1
        fi

        # Get uid of the dashboard
        ZABBIX_DASHBOARD_ID=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -H "Authorization:Bearer $GRF_API_KEY" \
        -X GET "$GRF_SERVER_URL/api/search?folderIds=0&query=&starred=false" |jq .[].uid |tr -d '"')

        # Delete existing Zabbix Server Dashboard
        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -H "Authorization:Bearer $GRF_API_KEY" \
        -X DELETE "$GRF_SERVER_URL/api/dashboards/uid/$ZABBIX_DASHBOARD_ID"  |jq .)

        if [[ "$POST" == *"Not found"* ]]; then
                echo -n "Default zabbix dashboard not found."
                echo -ne "\t\t" && Skip
        elif [[ "$POST" == *"error"* ]]; then
                echo ""
                echo -n "Delete default zabbix dashboard:"
                echo -ne "\t\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo $POST |jq .
                sleep 1
        else
            echo -n "Delete default zabbix dashboard:"
            echo -ne "\t\t" && Done
            sleep 1
        fi

        # Import Zabbix system status dashboard
        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type: application/json;charset=UTF-8" \
        -H "Authorization:Bearer $GRF_API_KEY" \
        -d "@../grafana_dashboards/zabbix-server-dashboard.json" \
        -X POST "$GRF_SERVER_URL/api/dashboards/db" |jq .)

        if [[ "$POST" == *"success"* ]]; then
            echo -n "Import Zabbix system status dashboard:"
            echo -ne "\t\t" && Done
            sleep 1
        else
            echo ""
            echo -n "Import Zabbix system status dashboard:"
            echo -ne "\t\t" && Failed
            echo -n "An error occured. Please check the error output"
            echo $POST |jq .
            sleep 1
        fi
        EchoDash


        ########## NOTIFICATION CONFIGURATIONS ##########
        echo -e ""
        echo -e '\E[96m'"\033\- NOTIFICATION CONFIGURATIONS.\033[0m"
        sleep 1

        ########## EMAIL CONFIGURATION ##########
        echo ""
        GetSMTPNotifAnswer
        if [[ "$SMTPEnable" =~ $yesPattern ]]; then
            POST=$(curl -s --insecure \
            -H "Accept: application/json" \
            -H "Content-Type:application/json" \
            -X POST --data "$(SMTPConfigPD)" "$ZBX_SERVER_URL/api_jsonrpc.php" |jq .)

            if [[ "$POST" == *"error"* ]]; then
                echo -n "SMTP notification configuration:"
                echo -ne "\t\t" && Failed
                echo "An error occured. Please check the error output"
                echo "$POST" |jq .
                sleep 1
                else
                echo -n "SMTP notification configuration:"
                echo -ne "\t\t" && Done
                sleep 1
            fi

            POST=$(curl -s --insecure \
            -H "Accept: application/json" \
            -H "Content-Type:application/json" \
            -X POST --data "$(AdminSmtpMediaTypePD)" "$ZBX_SERVER_URL/api_jsonrpc.php" |jq .)

            if [[ "$POST" == *"error"* ]]; then
                echo -n "Set admin's email address:"
                echo -ne "\t\t\t" && Failed
                echo "An error occured. Please check the error output"
                echo "$POST" |jq .
                sleep 1
                else
                echo -n "Set admin's email address:"
                echo -ne "\t\t\t" && Done
                sleep 1
            fi

            POST=$(curl -s --insecure \
            -H "Accept: application/json" \
            -H "Content-Type:application/json" \
            -X POST --data "$(NotifTriggerPD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

            if [[ "$POST" == *"error"* ]]; then
                echo -n "Enable notifications for admin group:"
                echo -ne "\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo "$POST" |jq .
                sleep 1
                else
                echo -n "Enable notifications for admin group:"
                echo -ne "\t\t" && Done
                sleep 1
                EchoDash
            fi
        fi

        ########## SLACK CONFIGURATION ##########
        echo ""
        GetSlackNotifAnswer
        if [[ "$SlackEnable" =~ $yesPattern ]]; then

            GetZabbixAuthToken
            POST=$(curl -s --insecure \
            -H "Accept: application/json" \
            -H "Content-Type:application/json" \
            -X POST --data "$(ZabbixUrlGlobalMacroPD)" "$ZBX_SERVER_URL/api_jsonrpc.php" |jq .)

                if [[ "$POST" == *"error"* ]]; then
                    echo -n "Creating a global macro for Zabbix URL:"
                    echo -ne "\t\t" && Failed
                    echo "An error occured. Please check the error output"
                    echo "$POST" |jq .
                    sleep 1
                    else
                    echo -n "Creating a global macro for Zabbix URL:"
                    echo -ne "\t\t" && Done
                    sleep 1
                fi

            POST=$(curl -s --insecure \
            -H "Accept: application/json" \
            -H "Content-Type:application/json" \
            -X POST --data "$(SetSlackBotTokenPD)" "$ZBX_SERVER_URL/api_jsonrpc.php" |jq .)

                if [[ "$POST" == *"error"* ]]; then
                    echo -n "Adding bot token to slack medita type:"
                    echo -ne "\t\t" && Failed
                    echo "An error occured. Please check the error output"
                    echo "$POST" |jq .
                    sleep 1
                    else
                    echo -n "Adding bot token to slack medita type:"
                    echo -ne "\t\t" && Done
                    sleep 1
                fi

            if [[ "$SMTPEnable" =~ $yesPattern ]]; then
                POST=$(curl -s --insecure \
                -H "Accept: application/json" \
                -H "Content-Type:application/json" \
                -X POST --data "$(AdminSmtpSlackMediaTypePD)" "$ZBX_SERVER_URL/api_jsonrpc.php" |jq .)

                    if [[ "$POST" == *"error"* ]]; then
                        echo -n "Adding slack and smtp media types to admin user:"
                        echo -ne "\t\t" && Failed
                        echo "An error occured. Please check the error output"
                        echo "$POST" |jq .
                        sleep 1
                        else
                        echo -n "Adding slack and smtp media types to admin user:"
                        echo -ne "\t\t" && Done
                        sleep 1
                    fi
            else
                POST=$(curl -s --insecure \
                -H "Accept: application/json" \
                -H "Content-Type:application/json" \
                -X POST --data "$(AdminSlackMediaTypePD)" "$ZBX_SERVER_URL/api_jsonrpc.php" |jq .)

                    if [[ "$POST" == *"error"* ]]; then
                        echo -n "Adding slack media type to admin user:"
                        echo -ne "\t\t" && Failed
                        echo "An error occured. Please check the error output"
                        echo "$POST" |jq .
                        sleep 1
                        else
                        echo -n "Adding slack media type to admin user:"
                        echo -ne "\t\t" && Done
                        sleep 1
                    fi
            fi

            POST=$(curl -s --insecure \
            -H "Accept: application/json" \
            -H "Content-Type:application/json" \
            -X POST --data "$(NotifTriggerPD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

                if [[ "$POST" == *"error"* ]]; then
                    echo -n "Enable notifications for admin group:"
                    echo -ne "\t" && Failed
                    echo -n "An error occured. Please check the error output"
                    echo "$POST" |jq .
                    sleep 1
                else
                    echo -n "Enable notifications for admin group:"
                    echo -ne "\t\t" && Done
                    sleep 1
                    EchoDash
                    FinisMessage
                fi
        else
            FinisMessage
            exit 0
        fi
    ;;

    enable-slack)
        ########## SLACK CONFIGURATION ##########
        echo ""
        GetSlackNotifAnswer
        if [[ "$SlackEnable" =~ $yesPattern ]]; then

            GetZabbixAuthToken
            POST=$(curl -s --insecure \
            -H "Accept: application/json" \
            -H "Content-Type:application/json" \
            -X POST --data "$(ZabbixUrlGlobalMacroPD)" "$ZBX_SERVER_URL/api_jsonrpc.php" |jq .)

                if [[ "$POST" == *"error"* ]]; then
                    echo -n "Creating a global macro for Zabbix URL:"
                    echo -ne "\t\t" && Failed
                    echo "An error occured. Please check the error output"
                    echo "$POST" |jq .
                    sleep 1
                    else
                    echo -n "Creating a global macro for Zabbix URL:"
                    echo -ne "\t\t" && Done
                    sleep 1
                fi

            POST=$(curl -s --insecure \
            -H "Accept: application/json" \
            -H "Content-Type:application/json" \
            -X POST --data "$(SetSlackBotTokenPD)" "$ZBX_SERVER_URL/api_jsonrpc.php" |jq .)

                if [[ "$POST" == *"error"* ]]; then
                    echo -n "Adding bot token to slack medita type:"
                    echo -ne "\t\t" && Failed
                    echo "An error occured. Please check the error output"
                    echo "$POST" |jq .
                    sleep 1
                    else
                    echo -n "Adding bot token to slack medita type:"
                    echo -ne "\t\t" && Done
                    sleep 1
                fi

            if [[ "$SMTPEnable" =~ $yesPattern ]]; then
                POST=$(curl -s --insecure \
                -H "Accept: application/json" \
                -H "Content-Type:application/json" \
                -X POST --data "$(AdminSmtpSlackMediaTypePD)" "$ZBX_SERVER_URL/api_jsonrpc.php" |jq .)

                    if [[ "$POST" == *"error"* ]]; then
                        echo -n "Adding slack and smtp media types to admin user:"
                        echo -ne "\t\t" && Failed
                        echo "An error occured. Please check the error output"
                        echo "$POST" |jq .
                        sleep 1
                        else
                        echo -n "Adding slack and smtp media types to admin user:"
                        echo -ne "\t\t" && Done
                        sleep 1
                    fi
            else
                POST=$(curl -s --insecure \
                -H "Accept: application/json" \
                -H "Content-Type:application/json" \
                -X POST --data "$(AdminSlackMediaTypePD)" "$ZBX_SERVER_URL/api_jsonrpc.php" |jq .)

                    if [[ "$POST" == *"error"* ]]; then
                        echo -n "Adding slack media type to admin user:"
                        echo -ne "\t\t" && Failed
                        echo "An error occured. Please check the error output"
                        echo "$POST" |jq .
                        sleep 1
                        else
                        echo -n "Adding slack media type to admin user:"
                        echo -ne "\t\t" && Done
                        sleep 1
                    fi
            fi

            POST=$(curl -s --insecure \
            -H "Accept: application/json" \
            -H "Content-Type:application/json" \
            -X POST --data "$(NotifTriggerPD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

                if [[ "$POST" == *"error"* ]]; then
                    echo -n "Enable notifications for admin group:"
                    echo -ne "\t" && Failed
                    echo -n "An error occured. Please check the error output"
                    echo "$POST" |jq .
                    sleep 1
                    else
                    echo -n "Enable notifications for admin group:"
                    echo -ne "\t\t" && Done
                    sleep 1
                    EchoDash
                fi
        else
            exit 0
        fi
    ;;

    *)
        echo $"Usage: $0 {init}"
        exit 1
esac
