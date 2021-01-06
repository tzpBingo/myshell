red="\033[31m"
black="\033[0m"

#====================================================#
#	System Request:Ubuntu 18.04+/Centos 7+	     #
#	Author:	tzpbingo			     #
#	Dscription: aws cli shell manager	     #
#	Version: 1.0				     #
#	email:tzpbingo@gmail.com		     #
#====================================================#

region=us-east-1

if type aws >/dev/null 2>&1; then 
	aws --version
else
	read -p "请先安装Aws Cli，按任意键开始安装。"
	curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
	unzip awscliv2.zip
	sudo ./aws/install
	sleep 3
	echo -e "请按提示输入以下信息"
	echo -e "如没有，请先登录账户获取，文档：[https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-creds]：\n"
	echo -e "然后再手动执行：aws configure"
	aws configure
fi

change-regions(){
	echo -e "EC2可用区域：\n"
	aws ec2 describe-regions --region $region --query "Regions[].{Endpoint:Endpoint,Region:RegionName}" --out table
	echo -e "Lightsail可用区域：\n"
	aws lightsail get-regions --region $region --query "regions[].{Area:displayName,Region:name}" --out table
	read -rp "请选择Region（Default: us-east-1）:" region
	[[ -z ${region} ]] && region="us-east-1"
	echo -e "${red}你选择了【$region】,接下来的操作都会在当前区。${black}"
}

change-regions

keep_user_input(){
    info=$1
    read -rp "$info:" input
    while [[ ! -n "$input" ]]
    do
        keep_user_input $info
    done
    echo $input
}


keep_user_confirm(){
    info=$1
	command=$2
    read -p "$info" go_next
    [[ -z ${go_next} ]] && go_next="Y"
    case $go_next in
        [yY][eE][sS]|[yY])
            echo -e "${GreenBG} 【确认】 ${Font}"
            sleep 1
			$(command)
            ;;
        *)
            echo -e "${RedBG} 【取消】 ${Font}"
            exit 2
            ;;
        esac
}


#查看EC2
ec2-describe-instances(){
aws ec2 describe-instances --region $region \
			--query 'Reservations[*].Instances[*].{Instance:InstanceId,AZ:Placement.AvailabilityZone,InstanceType:InstanceType,Platform:Platform,State:State.Name,CPU:CpuOptions.CoreCount,IP:NetworkInterfaces[0].Association.PublicIp,Name:Tags[?Key==`Name`]|[0].Value}' \
			--output table
}

#查看所有区域EC2
ec2-describe-instances-all-regions(){
	
	for r in `aws ec2 describe-regions --output text | cut -f4`
	do
		echo -e "\n地区:【'$r'】："
		aws ec2 describe-instances --region $r \
			--query 'Reservations[*].Instances[*].{Instance:InstanceId,AZ:Placement.AvailabilityZone,InstanceType:InstanceType,Platform:Platform,State:State.Name,CPU:CpuOptions.CoreCount,IP:NetworkInterfaces[0].Association.PublicIp,Name:Tags[?Key==`Name`]|[0].Value}' \
			--output table
		sleep 3
	done
}

