bash <(curl -sSL https://linuxmirrors.cn/main.sh) \
  --source mirrors.tuna.tsinghua.edu.cn \
  --protocol http \
  --use-intranet-source false \
  --install-epel true \
  --backup true \
  --upgrade-software false \
  --clean-cache false \
  --ignore-backup-tips
