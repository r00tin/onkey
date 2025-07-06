#!/bin/bash

VPN_USERS=(
  "vip1:111111"
  "vip2:111111"
  "vip3:111111"
  "vip4:111111"
  "vip5:111111"
  "vip6:111111"
  "vip7:111111"
  "vip8:111111"
  "vip9:111111"
  "vip10:111111"
)


export DEBIAN_FRONTEND=noninteractive


ufw disable


apt update && apt install -y wget iptables iproute2 net-tools dnsutils openssl ppp xl2tpd fail2ban libnss3-tools


VPN_L2TP_NET="172.28.42.0/24"
VPN_L2TP_LOCAL="172.28.42.1"
VPN_L2TP_POOL="172.28.42.10-172.28.42.250"
DNS_SRV1="8.8.8.8"
DNS_SRV2="8.8.4.4"


PUBLIC_IP=$(wget -qO- http://ipv4.icanhazip.com)


cat > /etc/xl2tpd/xl2tpd.conf <<EOF
[global]
port = 1701

[lns default]
ip range = ${VPN_L2TP_POOL}
local ip = ${VPN_L2TP_LOCAL}
require chap = yes
refuse pap = yes
require authentication = yes
name = l2tpd
pppoptfile = /etc/ppp/options.xl2tpd
length bit = yes
EOF


cat > /etc/ppp/options.xl2tpd <<EOF
+mschap-v2
ipcp-accept-local
ipcp-accept-remote
noccp
auth
mtu 1280
mru 1280
proxyarp
lcp-echo-failure 4
lcp-echo-interval 30
connect-delay 5000
ms-dns ${DNS_SRV1}
ms-dns ${DNS_SRV2}
EOF


cat > /etc/ppp/chap-secrets <<EOF
EOF
for user in "${VPN_USERS[@]}"; do
  IFS=":" read -r username password <<< "$user"
  echo "\"${username}\" l2tpd \"${password}\" *" >> /etc/ppp/chap-secrets
done

cat >> /etc/sysctl.conf <<EOF

# L2TP VPN
net.ipv4.ip_forward = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
EOF

sysctl -p


iptables -F
iptables -t nat -F
iptables -A INPUT -p udp --dport 1701 -j ACCEPT
iptables -A INPUT -p tcp --dport 6666 -j ACCEPT
iptables -A FORWARD -s ${VPN_L2TP_NET} -j ACCEPT
iptables -t nat -A POSTROUTING -s ${VPN_L2TP_NET} -o eth0 -j MASQUERADE
iptables-save > /etc/iptables.rules

cat > /etc/network/if-pre-up.d/iptablesload <<EOF
#!/bin/sh
iptables-restore < /etc/iptables.rules
exit 0
EOF
chmod +x /etc/network/if-pre-up.d/iptablesload


/certificate add name=CA common-name=CA days-valid=3650 key-size=2048 key-usage=crl-sign,key-cert-sign
/certificate sign CA

/certificate add name=server common-name=server days-valid=3650 key-size=2048 key-usage=digital-signature,key-encipherment,tls-server
/certificate sign server ca=CA


/interface sstp-server server set certificate=server enabled=yes pfs=yes port=6666


systemctl enable xl2tpd
systemctl restart xl2tpd
systemctl restart fail2ban

echo "========================================================="
echo "L2TP VPN 安装完成"
echo "服务器公网 IP: ${PUBLIC_IP}"
echo "已创建的 VPN 账户:"
for user in "${VPN_USERS[@]}"; do
  IFS=":" read -r username password <<< "$user"
  echo "账户: ${username} 密码: ${password}"
done
echo "请忽略insserv: warning之类的警告"
echo "========================================================="
echo "L2TP 服务器已启用，端口: 1721"
echo "========================================================="

exit 0