#终止EC2
ec2-terminate-instances(){
read -p "【EC2】请输入需要被终止的实例ID: " id
aws ec2 terminate-instances --region $region --instance-ids $id \
				--query 'TerminatingInstances[*].{Instance:InstanceId,CurrentState:CurrentState.Name}' \
				--output table
}
#管理EC2
ec2-manager-instances(){
    ec2-describe-instances
    echo  -e "${red}当前位置【管理EC2】,请选择（请输入数字）？Ctrl+C 退出本脚本${black}"
    select todo in 开机 关机 重启 端口全开 添加弹性IP 删除已绑定弹性IP 删除未绑定EC2弹性IP 获取WIN系统密码 返回
    do
        case $todo in
        开机)
            ids=$(echo `keep_user_input "请输入EC2实例ID："`)
            aws ec2 start-instances --region $region --instance-ids  $ids
            ec2-manager-instances
            ;;
        关机)
            ids=$(echo `keep_user_input "请输入EC2实例ID："`)
            aws ec2 stop-instances --region $region --instance-ids  $ids
            ec2-manager-instances
            ;;
        重启)
            ids=$(echo `keep_user_input "请输入EC2实例ID："`)
            aws ec2 reboot-instances --region $region --instance-ids  $ids
            ec2-manager-instances
            ;; 
		端口全开)
            aws ec2 authorize-security-group-ingress --region $region \
				--group-name default \
				--protocol -1 \
				--port 0-65535 \
				--cidr 0.0.0.0/0
            ec2-manager-instances
            ;; 	
		添加弹性IP)
            ids=$(echo `keep_user_input "请输入EC2实例ID："`)
            newip=$(aws ec2 allocate-address --region $region --query 'PublicIp' --out text)
			aws ec2 associate-address --region $region --instance-id $ids --public-ip $newip
            ec2-manager-instances
            ;;
		删除已绑定EC2弹性IP)
            ids=$(echo `keep_user_input "请输入EC2实例ID："`)
            allocationId=$(aws ec2 describe-addresses --region $region --query "Addresses[?InstanceId=='$ids'].AllocationId" --out text)
			if [ "$allocationId" = "" ]; then  
				echo "当前EC2实例没有绑定弹性IP"  
			else
				aws ec2 describe-addresses --region $region \
						--query "Addresses[?InstanceId=='$ids'].{InstanceId:InstanceId,PublicIp:PublicIp,AllocationId:AllocationId}" \
						--out table
				read -p "【删除已绑定弹性IP】请确认是否删除(Y/N): " go_run
				[[ -z ${go_run} ]] && go_run="Y"
				case $go_run in
				[yY][eE][sS]|[yY])
					echo -e "${GreenBG} 【删除】 ${Font}"
					sleep 1
					aws ec2 release-address --region $region --allocation-id  $allocationId
					;;
				*)
					echo -e "${RedBG} 【取消】 ${Font}"
					;;
				esac	
			fi
            ec2-manager-instances
            ;;
		删除未绑定EC2弹性IP)
			aws ec2 describe-addresses --region $region --query "Addresses[].{InstanceId:InstanceId,PublicIp:PublicIp,AllocationId:AllocationId}" --out table
            allocationId=$(echo `keep_user_input "显示有InstanceId的是已绑定EC2,请输入AllocationId："`)
            aws ec2 release-address --region $region --allocation-id  $allocationId
            ec2-manager-instances
            ;;
		获取WIN系统密码)
			echo "需要等实例完全启动才可以获取到，不然获取的结果为空！！！"
			ids=$(echo `keep_user_input "请输入EC2实例ID："`)
			keypath=$(echo `keep_user_input "请输入对应私钥文件绝对路径："`)
			aws ec2 get-password-data  --region $region --instance-id $ids --priv-launch-key $keypath
            ;;			
        返回)
            main
            ;;       
        *)
            echo "如果要退出，请按Ctrl+C"
            ;;
        esac
    done
}

#创建EC2
ec2-run-instances(){
ec2-images
read -p "【EC2】请输入image-id: （默认：Ubuntu20.04LTS）" imageid
[[ -z ${imageid} ]] && imageid=ami-0be3f0371736d5394
ec2-describe-instance-types
read -p "【EC2】请输入instance-type: （默认：t2.xlarge）" instancetype
[[ -z ${instancetype} ]] && instancetype=t2.xlarge
ec2-describe-key-pairs
read -p "【EC2】请输入key-pairs: " keypairs
read -p "【EC2】请输入开启实例数量: " count

echo "image-id: $imageid"
echo "instance-type: $instancetype"
echo "key-pairs: $keypairs"
echo "count: $count"

read -p "【EC2】请确认实例信息(Y/N): " go_run_instances
    [[ -z ${go_run_instances} ]] && go_run_instances="Y"
    case $go_run_instances in
        [yY][eE][sS]|[yY])
            echo -e "${GreenBG} 创建实例 ${Font}"
            sleep 2
			aws ec2 run-instances  --region $region \
			    --image-id $imageid \
				--count $count \
			    --instance-type $instancetype \
			    --key-name $keypairs \
				--query 'Instances[*].{Instance:InstanceId,AZ:Placement.AvailabilityZone,InstanceType:InstanceType,Platform:Platform,State:State.Name,CPU:CpuOptions.CoreCount,IP:NetworkInterfaces[0].Association.PublicIp,Name:Tags[?Key==`Name`]|[0].Value}' \
				--output table
            ;;
        *)
            echo -e "${RedBG} 终止 ${Font}"
            exit 2
            ;;
        esac
}
#EC2机器配置
ec2-describe-instance-types(){
read -p "【EC2】请输入机器类型组名（Default: t2），如:t3、c5、c6g、r6g，如需其他请查看官网: " grp
[[ -z ${grp} ]] && grp=t2
aws ec2 describe-instance-types  --region $region  \
    --query 'InstanceTypes[*].{InstanceType:InstanceType,CPU:VCpuInfo.DefaultCores,RAM:MemoryInfo.SizeInMiB}' \
    --filters  "Name=instance-type,Values=$grp*" \
    --output table	
}

