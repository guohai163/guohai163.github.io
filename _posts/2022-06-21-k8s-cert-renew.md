---
layout: post
title:  "基于K8S环境的 证书过期的处理"
date:   2022-06-21 10:10:00
categories: [develop]
tags: [k8s, java]
image: /doc-pic/2022/sb-love-k8s.png
---

k8s的证书正常情况下一年一过期，今天我遇到了。来说下中间的处理过程也做个记录。

## 现象

在k8s执行任何操作时都会报一个错误 `Unable to connect to the server: x509: certificate has expired or is not yet valid: current time 2022-06-21T13:10:21+08:00 is after 2022-06-21T05:07:15Z`

在master节点执行 `kubeadm certs check-expiration`可以查看一下证书的有效期

~~~ shell
$ kubeadm certs check-expiration
[check-expiration] Reading configuration from the cluster...
[check-expiration] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'

CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
admin.conf                 Jun 21, 2022 05:19 UTC   0d                                    no
apiserver                  Jun 21, 2022 05:20 UTC   0d            ca                      no
apiserver-etcd-client      Jun 21, 2022 05:19 UTC   0d            etcd-ca                 no
apiserver-kubelet-client   Jun 21, 2022 05:19 UTC   0d            ca                      no
controller-manager.conf    Jun 21, 2022 05:19 UTC   0d                                    no
etcd-healthcheck-client    Jun 21, 2022 05:19 UTC   0d            etcd-ca                 no
etcd-peer                  Jun 21, 2022 05:19 UTC   0d            etcd-ca                 no
etcd-server                Jun 21, 2022 05:19 UTC   0d            etcd-ca                 no
front-proxy-client         Jun 21, 2022 05:19 UTC   0d            front-proxy-ca          no
scheduler.conf             Jun 21, 2022 05:19 UTC   0d                                    no

CERTIFICATE AUTHORITY   EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
ca                      Jun 19, 2031 05:07 UTC   8y              no
etcd-ca                 Jun 19, 2031 05:07 UTC   8y              no
front-proxy-ca          Jun 19, 2031 05:07 UTC   8y              no
~~~

## 初步处理

1. 有两种选择，一种是更新k8s版本。证书会自动续期，但风险太大，万一出现插件不兼容。方案二就是执行 `kubeadm certs renew all`所有证书会向后延期一年。
2. 证书更新后还需要 更新下你手里的kube/config文件 `cp -i /etc/kubernetes/admin.conf /root/.kube/config`
3. 证书续费后你使用kubectl get pods之类的命令都会是正常状态，但一旦要创建新的pod都说发现新pod的状态都是pendding的状态，使用`kubectl get pods -o wide`会发现新的pod都没法命中具体的node节点。
4. 这时我们要做的是要重启下k8s的环境 `systemctl restart kubelet`
5. 接下来要重启kube-apiserver、kube-controller-manager、kube-scheduler的三个pod.如果用 delete pod方式不会生效，需要使用
    ~~~ shell
        # docker ps |grep kube-apiserver|grep -v pause|awk '{print $1}'|xargs -i docker restart {}
        # docker ps |grep kube-controller-manage|grep -v pause|awk '{print $1}'|xargs -i docker restart {}
        # docker ps |grep kube-scheduler|grep -v pause|awk '{print $1}'|xargs -i docker restart {}
    ~~~

## 所有操作结束