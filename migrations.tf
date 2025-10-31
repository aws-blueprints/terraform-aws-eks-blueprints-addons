################################################################################
# from -> aws-ia/terraform-aws-eks-blueprints-addons 1.22
# to -> aws-blueprints/terraform-aws-eks-blueprints-addons 2.0
################################################################################

moved {
  from = module.argo_rollouts[0].helm_release.this
  to   = helm_release.argo_rollouts
}

moved {
  from = module.argo_workflows[0].helm_release.this
  to   = helm_release.argo_workflows
}

moved {
  from = module.argocd[0].helm_release.this
  to   = helm_release.argocd
}

moved {
  from = module.argo_events[0].helm_release.this
  to   = helm_release.argo_events
}