#EC2 Images
ec2-images(){
echo "1：Ubuntu"
echo "2: Centos"
echo "3：Win"
read -p "【EC2】请选择系统，然后复制镜像ImageId（Default: Ubuntu）: " platform
[[ -z ${platform} ]] && platform=1
	if [[ $platform == 1 ]];then
		aws ec2 describe-images --region $region \
			--owners 099720109477 \
			--query 'reverse(sort_by(Images, &CreationDate))[?contains(Description, `UNSUPPORTED`) != `true`]|[?contains(Description, `amd64`) == `true`]|[0:10].{ImageId:ImageId,Description:Description}' \
			--filters  "Name=description,Values=*Ubuntu*20*04*LTS*amd64*focal*image*build*on*" \
			--output table
		#main
	elif [[ $platform == 2 ]];then
		# aws ec2 describe-images --region $region \
		# 	--owners 'aws-marketplace' \
		# 	--filters 'Name=product-code,Values=cvugziknvmxgqna9noibqnnsy' \
		# 	--query 'reverse(sort_by(Images, &CreationDate))[0:10].{ImageId:ImageId,Description:Description}' \
		# 	--output table
		aws ec2 describe-images --region $region \
			--filters  "Name=description,Values=*CentOS*x86_64*"  \
			--owners '125523088429' \
			--query 'reverse(sort_by(Images, &CreationDate))[].{ImageId:ImageId,Description:Description}' \
			--output table
	else
		aws ec2 describe-images --region $region \
			--owners amazon \
			--query 'reverse(sort_by(Images, &CreationDate))[0:10].{ImageId:ImageId,Description:Description}' \
			--filters  "Name=description,Values=*Microsoft*Windows*Server*2019*with*Desktop*Experience*Locale*" \
			--output table	
		#main	
	fi
}
#获取GetRegions Zones
lightsail-get-regions(){
aws lightsail get-regions  --region $region \
    --include-availability-zones \
    --query 'regions[?length(availabilityZones[?state==`available`])>`0`].{Zones:availabilityZones[*].zoneName}' \
    --output table
}
#获取机器配置
lightsail-get-bundles(){
aws lightsail get-bundles --region $region \
    --query 'bundles[*].{Price:price,CPU:cpuCount,ID:bundleId,ARM:ramSizeInGb}' \
    --output table	
}
#获取蓝图镜像
lightsail-get-blueprints(){
aws lightsail get-blueprints --region $region 	\
    --query 'blueprints[*].{ID:blueprintId,Name:name,Platform:platform,Version:version}' \
    --output table
}

#创建Lightsail
lightsail-create-instances(){
read -p "【LS】请输入实例Name: " name
lightsail-get-regions
read -p "【LS】请选择Regions Zones: " regionszones
lightsail-get-bundles
read -p "【LS】请选择机器配置ID: " bundles
lightsail-get-blueprints
read -p "【LS】请选择镜像ID: " blueprints
lightsail-get-key-pairs
read -p "【LS】请选择Key Pair ID,没有请返回创建: " keypair
aws lightsail create-instances --region $region \
    --instance-names $name \
    --availability-zone $regionszones \
    --blueprint-id $blueprints \
    --bundle-id $bundles \
    --key-pair-name $keypair
echo  -e "${red}默认开放全部端口！${black}"	
lightsail-open-instance-public-ports $name
}

#查看Lightsail
lightsail-get-instances(){
aws lightsail get-instances  --region $region \
			--query 'instances[*].{UserName:username,IP:publicIpAddress,Name:name,State:state.name}' \
			--output table
}

