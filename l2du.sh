service xl2tpd stop
echo 正在执行多用户补丁(须先安装l2脚本)...
sleep 3
cat >> /etc/ppp/chap-secrets <<'EOF'
"vip2" 2 "111111" *
"vip3" 3 "111111" *
"vip4" 4 "111111" *
"vip5" 5 "111111" *
"vip6" 6 "111111" *
"vip7" 7 "111111" *
"vip8" 8 "111111" *
"vip9" 9 "111111" *
"vip10" l0 "111111" *
EOF
echo 执行完成.
sleep 2
service xl2tpd start
echo “以下为多账号，格式:账号 序号 密码 ”
cat /etc/ppp/chap-secrets
