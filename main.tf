data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# This resource is used to provide a means of mapping an implicit dependency
# between the cluster and the addons.
resource "time_sleep" "this" {
  create_duration = var.create_delay_duration

  triggers = {
    cluster_endpoint  = var.cluster_endpoint
    cluster_name      = var.cluster_name
    custom            = join(",", var.create_delay_dependencies)
    oidc_provider_arn = var.oidc_provider_arn
  }
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.region

  # Threads the sleep resource into the module to make the dependency
  cluster_endpoint  = time_sleep.this.triggers["cluster_endpoint"]
  cluster_name      = time_sleep.this.triggers["cluster_name"]
  oidc_provider_arn = time_sleep.this.triggers["oidc_provider_arn"]

  iam_role_policy_prefix = "arn:${local.partition}:iam::aws:policy"

  # Used by Karpenter & AWS Node Termination Handler
  ec2_events = {
    health_event = {
      name        = "HealthEvent"
      description = "AWS health event"
      event_pattern = merge(
        {
          source      = ["aws.health"]
          detail-type = ["AWS Health Event"]
        },
        try(length(var.aws_node_termination_handler_asg_names) > 0 ? {
          detail = {
            AutoScalingGroupName = var.aws_node_termination_handler_asg_names
          }
        } : {}, {})
      )
    }
    spot_interupt = {
      name        = "SpotInterrupt"
      description = "EC2 spot instance interruption warning"
      event_pattern = merge(
        {
          source      = ["aws.ec2"]
          detail-type = ["EC2 Spot Instance Interruption Warning"]
        },
        try(length(var.aws_node_termination_handler_asg_names) > 0 ? {
          detail = {
            AutoScalingGroupName = var.aws_node_termination_handler_asg_names
          }
        } : {}, {})
      )
    }
    instance_rebalance = {
      name        = "InstanceRebalance"
      description = "EC2 instance rebalance recommendation"
      event_pattern = merge(
        {
          source      = ["aws.ec2"]
          detail-type = ["EC2 Instance Rebalance Recommendation"]
        },
        try(length(var.aws_node_termination_handler_asg_names) > 0 ? {
          detail = {
            AutoScalingGroupName = var.aws_node_termination_handler_asg_names
          }
        } : {}, {})
      )
    }
    instance_state_change = {
      name        = "InstanceStateChange"
      description = "EC2 instance state-change notification"
      event_pattern = merge(
        {
          source      = ["aws.ec2"]
          detail-type = ["EC2 Instance State-change Notification"]
        },
        try(length(var.aws_node_termination_handler_asg_names) > 0 ? {
          detail = {
            AutoScalingGroupName = var.aws_node_termination_handler_asg_names
          }
        } : {}, {})
      )
    }
  }
}

################################################################################
# AWS Cloudwatch Metrics
################################################################################

locals {
  aws_cloudwatch_metrics_service_account = try(var.aws_cloudwatch_metrics.service_account_name, "aws-cloudwatch-metrics")
  aws_cloudwatch_metrics_namespace       = try(var.aws_cloudwatch_metrics.namespace, "amazon-cloudwatch")
}

module "aws_cloudwatch_metrics" {
  source  = "aws-blueprints/eks-blueprints-addon/aws"
  version = "2.0.0"

  create = var.enable_aws_cloudwatch_metrics

  # https://github.com/aws/eks-charts/tree/master/stable/aws-cloudwatch-metrics
  name             = try(var.aws_cloudwatch_metrics.name, "aws-cloudwatch-metrics")
  description      = try(var.aws_cloudwatch_metrics.description, "A Helm chart to deploy aws-cloudwatch-metrics project")
  namespace        = local.aws_cloudwatch_metrics_namespace
  create_namespace = try(var.aws_cloudwatch_metrics.create_namespace, true)
  chart            = try(var.aws_cloudwatch_metrics.chart, "aws-cloudwatch-metrics")
  chart_version    = try(var.aws_cloudwatch_metrics.chart_version, "0.0.10")
  repository       = try(var.aws_cloudwatch_metrics.repository, "https://aws.github.io/eks-charts")
  values           = try(var.aws_cloudwatch_metrics.values, [])

  timeout                    = try(var.aws_cloudwatch_metrics.timeout, null)
  repository_key_file        = try(var.aws_cloudwatch_metrics.repository_key_file, null)
  repository_cert_file       = try(var.aws_cloudwatch_metrics.repository_cert_file, null)
  repository_ca_file         = try(var.aws_cloudwatch_metrics.repository_ca_file, null)
  repository_username        = try(var.aws_cloudwatch_metrics.repository_username, null)
  repository_password        = try(var.aws_cloudwatch_metrics.repository_password, null)
  devel                      = try(var.aws_cloudwatch_metrics.devel, null)
  verify                     = try(var.aws_cloudwatch_metrics.verify, null)
  keyring                    = try(var.aws_cloudwatch_metrics.keyring, null)
  disable_webhooks           = try(var.aws_cloudwatch_metrics.disable_webhooks, null)
  reuse_values               = try(var.aws_cloudwatch_metrics.reuse_values, null)
  reset_values               = try(var.aws_cloudwatch_metrics.reset_values, null)
  force_update               = try(var.aws_cloudwatch_metrics.force_update, null)
  recreate_pods              = try(var.aws_cloudwatch_metrics.recreate_pods, null)
  cleanup_on_fail            = try(var.aws_cloudwatch_metrics.cleanup_on_fail, null)
  max_history                = try(var.aws_cloudwatch_metrics.max_history, null)
  atomic                     = try(var.aws_cloudwatch_metrics.atomic, null)
  skip_crds                  = try(var.aws_cloudwatch_metrics.skip_crds, null)
  render_subchart_notes      = try(var.aws_cloudwatch_metrics.render_subchart_notes, null)
  disable_openapi_validation = try(var.aws_cloudwatch_metrics.disable_openapi_validation, null)
  wait                       = try(var.aws_cloudwatch_metrics.wait, false)
  wait_for_jobs              = try(var.aws_cloudwatch_metrics.wait_for_jobs, null)
  dependency_update          = try(var.aws_cloudwatch_metrics.dependency_update, null)
  replace                    = try(var.aws_cloudwatch_metrics.replace, null)
  lint                       = try(var.aws_cloudwatch_metrics.lint, null)

  postrender = try(var.aws_cloudwatch_metrics.postrender, [])
  set = concat(
    [
      {
        name  = "clusterName"
        value = local.cluster_name
      },
      {
        name  = "serviceAccount.name"
        value = local.aws_cloudwatch_metrics_service_account
      },
      {
        name                  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
        value_is_iam_role_arn = true
      }
    ],
    try(var.aws_cloudwatch_metrics.set, [])
  )
  set_sensitive = try(var.aws_cloudwatch_metrics.set_sensitive, [])

  # IAM role for service account (IRSA)
  role_name                     = try(var.aws_cloudwatch_metrics.role_name, "aws-cloudwatch-metrics")
  role_name_use_prefix          = try(var.aws_cloudwatch_metrics.role_name_use_prefix, true)
  role_path                     = try(var.aws_cloudwatch_metrics.role_path, "/")
  role_permissions_boundary_arn = try(var.aws_cloudwatch_metrics.role_permissions_boundary_arn, null)
  role_description              = try(var.aws_cloudwatch_metrics.role_description, "IRSA for aws-cloudwatch-metrics project")
  role_policies = lookup(var.aws_cloudwatch_metrics, "role_policies",
    { CloudWatchAgentServerPolicy = "arn:${local.partition}:iam::aws:policy/CloudWatchAgentServerPolicy" }
  )
  create_policy = try(var.aws_cloudwatch_metrics.create_policy, false)

  irsa_oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.aws_cloudwatch_metrics_service_account
    }
  }

  tags = var.tags
}

################################################################################
# AWS EFS CSI DRIVER
################################################################################

locals {
  aws_efs_csi_driver_controller_service_account = try(var.aws_efs_csi_driver.controller_service_account_name, "efs-csi-controller-sa")
  aws_efs_csi_driver_node_service_account       = try(var.aws_efs_csi_driver.node_service_account_name, "efs-csi-node-sa")
  aws_efs_csi_driver_namespace                  = try(var.aws_efs_csi_driver.namespace, "kube-system")
  efs_arns = lookup(var.aws_efs_csi_driver, "efs_arns",
    ["arn:${local.partition}:elasticfilesystem:${local.region}:${local.account_id}:file-system/*"],
  )
  efs_access_point_arns = lookup(var.aws_efs_csi_driver, "efs_access_point_arns",
    ["arn:${local.partition}:elasticfilesystem:${local.region}:${local.account_id}:access-point/*"]
  )
}

data "aws_iam_policy_document" "aws_efs_csi_driver" {
  count = var.enable_aws_efs_csi_driver ? 1 : 0

  source_policy_documents   = lookup(var.aws_efs_csi_driver, "source_policy_documents", [])
  override_policy_documents = lookup(var.aws_efs_csi_driver, "override_policy_documents", [])

  statement {
    sid       = "AllowDescribeAvailabilityZones"
    actions   = ["ec2:DescribeAvailabilityZones"]
    resources = ["*"]
  }

  statement {
    sid = "AllowDescribeFileSystems"
    actions = [
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:DescribeFileSystems",
      "elasticfilesystem:DescribeMountTargets"
    ]
    resources = flatten([
      local.efs_arns,
      local.efs_access_point_arns,
    ])
  }

  statement {
    actions = [
      "elasticfilesystem:CreateAccessPoint",
      "elasticfilesystem:TagResource",
    ]
    resources = local.efs_arns

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/efs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }

  statement {
    sid       = "AllowDeleteAccessPoint"
    actions   = ["elasticfilesystem:DeleteAccessPoint"]
    resources = local.efs_access_point_arns

    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/efs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }

  statement {
    sid = "ClientReadWrite"
    actions = [
      "elasticfilesystem:ClientRootAccess",
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:ClientMount",
    ]
    resources = local.efs_arns

    condition {
      test     = "Bool"
      variable = "elasticfilesystem:AccessedViaMountTarget"
      values   = ["true"]
    }
  }
}

module "aws_efs_csi_driver" {
  source  = "aws-blueprints/eks-blueprints-addon/aws"
  version = "2.0.0"

  create = var.enable_aws_efs_csi_driver

  # https://github.com/kubernetes-sigs/aws-efs-csi-driver/tree/master/charts/aws-efs-csi-driver
  name             = try(var.aws_efs_csi_driver.name, "aws-efs-csi-driver")
  description      = try(var.aws_efs_csi_driver.description, "A Helm chart to deploy aws-efs-csi-driver")
  namespace        = local.aws_efs_csi_driver_namespace
  create_namespace = try(var.aws_efs_csi_driver.create_namespace, false)
  chart            = try(var.aws_efs_csi_driver.chart, "aws-efs-csi-driver")
  chart_version    = try(var.aws_efs_csi_driver.chart_version, "2.5.6")
  repository       = try(var.aws_efs_csi_driver.repository, "https://kubernetes-sigs.github.io/aws-efs-csi-driver/")
  values           = try(var.aws_efs_csi_driver.values, [])

