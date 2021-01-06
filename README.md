常用Shell脚本
=========
###  [awsmanager.sh] AWS Cli Shell 控制，当前支持EC2、Lightsail
> 用法：
1.安装aws cli [官网文档](https://docs.aws.amazon.com/zh_cn/cli/latest/userguide/install-cliv2-linux.html)
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```
2. 配置AWS Cli
```
# AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
# AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
# Default region name [None]: us-west-2
# Default output format [None]: json
# 运行命令，需要先获取以上信息，具体请查看文档
aws configure
```
3. 运行脚本
```
wget --no-check-certificate https://raw.githubusercontent.com/tzpBingo/myshell/master/awsmanager.sh -O awsmanager.sh && chmod +x awsmanager.sh
./awsmanager.sh
```
4. 效果
>> ![image](https://github.com/tzpBingo/myshell/blob/master/imgs/aws.gif)
---------------------------------------------------------------------------------

###  [azmanager.sh] Azure Cli Shell 控制
> 用法：
1.安装azure cli [官网文档](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=script)
```
curl -L https://aka.ms/InstallAzureCli | bash
```
2. 配置Azure Cli
```
# 运行命令，按提示登录，具体请查看文档
az login
```
3. 运行脚本
```
wget --no-check-certificate https://raw.githubusercontent.com/tzpBingo/myshell/master/azmanager.sh -O azmanager.sh && chmod +x azmanager.sh
./azmanager.sh
```
4. 效果
>> ![image](https://github.com/tzpBingo/myshell/blob/master/imgs/az.jpg)
------------------------------------------------------------------------

###  [refresh-aws-starter-session.py] 自动获取AWS Starter Access 信息并写入/root/.aws/credentials
> 用法：
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
wget --no-check-certificate  https://raw.githubusercontent.com/tzpBingo/myshell/master/refresh-aws-starter-session.py -O refresh-aws-starter-session.py
python3 refresh-aws-starter-session.py -e awsstarter@email.com -p password
```
4. 效果
>> ![image](https://github.com/tzpBingo/myshell/blob/master/imgs/refresh-aws-starter-session.jpg)
------------------------------------------------------------------------
###  [onekey.sh] v2ray一键安装脚本
> 用法：[wulabing](https://github.com/wulabing/V2Ray_ws-tls_bash_onekey)
---------
