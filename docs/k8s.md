## *Kubernetes*

### *K9s*

- #### *A.　安裝方式*
```
curl -sS https://webinstall.dev/k9s | bash

安裝完後，重啟終端機或輸入 source ~/.config/envman/PATH.env 即可生效
```

- #### *B.　使用方式*
```
: ：輸入命令（例如 :pod 看 Pod, :node 看節點）

/ ：過濾關鍵字

d ：Describe（查看詳細描述）

l ：Logs（查看日誌）

esc ：返回上一層
```

<br>

### *MiniKube*
- #### *A.　部署指令範例*
```
在 Helm 中，我們不重複寫 YAML，而是透過不同的 values.yaml 來切割：
- Dev: 副本數 = 1, 使用 MiniKube 的 standard storage class
- Prod: 副本數 = 3, 使用雲端 SSD storage class, 並限制 CPU/Memory 資源

helm install my-app ./helm/app-stack -f ./helm/app-stack/values-dev.yaml --namespace dev
helm install my-app ./helm/app-stack -f ./helm/app-stack/values-prod.yaml --namespace prod
```


<br>