  timeout                    = try(var.aws_efs_csi_driver.timeout, null)
  repository_key_file        = try(var.aws_efs_csi_driver.repository_key_file, null)
  repository_cert_file       = try(var.aws_efs_csi_driver.repository_cert_file, null)
  repository_ca_file         = try(var.aws_efs_csi_driver.repository_ca_file, null)
  repository_username        = try(var.aws_efs_csi_driver.repository_username, null)
  repository_password        = try(var.aws_efs_csi_driver.repository_password, null)
  devel                      = try(var.aws_efs_csi_driver.devel, null)
  verify                     = try(var.aws_efs_csi_driver.verify, null)
  keyring                    = try(var.aws_efs_csi_driver.keyring, null)
  disable_webhooks           = try(var.aws_efs_csi_driver.disable_webhooks, null)
  reuse_values               = try(var.aws_efs_csi_driver.reuse_values, null)
  reset_values               = try(var.aws_efs_csi_driver.reset_values, null)
  force_update               = try(var.aws_efs_csi_driver.force_update, null)
  recreate_pods              = try(var.aws_efs_csi_driver.recreate_pods, null)
  cleanup_on_fail            = try(var.aws_efs_csi_driver.cleanup_on_fail, null)
  max_history                = try(var.aws_efs_csi_driver.max_history, null)
  atomic                     = try(var.aws_efs_csi_driver.atomic, null)
  skip_crds                  = try(var.aws_efs_csi_driver.skip_crds, null)
  render_subchart_notes      = try(var.aws_efs_csi_driver.render_subchart_notes, null)
  disable_openapi_validation = try(var.aws_efs_csi_driver.disable_openapi_validation, null)
  wait                       = try(var.aws_efs_csi_driver.wait, false)
  wait_for_jobs              = try(var.aws_efs_csi_driver.wait_for_jobs, null)
  dependency_update          = try(var.aws_efs_csi_driver.dependency_update, null)
  replace                    = try(var.aws_efs_csi_driver.replace, null)
  lint                       = try(var.aws_efs_csi_driver.lint, null)

  postrender = try(var.aws_efs_csi_driver.postrender, [])
  set = concat([
    {
      name  = "controller.serviceAccount.name"
      value = local.aws_efs_csi_driver_controller_service_account
    },
    {
      name  = "node.serviceAccount.name"
      value = local.aws_efs_csi_driver_node_service_account
    },
    {
      name                  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value_is_iam_role_arn = true
    },
    {
      name                  = "node.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value_is_iam_role_arn = true
    }],
    try(var.aws_efs_csi_driver.set, [])
  )
  set_sensitive = try(var.aws_efs_csi_driver.set_sensitive, [])

  # IAM role for service account (IRSA)
  role_name                     = try(var.aws_efs_csi_driver.role_name, "aws-efs-csi-driver")
  role_name_use_prefix          = try(var.aws_efs_csi_driver.role_name_use_prefix, true)
  role_path                     = try(var.aws_efs_csi_driver.role_path, "/")
  role_permissions_boundary_arn = lookup(var.aws_efs_csi_driver, "role_permissions_boundary_arn", null)
  role_description              = try(var.aws_efs_csi_driver.role_description, "IRSA for aws-efs-csi-driver project")
  role_policies                 = lookup(var.aws_efs_csi_driver, "role_policies", {})

  source_policy_documents = data.aws_iam_policy_document.aws_efs_csi_driver[*].json
  policy_statements       = lookup(var.aws_efs_csi_driver, "policy_statements", [])
  policy_name             = try(var.aws_efs_csi_driver.policy_name, null)
  policy_name_use_prefix  = try(var.aws_efs_csi_driver.policy_name_use_prefix, true)
  policy_path             = try(var.aws_efs_csi_driver.policy_path, null)
  policy_description      = try(var.aws_efs_csi_driver.policy_description, "IAM Policy for AWS EFS CSI Driver")

  irsa_oidc_providers = {
    controller = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.aws_efs_csi_driver_controller_service_account
    }
    node = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.aws_efs_csi_driver_node_service_account
    }
  }

  tags = var.tags
}

################################################################################
# AWS FSX CSI DRIVER
################################################################################

locals {
  aws_fsx_csi_driver_controller_service_account = try(var.aws_fsx_csi_driver.controller_service_account_name, "aws-fsx-csi-controller-sa")
  aws_fsx_csi_driver_node_service_account       = try(var.aws_fsx_csi_driver.node_service_account_name, "aws-fsx-csi-node-sa")
  aws_fsx_csi_driver_namespace                  = try(var.aws_fsx_csi_driver.namespace, "kube-system")
}

data "aws_iam_policy_document" "aws_fsx_csi_driver" {
  count = var.enable_aws_fsx_csi_driver ? 1 : 0

  source_policy_documents   = lookup(var.aws_fsx_csi_driver, "source_policy_documents", [])
  override_policy_documents = lookup(var.aws_fsx_csi_driver, "override_policy_documents", [])

  statement {
    sid       = "AllowCreateServiceLinkedRoles"
    resources = ["arn:${local.partition}:iam::*:role/aws-service-role/s3.data-source.lustre.fsx.${data.aws_partition.current.dns_suffix}/*"]

    actions = [
      "iam:CreateServiceLinkedRole",
      "iam:AttachRolePolicy",
      "iam:PutRolePolicy",
    ]
  }

  statement {
    sid       = "AllowCreateServiceLinkedRole"
    resources = ["arn:${local.partition}:iam::${local.account_id}:role/*"]
    actions   = ["iam:CreateServiceLinkedRole"]

    condition {
      test     = "StringLike"
      variable = "iam:AWSServiceName"
      values   = ["fsx.amazonaws.com"]
    }
  }

  statement {
    sid       = "AllowListBuckets"
    resources = ["arn:${local.partition}:s3:::*"]
    actions = [
      "s3:ListBucket"
    ]
  }

  statement {
    resources = ["arn:${local.partition}:fsx:${local.region}:${local.account_id}:file-system/*"]
    actions = [
      "fsx:CreateFileSystem",
      "fsx:DeleteFileSystem",
      "fsx:UpdateFileSystem",
    ]
  }

  statement {
    resources = ["arn:${local.partition}:fsx:${local.region}:${local.account_id}:*"]
    actions = [
      "fsx:DescribeFileSystems",
      "fsx:TagResource"
    ]
  }
}

module "aws_fsx_csi_driver" {
  source  = "aws-blueprints/eks-blueprints-addon/aws"
  version = "2.0.0"

  create = var.enable_aws_fsx_csi_driver

  # https://github.com/kubernetes-sigs/aws-fsx-csi-driver/tree/master/charts/aws-fsx-csi-driver
  name             = try(var.aws_fsx_csi_driver.name, "aws-fsx-csi-driver")
  description      = try(var.aws_fsx_csi_driver.description, "A Helm chart for AWS FSx for Lustre CSI Driver")
  namespace        = local.aws_fsx_csi_driver_namespace
  create_namespace = try(var.aws_fsx_csi_driver.create_namespace, false)
  chart            = try(var.aws_fsx_csi_driver.chart, "aws-fsx-csi-driver")
  chart_version    = try(var.aws_fsx_csi_driver.chart_version, "1.9.0")
  repository       = try(var.aws_fsx_csi_driver.repository, "https://kubernetes-sigs.github.io/aws-fsx-csi-driver/")
  values           = try(var.aws_fsx_csi_driver.values, [])

  timeout                    = try(var.aws_fsx_csi_driver.timeout, null)
  repository_key_file        = try(var.aws_fsx_csi_driver.repository_key_file, null)
  repository_cert_file       = try(var.aws_fsx_csi_driver.repository_cert_file, null)
  repository_ca_file         = try(var.aws_fsx_csi_driver.repository_ca_file, null)
  repository_username        = try(var.aws_fsx_csi_driver.repository_username, null)
  repository_password        = try(var.aws_fsx_csi_driver.repository_password, null)
  devel                      = try(var.aws_fsx_csi_driver.devel, null)
  verify                     = try(var.aws_fsx_csi_driver.verify, null)
  keyring                    = try(var.aws_fsx_csi_driver.keyring, null)
  disable_webhooks           = try(var.aws_fsx_csi_driver.disable_webhooks, null)
  reuse_values               = try(var.aws_fsx_csi_driver.reuse_values, null)
  reset_values               = try(var.aws_fsx_csi_driver.reset_values, null)
  force_update               = try(var.aws_fsx_csi_driver.force_update, null)
  recreate_pods              = try(var.aws_fsx_csi_driver.recreate_pods, null)
  cleanup_on_fail            = try(var.aws_fsx_csi_driver.cleanup_on_fail, null)
  max_history                = try(var.aws_fsx_csi_driver.max_history, null)
  atomic                     = try(var.aws_fsx_csi_driver.atomic, null)
  skip_crds                  = try(var.aws_fsx_csi_driver.skip_crds, null)
  render_subchart_notes      = try(var.aws_fsx_csi_driver.render_subchart_notes, null)
  disable_openapi_validation = try(var.aws_fsx_csi_driver.disable_openapi_validation, null)
  wait                       = try(var.aws_fsx_csi_driver.wait, false)
  wait_for_jobs              = try(var.aws_fsx_csi_driver.wait_for_jobs, null)
  dependency_update          = try(var.aws_fsx_csi_driver.dependency_update, null)
  replace                    = try(var.aws_fsx_csi_driver.replace, null)
  lint                       = try(var.aws_fsx_csi_driver.lint, null)

  postrender = try(var.aws_fsx_csi_driver.postrender, [])
  set = concat([
    {
      name  = "controller.serviceAccount.name"
      value = local.aws_fsx_csi_driver_controller_service_account
    },
    {
      name  = "node.serviceAccount.name"
      value = local.aws_fsx_csi_driver_node_service_account
    },
    {
      name                  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value_is_iam_role_arn = true
    },
    {
      name                  = "node.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value_is_iam_role_arn = true
    }],
    try(var.aws_fsx_csi_driver.set, [])
  )
  set_sensitive = try(var.aws_fsx_csi_driver.set_sensitive, [])

  # IAM role for service account (IRSA)
  role_name                     = try(var.aws_fsx_csi_driver.role_name, "aws-fsx-csi-driver")
  role_name_use_prefix          = try(var.aws_fsx_csi_driver.role_name_use_prefix, true)
  role_path                     = try(var.aws_fsx_csi_driver.role_path, "/")
  role_permissions_boundary_arn = lookup(var.aws_fsx_csi_driver, "role_permissions_boundary_arn", null)
  role_description              = try(var.aws_fsx_csi_driver.role_description, "IRSA for aws-fsx-csi-driver")
  role_policies                 = lookup(var.aws_fsx_csi_driver, "role_policies", {})

  source_policy_documents = data.aws_iam_policy_document.aws_fsx_csi_driver[*].json
  policy_statements       = lookup(var.aws_fsx_csi_driver, "policy_statements", [])
  policy_name             = try(var.aws_fsx_csi_driver.policy_name, "aws-fsx-csi-driver")
  policy_name_use_prefix  = try(var.aws_fsx_csi_driver.policy_name_use_prefix, true)
  policy_path             = try(var.aws_fsx_csi_driver.policy_path, null)
  policy_description      = try(var.aws_fsx_csi_driver.policy_description, "IAM Policy for AWS FSX CSI Driver")

  irsa_oidc_providers = {
    controller = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.aws_fsx_csi_driver_controller_service_account
    }
    node = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.aws_fsx_csi_driver_node_service_account
    }
  }
}

################################################################################
# AWS Load Balancer Controller
################################################################################

locals {
  aws_load_balancer_controller_service_account = try(var.aws_load_balancer_controller.service_account_name, "aws-load-balancer-controller-sa")
  aws_load_balancer_controller_namespace       = try(var.aws_load_balancer_controller.namespace, "kube-system")
}