#查看所有区域Lightsail
lightsail-get-instances-all-regions(){
	for r in `aws lightsail get-regions --region us-east-1 --output text | cut -f5`
	do
		echo -e "\n地区:【'$r'】："
		aws lightsail get-instances  --region $r \
			--query 'instances[*].{UserName:username,IP:publicIpAddress,Name:name,State:state.name}' \
			--output table
		sleep 3
	done
}
#开放端口Lightsail
lightsail-open-instance-public-ports(){
	for i do
		name=$i
		aws lightsail open-instance-public-ports --region $region \
				--instance-name $name \
				--port-info fromPort=0,protocol=all,toPort=65535	
	done
}
#管理Lightsail
lightsail-manager-instances(){
	lightsail-get-instances
    echo  -e "${red}当前位置【管理LS】,请选择（请输入数字）？Ctrl+C 退出本脚本${black}"
    select todo in 开机 关机 重启 端口全开 添加静态IP 删除绑定实例的静态IP 删除空闲静态IP 返回
    do
        case $todo in
        开机)
            name=$(echo `keep_user_input "请输入LS实例Name："`)
            aws lightsail start-instance --region $region --instance-name  $name
            lightsail-manager-instances
            ;;
        关机)
            name=$(echo `keep_user_input "请输入LS实例Name："`)
            aws lightsail stop-instance --region $region --instance-name  $name
            lightsail-manager-instances
            ;;
        重启)
            name=$(echo `keep_user_input "请输入LS实例Name："`)
            aws lightsail reboot-instance --region $region --instance-name  $name
            lightsail-manager-instances
            ;;
		端口全开)
            name=$(echo `keep_user_input "请输入LS实例Name："`)
            lightsail-open-instance-public-ports --region $region $name
            lightsail-manager-instances
            ;;	
		添加静态IP)
			lsname=$(echo `keep_user_input "请输入需要绑定IP的LS实例Name："`)
            ipname=$(echo `keep_user_input "请输入创建静态IP名称："`)
			aws lightsail allocate-static-ip --region $region  --static-ip-name $ipname
			sleep 3
            aws lightsail attach-static-ip --region $region \
				--static-ip-name $ipname \
				--instance-name $lsname
            lightsail-manager-instances
            ;;
		删除绑定实例的静态IP)
            lsname=$(echo `keep_user_input "请输入LS实例Name："`)
            ipname=$(aws lightsail get-static-ips --region $region --query "staticIps[?attachedTo=='$lsname'].name" --out text)
			if [ "$ipname" = "" ]; then  
				echo "当前LS实例没有绑定静态IP"  
			else
				aws lightsail get-static-ips --region=$region  \
				--query "staticIps[?attachedTo=='$lsname'].{IpName:name,IP:ipAddress,IsAttached:isAttached,AttachedTo:attachedTo}" \
				--output table
				read -p "【删除已绑定静态IP】请确认是否删除(Y/N): " go_run
				[[ -z ${go_run} ]] && go_run="Y"
				case $go_run in
				[yY][eE][sS]|[yY])
					echo -e "${GreenBG} 【删除】 ${Font}"
					sleep 1
					aws lightsail release-static-ip --region=$region --static-ip-name $ipname
					;;
				*)
					echo -e "${RedBG} 【取消】 ${Font}"
					;;
				esac	
			fi
            lightsail-manager-instances
            ;;
		删除空闲静态IP)
			aws lightsail get-static-ips --region=$region  \
				--query "staticIps[?to_string(isAttached)=='false'].{IpName:name,IP:ipAddress,IsAttached:isAttached,AttachedTo:attachedTo}" \
				--output table
            ipname=$(echo `keep_user_input "请输入需要删除的IP名称："`)
			aws lightsail release-static-ip  --region=$region --static-ip-name $ipname
            lightsail-manager-instances
            ;;			 	 	
        返回)
            main
            ;;       
        *)
			lightsail-manager-instances
            echo "如果要退出，请按Ctrl+C"
            ;;
        esac
    done
}
#删除Lightsail
lightsail-delete-instance(){
read -p "【LS】如需删除所有请输入ALL,否则回车继续: " go_run
	[[ -z ${go_run} ]]
	case $go_run in
	ALL)
		for name in `aws lightsail get-instances  --region $region --query 'instances[*].{Name:name}' --output  text`
		do
			echo -e "\n删除LS实例:【'$name'】："
			aws lightsail delete-instance --region $region \
			--instance-name $name --output table
			sleep 2
		done
		;;	
	*)
		read -p "【LS】请输入需要被删除的实例Name: " name
		aws lightsail delete-instance --region $region \
			--instance-name $name --output table
		;;
	esac	
}

