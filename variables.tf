variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes `<major>.<minor>` version to use for the EKS cluster (i.e.: `1.24`)"
  type        = string
}

variable "oidc_provider_arn" {
  description = "The ARN of the cluster OIDC Provider"
  type        = string
}

variable "create_delay_duration" {
  description = "The duration to wait before creating resources"
  type        = string
  default     = "30s"
}

variable "create_delay_dependencies" {
  description = "Dependency attribute which must be resolved before starting the `create_delay_duration`"
  type        = list(string)
  default     = []
}

variable "enable_eks_fargate" {
  description = "Identifies whether or not respective addons should be modified to support deployment on EKS Fargate"
  type        = bool
  default     = false
}

################################################################################
# AWS Cloudwatch Metrics
################################################################################

variable "enable_aws_cloudwatch_metrics" {
  description = "Enable AWS Cloudwatch Metrics add-on for Container Insights"
  type        = bool
  default     = false
}

variable "aws_cloudwatch_metrics" {
  description = "Cloudwatch Metrics add-on configuration values"
  type        = any
  default     = {}
}

################################################################################
# AWS EFS CSI Driver
################################################################################

variable "enable_aws_efs_csi_driver" {
  description = "Enable AWS EFS CSI Driver add-on"
  type        = bool
  default     = false
}

variable "aws_efs_csi_driver" {
  description = "EFS CSI Driver add-on configuration values"
  type        = any
  default     = {}
}

################################################################################
# AWS FSx CSI Driver
################################################################################

variable "enable_aws_fsx_csi_driver" {
  description = "Enable AWS FSX CSI Driver add-on"
  type        = bool
  default     = false
}

variable "aws_fsx_csi_driver" {
  description = "FSX CSI Driver add-on configuration values"
  type        = any
  default     = {}
}

################################################################################
# AWS Load Balancer Controller
################################################################################

variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller add-on"
  type        = bool
  default     = false
}

variable "aws_load_balancer_controller" {
  description = "AWS Load Balancer Controller add-on configuration values"
  type        = any
  default     = {}
}

################################################################################
# AWS Node Termination Handler
################################################################################

variable "enable_aws_node_termination_handler" {
  description = "Enable AWS Node Termination Handler add-on"
  type        = bool
  default     = false
}

variable "aws_node_termination_handler" {
  description = "AWS Node Termination Handler add-on configuration values"
  type        = any
  default     = {}
}

variable "aws_node_termination_handler_sqs" {
  description = "AWS Node Termination Handler SQS queue configuration values"
  type        = any
  default     = {}
}

variable "aws_node_termination_handler_asg_arns" {
  description = "List of Auto Scaling group ARNs that AWS Node Termination Handler will monitor for EC2 events"
  type        = list(string)
  default     = []
}

variable "aws_node_termination_handler_asg_names" {
  description = "List of Auto Scaling group names that AWS Node Termination Handler will monitor for EC2 events. If leaving this empty, all ASGs will be monitored"
  type        = list(string)
  default     = []
}

################################################################################
# AWS Private CA Issuer
################################################################################

variable "enable_aws_privateca_issuer" {
  description = "Enable AWS PCA Issuer"
  type        = bool
  default     = false
}

variable "aws_privateca_issuer" {
  description = "AWS PCA Issuer add-on configurations"
  type        = any
  default     = {}
}

################################################################################
# Cert Manager
################################################################################

variable "enable_cert_manager" {
  description = "Enable cert-manager add-on"
  type        = bool
  default     = false
}

variable "cert_manager" {
  description = "cert-manager add-on configuration values"
  type        = any
  default     = {}
}

variable "cert_manager_route53_hosted_zone_arns" {
  description = "List of Route53 Hosted Zone ARNs that are used by cert-manager to create DNS records"
  type        = list(string)
  default     = ["arn:aws:route53:::hostedzone/*"]
}

################################################################################
# Cluster Autoscaler
################################################################################

variable "enable_cluster_autoscaler" {
  description = "Enable Cluster autoscaler add-on"
  type        = bool
  default     = false
}

variable "cluster_autoscaler" {
  description = "Cluster Autoscaler add-on configuration values"
  type        = any
  default     = {}
}

################################################################################
# External DNS
################################################################################

variable "enable_external_dns" {
  description = "Enable external-dns operator add-on"
  type        = bool
  default     = false
}

variable "external_dns" {
  description = "external-dns add-on configuration values"
  type        = any
  default     = {}
}

variable "external_dns_route53_zone_arns" {
  description = "List of Route53 zones ARNs which external-dns will have access to create/manage records (if using Route53)"
  type        = list(string)
  default     = []
}

################################################################################
# External Secrets
################################################################################

variable "enable_external_secrets" {
  description = "Enable External Secrets operator add-on"
  type        = bool
  default     = false
}

variable "external_secrets" {
  description = "External Secrets add-on configuration values"
  type        = any
  default     = {}
}

variable "external_secrets_ssm_parameter_arns" {
  description = "List of Systems Manager Parameter ARNs that contain secrets to mount using External Secrets"
  type        = list(string)
  default     = ["arn:aws:ssm:*:*:parameter/*"]
}

variable "external_secrets_secrets_manager_arns" {
  description = "List of Secrets Manager ARNs that contain secrets to mount using External Secrets"
  type        = list(string)
  default     = ["arn:aws:secretsmanager:*:*:secret:*"]
}

variable "external_secrets_kms_key_arns" {
  description = "List of KMS Key ARNs that are used by Secrets Manager that contain secrets to mount using External Secrets"
  type        = list(string)
  default     = ["arn:aws:kms:*:*:key/*"]
}

################################################################################
# Karpenter
################################################################################

variable "enable_karpenter" {
  description = "Enable Karpenter controller add-on"
  type        = bool
  default     = false
}

variable "karpenter" {
  description = "Karpenter add-on configuration values"
  type        = any
  default     = {}
}

variable "karpenter_enable_spot_termination" {
  description = "Determines whether to enable native node termination handling"
  type        = bool
  default     = true
}

variable "karpenter_enable_instance_profile_creation" {
  description = "Determines whether Karpenter will be allowed to create the IAM instance profile (v1beta1) or if Terraform will (v1alpha1)"
  type        = bool
  default     = true
}

variable "karpenter_sqs" {
  description = "Karpenter SQS queue for native node termination handling configuration values"
  type        = any
  default     = {}
}

variable "karpenter_node" {
  description = "Karpenter IAM role and IAM instance profile configuration values"
  type        = any
  default     = {}
}

################################################################################
# Velero
################################################################################

variable "enable_velero" {
  description = "Enable Kubernetes Dashboard add-on"
  type        = bool
  default     = false
}

variable "velero" {
  description = "Velero add-on configuration values"
  type        = any
  default     = {}
}

################################################################################
#  AWS Gateway API Controller
################################################################################

variable "enable_aws_gateway_api_controller" {
  description = "Enable AWS Gateway API Controller add-on"
  type        = bool
  default     = false
}

variable "aws_gateway_api_controller" {
  description = "AWS Gateway API Controller add-on configuration values"
  type        = any
  default     = {}
}