# https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/docs/install/iam_policy.json
data "aws_iam_policy_document" "aws_load_balancer_controller" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  source_policy_documents   = lookup(var.aws_load_balancer_controller, "source_policy_documents", [])
  override_policy_documents = lookup(var.aws_load_balancer_controller, "override_policy_documents", [])

  statement {
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["elasticloadbalancing.amazonaws.com"]
    }
  }

  statement {
    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeVpcs",
      "ec2:DescribeVpcPeeringConnections",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeTags",
      "ec2:GetCoipPoolUsage",
      "ec2:DescribeCoipPools",
      "ec2:GetSecurityGroupsForVpc",
      "ec2:DescribeIpamPools",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeTrustStores",
      "elasticloadbalancing:DescribeListenerAttributes",
      "elasticloadbalancing:DescribeCapacityReservation",
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "cognito-idp:DescribeUserPoolClient",
      "acm:ListCertificates",
      "acm:DescribeCertificate",
      "iam:ListServerCertificates",
      "iam:GetServerCertificate",
      "waf-regional:GetWebACL",
      "waf-regional:GetWebACLForResource",
      "waf-regional:AssociateWebACL",
      "waf-regional:DisassociateWebACL",
      "wafv2:GetWebACL",
      "wafv2:GetWebACLForResource",
      "wafv2:AssociateWebACL",
      "wafv2:DisassociateWebACL",
      "shield:GetSubscriptionState",
      "shield:DescribeProtection",
      "shield:CreateProtection",
      "shield:DeleteProtection",
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
    ]
    resources = ["*"]
  }

  statement {
    actions   = ["ec2:CreateSecurityGroup"]
    resources = ["*"]
  }

  statement {
    actions   = ["ec2:CreateTags"]
    resources = ["arn:${local.partition}:ec2:*:*:security-group/*", ]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["CreateSecurityGroup"]
    }

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags",
    ]
    resources = ["arn:${local.partition}:ec2:*:*:security-group/*"]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["true"]
    }

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:DeleteSecurityGroup",
    ]
    resources = ["*"]

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    actions = [
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateTargetGroup",
    ]
    resources = ["*"]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    actions = [
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:DeleteRule",
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags",
    ]
    resources = [
      "arn:${local.partition}:elasticloadbalancing:*:*:targetgroup/*/*",
      "arn:${local.partition}:elasticloadbalancing:*:*:loadbalancer/net/*/*",
      "arn:${local.partition}:elasticloadbalancing:*:*:loadbalancer/app/*/*"
    ]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["true"]
    }

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags",
    ]
    resources = [
      "arn:${local.partition}:elasticloadbalancing:*:*:listener/net/*/*/*",
      "arn:${local.partition}:elasticloadbalancing:*:*:listener/app/*/*/*",
      "arn:${local.partition}:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
      "arn:${local.partition}:elasticloadbalancing:*:*:listener-rule/app/*/*/*",
    ]
  }

  statement {
    actions = [
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:ModifyListenerAttributes",
      "elasticloadbalancing:ModifyCapacityReservation",
      "elasticloadbalancing:ModifyIpPools",
    ]
    resources = ["*"]

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    actions = ["elasticloadbalancing:AddTags"]
    resources = [
      "arn:${local.partition}:elasticloadbalancing:*:*:targetgroup/*/*",
      "arn:${local.partition}:elasticloadbalancing:*:*:loadbalancer/net/*/*",
      "arn:${local.partition}:elasticloadbalancing:*:*:loadbalancer/app/*/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "elasticloadbalancing:CreateAction"
      values = [
        "CreateTargetGroup",
        "CreateLoadBalancer",
      ]
    }

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    actions = [
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
    ]
    resources = ["arn:${local.partition}:elasticloadbalancing:*:*:targetgroup/*/*"]
  }

  statement {
    actions = [
      "elasticloadbalancing:SetWebAcl",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:AddListenerCertificates",
      "elasticloadbalancing:RemoveListenerCertificates",
      "elasticloadbalancing:ModifyRule",
      "elasticloadbalancing:SetRulePriorities",
    ]
    resources = ["*"]
  }
}

module "aws_load_balancer_controller" {
  source  = "aws-blueprints/eks-blueprints-addon/aws"
  version = "2.0.0"

  create = var.enable_aws_load_balancer_controller

  # https://github.com/aws/eks-charts/blob/master/stable/aws-load-balancer-controller/Chart.yaml
  name        = try(var.aws_load_balancer_controller.name, "aws-load-balancer-controller")
  description = try(var.aws_load_balancer_controller.description, "A Helm chart to deploy aws-load-balancer-controller for ingress resources")
  namespace   = local.aws_load_balancer_controller_namespace
  # namespace creation is false here as kube-system already exists by default
  create_namespace = try(var.aws_load_balancer_controller.create_namespace, false)
  chart            = try(var.aws_load_balancer_controller.chart, "aws-load-balancer-controller")
  chart_version    = try(var.aws_load_balancer_controller.chart_version, "1.7.1")
  repository       = try(var.aws_load_balancer_controller.repository, "https://aws.github.io/eks-charts")
  values           = try(var.aws_load_balancer_controller.values, [])

  timeout                    = try(var.aws_load_balancer_controller.timeout, null)
  repository_key_file        = try(var.aws_load_balancer_controller.repository_key_file, null)
  repository_cert_file       = try(var.aws_load_balancer_controller.repository_cert_file, null)
  repository_ca_file         = try(var.aws_load_balancer_controller.repository_ca_file, null)
  repository_username        = try(var.aws_load_balancer_controller.repository_username, null)
  repository_password        = try(var.aws_load_balancer_controller.repository_password, null)
  devel                      = try(var.aws_load_balancer_controller.devel, null)
  verify                     = try(var.aws_load_balancer_controller.verify, null)
  keyring                    = try(var.aws_load_balancer_controller.keyring, null)
  disable_webhooks           = try(var.aws_load_balancer_controller.disable_webhooks, null)
  reuse_values               = try(var.aws_load_balancer_controller.reuse_values, null)
  reset_values               = try(var.aws_load_balancer_controller.reset_values, null)
  force_update               = try(var.aws_load_balancer_controller.force_update, null)
  recreate_pods              = try(var.aws_load_balancer_controller.recreate_pods, null)
  cleanup_on_fail            = try(var.aws_load_balancer_controller.cleanup_on_fail, null)
  max_history                = try(var.aws_load_balancer_controller.max_history, null)
  atomic                     = try(var.aws_load_balancer_controller.atomic, null)
  skip_crds                  = try(var.aws_load_balancer_controller.skip_crds, null)
  render_subchart_notes      = try(var.aws_load_balancer_controller.render_subchart_notes, null)
  disable_openapi_validation = try(var.aws_load_balancer_controller.disable_openapi_validation, null)
  wait                       = try(var.aws_load_balancer_controller.wait, false)
  wait_for_jobs              = try(var.aws_load_balancer_controller.wait_for_jobs, null)
  dependency_update          = try(var.aws_load_balancer_controller.dependency_update, null)
  replace                    = try(var.aws_load_balancer_controller.replace, null)
  lint                       = try(var.aws_load_balancer_controller.lint, null)

  postrender = try(var.aws_load_balancer_controller.postrender, [])
  set = concat([
    {
      name  = "serviceAccount.name"
      value = local.aws_load_balancer_controller_service_account
    },
    {
      name  = "clusterName"
      value = local.cluster_name
    },
    {
      name                  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value_is_iam_role_arn = true
    }],
    try(var.aws_load_balancer_controller.set, [])
  )
  set_sensitive = try(var.aws_load_balancer_controller.set_sensitive, [])

  # IAM role for service account (IRSA)
  role_name                     = try(var.aws_load_balancer_controller.role_name, "alb-controller")
  role_name_use_prefix          = try(var.aws_load_balancer_controller.role_name_use_prefix, true)
  role_path                     = try(var.aws_load_balancer_controller.role_path, "/")
  role_permissions_boundary_arn = lookup(var.aws_load_balancer_controller, "role_permissions_boundary_arn", null)
  role_description              = try(var.aws_load_balancer_controller.role_description, "IRSA for aws-load-balancer-controller project")
  role_policies                 = lookup(var.aws_load_balancer_controller, "role_policies", {})

  source_policy_documents = data.aws_iam_policy_document.aws_load_balancer_controller[*].json
  policy_statements       = lookup(var.aws_load_balancer_controller, "policy_statements", [])
  policy_name             = try(var.aws_load_balancer_controller.policy_name, null)
  policy_name_use_prefix  = try(var.aws_load_balancer_controller.policy_name_use_prefix, true)
  policy_path             = try(var.aws_load_balancer_controller.policy_path, null)
  policy_description      = try(var.aws_load_balancer_controller.policy_description, "IAM Policy for AWS Load Balancer Controller")

  irsa_oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.aws_load_balancer_controller_service_account
    }
  }

  tags = var.tags
}

################################################################################
# AWS Node Termination Handler
################################################################################

locals {
  aws_node_termination_handler_service_account = try(var.aws_node_termination_handler.service_account_name, "aws-node-termination-handler-sa")
  aws_node_termination_handler_namespace       = try(var.aws_node_termination_handler.namespace, "aws-node-termination-handler")
  aws_node_termination_handler_events = merge(
    {
      autoscaling_terminate = {
        name        = "ASGTerminiate"
        description = "Auto scaling instance terminate event"
        event_pattern = merge(
          {
            source      = ["aws.autoscaling"]
            detail-type = ["EC2 Instance-terminate Lifecycle Action"]
          },
          try(length(var.aws_node_termination_handler_asg_names) > 0 ? {
            detail = {
              AutoScalingGroupName = var.aws_node_termination_handler_asg_names
            }
          } : {}, {})
        )
      }
    },
    local.ec2_events
  )
}

module "aws_node_termination_handler_sqs" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "4.0.1"

  create = var.enable_aws_node_termination_handler

  name = try(var.aws_node_termination_handler_sqs.queue_name, "aws-nth-${var.cluster_name}")

  message_retention_seconds         = try(var.aws_node_termination_handler_sqs.message_retention_seconds, 300)
  sqs_managed_sse_enabled           = try(var.aws_node_termination_handler_sqs.sse_enabled, true)
  kms_master_key_id                 = try(var.aws_node_termination_handler_sqs.kms_master_key_id, null)
  kms_data_key_reuse_period_seconds = try(var.aws_node_termination_handler_sqs.kms_data_key_reuse_period_seconds, null)

  create_queue_policy = true
  queue_policy_statements = {
    account = {
      sid     = "SendEventsToQueue"
      actions = ["sqs:SendMessage"]
      principals = [
        {
          type = "Service"
          identifiers = [
            "events.amazonaws.com",
            "sqs.amazonaws.com",
          ]
        }
      ]
    }
  }

  tags = merge(var.tags, try(var.aws_node_termination_handler_sqs.tags, {}))
}

resource "aws_autoscaling_lifecycle_hook" "aws_node_termination_handler" {
  for_each = { for k, v in var.aws_node_termination_handler_asg_arns : k => v if var.enable_aws_node_termination_handler }

  name                   = "aws_node_termination_handler"
  autoscaling_group_name = replace(each.value, "/^.*:autoScalingGroupName//", "")
  default_result         = "CONTINUE"
  heartbeat_timeout      = 300
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
}

resource "aws_autoscaling_group_tag" "aws_node_termination_handler" {
  for_each = { for k, v in var.aws_node_termination_handler_asg_arns : k => v if var.enable_aws_node_termination_handler }

  autoscaling_group_name = replace(each.value, "/^.*:autoScalingGroupName//", "")

  tag {
    key                 = "aws-node-termination-handler/managed"
    value               = "true"
    propagate_at_launch = true
  }
}

