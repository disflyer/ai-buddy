#!/bin/bash

# 设置错误时退出
set -e

# 检查必要的环境变量
if [ -z "$PROJECT_ID" ]; then
    echo "错误: 未设置 PROJECT_ID 环境变量"
    exit 1
fi

if [ -z "$ENV" ]; then
    echo "错误: 未设置 ENV 环境变量"
    exit 1
fi

if [ -z "$REGION" ]; then
    echo "错误: 未设置 REGION 环境变量"
    exit 1
fi

echo "开始导入资源状态..."
echo "项目ID: $PROJECT_ID"
echo "环境: $ENV"
echo "区域: $REGION"

# 进入GKE集群目录
cd "$(dirname "$0")/../environments/$ENV/gke_cluster"

# 导入NAT Router
echo "导入 NAT Router..."
terragrunt import \
  "google_compute_router.router[0]" \
  "projects/$PROJECT_ID/regions/$REGION/routers/${ENV}-nat-router" || {
    echo "警告: NAT Router 导入失败，可能资源不存在"
}

# 导入Cloud NAT
echo "导入 Cloud NAT..."
terragrunt import \
  "google_compute_router_nat.nat[0]" \
  "projects/$PROJECT_ID/regions/$REGION/routers/${ENV}-nat-router/nats/${ENV}-cloud-nat" || {
    echo "警告: Cloud NAT 导入失败，可能资源不存在"
}

# 导入GKE集群
echo "导入 GKE 集群..."
terragrunt import \
  "google_container_cluster.primary" \
  "projects/$PROJECT_ID/locations/$REGION/clusters/ai-buddy-cluster" || {
    echo "警告: GKE 集群导入失败，可能资源不存在"
}

# 导入节点池
echo "导入主节点池..."
terragrunt import \
  "google_container_node_pool.primary_nodes" \
  "projects/$PROJECT_ID/locations/$REGION/clusters/ai-buddy-cluster/${ENV}-primary-pool" || {
    echo "警告: 主节点池导入失败，可能资源不存在"
}

# 如果是生产环境，导入生产专用节点池
if [ "$ENV" = "prod" ]; then
    echo "导入生产专用节点池..."
    terragrunt import \
      "google_container_node_pool.prod_nodes[0]" \
      "projects/$PROJECT_ID/locations/$REGION/clusters/ai-buddy-cluster/prod-dedicated-pool" || {
        echo "警告: 生产专用节点池导入失败，可能资源不存在"
    }
fi

# 导入服务账号
echo "导入节点服务账号..."
terragrunt import \
  "google_service_account.gke_node" \
  "projects/$PROJECT_ID/serviceAccounts/${ENV}-gke-node@$PROJECT_ID.iam.gserviceaccount.com" || {
    echo "警告: 服务账号导入失败，可能资源不存在"
}

echo "资源导入完成！"
echo "请运行 'terragrunt plan' 检查状态是否正确同步。" 