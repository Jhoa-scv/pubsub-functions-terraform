

locals {
  excluded_permissions = (var.excluded_permissions)
  included_permissions = concat(flatten(values(data.google_iam_role.role_permissions)[*].included_permissions), var.permissions)
  permissions          = [for permission in local.included_permissions : permission if !contains(local.excluded_permissions, permission)]
  custom-role-output   = google_project_iam_custom_role.project-custom-role[0].role_id
}

/******************************************
  Permissions from predefined roles
 *****************************************/
data "google_iam_role" "role_permissions" {
  for_each = toset(var.base_roles)
  name     = each.value
}


/******************************************
  Custom IAM Project Role
 *****************************************/
resource "google_project_iam_custom_role" "project-custom-role" {
  count = var.target_level == "project" ? 1 : 0

  project     = var.target_id
  role_id     = var.role_id
  title       = var.title == "" ? var.role_id : var.title
  description = var.description
  permissions = local.permissions
  stage       = var.stage
}

/******************************************
  Assigning custom_role to member
 *****************************************/
resource "google_project_iam_member" "custom_role_member" {

  for_each = var.target_level == "project" ? toset(var.members) : []
  project  = var.target_id
  role     = "projects/${var.target_id}/roles/${local.custom-role-output}"
  member   = each.key
}