resource "aws_cloudwatch_event_rule" "aws_node_termination_handler" {
  for_each = { for k, v in local.aws_node_termination_handler_events : k => v if var.enable_aws_node_termination_handler }

  name_prefix   = "NTH-${each.value.name}-"
  description   = each.value.description
  event_pattern = jsonencode(each.value.event_pattern)

  tags = merge(
    { "ClusterName" : var.cluster_name },
    var.tags,
  )
}

resource "aws_cloudwatch_event_target" "aws_node_termination_handler" {
  for_each = { for k, v in local.aws_node_termination_handler_events : k => v if var.enable_aws_node_termination_handler }

  rule      = aws_cloudwatch_event_rule.aws_node_termination_handler[each.key].name
  target_id = "AWSNodeTerminationHandlerQueueTarget"
  arn       = module.aws_node_termination_handler_sqs.queue_arn
}

data "aws_iam_policy_document" "aws_node_termination_handler" {
  count = var.enable_aws_node_termination_handler ? 1 : 0

  source_policy_documents   = lookup(var.aws_node_termination_handler, "source_policy_documents", [])
  override_policy_documents = lookup(var.aws_node_termination_handler, "override_policy_documents", [])

  statement {
    actions = [
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeTags",
      "ec2:DescribeInstances",
    ]
    resources = ["*"]
  }

  statement {
    actions   = ["autoscaling:CompleteLifecycleAction"]
    resources = var.aws_node_termination_handler_asg_arns
  }

  statement {
    actions = [
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage",
    ]
    resources = [module.aws_node_termination_handler_sqs.queue_arn]
  }
}

module "aws_node_termination_handler" {
  source  = "aws-blueprints/eks-blueprints-addon/aws"
  version = "2.0.0"

  create = var.enable_aws_node_termination_handler

  # https://github.com/aws/eks-charts/blob/master/stable/aws-node-termination-handler/Chart.yaml
  name             = try(var.aws_node_termination_handler.name, "aws-node-termination-handler")
  description      = try(var.aws_node_termination_handler.description, "A Helm chart to deploy AWS Node Termination Handler")
  namespace        = local.aws_node_termination_handler_namespace
  create_namespace = try(var.aws_node_termination_handler.create_namespace, true)
  chart            = try(var.aws_node_termination_handler.chart, "aws-node-termination-handler")
  chart_version    = try(var.aws_node_termination_handler.chart_version, "0.21.0")
  repository       = try(var.aws_node_termination_handler.repository, "https://aws.github.io/eks-charts")
  values           = try(var.aws_node_termination_handler.values, [])

  timeout                    = try(var.aws_node_termination_handler.timeout, null)
  repository_key_file        = try(var.aws_node_termination_handler.repository_key_file, null)
  repository_cert_file       = try(var.aws_node_termination_handler.repository_cert_file, null)
  repository_ca_file         = try(var.aws_node_termination_handler.repository_ca_file, null)
  repository_username        = try(var.aws_node_termination_handler.repository_username, null)
  repository_password        = try(var.aws_node_termination_handler.repository_password, null)
  devel                      = try(var.aws_node_termination_handler.devel, null)
  verify                     = try(var.aws_node_termination_handler.verify, null)
  keyring                    = try(var.aws_node_termination_handler.keyring, null)
  disable_webhooks           = try(var.aws_node_termination_handler.disable_webhooks, null)
  reuse_values               = try(var.aws_node_termination_handler.reuse_values, null)
  reset_values               = try(var.aws_node_termination_handler.reset_values, null)
  force_update               = try(var.aws_node_termination_handler.force_update, null)
  recreate_pods              = try(var.aws_node_termination_handler.recreate_pods, null)
  cleanup_on_fail            = try(var.aws_node_termination_handler.cleanup_on_fail, null)
  max_history                = try(var.aws_node_termination_handler.max_history, null)
  atomic                     = try(var.aws_node_termination_handler.atomic, null)
  skip_crds                  = try(var.aws_node_termination_handler.skip_crds, null)
  render_subchart_notes      = try(var.aws_node_termination_handler.render_subchart_notes, null)
  disable_openapi_validation = try(var.aws_node_termination_handler.disable_openapi_validation, null)
  wait                       = try(var.aws_node_termination_handler.wait, false)
  wait_for_jobs              = try(var.aws_node_termination_handler.wait_for_jobs, null)
  dependency_update          = try(var.aws_node_termination_handler.dependency_update, null)
  replace                    = try(var.aws_node_termination_handler.replace, null)
  lint                       = try(var.aws_node_termination_handler.lint, null)

  postrender = try(var.aws_node_termination_handler.postrender, [])
  set = concat(
    [
      {
        name  = "serviceAccount.name"
        value = local.aws_node_termination_handler_service_account
      },
      {
        name  = "awsRegion"
        value = local.region
      },
      { name  = "queueURL"
        value = try(module.aws_node_termination_handler_sqs.queue_url, "")
      },
      {
        name  = "enableSqsTerminationDraining"
        value = true
      },
      {
        name                  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
        value_is_iam_role_arn = true
      }
    ],
    try(var.aws_node_termination_handler.set, [])
  )
  set_sensitive = try(var.aws_node_termination_handler.set_sensitive, [])

  # IAM role for service account (IRSA)
  role_name                     = try(var.aws_node_termination_handler.role_name, "aws-node-termination-handler")
  role_name_use_prefix          = try(var.aws_node_termination_handler.role_name_use_prefix, true)
  role_path                     = try(var.aws_node_termination_handler.role_path, "/")
  role_permissions_boundary_arn = lookup(var.aws_node_termination_handler, "role_permissions_boundary_arn", null)
  role_description              = try(var.aws_node_termination_handler.role_description, "IRSA for AWS Node Termination Handler project")
  role_policies                 = lookup(var.aws_node_termination_handler, "role_policies", {})

  source_policy_documents = data.aws_iam_policy_document.aws_node_termination_handler[*].json
  policy_statements       = lookup(var.aws_node_termination_handler, "policy_statements", [])
  policy_name             = try(var.aws_node_termination_handler.policy_name, null)
  policy_name_use_prefix  = try(var.aws_node_termination_handler.policy_name_use_prefix, true)
  policy_path             = try(var.aws_node_termination_handler.policy_path, null)
  policy_description      = try(var.aws_node_termination_handler.policy_description, "IAM Policy for AWS Node Termination Handler")

  irsa_oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.aws_node_termination_handler_service_account
    }
  }

  tags = var.tags
}

################################################################################
# AWS Private CA Issuer
################################################################################

locals {
  aws_privateca_issuer_service_account = try(var.aws_privateca_issuer.service_account_name, "aws-privateca-issuer-sa")
  aws_privateca_issuer_namespace       = try(var.aws_privateca_issuer.namespace, local.cert_manager_namespace)
}

data "aws_iam_policy_document" "aws_privateca_issuer" {
  count = var.enable_aws_privateca_issuer ? 1 : 0

  source_policy_documents   = lookup(var.aws_privateca_issuer, "source_policy_documents", [])
  override_policy_documents = lookup(var.aws_privateca_issuer, "override_policy_documents", [])

  statement {
    actions = [
      "acm-pca:DescribeCertificateAuthority",
      "acm-pca:GetCertificate",
      "acm-pca:IssueCertificate",
    ]
    resources = [
      try(var.aws_privateca_issuer.acmca_arn,
      "arn:${local.partition}:acm-pca:${local.region}:${local.account_id}:certificate-authority/*")
    ]
  }
}

module "aws_privateca_issuer" {
  source  = "aws-blueprints/eks-blueprints-addon/aws"
  version = "2.0.0"

  create = var.enable_aws_privateca_issuer

  # https://github.com/cert-manager/aws-privateca-issuer/blob/main/charts/aws-pca-issuer/Chart.yaml
  name             = try(var.aws_privateca_issuer.name, "aws-privateca-issuer")
  description      = try(var.aws_privateca_issuer.description, "A Helm chart to install the AWS Private CA Issuer")
  namespace        = local.aws_privateca_issuer_namespace
  create_namespace = try(var.aws_privateca_issuer.create_namespace, false)
  chart            = try(var.aws_privateca_issuer.chart, "aws-privateca-issuer")
  chart_version    = try(var.aws_privateca_issuer.chart_version, "v1.2.7")
  repository       = try(var.aws_privateca_issuer.repository, "https://cert-manager.github.io/aws-privateca-issuer")
  values           = try(var.aws_privateca_issuer.values, [])

  timeout                    = try(var.aws_privateca_issuer.timeout, null)
  repository_key_file        = try(var.aws_privateca_issuer.repository_key_file, null)
  repository_cert_file       = try(var.aws_privateca_issuer.repository_cert_file, null)
  repository_ca_file         = try(var.aws_privateca_issuer.repository_ca_file, null)
  repository_username        = try(var.aws_privateca_issuer.repository_username, null)
  repository_password        = try(var.aws_privateca_issuer.repository_password, null)
  devel                      = try(var.aws_privateca_issuer.devel, null)
  verify                     = try(var.aws_privateca_issuer.verify, null)
  keyring                    = try(var.aws_privateca_issuer.keyring, null)
  disable_webhooks           = try(var.aws_privateca_issuer.disable_webhooks, null)
  reuse_values               = try(var.aws_privateca_issuer.reuse_values, null)
  reset_values               = try(var.aws_privateca_issuer.reset_values, null)
  force_update               = try(var.aws_privateca_issuer.force_update, null)
  recreate_pods              = try(var.aws_privateca_issuer.recreate_pods, null)
  cleanup_on_fail            = try(var.aws_privateca_issuer.cleanup_on_fail, null)
  max_history                = try(var.aws_privateca_issuer.max_history, null)
  atomic                     = try(var.aws_privateca_issuer.atomic, null)
  skip_crds                  = try(var.aws_privateca_issuer.skip_crds, null)
  render_subchart_notes      = try(var.aws_privateca_issuer.render_subchart_notes, null)
  disable_openapi_validation = try(var.aws_privateca_issuer.disable_openapi_validation, null)
  wait                       = try(var.aws_privateca_issuer.wait, false)
  wait_for_jobs              = try(var.aws_privateca_issuer.wait_for_jobs, null)
  dependency_update          = try(var.aws_privateca_issuer.dependency_update, null)
  replace                    = try(var.aws_privateca_issuer.replace, null)
  lint                       = try(var.aws_privateca_issuer.lint, null)

  postrender = try(var.aws_privateca_issuer.postrender, [])
  set = concat([
    {
      name  = "serviceAccount.name"
      value = local.aws_privateca_issuer_service_account
    },
    {
      name                  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value_is_iam_role_arn = true
    }],
    try(var.aws_privateca_issuer.set, [])
  )
  set_sensitive = try(var.aws_privateca_issuer.set_sensitive, [])

  # IAM role for service account (IRSA)
  role_name                     = try(var.aws_privateca_issuer.role_name, "aws-privateca-issuer")
  role_name_use_prefix          = try(var.aws_privateca_issuer.role_name_use_prefix, true)
  role_path                     = try(var.aws_privateca_issuer.role_path, "/")
  role_permissions_boundary_arn = lookup(var.aws_privateca_issuer, "role_permissions_boundary_arn", null)
  role_description              = try(var.aws_privateca_issuer.role_description, "IRSA for AWS Private CA Issuer")
  role_policies                 = lookup(var.aws_privateca_issuer, "role_policies", {})

