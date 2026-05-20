## *K3s Migration*

### *A.　Makefile Command*
```
Terraform:
    # 初始化 terraform 配置
    make init
    
    # 安裝 VM 環境 ( 包括: deploy_k3s.yml + init_nodes.yml ) => SSH 無密碼登入
    make apply
    
    # 拆除 VM 環境
    make destroy

Ansible:
    # 檢視狀態 ( pods + nodes )
    make status
    
    # VM 關機 ( K3s 集群 )
    make power-manage action=stop
    
    # VM 重新啟動 ( K3s 集群 )
    make power-manage action=reboot

Kubectl ( k ):
    # 標籤設置，節點 0 為 Master，接著 2 個節點的 service-type 為 app，其餘為 service
    make label-nodes app=2
    
Helm:
    # [暫時] 塞本地 imags 到 VM
        make save IMAGE_NAME=my-python-app TAG=v5 TAR_FILE=my-python-app.tar
        make load-images TAR_FILE=my-python-app.tar
    
    # 部署 v5 版本測試腳本
    make deploy ver=v5
```

