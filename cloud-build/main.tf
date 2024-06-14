# importing info from custom SA. 
data "google_service_account" "sa" {
  count      = coalesce(var.service_account, "unspecified") != "unspecified" ? 1 : 0
  account_id = var.service_account
}

# Create a Cloud Build trigger
resource "google_cloudbuild_trigger" "trigger" {
  project         = var.project
  name            = var.name
  location        = var.location
  description     = var.description
  service_account = length(data.google_service_account.sa) == 1 ? data.google_service_account.sa[0].name : ""
  tags            = var.tags
  substitutions   = var.substitutions
  ignored_files   = var.ignored_files
  included_files  = var.included_files
  # set when using github trigger
  filename = var.file_name

  # set when creating trigger for pub/sub, webhook, or manual
  dynamic "source_to_build" {
    for_each = { for k, v in var.trigger_config : k => v if k == "source_to_build" && v != null }
    content {
      uri       = source_to_build.value.uri
      ref       = source_to_build.value.ref
      repo_type = source_to_build.value.repo_type
    }
  }

  # set when creating trigger for pub/sub, webhook, or manual
  dynamic "git_file_source" {
    for_each = { for k, v in var.trigger_config : k => v if k == "git_file_source" && v != null }
    content {
      path      = git_file_source.value.path
      uri       = git_file_source.value.uri
      revision  = git_file_source.value.revision
      repo_type = git_file_source.value.repo_type
    }
  }

  # Pub/Sub trigger
  dynamic "pubsub_config" {
    for_each = { for k, v in var.trigger_config : k => v if k == "pubsub" && v != null }
    content {
      topic                 = pubsub_config.value.topic
      service_account_email = pubsub_config.value.service_account_email
    }
  }

  # Webhook trigger
  dynamic "webhook_config" {
    for_each = { for k, v in var.trigger_config : k => v if k == "webhook" && v != null }
    content {
      secret = webhook_config.value.secret
    }
  }

  # Create trigger whenever GitHub event is received
  dynamic "github" {
    for_each = { for k, v in var.trigger_config : k => v if k == "github" && v != null }
    content {
      owner = github.value.owner
      name  = github.value.name

      # only one of branch or tag can be set. 
      # if trigger by branch then set tag = null
      # if trigger by tag then set branch = null
      dynamic "push" {
        for_each = { for k, v in var.trigger_config : k => v if k == "github" && v != null }
        content {
          branch       = push.value.branch_regex
          tag          = push.value.tag_regex
          invert_regex = var.invert_regex
        }
      }
    }
  }

  # default is true - you always need approval to run trigger
  approval_config {
    approval_required = var.approval_required
  }

}