
################################################################################
# Argo Rollouts
################################################################################

resource "helm_release" "argo_rollouts" {
  count = var.argo_rollouts.enable ? 1 : 0

  atomic                     = var.argo_rollouts.atomic
  chart                      = var.argo_rollouts.chart
  cleanup_on_fail            = var.argo_rollouts.cleanup_on_fail
  create_namespace           = var.argo_rollouts.create_namespace
  dependency_update          = var.argo_rollouts.dependency_update
  description                = var.argo_rollouts.description
  devel                      = var.argo_rollouts.devel
  disable_crd_hooks          = var.argo_rollouts.disable_crd_hooks
  disable_openapi_validation = var.argo_rollouts.disable_openapi_validation
  disable_webhooks           = var.argo_rollouts.disable_webhooks
  force_update               = var.argo_rollouts.force_update
  keyring                    = var.argo_rollouts.keyring
  lint                       = var.argo_rollouts.lint
  max_history                = var.argo_rollouts.max_history
  name                       = try(coalesce(var.argo_rollouts.name, var.argo_rollouts.chart), "")
  namespace                  = var.argo_rollouts.namespace
  pass_credentials           = var.argo_rollouts.pass_credentials
  postrender                 = var.argo_rollouts.postrender
  recreate_pods              = var.argo_rollouts.recreate_pods
  render_subchart_notes      = var.argo_rollouts.render_subchart_notes
  replace                    = var.argo_rollouts.replace
  repository                 = var.argo_rollouts.repository
  repository_ca_file         = var.argo_rollouts.repository_ca_file
  repository_cert_file       = var.argo_rollouts.repository_cert_file
  repository_key_file        = var.argo_rollouts.repository_key_file
  repository_password        = var.argo_rollouts.repository_password
  repository_username        = var.argo_rollouts.repository_username
  reset_values               = var.argo_rollouts.reset_values
  reuse_values               = var.argo_rollouts.reuse_values
  set                        = var.argo_rollouts.set
  set_list                   = var.argo_rollouts.set_list
  set_sensitive              = var.argo_rollouts.set_sensitive
  set_wo                     = var.argo_rollouts.set_wo
  set_wo_revision            = var.argo_rollouts.set_wo_revision
  skip_crds                  = var.argo_rollouts.skip_crds
  take_ownership             = var.argo_rollouts.take_ownership
  timeout                    = var.argo_rollouts.timeout
  timeouts                   = var.argo_rollouts.release_timeouts
  upgrade_install            = var.argo_rollouts.upgrade_install
  values                     = var.argo_rollouts.values
  verify                     = var.argo_rollouts.verify
  version                    = var.argo_rollouts.chart_version
  wait                       = var.argo_rollouts.wait
  wait_for_jobs              = var.argo_rollouts.wait_for_jobs
}

################################################################################
# Argo Workflows
################################################################################

resource "helm_release" "argo_workflows" {
  count = var.argo_workflows.enable ? 1 : 0

  atomic                     = var.argo_workflows.atomic
  chart                      = var.argo_workflows.chart
  cleanup_on_fail            = var.argo_workflows.cleanup_on_fail
  create_namespace           = var.argo_workflows.create_namespace
  dependency_update          = var.argo_workflows.dependency_update
  description                = var.argo_workflows.description
  devel                      = var.argo_workflows.devel
  disable_crd_hooks          = var.argo_workflows.disable_crd_hooks
  disable_openapi_validation = var.argo_workflows.disable_openapi_validation
  disable_webhooks           = var.argo_workflows.disable_webhooks
  force_update               = var.argo_workflows.force_update
  keyring                    = var.argo_workflows.keyring
  lint                       = var.argo_workflows.lint
  max_history                = var.argo_workflows.max_history
  name                       = try(coalesce(var.argo_workflows.name, var.argo_workflows.chart), "")
  namespace                  = var.argo_workflows.namespace
  pass_credentials           = var.argo_workflows.pass_credentials
  postrender                 = var.argo_workflows.postrender
  recreate_pods              = var.argo_workflows.recreate_pods
  render_subchart_notes      = var.argo_workflows.render_subchart_notes
  replace                    = var.argo_workflows.replace
  repository                 = var.argo_workflows.repository
  repository_ca_file         = var.argo_workflows.repository_ca_file
  repository_cert_file       = var.argo_workflows.repository_cert_file
  repository_key_file        = var.argo_workflows.repository_key_file
  repository_password        = var.argo_workflows.repository_password
  repository_username        = var.argo_workflows.repository_username
  reset_values               = var.argo_workflows.reset_values
  reuse_values               = var.argo_workflows.reuse_values
  set                        = var.argo_workflows.set
  set_list                   = var.argo_workflows.set_list
  set_sensitive              = var.argo_workflows.set_sensitive
  set_wo                     = var.argo_workflows.set_wo
  set_wo_revision            = var.argo_workflows.set_wo_revision
  skip_crds                  = var.argo_workflows.skip_crds
  take_ownership             = var.argo_workflows.take_ownership
  timeout                    = var.argo_workflows.timeout
  timeouts                   = var.argo_workflows.release_timeouts
  upgrade_install            = var.argo_workflows.upgrade_install
  values                     = var.argo_workflows.values
  verify                     = var.argo_workflows.verify
  version                    = var.argo_workflows.chart_version
  wait                       = var.argo_workflows.wait
  wait_for_jobs              = var.argo_workflows.wait_for_jobs
}