  source_policy_documents = data.aws_iam_policy_document.aws_privateca_issuer[*].json
  policy_statements       = lookup(var.aws_privateca_issuer, "policy_statements", [])
  policy_name             = try(var.aws_privateca_issuer.policy_name, "aws-privateca-issuer")
  policy_name_use_prefix  = try(var.aws_privateca_issuer.policy_name_use_prefix, true)
  policy_path             = try(var.aws_privateca_issuer.policy_path, null)
  policy_description      = try(var.aws_privateca_issuer.policy_description, "IAM Policy for AWS Private CA Issuer")

  irsa_oidc_providers = {
    controller = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.aws_privateca_issuer_service_account
    }
  }

  tags = var.tags
}

################################################################################
# Cert Manager
################################################################################

locals {
  cert_manager_service_account = try(var.cert_manager.service_account_name, "cert-manager")
  create_cert_manager_irsa     = var.enable_cert_manager && length(var.cert_manager_route53_hosted_zone_arns) > 0
  cert_manager_namespace       = try(var.cert_manager.namespace, "cert-manager")
}

data "aws_iam_policy_document" "cert_manager" {
  count = local.create_cert_manager_irsa ? 1 : 0

  source_policy_documents   = lookup(var.cert_manager, "source_policy_documents", [])
  override_policy_documents = lookup(var.cert_manager, "override_policy_documents", [])

  statement {
    actions   = ["route53:GetChange", ]
    resources = ["arn:${local.partition}:route53:::change/*"]
  }

  statement {
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
    ]
    resources = var.cert_manager_route53_hosted_zone_arns
  }

  statement {
    actions   = ["route53:ListHostedZonesByName"]
    resources = ["*"]
  }
}

module "cert_manager" {
  source  = "aws-blueprints/eks-blueprints-addon/aws"
  version = "2.0.0"

  create = var.enable_cert_manager

  # https://github.com/cert-manager/cert-manager/blob/master/deploy/charts/cert-manager/Chart.template.yaml
  name             = try(var.cert_manager.name, "cert-manager")
  description      = try(var.cert_manager.description, "A Helm chart to deploy cert-manager")
  namespace        = local.cert_manager_namespace
  create_namespace = try(var.cert_manager.create_namespace, true)
  chart            = try(var.cert_manager.chart, "cert-manager")
  chart_version    = try(var.cert_manager.chart_version, "v1.14.3")
  repository       = try(var.cert_manager.repository, "https://charts.jetstack.io")
  values           = try(var.cert_manager.values, [])

  timeout                    = try(var.cert_manager.timeout, null)
  repository_key_file        = try(var.cert_manager.repository_key_file, null)
  repository_cert_file       = try(var.cert_manager.repository_cert_file, null)
  repository_ca_file         = try(var.cert_manager.repository_ca_file, null)
  repository_username        = try(var.cert_manager.repository_username, null)
  repository_password        = try(var.cert_manager.repository_password, null)
  devel                      = try(var.cert_manager.devel, null)
  verify                     = try(var.cert_manager.verify, null)
  keyring                    = try(var.cert_manager.keyring, null)
  disable_webhooks           = try(var.cert_manager.disable_webhooks, null)
  reuse_values               = try(var.cert_manager.reuse_values, null)
  reset_values               = try(var.cert_manager.reset_values, null)
  force_update               = try(var.cert_manager.force_update, null)
  recreate_pods              = try(var.cert_manager.recreate_pods, null)
  cleanup_on_fail            = try(var.cert_manager.cleanup_on_fail, null)
  max_history                = try(var.cert_manager.max_history, null)
  atomic                     = try(var.cert_manager.atomic, null)
  skip_crds                  = try(var.cert_manager.skip_crds, null)
  render_subchart_notes      = try(var.cert_manager.render_subchart_notes, null)
  disable_openapi_validation = try(var.cert_manager.disable_openapi_validation, null)
  wait                       = try(var.cert_manager.wait, false)
  wait_for_jobs              = try(var.cert_manager.wait_for_jobs, null)
  dependency_update          = try(var.cert_manager.dependency_update, null)
  replace                    = try(var.cert_manager.replace, null)
  lint                       = try(var.cert_manager.lint, null)

  postrender = try(var.cert_manager.postrender, [])
  set = concat([
    {
      name  = "installCRDs"
      value = true
    },
    {
      name  = "serviceAccount.name"
      value = local.cert_manager_service_account
    },
    {
      name                  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value_is_iam_role_arn = true
    }
    ],
    try(var.cert_manager.set, [])
  )
  set_sensitive = try(var.cert_manager.set_sensitive, [])

  # IAM role for service account (IRSA)
  role_name                     = try(var.cert_manager.role_name, "cert-manager")
  role_name_use_prefix          = try(var.cert_manager.role_name_use_prefix, true)
  role_path                     = try(var.cert_manager.role_path, "/")
  role_permissions_boundary_arn = lookup(var.cert_manager, "role_permissions_boundary_arn", null)
  role_description              = try(var.cert_manager.role_description, "IRSA for cert-manger project")
  role_policies                 = lookup(var.cert_manager, "role_policies", {})

  source_policy_documents = data.aws_iam_policy_document.cert_manager[*].json
  policy_statements       = lookup(var.cert_manager, "policy_statements", [])
  policy_name             = try(var.cert_manager.policy_name, null)
  policy_name_use_prefix  = try(var.cert_manager.policy_name_use_prefix, true)
  policy_path             = try(var.cert_manager.policy_path, null)
  policy_description      = try(var.cert_manager.policy_description, "IAM Policy for cert-manager")

  irsa_oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.cert_manager_service_account
    }
  }

  tags = var.tags
}

################################################################################
# Cluster Autoscaler
################################################################################

locals {
  cluster_autoscaler_service_account    = try(var.cluster_autoscaler.service_account_name, "cluster-autoscaler-sa")
  cluster_autoscaler_namespace          = try(var.cluster_autoscaler.namespace, "kube-system")
  cluster_autoscaler_image_tag_selected = try(var.cluster_autoscaler.image_tag_override, local.cluster_autoscaler_image_tag[var.cluster_version], "v${var.cluster_version}.0")

  # Lookup map to pull latest cluster-autoscaler patch version given the cluster version
  cluster_autoscaler_image_tag = {
    "1.20" = "v1.20.3"
    "1.21" = "v1.21.3"
    "1.22" = "v1.22.3"
    "1.23" = "v1.23.1"
    "1.24" = "v1.24.3"
    "1.25" = "v1.25.3"
    "1.26" = "v1.26.6"
    "1.27" = "v1.27.5"
    "1.28" = "v1.28.2"
    "1.29" = "v1.29.0"
    "1.30" = "v1.30.4"
    "1.31" = "v1.31.2"
    "1.32" = "v1.32.1"
    "1.33" = "v1.32.1"
  }
}

data "aws_iam_policy_document" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  source_policy_documents   = lookup(var.cluster_autoscaler, "source_policy_documents", [])
  override_policy_documents = lookup(var.cluster_autoscaler, "override_policy_documents", [])

  statement {
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:DescribeInstanceTypes",
      "eks:DescribeNodegroup",
      "ec2:DescribeImages",
      "ec2:GetInstanceTypesFromInstanceRequirements"
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }
  }
}

module "cluster_autoscaler" {
  source  = "aws-blueprints/eks-blueprints-addon/aws"
  version = "2.0.0"

  create = var.enable_cluster_autoscaler

  # https://github.com/kubernetes/autoscaler/blob/master/charts/cluster-autoscaler/Chart.yaml
  name             = try(var.cluster_autoscaler.name, "cluster-autoscaler")
  description      = try(var.cluster_autoscaler.description, "A Helm chart to deploy cluster-autoscaler")
  namespace        = local.cluster_autoscaler_namespace
  create_namespace = try(var.cluster_autoscaler.create_namespace, false)
  chart            = try(var.cluster_autoscaler.chart, "cluster-autoscaler")
  chart_version    = try(var.cluster_autoscaler.chart_version, "9.35.0")
  repository       = try(var.cluster_autoscaler.repository, "https://kubernetes.github.io/autoscaler")
  values           = try(var.cluster_autoscaler.values, [])

  timeout                    = try(var.cluster_autoscaler.timeout, null)
  repository_key_file        = try(var.cluster_autoscaler.repository_key_file, null)
  repository_cert_file       = try(var.cluster_autoscaler.repository_cert_file, null)
  repository_ca_file         = try(var.cluster_autoscaler.repository_ca_file, null)
  repository_username        = try(var.cluster_autoscaler.repository_username, null)
  repository_password        = try(var.cluster_autoscaler.repository_password, null)
  devel                      = try(var.cluster_autoscaler.devel, null)
  verify                     = try(var.cluster_autoscaler.verify, null)
  keyring                    = try(var.cluster_autoscaler.keyring, null)
  disable_webhooks           = try(var.cluster_autoscaler.disable_webhooks, null)
  reuse_values               = try(var.cluster_autoscaler.reuse_values, null)
  reset_values               = try(var.cluster_autoscaler.reset_values, null)
  force_update               = try(var.cluster_autoscaler.force_update, null)
  recreate_pods              = try(var.cluster_autoscaler.recreate_pods, null)
  cleanup_on_fail            = try(var.cluster_autoscaler.cleanup_on_fail, null)
  max_history                = try(var.cluster_autoscaler.max_history, null)
  atomic                     = try(var.cluster_autoscaler.atomic, null)
  skip_crds                  = try(var.cluster_autoscaler.skip_crds, null)
  render_subchart_notes      = try(var.cluster_autoscaler.render_subchart_notes, null)
  disable_openapi_validation = try(var.cluster_autoscaler.disable_openapi_validation, null)
  wait                       = try(var.cluster_autoscaler.wait, false)
  wait_for_jobs              = try(var.cluster_autoscaler.wait_for_jobs, null)
  dependency_update          = try(var.cluster_autoscaler.dependency_update, null)
  replace                    = try(var.cluster_autoscaler.replace, null)
  lint                       = try(var.cluster_autoscaler.lint, null)

  postrender = try(var.cluster_autoscaler.postrender, [])
  set = concat(
    [
      {
        name  = "awsRegion"
        value = local.region
      },
      {
        name  = "autoDiscovery.clusterName"
        value = local.cluster_name
      },
      {
        name  = "image.tag"
        value = local.cluster_autoscaler_image_tag_selected
      },
      {
        name  = "rbac.serviceAccount.name"
        value = local.cluster_autoscaler_service_account
      },
      {
        name                  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
        value_is_iam_role_arn = true
      }
    ],
    try(var.cluster_autoscaler.set, [])
  )
  set_sensitive = try(var.cluster_autoscaler.set_sensitive, [])

  # IAM role for service account (IRSA)
  role_name                     = try(var.cluster_autoscaler.role_name, "cluster-autoscaler")
  role_name_use_prefix          = try(var.cluster_autoscaler.role_name_use_prefix, true)
  role_path                     = try(var.cluster_autoscaler.role_path, "/")
  role_permissions_boundary_arn = lookup(var.cluster_autoscaler, "role_permissions_boundary_arn", null)
  role_description              = try(var.cluster_autoscaler.role_description, "IRSA for cluster-autoscaler operator")
  role_policies                 = lookup(var.cluster_autoscaler, "role_policies", {})

  source_policy_documents = data.aws_iam_policy_document.cluster_autoscaler[*].json
  policy_statements       = lookup(var.cluster_autoscaler, "policy_statements", [])
  policy_name             = try(var.cluster_autoscaler.policy_name, null)
  policy_name_use_prefix  = try(var.cluster_autoscaler.policy_name_use_prefix, true)
  policy_path             = try(var.cluster_autoscaler.policy_path, null)
  policy_description      = try(var.cluster_autoscaler.policy_description, "IAM Policy for cluster-autoscaler operator")

