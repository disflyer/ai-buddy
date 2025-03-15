#!/bin/bash
set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 帮助信息
function show_help {
  echo -e "${YELLOW}使用方法:${NC}"
  echo -e "  $0 [选项]"
  echo
  echo -e "${YELLOW}选项:${NC}"
  echo -e "  -h, --help         显示帮助信息"
  echo -e "  -i, --infra        仅部署基础设施"
  echo -e "  -a, --app          仅部署应用"
  echo -e "  -e, --env ENV      指定环境 (staging 或 prod，默认: staging)"
  echo -e "  -p, --plan         仅显示 Terraform 计划，不应用"
  echo
  echo -e "${YELLOW}示例:${NC}"
  echo -e "  $0 -i -e prod      部署生产环境基础设施"
  echo -e "  $0 -a -e staging   部署测试环境应用"
}

# 默认值
DEPLOY_INFRA=false
DEPLOY_APP=false
ENVIRONMENT="staging"
PLAN_ONLY=false

# 解析参数
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    -i|--infra)
      DEPLOY_INFRA=true
      shift
      ;;
    -a|--app)
      DEPLOY_APP=true
      shift
      ;;
    -e|--env)
      ENVIRONMENT="$2"
      shift 2
      ;;
    -p|--plan)
      PLAN_ONLY=true
      shift
      ;;
    *)
      echo -e "${RED}错误: 未知选项 $1${NC}"
      show_help
      exit 1
      ;;
  esac
done

# 如果没有指定部署类型，则默认全部部署
if [[ "$DEPLOY_INFRA" == "false" && "$DEPLOY_APP" == "false" ]]; then
  DEPLOY_INFRA=true
  DEPLOY_APP=true
fi

# 验证环境
if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "prod" ]]; then
  echo -e "${RED}错误: 环境必须是 staging 或 prod${NC}"
  exit 1
fi

# 部署基础设施
if [[ "$DEPLOY_INFRA" == "true" ]]; then
  echo -e "${GREEN}开始部署基础设施...${NC}"
  
  cd terraform/main
  
  # 初始化 Terraform
  echo -e "${YELLOW}初始化 Terraform...${NC}"
  terraform init
  
  # 计划或应用
  if [[ "$PLAN_ONLY" == "true" ]]; then
    echo -e "${YELLOW}生成 Terraform 计划...${NC}"
    terraform plan
  else
    echo -e "${YELLOW}应用 Terraform 配置...${NC}"
    terraform apply -auto-approve
    
    # 提取基本配置信息
    PROJECT_ID=$(grep -E "^project_id\s*=" terraform.tfvars | cut -d'"' -f2)
    REGION=$(grep -E "^region\s*=" terraform.tfvars | cut -d'"' -f2)
    ZONE="${REGION}-a"  # 使用可用区而非区域
    CLUSTER_NAME=$(terraform output -raw kubernetes_cluster_name)
    
    # 导出集群凭证
    echo -e "${YELLOW}获取集群凭证...${NC}"
    gcloud container clusters get-credentials ${CLUSTER_NAME} --zone ${ZONE} --project ${PROJECT_ID}
    
    # 导出镜像仓库路径
    export REGISTRY_PATH=$(terraform output -raw image_registry_path)
    echo -e "${GREEN}镜像仓库路径: $REGISTRY_PATH${NC}"
  fi
  
  cd ../..
fi

# 部署应用
if [[ "$DEPLOY_APP" == "true" ]]; then
  echo -e "${GREEN}开始部署 $ENVIRONMENT 环境应用...${NC}"
  
  # 如果没有部署基础设施，需要获取镜像仓库路径
  if [[ "$DEPLOY_INFRA" == "false" ]]; then
    cd terraform/main
    export REGISTRY_PATH=$(terraform output -raw image_registry_path)
    cd ../..
  fi
  
  # 替换镜像仓库路径
  echo -e "${YELLOW}更新镜像仓库路径...${NC}"
  sed -i.bak "s|REGISTRY_PATH|$REGISTRY_PATH|g" kubernetes/overlays/$ENVIRONMENT/kustomization.yaml
  
  # 应用 Kustomize 配置
  echo -e "${YELLOW}应用 Kubernetes 配置...${NC}"
  kubectl apply -k kubernetes/overlays/$ENVIRONMENT/
  
  # 恢复原始文件
  mv kubernetes/overlays/$ENVIRONMENT/kustomization.yaml.bak kubernetes/overlays/$ENVIRONMENT/kustomization.yaml
  
  echo -e "${GREEN}$ENVIRONMENT 环境应用部署完成${NC}"
fi

echo -e "${GREEN}部署完成!${NC}" 