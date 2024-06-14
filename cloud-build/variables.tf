variable "project" {
  description = "The ID of the project in which the resource belongs to."
  type        = string
}

variable "name" {
  description = "Name of Cloud Build Trigger"
  type        = string
}

variable "description" {
  description = "Description of the trigger."
  type        = string
  default     = ""
}

variable "location" {
  description = "Cloud Build location for the trigger. If not set, global is used"
  type        = string
  default     = "global"
}

# Use https://gitlab.com/optoro/infrastructure/terraform/gcp/-/tree/main/modules/service-accounts to create custom service account with required roles/permission needed
variable "service_account" {
  description = "The service account used for all user-controlled operations. If no service account is set, then the standard Cloud Build service account ([PROJECT_NUM]@system.gserviceaccount.com) will be used instead."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags for annotation of a Build"
  type        = set(string)
  default     = []
}

variable "substitutions" {
  description = "Substitutions data for Build resource."
  type        = map(string)
  default     = {}
}

variable "ignored_files" {
  description = "If ignoredFiles and changed files are both empty, then they are not used to determine whether or not to trigger a build. If ignoredFiles is not empty, then we ignore any files that match any of the ignored_file globs"
  type        = list(string)
  default     = []
}

variable "included_files" {
  description = "If any of the files altered in the commit pass the ignoredFiles filter and includedFiles is empty, then as far as this filter is concerned, we should trigger the build. If any of the files altered in the commit pass the ignoredFiles filter and includedFiles is not empty, then we make sure that at least one of those files matches a includedFiles globs"
  type        = list(string)
  default     = []
}

variable "file_name" {
  description = "Path, from the source root, to a file whose contents is used for the template. Either a filename or build template must be provided. Set this only when using trigger_template or github. When using Pub/Sub, Webhook or Manual set the file name using git_file_source instead."
  type        = string
  default     = null
}

# reference https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloudbuild_trigger
variable "trigger_config" {
  description = "Parameters to setup config trigger"
  type = object({
    source_to_build = object({
      uri       = string
      ref       = string
      repo_type = string
    })
    git_file_source = object({
      path      = string
      repo_type = string
      revision  = string
      uri       = string
    })
    github = object({
      owner           = string
      name            = string
      branch_regex    = string
      tag_regex       = string
    })
    pubsub = object({
      topic                 = string
      service_account_email = string
    })
    webhook = object({
      secret = string
    })
  })
}

variable "approval_required" {
  description = "Whether or not approval is needed for trigger to run"
  type        = bool
  default     = true
}

variable "invert_regex" {
  description = "Only trigger a build if the revision regex does NOT match the revision regex."
  type        = bool
  default     = false
}