################################################################################
# ArgoCD
################################################################################

resource "helm_release" "argocd" {
  count = var.argocd.enable ? 1 : 0

  atomic                     = var.argocd.atomic
  chart                      = var.argocd.chart
  cleanup_on_fail            = var.argocd.cleanup_on_fail
  create_namespace           = var.argocd.create_namespace
  dependency_update          = var.argocd.dependency_update
  description                = var.argocd.description
  devel                      = var.argocd.devel
  disable_crd_hooks          = var.argocd.disable_crd_hooks
  disable_openapi_validation = var.argocd.disable_openapi_validation
  disable_webhooks           = var.argocd.disable_webhooks
  force_update               = var.argocd.force_update
  keyring                    = var.argocd.keyring
  lint                       = var.argocd.lint
  max_history                = var.argocd.max_history
  name                       = try(coalesce(var.argocd.name, var.argocd.chart), "")
  namespace                  = var.argocd.namespace
  pass_credentials           = var.argocd.pass_credentials
  postrender                 = var.argocd.postrender
  recreate_pods              = var.argocd.recreate_pods
  render_subchart_notes      = var.argocd.render_subchart_notes
  replace                    = var.argocd.replace
  repository                 = var.argocd.repository
  repository_ca_file         = var.argocd.repository_ca_file
  repository_cert_file       = var.argocd.repository_cert_file
  repository_key_file        = var.argocd.repository_key_file
  repository_password        = var.argocd.repository_password
  repository_username        = var.argocd.repository_username
  reset_values               = var.argocd.reset_values
  reuse_values               = var.argocd.reuse_values
  set                        = var.argocd.set
  set_list                   = var.argocd.set_list
  set_sensitive              = var.argocd.set_sensitive
  set_wo                     = var.argocd.set_wo
  set_wo_revision            = var.argocd.set_wo_revision
  skip_crds                  = var.argocd.skip_crds
  take_ownership             = var.argocd.take_ownership
  timeout                    = var.argocd.timeout
  timeouts                   = var.argocd.release_timeouts
  upgrade_install            = var.argocd.upgrade_install
  values                     = var.argocd.values
  verify                     = var.argocd.verify
  version                    = var.argocd.chart_version
  wait                       = var.argocd.wait
  wait_for_jobs              = var.argocd.wait_for_jobs
}

################################################################################
# Argo Events
################################################################################

resource "helm_release" "argo_events" {
  count = var.argo_events.enable ? 1 : 0

  atomic                     = var.argo_events.atomic
  chart                      = var.argo_events.chart
  cleanup_on_fail            = var.argo_events.cleanup_on_fail
  create_namespace           = var.argo_events.create_namespace
  dependency_update          = var.argo_events.dependency_update
  description                = var.argo_events.description
  devel                      = var.argo_events.devel
  disable_crd_hooks          = var.argo_events.disable_crd_hooks
  disable_openapi_validation = var.argo_events.disable_openapi_validation
  disable_webhooks           = var.argo_events.disable_webhooks
  force_update               = var.argo_events.force_update
  keyring                    = var.argo_events.keyring
  lint                       = var.argo_events.lint
  max_history                = var.argo_events.max_history
  name                       = try(coalesce(var.argo_events.name, var.argo_events.chart), "")
  namespace                  = var.argo_events.namespace
  pass_credentials           = var.argo_events.pass_credentials
  postrender                 = var.argo_events.postrender
  recreate_pods              = var.argo_events.recreate_pods
  render_subchart_notes      = var.argo_events.render_subchart_notes
  replace                    = var.argo_events.replace
  repository                 = var.argo_events.repository
  repository_ca_file         = var.argo_events.repository_ca_file
  repository_cert_file       = var.argo_events.repository_cert_file
  repository_key_file        = var.argo_events.repository_key_file
  repository_password        = var.argo_events.repository_password
  repository_username        = var.argo_events.repository_username
  reset_values               = var.argo_events.reset_values
  reuse_values               = var.argo_events.reuse_values
  set                        = var.argo_events.set
  set_list                   = var.argo_events.set_list
  set_sensitive              = var.argo_events.set_sensitive
  set_wo                     = var.argo_events.set_wo
  set_wo_revision            = var.argo_events.set_wo_revision
  skip_crds                  = var.argo_events.skip_crds
  take_ownership             = var.argo_events.take_ownership
  timeout                    = var.argo_events.timeout
  timeouts                   = var.argo_events.release_timeouts
  upgrade_install            = var.argo_events.upgrade_install
  values                     = var.argo_events.values
  verify                     = var.argo_events.verify
  version                    = var.argo_events.chart_version
  wait                       = var.argo_events.wait
  wait_for_jobs              = var.argo_events.wait_for_jobs
}