  irsa_oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.cluster_autoscaler_service_account
    }
  }

  tags = var.tags
}

################################################################################
# External DNS
################################################################################

locals {
  external_dns_service_account = try(var.external_dns.service_account_name, "external-dns-sa")
  external_dns_namespace       = try(var.external_dns.namespace, "external-dns")
}

data "aws_iam_policy_document" "external_dns" {
  count = var.enable_external_dns && length(var.external_dns_route53_zone_arns) > 0 ? 1 : 0

  source_policy_documents   = lookup(var.external_dns, "source_policy_documents", [])
  override_policy_documents = lookup(var.external_dns, "override_policy_documents", [])

  statement {
    actions   = ["route53:ChangeResourceRecordSets"]
    resources = var.external_dns_route53_zone_arns
  }

  statement {
    actions   = ["route53:ListTagsForResource"]
    resources = var.external_dns_route53_zone_arns
  }

  statement {
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
    ]
    resources = ["*"]
  }
}

module "external_dns" {
  source  = "aws-blueprints/eks-blueprints-addon/aws"
  version = "2.0.0"

  create = var.enable_external_dns

  # https://github.com/kubernetes-sigs/external-dns/tree/master/charts/external-dns/Chart.yaml
  name             = try(var.external_dns.name, "external-dns")
  description      = try(var.external_dns.description, "A Helm chart to deploy external-dns")
  namespace        = local.external_dns_namespace
  create_namespace = try(var.external_dns.create_namespace, true)
  chart            = try(var.external_dns.chart, "external-dns")
  chart_version    = try(var.external_dns.chart_version, "1.14.3")
  repository       = try(var.external_dns.repository, "https://kubernetes-sigs.github.io/external-dns/")
  values           = try(var.external_dns.values, ["provider: aws"])

  timeout                    = try(var.external_dns.timeout, null)
  repository_key_file        = try(var.external_dns.repository_key_file, null)
  repository_cert_file       = try(var.external_dns.repository_cert_file, null)
  repository_ca_file         = try(var.external_dns.repository_ca_file, null)
  repository_username        = try(var.external_dns.repository_username, null)
  repository_password        = try(var.external_dns.repository_password, null)
  devel                      = try(var.external_dns.devel, null)
  verify                     = try(var.external_dns.verify, null)
  keyring                    = try(var.external_dns.keyring, null)
  disable_webhooks           = try(var.external_dns.disable_webhooks, null)
  reuse_values               = try(var.external_dns.reuse_values, null)
  reset_values               = try(var.external_dns.reset_values, null)
  force_update               = try(var.external_dns.force_update, null)
  recreate_pods              = try(var.external_dns.recreate_pods, null)
  cleanup_on_fail            = try(var.external_dns.cleanup_on_fail, null)
  max_history                = try(var.external_dns.max_history, null)
  atomic                     = try(var.external_dns.atomic, null)
  skip_crds                  = try(var.external_dns.skip_crds, null)
  render_subchart_notes      = try(var.external_dns.render_subchart_notes, null)
  disable_openapi_validation = try(var.external_dns.disable_openapi_validation, null)
  wait                       = try(var.external_dns.wait, false)
  wait_for_jobs              = try(var.external_dns.wait_for_jobs, null)
  dependency_update          = try(var.external_dns.dependency_update, null)
  replace                    = try(var.external_dns.replace, null)
  lint                       = try(var.external_dns.lint, null)

  postrender = try(var.external_dns.postrender, [])
  set = concat([
    {
      name  = "serviceAccount.name"
      value = local.external_dns_service_account
    },
    {
      name                  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value_is_iam_role_arn = true
    }],
    try(var.external_dns.set, [])
  )
  set_sensitive = try(var.external_dns.set_sensitive, [])

  # IAM role for service account (IRSA)
  role_name                     = try(var.external_dns.role_name, "external-dns")
  role_name_use_prefix          = try(var.external_dns.role_name_use_prefix, true)
  role_path                     = try(var.external_dns.role_path, "/")
  role_permissions_boundary_arn = lookup(var.external_dns, "role_permissions_boundary_arn", null)
  role_description              = try(var.external_dns.role_description, "IRSA for external-dns operator")
  role_policies                 = lookup(var.external_dns, "role_policies", {})

  source_policy_documents = data.aws_iam_policy_document.external_dns[*].json
  policy_statements       = lookup(var.external_dns, "policy_statements", [])
  policy_name             = try(var.external_dns.policy_name, null)
  policy_name_use_prefix  = try(var.external_dns.policy_name_use_prefix, true)
  policy_path             = try(var.external_dns.policy_path, null)
  policy_description      = try(var.external_dns.policy_description, "IAM Policy for external-dns operator")

  irsa_oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.external_dns_service_account
    }
  }

  tags = var.tags
}

################################################################################
# External Secrets
################################################################################

locals {
  external_secrets_service_account = try(var.external_secrets.service_account_name, "external-secrets-sa")
  external_secrets_namespace       = try(var.external_secrets.namespace, "external-secrets")
}

data "aws_iam_policy_document" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  source_policy_documents   = lookup(var.external_secrets, "source_policy_documents", [])
  override_policy_documents = lookup(var.external_secrets, "override_policy_documents", [])

  dynamic "statement" {
    for_each = length(var.external_secrets_ssm_parameter_arns) > 0 ? [1] : []

    content {
      actions   = ["ssm:DescribeParameters"]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = length(var.external_secrets_ssm_parameter_arns) > 0 ? [1] : []

    content {
      actions = [
        "ssm:GetParameter",
        "ssm:GetParameters",
      ]
      resources = var.external_secrets_ssm_parameter_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.external_secrets_secrets_manager_arns) > 0 ? [1] : []

    content {
      actions   = ["secretsmanager:ListSecrets"]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = length(var.external_secrets_secrets_manager_arns) > 0 ? [1] : []

    content {
      actions = [
        "secretsmanager:GetResourcePolicy",
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:ListSecretVersionIds",
        "secretsmanager:BatchGetSecretValue",
      ]
      resources = var.external_secrets_secrets_manager_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.external_secrets_kms_key_arns) > 0 ? [1] : []

    content {
      actions   = ["kms:Decrypt"]
      resources = var.external_secrets_kms_key_arns
    }
  }
}

module "external_secrets" {
  source  = "aws-blueprints/eks-blueprints-addon/aws"
  version = "2.0.0"

  create = var.enable_external_secrets

  # https://github.com/external-secrets/external-secrets/blob/main/deploy/charts/external-secrets/Chart.yaml
  name             = try(var.external_secrets.name, "external-secrets")
  description      = try(var.external_secrets.description, "A Helm chart to deploy external-secrets")
  namespace        = local.external_secrets_namespace
  create_namespace = try(var.external_secrets.create_namespace, true)
  chart            = try(var.external_secrets.chart, "external-secrets")
  chart_version    = try(var.external_secrets.chart_version, "0.9.13")
  repository       = try(var.external_secrets.repository, "https://charts.external-secrets.io")
  values           = try(var.external_secrets.values, [])

  timeout                    = try(var.external_secrets.timeout, null)
  repository_key_file        = try(var.external_secrets.repository_key_file, null)
  repository_cert_file       = try(var.external_secrets.repository_cert_file, null)
  repository_ca_file         = try(var.external_secrets.repository_ca_file, null)
  repository_username        = try(var.external_secrets.repository_username, null)
  repository_password        = try(var.external_secrets.repository_password, null)
  devel                      = try(var.external_secrets.devel, null)
  verify                     = try(var.external_secrets.verify, null)
  keyring                    = try(var.external_secrets.keyring, null)
  disable_webhooks           = try(var.external_secrets.disable_webhooks, null)
  reuse_values               = try(var.external_secrets.reuse_values, null)
  reset_values               = try(var.external_secrets.reset_values, null)
  force_update               = try(var.external_secrets.force_update, null)
  recreate_pods              = try(var.external_secrets.recreate_pods, null)
  cleanup_on_fail            = try(var.external_secrets.cleanup_on_fail, null)
  max_history                = try(var.external_secrets.max_history, null)
  atomic                     = try(var.external_secrets.atomic, null)
  skip_crds                  = try(var.external_secrets.skip_crds, null)
  render_subchart_notes      = try(var.external_secrets.render_subchart_notes, null)
  disable_openapi_validation = try(var.external_secrets.disable_openapi_validation, null)
  wait                       = try(var.external_secrets.wait, false)
  wait_for_jobs              = try(var.external_secrets.wait_for_jobs, null)
  dependency_update          = try(var.external_secrets.dependency_update, null)
  replace                    = try(var.external_secrets.replace, null)
  lint                       = try(var.external_secrets.lint, null)

  postrender = try(var.external_secrets.postrender, [])
  set = concat([
    {
      name  = "serviceAccount.name"
      value = local.external_secrets_service_account
    },
    {
      name  = "webhook.port"
      value = var.enable_eks_fargate ? "9443" : "10250"
    },
    {
      name                  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value_is_iam_role_arn = true
    }],
    try(var.external_secrets.set, [])
  )
  set_sensitive = try(var.external_secrets.set_sensitive, [])

  # IAM role for service account (IRSA)
  role_name                     = try(var.external_secrets.role_name, "external-secrets")
  role_name_use_prefix          = try(var.external_secrets.role_name_use_prefix, true)
  role_path                     = try(var.external_secrets.role_path, "/")
  role_permissions_boundary_arn = lookup(var.external_secrets, "role_permissions_boundary_arn", null)
  role_description              = try(var.external_secrets.role_description, "IRSA for external-secrets operator")
  role_policies                 = lookup(var.external_secrets, "role_policies", {})

  source_policy_documents = data.aws_iam_policy_document.external_secrets[*].json
  policy_statements       = lookup(var.external_secrets, "policy_statements", [])
  policy_name             = try(var.external_secrets.policy_name, null)
  policy_name_use_prefix  = try(var.external_secrets.policy_name_use_prefix, true)
  policy_path             = try(var.external_secrets.policy_path, null)
  policy_description      = try(var.external_secrets.policy_description, "IAM Policy for external-secrets operator")

  irsa_oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.external_secrets_service_account
    }
  }

  tags = var.tags
}

################################################################################
# Karpenter
################################################################################

