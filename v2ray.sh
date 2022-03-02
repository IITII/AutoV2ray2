#!/usr/bin/env bash
#=================================================
#	Recommend OS: Debian/Ubuntu
#	Description: V2ray auto-deploy
#	Version: 2.0.0
#	Author: IITII
#	Blog: https://IITII.github.io
#=================================================
export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/v2ray/
#=================================================
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
siteName=""
wsPath=""
# ssl public: *.cer *.crt *.pem
# ssl key: *.key
uuid=""
he_net_ddns_key=""
SLEEP_TIME=5

# Don't modify
release="ubuntu"
flag=0
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
SKYBLUE='\033[0;36m'
PLAIN='\033[0m'

check_root() {
    [[ $(id -u) != "0" ]] && {
        log "Error: You must be root to run this script"
        exit 1
    }
}
pre_command_run_status() {
    if [[ $? -eq 0 ]]; then
        log_success "Success"
    else
        log_err "Failed"
        exit 1
    fi
}
log() {
    echo -e "[$(/bin/date)] $1"
}
log_success() {
    echo -e "${GREEN}[$(/bin/date)] $1${PLAIN}"
}
log_info() {
    echo -e "${YELLOW}[$(/bin/date)] $1${PLAIN}"
}
log_prompt() {
    echo -e "${SKYBLUE}[$(/bin/date)] $1${PLAIN}"
}
log_err() {
    echo -e "${RED}[$(/bin/date)] $1${PLAIN}"
}
check_release() {
    if [[ -f /etc/redhat-release ]]; then
        release="centos"
    elif cat /etc/issue | grep -Eqi "debian"; then
        release="debian"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        release="ubuntu"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
    elif cat /etc/issue | grep -Eqi "alpine"; then
        release="alpine"
    elif cat /proc/version | grep -Eqi "debian"; then
        release="debian"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        release="ubuntu"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
    fi
}
show_help() {
    echo "Usage:
  $0 -h, --help            Show this page
  $0 -w                    siteName
  $0 -p, --path            v2ray web socket path, default \"/bin/date +\"%S\" | /usr/bin/base64\"
  $0 -u, --uuid            v2ray uuid
  $0 --ddns                dns.he.net ddns's key
"
}
check_command() {
    if ! command -v $2 >/dev/null 2>&1; then
        log "Installing $2 from $1 repo"
        if [[ "$1" = "centos" ]]; then
            yum update >/dev/null 2>&1
            yum -y install $3 >/dev/null 2>&1
        elif [[ "$1" = "alpine" ]]; then
            apk update >/dev/null 2>&1
            apk --no-cache add $3 >/dev/null 2>&1
        else
            apt-get update >/dev/null 2>&1
            apt-get install $3 -y >/dev/null 2>&1
        fi
        pre_command_run_status
    fi
}
check_caddy() {
    if ! command -v caddy >/dev/null 2>&1; then
        log "Installing caddy from $1 repo"
        if [[ "$1" = "centos" ]]; then
            yum install yum-plugin-copr
            yum copr enable @caddy/caddy
            yum install caddy
        else
            apt install -y debian-keyring debian-archive-keyring apt-transport-https >/dev/null 2>&1
            curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo tee /etc/apt/trusted.gpg.d/caddy-stable.asc >/dev/null 2>&1
            curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list >/dev/null 2>&1
            apt update >/dev/null
            apt install -y caddy >/dev/null
        fi
        pre_command_run_status
    fi
}
check_path() {
    log "Checking Path $1"
    if ! [[ -d $1 ]]; then
        log "Create Un-exist Path $1"
        mkdir -p $1
        pre_command_run_status
    else
        log "Existed !"
    fi
}
update_ddns() {
    # see https://dns.he.net/docs.html
    log "Update DDNS Record..."
    res=$(curl -4 "https://$siteName:$he_net_ddns_key@dyn.dns.he.net/nic/update?hostname=$siteName")
    log $res
    log "Sleep $SLEEP_TIME s --> Time for dns record update."
    sleep ${SLEEP_TIME}
    log "Update DDNS Record successful!!!"
}
pre_check_var() {
    log "Check necessary variable..."
    if [[ -z ${siteName} ]]; then
        log "SiteName can not be empty!!!"
        exit 1
    fi
    if [[ -z ${uuid} ]]; then
        log "uuid is Empty, Generating..."
        uuid=$(v2ctl uuid)
        log "Now uuid is $uuid"
    fi
    if [[ -z ${wsPath} ]]; then
        log "wsPath is Empty, Generating..."
        wsPath=$(/bin/date +"%S" | base64)
        log "Now wsPath is $wsPath"
    fi
    if [[ -z ${he_net_ddns_key} ]]; then
        log_prompt "Empty dns.he.net ddns key. You must update dns record for $siteName by your own!!!"
    else
        update_ddns
    fi
    if [[ ${flag} -eq 0 ]]; then
        log_info \
            "Check again: siteName: $siteName , uuid: $uuid , wsPath: $wsPath , he_net_ddns_key: $he_net_ddns_key"
    else
        log_info \
            "Check again: siteName: $siteName , uuid: $uuid , wsPath: $wsPath"
    fi
}
firewall_rule() {
    log "Adding iptable rules..."
    if [[ "$release" = "centos" ]]; then
        systemctl stop firewalld.service >/dev/null 2>&1
        systemctl disable firewalld.service >/dev/null 2>&1
    else
        ufw allow 22 >/dev/null 2>&1
        ufw allow 80 >/dev/null 2>&1
        ufw allow 443 >/dev/null 2>&1
        ufw reload >/dev/null 2>&1
    fi
    iptables -A INPUT -p tcp -m multiport --dports 22,80,443 -j ACCEPT
    iptables -A OUTPUT -p tcp -m multiport --sports 22,80,443 -j ACCEPT
    log "Finished!!!"
}
vmess_gen() {
    tempRaw=$(/bin/cat ${CURRENT_DIR}/conf/share.json | /bin/sed \
        -e "s/baidu.com/$siteName/g" \
        -e "s/\"id\": \"\S\+/\"id\": \"$uuid\",/g" \
        -e "s/\"path\": \"\S\+/\"path\": \"\/$wsPath\",/g")
    temp=$(echo $tempRaw | base64 -w 0)
    temp=$(echo vmess://${temp})
    clash_yml=$(/bin/cat ${CURRENT_DIR}/conf/clash.yml | /bin/sed \
        -e "s/v2ray.com/$siteName/g" \
        -e "s/ruuid/$uuid/g" \
        -e "s/\/path/\/$wsPath/g")
    log_prompt "v2ray info: \n ${tempRaw}"
    log_prompt "v2ray info for clash: \n ${clash_yml}"
    log_prompt "v2ray link: ${SKYBLUE}${temp}${PLAIN}"
    echo "${tempRaw} \n ${clash_yml} \n ${temp}" >/root/v2ray_link &&
        log_success "v2ray link save to /root/v2ray_link"
}
main() {
    declare caddyconfig="/etc/caddy/Caddyfile"
    log "Ensure service is started...."
    systemctl restart caddy v2ray
    log "Modifying caddy, v2ray config file..."
    /bin/cat ${CURRENT_DIR}/conf/reverse_h2.caddy | /bin/sed \
        -e "s/v2ray.com/$3/g" \
        -e "s/path/$2/g" |
        caddy fmt - \
            >$caddyconfig
    cp -R ${CURRENT_DIR}/www/* /usr/share/caddy/
    log "Testing caddy config..."
    caddy validate --config $caddyconfig >/dev/null 2>&1
    pre_command_run_status
    log "Reload caddy..." && systemctl restart caddy >/dev/null 2>&1
    pre_command_run_status

    log "Modifying v2ray config file"
    /bin/cat ${CURRENT_DIR}/conf/server.json | /bin/sed \
        -e "s/\"id\": \"\S\+/\"id\": \"$1\",/g" \
        -e "s/\"path\": \"\S\+/\"path\": \"\/$2\"/g" |
        tee >/usr/local/etc/v2ray/config.json
    log "Reload v2ray..."
    systemctl restart v2ray && log_success "Success"
    log "Enable auto start..." && systemctl enable v2ray && log_success "Success"
    firewall_rule
}

if [[ -z "$1" ]]; then
    show_help
    exit 1
fi
cd ${CURRENT_DIR}
check_release
check_command ${release} getopt "util-linux"
check_command ${release} tee "tee"
check_command ${release} base64 "coreutils"
check_command ${release} curl "curl"
check_command ${release} tree "tree"
check_caddy ${release}

ARGS=$(getopt -a -o hw:p:u: -l help,path:,ddns:,uuid: -- "$@")
#set -- "${ARGS}"
#log "\$@: $@"
eval set -- "${ARGS}"
while [[ -n $1 ]]; do
    case "$1" in
    -w)
        if [[ -n $2 ]]; then
            siteName="$2"
        else
            log "SiteName can not be empty!!!"
            exit 1
        fi
        shift
        ;;
    -h | --help)
        show_help
        ;;
    -p | --path)
        wsPath="$2"
        shift
        ;;
    -u | --uuid)
        uuid="$2"
        shift
        ;;
    --ddns)
        he_net_ddns_key="$2"
        shift
        ;;
    --)
        shift
        break
        ;;
    *)
        log "unknown argument"
        exit 1
        ;;
    esac
    shift
done

if ! ( (command -v v2ray) && (command -v v2ctl)) >/dev/null 2>&1; then
    log "Install main program..."
    rm -rf /usr/bin/v2ray /usr/local/bin/v2ray /usr/local/bin/v2ctl
    #See: https://github.com/v2fly/fhs-install-v2ray/blob/master/README.zh-Hans-CN.md
    bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh) >/dev/null 2>&1
    pre_command_run_status
else
    log_prompt "Already installed"
fi

pre_check_var
main ${uuid} ${wsPath} ${siteName}
vmess_gen