#获取EC2-Key-Pair
ec2-describe-key-pairs(){
		aws ec2 describe-key-pairs --region $region \
			--query 'KeyPairs[*].{KeyName:KeyName}' \
			--output table
}
#创建EC2-Key-Pair
ec2-create-key-pair(){
		read -p "【EC2】请输入key-name: " keyname
		echo  -e "${red}请复制保存下面生成的私钥！！！${black}"
		aws ec2 create-key-pair  --region $region --key-name $keyname 
}
#导入EC2-Key-Pair
ec2-import-key-pair(){
	echo  -e "${red}这里是通过你输入的公钥字符串写入文件，然后通过文件导入的，请先准备好公钥，复制里面全部信息！！！${black}"
	keyfilepath=/tmp/awspub.txt
	read -p "【EC2】请输入key-name(同一区域不能重复): " keyname
	read -p "【EC2】请输入公钥字符串: " pubkeystr
	echo $pubkeystr > $keyfilepath
	aws ec2 import-key-pair  --region $region --key-name "$keyname" --public-key-material fileb://$keyfilepath
	rm -rf /tmp/awspub.txt
}
ec2-import-key-pair-all-region(){
	echo  -e "${red}这里是通过你输入的公钥字符串写入文件，然后通过文件导入的，请先准备好公钥，复制里面全部信息！！！${black}"
	keyfilepath=/tmp/awspub.txt
	read -p "【EC2】请输入key-name(同一区域不能重复): " keyname
	read -p "【EC2】请输入公钥字符串: " pubkeystr
	echo $pubkeystr > $keyfilepath
	echo  -e "${red}开始导入...${black}"
	sleep 1
	for region in `aws ec2 describe-regions --output text | cut -f4`
	do
		echo -e "\n地区:【'$region'】："
		aws ec2 import-key-pair  --region $region --key-name "$keyname" --public-key-material fileb://$keyfilepath
		sleep 2
		ec2-describe-key-pairs
		sleep 1
	done
	rm -rf /tmp/awspub.txt
	echo  -e "${red}导入完成...${black}"
}
#删除EC2-Key-Pair
ec2-delete-key-pair(){
		read -p "【EC2】请输入需要删除的key-name: " keyname
		aws ec2 delete-key-pair  --region $region --key-name $keyname
}

#管理EC2-Key-Pair
ec2-key-pair(){
	echo  -e "${red}当前位置【管理EC2-Key-Pair】,请选择（请输入数字）？Ctrl+C 退出本脚本${black}"
	echo "当前Region：$region下EC2 Key Pair信息："
	ec2-describe-key-pairs
	select todo in 创建EC2-Key-Pair 导入EC2-Key-Pair 删除EC2-Key-Pair 返回
	do
		case $todo in
		创建EC2-Key-Pair)
			ec2-create-key-pair
			sleep 2	
			ec2-key-pair
			;;
		导入EC2-Key-Pair)
			read -p "导入当前区域[$region]，按回车继续，如需导入所有区域请输入ALL: " go_run
				[[ -z ${go_run} ]]
				case $go_run in
				ALL)
					ec2-import-key-pair-all-region
					;;	
				*)
					ec2-import-key-pair
					;;
				esac
			sleep 2	
			ec2-key-pair	
			;;
		删除EC2-Key-Pair)
			ec2-delete-key-pair
			sleep 2	
			ec2-key-pair	
			;;
		返回)
			break
			;;			
		*)
			echo "如果要退出，请按Ctrl+C"
			;;
		esac
	done
}
#获取LS-Key-Pair
lightsail-get-key-pairs(){
	aws lightsail get-key-pairs --region $region --query 'keyPairs[*].{KeyName:name,RegionName:location.regionName}' --output table
}
#导入LS-Key-Pair
lightsail-import-key-pair(){
read -p "【LS】请输入key-name: " keyname
		read -p "【LS】请输入public-key-base64公钥字符串: " publickeybase64
		aws lightsail import-key-pair --region $region  \
			--key-pair-name $keyname \
			--public-key-base64 "$publickeybase64"
}
lightsail-import-key-pair-all-region(){
	read -p "【LS】请输入key-name: " keyname
	read -p "【LS】请输入public-key-base64公钥字符串: " publickeybase64
	for region in `aws lightsail get-regions --region us-east-1  --output text | cut -f5`
	do
		echo -e "\n地区:【'$region'】："
		aws lightsail import-key-pair --region $region  \
			--key-pair-name $keyname \
			--public-key-base64 "$publickeybase64"
		sleep 3
	done
}
#创建LS-Key-Pair
lightsail-create-key-pair(){
read -p "【LS】请输入key-name: " keyname
		aws lightsail create-key-pair --region $region \
    		--key-pair-name $keyname
}
#下载默认LS-Key-Pair
lightsail-download-default-key-pair(){
aws lightsail download-default-key-pair --region $region
}
#删除LS-Key-Pair
lightsail-delete-key-pair(){
read -p "【LS】请输入需要删除的key-name: " keyname
aws lightsail delete-key-pair --region $region \
    		--key-pair-name $keyname
}