locals {
  karpenter_service_account_name    = try(var.karpenter.service_account_name, "karpenter")
  karpenter_enable_spot_termination = var.enable_karpenter && var.karpenter_enable_spot_termination

  create_karpenter_node_iam_role = var.enable_karpenter && try(var.karpenter_node.create_iam_role, true)
  karpenter_node_iam_role_arn    = try(aws_iam_role.karpenter[0].arn, var.karpenter_node.iam_role_arn, "")
  karpenter_node_iam_role_name   = try(var.karpenter_node.iam_role_name, "karpenter-${var.cluster_name}")
  # This is the name used when the instance profile is created by the module
  input_karpenter_node_instance_profile_name = try(var.karpenter_node.instance_profile_name, local.karpenter_node_iam_role_name)
  # This is the name passed to the Karpenter Helm chart - either the profile the module creates, or one provided by the user
  output_karpenter_node_instance_profile_name = try(aws_iam_instance_profile.karpenter[0].name, var.karpenter_node.instance_profile_name, "")
  karpenter_namespace                         = try(var.karpenter.namespace, "karpenter")

  karpenter_set = [
    # TODO - remove at next breaking change
    # Pre 0.32.x
    {
      name  = "settings.aws.clusterName"
      value = local.cluster_name
    },
    {
      name  = "settings.aws.clusterEndpoint"
      value = local.cluster_endpoint
    },
    {
      name  = "settings.aws.interruptionQueueName"
      value = local.karpenter_enable_spot_termination ? module.karpenter_sqs.queue_name : null
    },
    {
      name  = "settings.aws.defaultInstanceProfile"
      value = var.karpenter_enable_instance_profile_creation ? null : local.output_karpenter_node_instance_profile_name
    },
    # Post 0.32.x
    {
      name  = "settings.clusterName"
      value = local.cluster_name
    },
    {
      name  = "settings.clusterEndpoint"
      value = local.cluster_endpoint
    },
    {
      name  = "settings.interruptionQueue"
      value = local.karpenter_enable_spot_termination ? module.karpenter_sqs.queue_name : null
    },
    # TODO - this is not valid but being discussed as a re-addition. TBD on what the schema will be though
    # {
    #   name  = "settings.defaultInstanceProfile"
    #   value = var.karpenter_enable_instance_profile_creation ? null : local.output_karpenter_node_instance_profile_name
    # },
    # Agnostic of version difference
    {
      name  = "serviceAccount.name"
      value = local.karpenter_service_account_name
    },
  ]
}

data "aws_iam_policy_document" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  source_policy_documents   = lookup(var.karpenter, "source_policy_documents", [])
  override_policy_documents = lookup(var.karpenter, "override_policy_documents", [])

  statement {
    actions = [
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeSubnets",
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "ec2:CreateFleet",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateTags",
      "ec2:DeleteLaunchTemplate",
      "ec2:RunInstances"
    ]
    resources = [
      "arn:${local.partition}:ec2:${local.region}:${local.account_id}:*",
      "arn:${local.partition}:ec2:${local.region}::image/*"
    ]
  }

  statement {
    actions   = ["iam:PassRole"]
    resources = [local.karpenter_node_iam_role_arn]
  }

  statement {
    actions   = ["pricing:GetProducts"]
    resources = ["*"]
  }

  statement {
    actions   = ["ssm:GetParameter"]
    resources = ["arn:${local.partition}:ssm:${local.region}::parameter/aws/service/*"]
  }

  statement {
    actions   = ["eks:DescribeCluster"]
    resources = ["arn:${local.partition}:eks:*:${local.account_id}:cluster/${var.cluster_name}"]
  }

  statement {
    actions   = ["ec2:TerminateInstances"]
    resources = ["arn:${local.partition}:ec2:${local.region}:${local.account_id}:instance/*"]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["*"]
    }
  }

  dynamic "statement" {
    for_each = local.karpenter_enable_spot_termination ? [1] : []

    content {
      actions = [
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
        "sqs:ReceiveMessage",
      ]
      resources = [module.karpenter_sqs.queue_arn]
    }
  }

  dynamic "statement" {
    for_each = var.karpenter_enable_instance_profile_creation ? [1] : []

    content {
      actions = [
        "iam:AddRoleToInstanceProfile",
        "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile",
        "iam:GetInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:TagInstanceProfile",
      ]
      resources = ["*"]
    }
  }
}

module "karpenter_sqs" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "4.0.1"

  create = local.karpenter_enable_spot_termination

  name = try(var.karpenter_sqs.queue_name, "karpenter-${var.cluster_name}")

  message_retention_seconds         = try(var.karpenter_sqs.message_retention_seconds, 300)
  sqs_managed_sse_enabled           = try(var.karpenter_sqs.sse_enabled, true)
  kms_master_key_id                 = try(var.karpenter_sqs.kms_master_key_id, null)
  kms_data_key_reuse_period_seconds = try(var.karpenter_sqs.kms_data_key_reuse_period_seconds, null)

  create_queue_policy = true
  queue_policy_statements = {
    account = {
      sid     = "SendEventsToQueue"
      actions = ["sqs:SendMessage"]
      principals = [
        {
          type = "Service"
          identifiers = [
            "events.amazonaws.com",
            "sqs.amazonaws.com",
          ]
        }
      ]
    }
  }

  tags = merge(var.tags, try(var.karpenter_sqs.tags, {}))
}

resource "aws_cloudwatch_event_rule" "karpenter" {
  for_each = { for k, v in local.ec2_events : k => v if local.karpenter_enable_spot_termination }

  name_prefix   = "Karpenter-${each.value.name}-"
  description   = each.value.description
  event_pattern = jsonencode(each.value.event_pattern)

  tags = merge(
    { "ClusterName" : var.cluster_name },
    var.tags,
  )
}

resource "aws_cloudwatch_event_target" "karpenter" {
  for_each = { for k, v in local.ec2_events : k => v if local.karpenter_enable_spot_termination }

  rule      = aws_cloudwatch_event_rule.karpenter[each.key].name
  target_id = "KarpenterQueueTarget"
  arn       = module.karpenter_sqs.queue_arn
}

data "aws_iam_policy_document" "karpenter_assume_role" {
  count = local.create_karpenter_node_iam_role ? 1 : 0

  statement {
    sid     = "KarpenterNodeAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "karpenter" {
  count = local.create_karpenter_node_iam_role ? 1 : 0

  name        = try(var.karpenter_node.iam_role_use_name_prefix, true) ? null : local.karpenter_node_iam_role_name
  name_prefix = try(var.karpenter_node.iam_role_use_name_prefix, true) ? "${local.karpenter_node_iam_role_name}-" : null
  path        = try(var.karpenter_node.iam_role_path, null)
  description = try(var.karpenter_node.iam_role_description, "Karpenter EC2 node IAM role")

  assume_role_policy    = try(data.aws_iam_policy_document.karpenter_assume_role[0].json, "")
  max_session_duration  = try(var.karpenter_node.iam_role_max_session_duration, null)
  permissions_boundary  = try(var.karpenter_node.iam_role_permissions_boundary, null)
  force_detach_policies = true

  tags = merge(var.tags, try(var.karpenter_node.iam_role_tags, {}))
}

resource "aws_iam_role_policy_attachment" "karpenter" {
  for_each = { for k, v in {
    AmazonEKSWorkerNodePolicy          = "${local.iam_role_policy_prefix}/AmazonEKSWorkerNodePolicy",
    AmazonEC2ContainerRegistryReadOnly = "${local.iam_role_policy_prefix}/AmazonEC2ContainerRegistryReadOnly",
    AmazonEKS_CNI_Policy               = "${local.iam_role_policy_prefix}/AmazonEKS_CNI_Policy"
  } : k => v if local.create_karpenter_node_iam_role }

  policy_arn = each.value
  role       = aws_iam_role.karpenter[0].name
}

resource "aws_iam_role_policy_attachment" "additional" {
  for_each = { for k, v in lookup(var.karpenter_node, "iam_role_additional_policies", {}) : k => v if local.create_karpenter_node_iam_role }

  policy_arn = each.value
  role       = aws_iam_role.karpenter[0].name
}

resource "aws_iam_instance_profile" "karpenter" {
  count = var.enable_karpenter && try(var.karpenter_node.create_instance_profile, true) ? 1 : 0

  name        = try(var.karpenter_node.iam_role_use_name_prefix, true) ? null : local.input_karpenter_node_instance_profile_name
  name_prefix = try(var.karpenter_node.iam_role_use_name_prefix, true) ? "${local.input_karpenter_node_instance_profile_name}-" : null
  path        = try(var.karpenter_node.iam_role_path, null)
  role        = try(aws_iam_role.karpenter[0].name, var.karpenter_node.iam_role_name, "")

  tags = merge(var.tags, try(var.karpenter_node.instance_profile_tags, {}))
}

module "karpenter" {
  source  = "aws-blueprints/eks-blueprints-addon/aws"
  version = "2.0.0"

  create = var.enable_karpenter

  # https://github.com/aws/karpenter/blob/main/charts/karpenter/Chart.yaml
  name             = try(var.karpenter.name, "karpenter")
  description      = try(var.karpenter.description, "A Helm chart to deploy Karpenter")
  namespace        = local.karpenter_namespace
  create_namespace = try(var.karpenter.create_namespace, true)
  chart            = try(var.karpenter.chart, "karpenter")
  chart_version    = try(var.karpenter.chart_version, "0.37.0")
  repository       = try(var.karpenter.repository, "oci://public.ecr.aws/karpenter")
  values           = try(var.karpenter.values, [])

  timeout                    = try(var.karpenter.timeout, null)
  repository_key_file        = try(var.karpenter.repository_key_file, null)
  repository_cert_file       = try(var.karpenter.repository_cert_file, null)
  repository_ca_file         = try(var.karpenter.repository_ca_file, null)
  repository_username        = try(var.karpenter.repository_username, null)
  repository_password        = try(var.karpenter.repository_password, null)
  devel                      = try(var.karpenter.devel, null)
  verify                     = try(var.karpenter.verify, null)
  keyring                    = try(var.karpenter.keyring, null)
  disable_webhooks           = try(var.karpenter.disable_webhooks, null)
  reuse_values               = try(var.karpenter.reuse_values, null)
  reset_values               = try(var.karpenter.reset_values, null)
  force_update               = try(var.karpenter.force_update, null)
  recreate_pods              = try(var.karpenter.recreate_pods, null)
  cleanup_on_fail            = try(var.karpenter.cleanup_on_fail, null)
  max_history                = try(var.karpenter.max_history, null)
  atomic                     = try(var.karpenter.atomic, null)
  skip_crds                  = try(var.karpenter.skip_crds, null)
  render_subchart_notes      = try(var.karpenter.render_subchart_notes, null)
  disable_openapi_validation = try(var.karpenter.disable_openapi_validation, null)
  wait                       = try(var.karpenter.wait, false)
  wait_for_jobs              = try(var.karpenter.wait_for_jobs, null)
  dependency_update          = try(var.karpenter.dependency_update, null)
  replace                    = try(var.karpenter.replace, null)
  lint                       = try(var.karpenter.lint, null)

  postrender = try(var.karpenter.postrender, [])
  set = concat(
    [for s in local.karpenter_set : s if s.value != null],
    {
      name                  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value_is_iam_role_arn = true
    },
    try(var.karpenter.set, [])
  )
  set_sensitive = try(var.karpenter.set_sensitive, [])

  # IAM role for service account (IRSA)
  role_name                     = try(var.karpenter.role_name, "karpenter")
  role_name_use_prefix          = try(var.karpenter.role_name_use_prefix, true)
  role_path                     = try(var.karpenter.role_path, "/")
  role_permissions_boundary_arn = lookup(var.karpenter, "role_permissions_boundary_arn", null)
  role_description              = try(var.karpenter.role_description, "IRSA for Karpenter")
  role_policies                 = lookup(var.karpenter, "role_policies", {})

  source_policy_documents = data.aws_iam_policy_document.karpenter[*].json
  policy_statements       = lookup(var.karpenter, "policy_statements", [])
  policy_name             = try(var.karpenter.policy_name, null)
  policy_name_use_prefix  = try(var.karpenter.policy_name_use_prefix, true)
  policy_path             = try(var.karpenter.policy_path, null)
  policy_description      = try(var.karpenter.policy_description, "IAM Policy for karpenter")

  irsa_oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.karpenter_service_account_name
    }
  }

  tags = var.tags
}

################################################################################
# Velero
################################################################################

