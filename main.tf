module "receiving-pubsub" {
  source     = "terraform-google-modules/pubsub/google"
  version    = "~> 6.0"
  topic      = "unit-received"
  project_id = "optoro-playground-rm"
  topic_labels = {
    team       = "receiving"
    app        = "receiving"
    project    = "optoro-playground-rm"
    managed_by = "terraform"
  }

  pull_subscriptions = [
    {
      name = "receiving-unit-received-sub",
      minimum_backoff = "20s",
      maximum_backoff = "600s",
      enable_message_ordering = true
    }
  ]

  subscription_labels = {
    team       = "receiving"
    app        = "receiving"
    project    = "optoro-playground-rm"
    managed_by = "terraform"
  }
}

# service account for cloud function (needed for scc notifications)
module "units-service-handler-sa" {
  source        = "./service-accounts"
  project_id    = "optoro-playground-rm"
  names         = ["units-handler-playground"]
  display_name  = "units-handler-playground"
  description   = "Service account used for all Cloud Functions on playground"
  project_roles = [
    "roles/artifactregistry.reader",
    "roles/cloudfunctions.developer",
    "roles/run.invoker",
    "roles/cloudsql.client",
    "roles/logging.logWriter",
    "roles/pubsub.publisher",
    "roles/pubsub.subscriber",
    "roles/secretmanager.secretAccessor",
    "roles/vpcaccess.user"
  ]
}

module "units-service-handler-role" {
  source       = "./iam/custom-role"
  target_level = "project"
  target_id    = "optoro-playground-rm"
  role_id      = "units_service_handler_playground_custom_role"
  title        = "units_service_handler_playground_custom_role"
  description  = "Custom role for Units Service Handler SA"
  permissions = [
    "iam.serviceAccounts.actAs",
    "iam.serviceAccounts.get",
    "iam.serviceAccounts.getAccessToken",
    "iam.serviceAccounts.getOpenIdToken",
    "cloudfunctions.functions.create",
    "cloudfunctions.functions.delete",
    "cloudfunctions.functions.update",
    "cloudfunctions.functions.get",
    "cloudfunctions.functions.sourceCodeGet",
    "cloudfunctions.functions.sourceCodeSet",
    "cloudfunctions.operations.get",
    "cloudfunctions.operations.list",
    "logging.logEntries.create",
    "run.routes.get",
    "run.routes.list",
    "run.routes.invoke",
  ]
  members = [
    "serviceAccount:units-handler-playground@optoro-playground-rm.iam.gserviceaccount.com",
  ]
  # SA need to exist before you can add custom role to it
  depends_on = [
    module.units-service-handler-sa
  ]
}


# Units service handler SA for Receiving team
module "units-functions-sa" {
  source        = "./service-accounts"
  project_id    = "optoro-playground-rm"
  prefix        = "playground"
  names         = ["units-functions-playground"]
  display_name  = "units-functions-playground"
  description   = "Service account used by Receiving team for Units service Cloud Functions"
  project_roles = ["roles/cloudbuild.builds.builder", "roles/run.invoker"]
}

# Cloud Build trigger for Units service
module "cloud-build-unit-creation-fucntion" {
  source          = "./cloud-build"
  project         = "optoro-playground-rm"
  name            = "unit-creation-release-trigger"
  description     = "Deploys Unit Creation cloud function"
  service_account = "211859958078-compute@developer.gserviceaccount.com"

  # required approval before trigger can run
  approval_required = false

  trigger_config = {
    # setting trigger for GitHub events
    github = {
      owner = "optoro"
      name  = "units_service_handler"
      filename = "cloudbuild.unit_creation.yaml"
      # only branch_regex or tag_regex can be set, do not set both
      # if use branch_regex for push event then set tag_reg = null
      # if use tag_regex for push event then set branch_regex = null
      branch_regex = null
      tag_regex    = "^playground-*"
    }
    # these are set if you want webhook, pub-sub, or manual event triggers
    source_to_build = null
    git_file_source = {
      path      = "cloudbuild.unit_creation.yaml"
      repo_type = "GITHUB"
      revision  = "refs/tags/^playground"
      uri       = "https://github.com/optoro/units_service_handler"
    }
    gsr             = null
    pubsub          = null
    webhook         = null
  }

  substitutions = {
    _SERVICE_ACCOUNT =  "units-functions-playground@optoro-playground-rm.iam.gserviceaccount.com"
    _PROJECT_ID            = "optoro-playground-rm"
    _UNITS_SERVER_BASE_URL = "https://units-7bb7gvp42a-uc.a.run.app"
  }

  depends_on = [
    module.units-functions-sa
  ]
}

# Cloud Build trigger for Units service
module "cloud-build-units" {
  source          = "./cloud-build"
  project         = "optoro-playground-rm"
  name            = "units-deployment"
  description     = "Deploys units service to cloud run"
  file_name       = "cloudbuild.deploy.yaml"
  # required approval before trigger can run
  approval_required = false
  trigger_config = {
    # setting trigger for GitHub events
    github = {
      owner = "optoro"
      name  = "units"
      # only branch_regex or tag_regex can be set, do not set both
      # if use branch_regex for push event then set tag_reg = null
      # if use tag_regex for push event then set branch_regex = null
      branch_regex = "^SC-2484"
      tag_regex    = null
    }
    # these are set if you want webhook, pub-sub, or manual event triggers
    source_to_build = null
    git_file_source = null
    gsr             = null
    pubsub          = null
    webhook         = null
  }
  substitutions = {
    # TODO: add the real database host; we need a dedicated Cloud SQL instance for this
    # service but we don't want to pay for it until we need it.
    _POSTGRES_HOST = "10.2.208.52"
    _VPC_PROJECT = "optoro-testing-host"
    _SERVICE_ACCOUNT = "cloud-run@optoro-playground-rm.iam.gserviceaccount.com"
  }
}