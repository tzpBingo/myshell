red="\033[31m"
black="\033[0m"

#====================================================#
#	System Request:Ubuntu 18.04+/Centos 7+			 #
#	Author:	tzpbingo								 #
#	Dscription: az cli shell manager				 #
#	Version: 1.0									 #
#	email:tzpbingo@gmail.com						 #
#====================================================#

echo "当前登录用户下所有订阅:"
default_subscription=$(az account list --query '[?isDefault].id'  -o tsv)
az account list --query '[].{Name:name, ID:id,Status:state}' -o table
read -rp "请选择订阅（Default: $default_subscription）:" subscription
[[ -z ${subscription} ]] && subscription="$default_subscription"
echo -e "${red}你选择了【$subscription】,接下来的操作都会使用该订阅。"
az account set --subscription  "$subscription"

az account subscription list-location --subscription-id "$subscription" -o table
read -rp "请选择地区location（Default: eastasia）:" location
[[ -z ${location} ]] && location="eastasia"
echo -e "${red}你选择了【$location】,接下来的操作都会该地区下。"

#查询所有VM
az-vm-list(){
    az graph query -q "Resources | where type =~ 'microsoft.compute/virtualmachines' \
    | extend nics=array_length(properties.networkProfile.networkInterfaces) \
    | mv-expand nic=properties.networkProfile.networkInterfaces \
    | where nics == 1 or nic.properties.primary =~ 'true' or isempty(nic) \
    | project vmId = id, location = location, resourceGroup = resourceGroup, vmName = name, status = tostring(properties.extended.instanceView.powerState.displayStatus), OS = tostring(properties.storageProfile.imageReference.offer), vmSize=tostring(properties.hardwareProfile.vmSize), nicId = tostring(nic.id) \
    | join kind=leftouter \
    ( Resources \
    | where type =~ 'microsoft.network/networkinterfaces' \
    | extend ipConfigsCount=array_length(properties.ipConfigurations) \
    | mv-expand ipconfig=properties.ipConfigurations | where ipConfigsCount == 1 or ipconfig.properties.primary =~ 'true' \
    | project nicId = id, publicIpId = tostring(ipconfig.properties.publicIPAddress.id)) on nicId \
    | project-away nicId1 \
    | summarize by vmId, location, status, resourceGroup, OS, vmName, vmSize, nicId, publicIpId \
    | join kind=leftouter \
    ( Resources \
    | where type =~ 'Microsoft.Network/publicIPAddresses' \
    | project publicIpId = id, publicIpAddress = properties.ipAddress) on publicIpId \
    | project-away publicIpId1 \
    | project-away nicId,publicIpId,vmId"  -o table
}
#管理VM
az-vm-manager(){
    az-vm-list
    echo  -e "${red}当前位置【管理VM】,请选择（请输入数字）？Ctrl+C 退出本脚本${black}"
    select todo in 开机 关机 重启 删除 返回
    do
        case $todo in
        开机)
            vmname=$(echo `keep_user_input "请输入VM名称："`)
            group=$(echo `keep_user_input "请输入资源组名："`)
            az vm start -g $group -n $vmname
            az-vm-manager
            ;;
        关机)
            vmname=$(echo `keep_user_input "请输入VM名称："`)
            group=$(echo `keep_user_input "请输入资源组名："`)
            az vm stop -g $group -n $vmname
            az-vm-manager
            ;;
        重启)
            vmname=$(echo `keep_user_input "请输入VM名称："`)
            group=$(echo `keep_user_input "请输入资源组名："`)
            az vm restart -g $group -n $vmname
            az-vm-manager
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
#查看地区
az-list-location(){
    az account subscription list-location --subscription-id "$subscription" -o table
}
#查询实例类型
az-vm-list-sizes(){
    echo -e "${red}默认查询Standard_B，核心数少于4的实例。"
    az vm list-sizes -l $location --query "sort_by(@,&name)[?contains(name, \`_B\`) && numberOfCores <= \`4\`]" -o table
}
#查看镜像
az-vm-image-list(){
    az vm image list -o table --location $location
}
#删除VM
az-vm-delete(){
    vmname=$(echo `keep_user_input "请输入需要删除的VM名称："`)
    az resource list --location $location \
        --query "[?resourceGroup=='$vmname-resource-group'].{ Group: resourceGroup, Name:name ,Type:type}" \
        -o table
    read -p "【AZURE】本脚本是按照资源组删除，请确认上面的信息(Y/N): " go_delete
    [[ -z ${go_delete} ]] && go_delete="Y"
    case $go_delete in
    [yY][eE][sS]|[yY])
        echo -e "${GreenBG} 删除资源... ${Font}"
        az group delete --name $vmname-resource-group --no-wait --yes
        ;;
    *)
        echo -e "${RedBG} 终止删除... ${Font}"
        break
        ;;
    esac
}
keep_user_input(){
    info=$1
    read -rp "$info:" input
    while [[ -z ${input} ]]
    do
        keep_input $info
    done
    echo $input
}
#创建VM
az-vm-create(){

    vmname=$(echo `keep_user_input "请输入VM名称："`)

    az-vm-list-sizes
    read -rp "请选择实例类型size（Default: Standard_B1s）:" size
    [[ -z ${size} ]] && size="Standard_B1s"
    echo -e "${red}你选择了【$size】。"

    az-vm-image-list
    read -rp "请选择镜像image（Default: UbuntuLTS）:" image
    [[ -z ${image} ]] && image="UbuntuLTS"
    echo -e "${red}你选择了【$image】。"

    username=$(echo `keep_user_input "请输入实例用户名:"`)
    password=$(echo `keep_user_input "请输入实例密码（密码需要一位大写、一个特殊符号、长度大于12）:"`)

    printf "%-10s %-10s\n" vmname: $vmname
    printf "%-10s %-10s\n" group: $vmname-resource-group
    printf "%-10s %-10s\n" location: $location
    printf "%-10s %-10s\n" size: $size
    printf "%-10s %-10s\n" image: $image
    printf "%-10s %-10s\n" username: $username
    printf "%-10s %-10s\n" password: $password

    read -p "【AZURE】请确认实例信息(Y/N): " go_create
        [[ -z ${go_create} ]] && go_create="Y"
        case $go_create in
        [yY][eE][sS]|[yY])
            echo -e "${GreenBG} 开始创建资源组... ${Font}"
            az group create --name $vmname"-resource-group" --location $location
            echo -e "${GreenBG} 开始创建VM... ${Font}"
            sleep 1
            az vm create \
                --resource-group $vmname"-resource-group" \
                --name $vmname \
                --size $size \
                --location $location \
                --image $image \
                --admin-username $username \
                --admin-password $password -o table\

            echo -e "${GreenBG} 默认放开全部端口... ${Font}"    
            az vm open-port -g $vmname"-resource-group" -n $vmname --port '*' -o table    
            ;;
        *)
            echo -e "${RedBG} 终止创建... ${Font}"
            break
            ;;
        esac
}

main(){
echo  -e "${red}当前位置【主菜单】,请选择（请输入数字）？Ctrl+C 退出本脚本${black}"
select todo in 创建VM 查看VM 管理VM 删除VM 安装AZCli
do
	case $todo in
    创建VM)
		az-vm-create
		main
        ;;
    查看VM)
		az-vm-list
		main
        ;;
    管理VM)
		az-vm-manager
		main
        ;;    
    删除VM)
        az-vm-delete
		main
        ;;	
    安装AZCli)
        if type az >/dev/null 2>&1; then 
        echo 'AZCli已经安装过。' 
        else 
        echo 'AZCli不存在，请先安装。' 
        fi
        ;;
    *)
        echo "如果要退出，请按Ctrl+C"
        ;;
    esac
done
}

main