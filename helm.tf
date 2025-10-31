################################################################################
# (Generic) Helm Release
################################################################################

resource "helm_release" "this" {
  for_each = var.helm_releases

  atomic                     = each.value.atomic
  chart                      = each.value.chart
  cleanup_on_fail            = each.value.cleanup_on_fail
  create_namespace           = each.value.create_namespace
  dependency_update          = each.value.dependency_update
  description                = each.value.description
  devel                      = each.value.devel
  disable_crd_hooks          = each.value.disable_crd_hooks
  disable_openapi_validation = each.value.disable_openapi_validation
  disable_webhooks           = each.value.disable_webhooks
  force_update               = each.value.force_update
  keyring                    = each.value.keyring
  lint                       = each.value.lint
  max_history                = each.value.max_history
  name                       = try(coalesce(each.value.name, each.key), "")
  namespace                  = each.value.namespace
  pass_credentials           = each.value.pass_credentials
  postrender                 = each.value.postrender
  recreate_pods              = each.value.recreate_pods
  render_subchart_notes      = each.value.render_subchart_notes
  replace                    = each.value.replace
  repository                 = each.value.repository
  repository_ca_file         = each.value.repository_ca_file
  repository_cert_file       = each.value.repository_cert_file
  repository_key_file        = each.value.repository_key_file
  repository_password        = each.value.repository_password
  repository_username        = each.value.repository_username
  reset_values               = each.value.reset_values
  reuse_values               = each.value.reuse_values
  set                        = each.value.set
  set_list                   = each.value.set_list
  set_sensitive              = each.value.set_sensitive
  set_wo                     = each.value.set_wo
  set_wo_revision            = each.value.set_wo_revision
  skip_crds                  = each.value.skip_crds
  take_ownership             = each.value.take_ownership
  timeout                    = each.value.timeout
  timeouts                   = each.value.release_timeouts
  upgrade_install            = each.value.upgrade_install
  values                     = each.value.values
  verify                     = each.value.verify
  version                    = each.value.chart_version # conflicts with reserved keyword
  wait                       = each.value.wait
  wait_for_jobs              = each.value.wait_for_jobs
}
