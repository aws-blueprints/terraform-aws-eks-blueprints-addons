output "aws_cloudwatch_metrics" {
  description = "Map of attributes of the Helm release and IRSA created"
  value       = module.aws_cloudwatch_metrics
}

output "aws_efs_csi_driver" {
  description = "Map of attributes of the Helm release and IRSA created"
  value       = module.aws_efs_csi_driver
}

output "aws_fsx_csi_driver" {
  description = "Map of attributes of the Helm release and IRSA created"
  value       = module.aws_fsx_csi_driver
}

output "aws_load_balancer_controller" {
  description = "Map of attributes of the Helm release and IRSA created"
  value       = module.aws_load_balancer_controller
}

output "aws_node_termination_handler" {
  description = "Map of attributes of the Helm release and IRSA created"
  value = merge(
    module.aws_node_termination_handler,
    {
      sqs = module.aws_node_termination_handler_sqs
    }
  )
}

output "aws_privateca_issuer" {
  description = "Map of attributes of the Helm release and IRSA created"
  value       = module.aws_privateca_issuer
}

output "cert_manager" {
  description = "Map of attributes of the Helm release and IRSA created"
  value       = module.cert_manager
}

output "cluster_autoscaler" {
  description = "Map of attributes of the Helm release and IRSA created"
  value       = module.cluster_autoscaler
}

output "external_dns" {
  description = "Map of attributes of the Helm release and IRSA created"
  value       = module.external_dns
}

output "external_secrets" {
  description = "Map of attributes of the Helm release and IRSA created"
  value       = module.external_secrets
}

output "karpenter" {
  description = "Map of attributes of the Helm release and IRSA created"
  value = merge(
    module.karpenter,
    {
      node_instance_profile_name = try(aws_iam_instance_profile.karpenter[0].name, "")
      node_iam_role_arn          = try(aws_iam_role.karpenter[0].arn, "")
      node_iam_role_name         = try(aws_iam_role.karpenter[0].name, "")
      sqs                        = module.karpenter_sqs
    }
  )
}

output "velero" {
  description = "Map of attributes of the Helm release and IRSA created"
  value       = module.velero
}

output "aws_gateway_api_controller" {
  description = "Map of attributes of the Helm release and IRSA created"
  value       = module.aws_gateway_api_controller
}
