常用Shell脚本
=========
- **onekey.sh** v2ray一键安装脚本
>> 用法：[wulabing](https://github.com/wulabing/V2Ray_ws-tls_bash_onekey)
---------
- **refresh-aws-starter-key.py** 自动获取AWS Starter Access 信息并写入/root/.aws/credentials
>> 用法：
1. 安装环境
```
yum install python3 -y 
yum install firefox -y &&
yum install dbus-x11 dbus -y &&
eval `dbus-launch --sh-syntax`
```
2.安装Python依赖和驱动
```
pip3 install --upgrade pip
pip3 install selenium
wget  https://github.com/mozilla/geckodriver/releases/download/v0.28.0/geckodriver-v0.28.0-linux64.tar.gz
tar -zxvf geckodriver-v0.28.0-linux64.tar.gz
mv geckodriver /usr/local/bin
```
3. 执行脚本
```
python3 refresh-aws-starter-key.py -e awsstarter@email.com -p password
```
---------
