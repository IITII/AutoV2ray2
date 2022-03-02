# AutoV2ray
> let v2ray configure automatic ( TLS+NGINX+WEB )  
> Just put your site file on `www` dir if you want to use your own site as the web page    

**[简体中文](https://iitii.github.io/2020/02/08/1/)**

* quick start
```bash
git clone https://github.com/IITII/AutoV2ray.git && cd AutoV2ray

## Manual add firewallcmd rules
sudo -i
sudo apt update -y && sudo apt install firewalld git -y
sudo firewall-cmd --zone=public --permanent --add-port=22/tcp
sudo firewall-cmd --zone=public --permanent --add-port=80/tcp
sudo firewall-cmd --zone=public --permanent --add-port=443/tcp
sudo firewall-cmd --reload
sudo systemctl enable firewalld
sudo systemctl status firewalld nginx v2ray
sudo systemctl start firewalld

## enable bbr via add kernel param
echo "net.core.default_qdisc=fq" >>/etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >>/etc/sysctl.conf
sysctl -p

## quick deploy
site="baidu.com" && \
./v2ray.sh -w $site --ddns $site

## update ddns record base on dns.he.net
site="baidu.com" && \
siteName=$site && \
he_net_ddns_key=$site && \
curl -4 "https://$siteName:$he_net_ddns_key@dyn.dns.he.net/nic/update?hostname=$siteName"
```

## Notice
1. v2ray will use self-signed certificate if you don't give a [dns.he.net](https://dns.he.net) ddns_key and sslPath either
2. Honestly, I don't recommend the self-signed certificates
3. Due to the safety reason, I disabled `TLSv1.0` and use `TLS1.3` for TLS protocol. ( Why I am keeping TLSv1.2? Just for better compatibility)
4. TLSv1.3 required **NGINX v1.13.0+**. So check your nginx version first if your install is failed.

### Pre-check
1. Have a domain
3. A clean linux server
4. Some basic knowledge of operating Linux

### Additional
2. A domain on [dns.he.net](http://dns.he.net) which had configured ddns

### Some presume
1. Your server ip is: `1.1.1.1`
2. Your domain is: `v2.google.com`
3. Your ddns key is: `re35A5xFGdEzrRow`
4. Your ws path is: `path`
5. Your uuid is: `85d0e39a-4571-44da-80bb-caf5f853c2ba`

### Quick start
1. Login to your server: `ssh root@1.1.1.1`
2. Clone repo: `git clone https://github.com/IITII/AutoV2ray.git`
3. Follow some example
4. Enjoy yourself
### Example

```bash
git clone https://github.com/IITII/AutoV2ray.git && cd AutoV2ray

bash ./v2ray -w "v2.google.com"
bash ./v2ray -w "v2.google.com" 
bash ./v2ray -w "v2.google.com"  -p "path"
bash ./v2ray -w "v2.google.com"  -p "path" -u "85d0e39a-4571-44da-80bb-caf5f853c2ba" 
bash ./v2ray -w "v2.google.com"  -p "path" -u "85d0e39a-4571-44da-80bb-caf5f853c2ba" --ddns "re35A5xFGdEzrRow"
bash ./v2ray -w "v2.google.com"  -p "path" -u "85d0e39a-4571-44da-80bb-caf5f853c2ba" --sslPath "/etc/nginx/ssl"

systemctl status v2ray nginx
```
----

```bash
root@test-machine# bash v2ray.sh
Usage:
  draft/v2ray.sh -h, --help            Show this page
  draft/v2ray.sh -w                    siteName
  draft/v2ray.sh -p, --path            v2ray web socket path, default "/bin/date +"%S" | /usr/bin/base64"
  draft/v2ray.sh -u, --uuid            v2ray uuid
  draft/v2ray.sh --ddns                dns.he.net ddns's key
  draft/v2ray.sh --sslPath             ssl cert path
```
### Debug
* `systemctl status v2ray nginx` & `cat /var/v2ray/config.json` & `cat /etc/nginx/sites-enabled/default` will help you a lot.

### Upgrade or re-deploy

* Using config from config file

> Sample  
> re-deploy from www.google.com to v2.google.com  

```bash
v2() {
    domain="$1.google.com"
    vpath=$(cat /usr/local/etc/v2ray/config.json | grep -e 'path' -e 'id' | awk -v FS='"' '{print $4}' | grep '/' | sed 's/\///g')
    vuuid=$(cat /usr/local/etc/v2ray/config.json | grep -e 'path' -e 'id' | awk -v FS='"' '{print $4}' | grep '/' -v)
    echo "$domain $vpath $vuuid"
    ./v2ray.sh -w $domain -p $vpath -u $vuuid --ddns $domain
}
# cd AutoV2ray
v2 v2
```

### Problems
> all problems is fixed on last commit  

* invalid user: VMessAEAD is enforced and a non VMessAEAD connection is received.
> set `alterId: 0` at client OR `Environment="V2RAY_VMESS_AEAD_FORCED=false"` to Service
* clashX configure sample base on ClashX 1.90.0+
