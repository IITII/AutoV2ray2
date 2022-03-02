# AutoV2ray2

> 一个简单的 V2ray 脚本 (HTTP/2+TLS+WEB base on caddy 2.x)  
> 兼容最新版 V2ray(V2Ray 4.44.0+) 和 Caddy(v2.4.6+)  
> 

* 一般使用场景的流量转发方式
```
Chrome <-HTTP/Socks-> V2RayClient <-H2+TLS-> Caddy <-H2C-> V2RayServer <-Freedom-> Internet
```

* TLS+NGINX+WEB 的 v2ray 一键脚本: https://github.com/IITII/AutoV2ray

## QuickStart

### 直接搭建

> 部分配置留空会自动生成
>

1. `git clone https://github.com/IITII/AutoV2ray2.git && cd AutoV2ray2`
2. 仅指定域名: bash `./v2ray -w "v2.google.com"`
2. 指定域名、h2 路径: `bash ./v2ray -w "v2.google.com"  -p "path"`
2. 指定域名、h2 路径、uuid: `bash ./v2ray -w "v2.google.com"  -p "path" -u "85d0e39a-4571-44da-80bb-caf5f853c2ba" `
2. 指定域名、h2 路径、uuid、he.net 的 ddns key: `bash ./v2ray -w "v2.google.com"  -p "path" -u "85d0e39a-4571-44da-80bb-caf5f853c2ba" --ddns "re35A5xFGdEzrRow"`

```
Usage:
  .v2ray.sh -h, --help            Show this page
  .v2ray.sh -w                    siteName
  .v2ray.sh -p, --path            v2ray web socket path, default "/bin/date +"%S" | /usr/bin/base64"
  .v2ray.sh -u, --uuid            v2ray uuid
  .v2ray.sh --ddns                dns.he.net ddns's key
```

### 重新部署

> 适用于需要更换域名的场景，如：域名到期
>

```bash
v2() {
    domain="$1.google.com"
    vpath=$(cat /usr/local/etc/v2ray/config.json | grep -e 'path' -e 'id' | awk -v FS='"' '{print $4}' | grep '/' | sed 's/\///g')
    vuuid=$(cat /usr/local/etc/v2ray/config.json | grep -e 'path' -e 'id' | awk -v FS='"' '{print $4}' | grep '/' -v)
    echo "$domain $vpath $vuuid"
    ./v2ray.sh -w $domain -p $vpath -u $vuuid --ddns $domain
}
# cd AutoV2ray
v2
```

## 注意事项

* ddns 更新目前仅支持 dns.he.net
* 不需要也不开放指定 ssl 证书，交由 Caddy 自动管理
  * 自动管理要求：域名解析正确
  * 如果不使用 ddns，那么请手动更新 dns 记录
* 因为证书是自动管理所以可能出现第一次访问出现问题，原因是证书还未颁发，过会儿就好

* 某些机器可能需要手动打开防火墙端口: 22, 80, 443

```bash
sudo apt update -y && sudo apt install firewalld git -y
sudo firewall-cmd --zone=public --permanent --add-port=22/tcp
sudo firewall-cmd --zone=public --permanent --add-port=80/tcp
sudo firewall-cmd --zone=public --permanent --add-port=443/tcp
sudo firewall-cmd --reload
sudo systemctl enable firewalld
sudo systemctl status firewalld nginx v2ray
sudo systemctl start firewalld
```

* 手动打开 BBR（仅在 Ubuntu18.04+ 测试过
> 可能会暴毙，请自行斟酌  

```bash
echo "net.core.default_qdisc=fq" >>/etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >>/etc/sysctl.conf
sysctl -p
```
* 手动更新 dns.he.net ddns 记录

```bash
site="baidu.com" && \
siteName=$site && \
he_net_ddns_key=$site && \
curl -4 "https://$siteName:$he_net_ddns_key@dyn.dns.he.net/nic/update?hostname=$siteName"
```

## 常见问题
> 以下问题均已修复  

* `invalid user: VMessAEAD is enforced and a non VMessAEAD connection is received.`
> 1. 升级客户端版本
> 2. 或客户端设置 `alterId: 0`   
> 3. 或服务端添加 V2ray 启动环境变量:  `Environment="V2RAY_VMESS_AEAD_FORCED=false"`   
>

* ClashX 配置文件在 `1.90.0` 有一次较大的修改。
* 本项目的配置文件基于新版的 ClashX，提问之前先确认自己 Clash 版本。

## Troubleshooting
* 查看 Caddy 和 V2ray 状态：`systemctl status v2ray caddy`
* 查看 Caddy 和 V2ray 配置文件：`cat /etc/caddy/Caddyfile; cat /usr/local/etc/v2ray/config.json`
* 直接 curl 看看，是不是防火墙的问题: `curl https://<网站域名>`