locals {
  velero_name                    = "velero"
  velero_service_account         = try(var.velero.service_account_name, "${local.velero_name}-server")
  velero_backup_s3_bucket        = try(split(":", var.velero.s3_backup_location), [])
  velero_backup_s3_bucket_arn    = try(split("/", var.velero.s3_backup_location)[0], var.velero.s3_backup_location, "")
  velero_backup_s3_bucket_name   = try(split("/", local.velero_backup_s3_bucket[5])[0], local.velero_backup_s3_bucket[5], "")
  velero_backup_s3_bucket_prefix = try(split("/", var.velero.s3_backup_location)[1], "")
  velero_namespace               = try(var.velero.namespace, "velero")
}

# https://github.com/vmware-tanzu/velero-plugin-for-aws#option-1-set-permissions-with-an-iam-user
data "aws_iam_policy_document" "velero" {
  count = var.enable_velero ? 1 : 0

  source_policy_documents   = lookup(var.velero, "source_policy_documents", [])
  override_policy_documents = lookup(var.velero, "override_policy_documents", [])

  statement {
    actions = [
      "ec2:CreateSnapshot",
      "ec2:CreateSnapshots",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:DeleteSnapshot"
    ]
    resources = [
      "arn:${local.partition}:ec2:${local.region}:${local.account_id}:instance/*",
      "arn:${local.partition}:ec2:${local.region}::snapshot/*",
      "arn:${local.partition}:ec2:${local.region}:${local.account_id}:volume/*"
    ]
  }

  statement {
    actions = [
      "ec2:DescribeSnapshots",
      "ec2:DescribeVolumes"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
    ]
    resources = ["${var.velero.s3_backup_location}/*"]
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [local.velero_backup_s3_bucket_arn]
  }
}

module "velero" {
  source  = "aws-blueprints/eks-blueprints-addon/aws"
  version = "2.0.0"

  create = var.enable_velero

  # https://github.com/vmware-tanzu/helm-charts/blob/main/charts/velero/Chart.yaml
  name             = try(var.velero.name, "velero")
  description      = try(var.velero.description, "A Helm chart to install the Velero")
  namespace        = local.velero_namespace
  create_namespace = try(var.velero.create_namespace, true)
  chart            = try(var.velero.chart, "velero")
  chart_version    = try(var.velero.chart_version, "3.2.0") # TODO - 6.0
  repository       = try(var.velero.repository, "https://vmware-tanzu.github.io/helm-charts/")
  values           = try(var.velero.values, [])

  timeout                    = try(var.velero.timeout, null)
  repository_key_file        = try(var.velero.repository_key_file, null)
  repository_cert_file       = try(var.velero.repository_cert_file, null)
  repository_ca_file         = try(var.velero.repository_ca_file, null)
  repository_username        = try(var.velero.repository_username, null)
  repository_password        = try(var.velero.repository_password, null)
  devel                      = try(var.velero.devel, null)
  verify                     = try(var.velero.verify, null)
  keyring                    = try(var.velero.keyring, null)
  disable_webhooks           = try(var.velero.disable_webhooks, null)
  reuse_values               = try(var.velero.reuse_values, null)
  reset_values               = try(var.velero.reset_values, null)
  force_update               = try(var.velero.force_update, null)
  recreate_pods              = try(var.velero.recreate_pods, null)
  cleanup_on_fail            = try(var.velero.cleanup_on_fail, null)
  max_history                = try(var.velero.max_history, null)
  atomic                     = try(var.velero.atomic, null)
  skip_crds                  = try(var.velero.skip_crds, null)
  render_subchart_notes      = try(var.velero.render_subchart_notes, null)
  disable_openapi_validation = try(var.velero.disable_openapi_validation, null)
  wait                       = try(var.velero.wait, false)
  wait_for_jobs              = try(var.velero.wait_for_jobs, null)
  dependency_update          = try(var.velero.dependency_update, null)
  replace                    = try(var.velero.replace, null)
  lint                       = try(var.velero.lint, null)

  postrender = try(var.velero.postrender, [])
  set = concat([
    {
      name  = "initContainers"
      value = <<-EOT
        - name: velero-plugin-for-aws
          image: velero/velero-plugin-for-aws:v1.7.1
          imagePullPolicy: IfNotPresent
          volumeMounts:
            - mountPath: /target
              name: plugins
      EOT
    },
    {
      name  = "serviceAccount.server.name"
      value = local.velero_service_account
    },
    {
      name  = "configuration.provider"
      value = "aws"
    },
    {
      name  = "configuration.backupStorageLocation.prefix"
      value = local.velero_backup_s3_bucket_prefix
    },
    {
      name  = "configuration.backupStorageLocation.bucket"
      value = local.velero_backup_s3_bucket_name
    },
    {
      name  = "configuration.backupStorageLocation.config.region"
      value = local.region
    },
    {
      name  = "configuration.volumeSnapshotLocation.config.region"
      value = local.region
    },
    {
      name  = "credentials.useSecret"
      value = false
    },
    {
      name                  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value_is_iam_role_arn = true
    }],
    try(var.velero.set, [])
  )
  set_sensitive = try(var.velero.set_sensitive, [])

  # IAM role for service account (IRSA)
  role_name                     = try(var.velero.role_name, "velero")
  role_name_use_prefix          = try(var.velero.role_name_use_prefix, true)
  role_path                     = try(var.velero.role_path, "/")
  role_permissions_boundary_arn = lookup(var.velero, "role_permissions_boundary_arn", null)
  role_description              = try(var.velero.role_description, "IRSA for Velero")
  role_policies                 = lookup(var.velero, "role_policies", {})

  source_policy_documents = data.aws_iam_policy_document.velero[*].json
  policy_statements       = lookup(var.velero, "policy_statements", [])
  policy_name             = try(var.velero.policy_name, "velero")
  policy_name_use_prefix  = try(var.velero.policy_name_use_prefix, true)
  policy_path             = try(var.velero.policy_path, null)
  policy_description      = try(var.velero.policy_description, "IAM Policy for Velero")

  irsa_oidc_providers = {
    controller = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.velero_service_account
    }
  }

  tags = var.tags
}

################################################################################
# AWS Gateway API Controller
################################################################################

locals {
  aws_gateway_api_controller_service_account = try(var.aws_gateway_api_controller.service_account_name, "gateway-api-controller")
  aws_gateway_api_controller_namespace       = try(var.aws_gateway_api_controller.namespace, "aws-application-networking-system")
}

data "aws_iam_policy_document" "aws_gateway_api_controller" {
  count = var.enable_aws_gateway_api_controller ? 1 : 0

  source_policy_documents   = lookup(var.aws_gateway_api_controller, "source_policy_documents", [])
  override_policy_documents = lookup(var.aws_gateway_api_controller, "override_policy_documents", [])

  statement {
    actions = [
      "vpc-lattice:*",
      "iam:CreateServiceLinkedRole",
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeSecurityGroups",
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "tag:GetResources"
    ]
    resources = ["*"]
  }
}

module "aws_gateway_api_controller" {
  source  = "aws-blueprints/eks-blueprints-addon/aws"
  version = "2.0.0"

  create = var.enable_aws_gateway_api_controller

  # https://github.com/aws/aws-application-networking-k8s/blob/main/helm/Chart.yaml
  name             = try(var.aws_gateway_api_controller.name, "aws-gateway-api-controller")
  description      = try(var.aws_gateway_api_controller.description, "A Helm chart to deploy aws-gateway-api-controller")
  namespace        = local.aws_gateway_api_controller_namespace
  create_namespace = try(var.aws_gateway_api_controller.create_namespace, true)
  chart            = try(var.aws_gateway_api_controller.chart, "aws-gateway-controller-chart")
  chart_version    = try(var.aws_gateway_api_controller.chart_version, "v0.0.18") # TODO - 1.0
  repository       = try(var.aws_gateway_api_controller.repository, "oci://public.ecr.aws/aws-application-networking-k8s")
  values           = try(var.aws_gateway_api_controller.values, [])

  timeout                    = try(var.aws_gateway_api_controller.timeout, null)
  repository_key_file        = try(var.aws_gateway_api_controller.repository_key_file, null)
  repository_cert_file       = try(var.aws_gateway_api_controller.repository_cert_file, null)
  repository_ca_file         = try(var.aws_gateway_api_controller.repository_ca_file, null)
  repository_username        = try(var.aws_gateway_api_controller.repository_username, null)
  repository_password        = try(var.aws_gateway_api_controller.repository_password, null)
  devel                      = try(var.aws_gateway_api_controller.devel, null)
  verify                     = try(var.aws_gateway_api_controller.verify, null)
  keyring                    = try(var.aws_gateway_api_controller.keyring, null)
  disable_webhooks           = try(var.aws_gateway_api_controller.disable_webhooks, null)
  reuse_values               = try(var.aws_gateway_api_controller.reuse_values, null)
  reset_values               = try(var.aws_gateway_api_controller.reset_values, null)
  force_update               = try(var.aws_gateway_api_controller.force_update, null)
  recreate_pods              = try(var.aws_gateway_api_controller.recreate_pods, null)
  cleanup_on_fail            = try(var.aws_gateway_api_controller.cleanup_on_fail, null)
  max_history                = try(var.aws_gateway_api_controller.max_history, null)
  atomic                     = try(var.aws_gateway_api_controller.atomic, null)
  skip_crds                  = try(var.aws_gateway_api_controller.skip_crds, null)
  render_subchart_notes      = try(var.aws_gateway_api_controller.render_subchart_notes, null)
  disable_openapi_validation = try(var.aws_gateway_api_controller.disable_openapi_validation, null)
  wait                       = try(var.aws_gateway_api_controller.wait, false)
  wait_for_jobs              = try(var.aws_gateway_api_controller.wait_for_jobs, null)
  dependency_update          = try(var.aws_gateway_api_controller.dependency_update, null)
  replace                    = try(var.aws_gateway_api_controller.replace, null)
  lint                       = try(var.aws_gateway_api_controller.lint, null)

  postrender = try(var.aws_gateway_api_controller.postrender, [])
  set = concat([
    {
      name  = "serviceAccount.name"
      value = local.aws_gateway_api_controller_service_account
    },
    {
      name  = "awsRegion"
      value = local.region
    },
    {
      name  = "awsAccountId"
      value = local.account_id
    },
    {
      name                  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value_is_iam_role_arn = true
    }],
    try(var.aws_gateway_api_controller.set, [])
  )
  set_sensitive = try(var.aws_gateway_api_controller.set_sensitive, [])

  # IAM role for service account (IRSA)
  role_name                     = try(var.aws_gateway_api_controller.role_name, "aws-gateway-api-controller")
  role_name_use_prefix          = try(var.aws_gateway_api_controller.role_name_use_prefix, true)
  role_path                     = try(var.aws_gateway_api_controller.role_path, "/")
  role_permissions_boundary_arn = lookup(var.aws_gateway_api_controller, "role_permissions_boundary_arn", null)
  role_description              = try(var.aws_gateway_api_controller.role_description, "IRSA for aws-gateway-api-controller")
  role_policies                 = lookup(var.aws_gateway_api_controller, "role_policies", {})

  source_policy_documents = data.aws_iam_policy_document.aws_gateway_api_controller[*].json
  policy_statements       = lookup(var.aws_gateway_api_controller, "policy_statements", [])
  policy_name             = try(var.aws_gateway_api_controller.policy_name, null)
  policy_name_use_prefix  = try(var.aws_gateway_api_controller.policy_name_use_prefix, true)
  policy_path             = try(var.aws_gateway_api_controller.policy_path, null)
  policy_description      = try(var.aws_gateway_api_controller.policy_description, "IAM Policy for aws-gateway-api-controller")

  irsa_oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.aws_gateway_api_controller_service_account
    }
  }

  tags = var.tags
}