#管理LS-Key-Pair
ls-key-pair(){
	echo  -e "${red}当前位置【管理LS-Key-Pair】,请选择（请输入数字）？Ctrl+C 退出本脚本${black}"
	echo "当前Region：$region下LS Key Pair信息："
	lightsail-get-key-pairs
	select todo in 导入LS-Key-Pair 创建LS-Key-Pair 下载默认LS-Key-Pair  删除LS-Key-Pair 返回
	do
		case $todo in

		导入LS-Key-Pair)
			read -p "导入当前区域[$region]，按回车继续，如需导入所有区域请输入ALL: " go_run
			[[ -z ${go_run} ]]
			case $go_run in
			ALL)
				lightsail-import-key-pair-all-region
				;;	
			*)
				lightsail-import-key-pair
				;;
			esac
			sleep 2
			ls-key-pair
			;;
		创建LS-Key-Pair)
			lightsail-create-key-pair
			sleep 2
			ls-key-pair
			;;
		下载默认LS-Key-Pair)
			lightsail-download-default-key-pair
			sleep 2
			ls-key-pair
			;;			
		删除LS-Key-Pair)
			lightsail-delete-key-pair
			sleep 2
			ls-key-pair
			;;
		返回)
			break
			;;			
		*)
			echo "如果要退出，请按Ctrl+C"
			;;
		esac
	done
}


main(){
echo  -e "${red}当前位置【主菜单】,请选择（请输入数字）？Ctrl+C 退出本脚本${black}"
select todo in 创建EC2 查看EC2 管理EC2 删除EC2 创建Lightsail 查看Lightsail 管理Lightsail 删除Lightsail 切换大区 管理EC2-Key-Pair 管理LS-Key-Pair 安装AWSCli
do
	case $todo in
    创建EC2)
        ec2-run-instances
		main
        ;;
    查看EC2)
		read -p "查看当前区域下的EC2，回车继续，如需查看所有请输入ALL: " go_run
		[[ -z ${go_run} ]]
		case $go_run in
		ALL)
			ec2-describe-instances-all-regions
			;;	
		*)
			ec2-describe-instances
			;;
		esac
		main
        ;;
	管理EC2)
		ec2-manager-instances
		main
        ;;	
    删除EC2)
        ec2-terminate-instances
		main
        ;;
	创建Lightsail)
        lightsail-create-instances
		lightsail-get-instances
		main
        ;;
    查看Lightsail)
		read -p "查看当前区域下的LS，回车继续，如需查看所有请输入ALL: " go_run
		[[ -z ${go_run} ]]
		case $go_run in
		ALL)
			lightsail-get-instances-all-regions
			;;	
		*)
			lightsail-get-instances
			;;
		esac
		main
        ;;
    管理Lightsail)
        lightsail-manager-instances
		main
        ;;		
	删除Lightsail)
		lightsail-get-instances
        lightsail-delete-instance
		main
        ;;
	切换大区)
        change-regions
		main
        ;;
	管理EC2-Key-Pair)
        ec2-key-pair
		main
        ;;		
	管理LS-Key-Pair)
        ls-key-pair
		main
        ;;		
    安装AWSCli)
		if type aws >/dev/null 2>&1; then 
			echo "Aws Cli 已经安装。"
			aws --version
		fi
        ;;
    *)
        echo "如果要退出，请按Ctrl+C"
        ;;
    esac
done
}

main
