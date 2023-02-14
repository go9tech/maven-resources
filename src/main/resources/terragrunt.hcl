locals {

  /*
   * Env
   */
  env_stage        = get_env("STAGE", "undefined")
  env_qualifier    = get_env("QUALIFIER", "undefined")
  env_build_number = get_env("BITBUCKET_BUILD_NUMBER", "undefined")


  /*
   * Service
   */
  artifact_id = "@project.artifactId@"
  service_name_parts = regex("(.*)(-base-|-custom-)(.*)|(.*)$", local.artifact_id)
  service_name = local.service_name_parts[0] != null && local.service_name_parts[2] != null ? "${local.service_name_parts[0]}-${local.service_name_parts[2]}" : local.artifact_id


  /*
   * Branch
   */
  branches = {
    fet = "feature"
    bug = "bugfix"
    dev = "develop"
    uat = "release"
    fix = "hotfix"
    prd = "master"
  }

  branch_tmp = local.env_stage == "undefined" ? run_cmd("git", "rev-parse", "--abbrev-ref", "HEAD") : lookup(local.branches, local.env_stage, local.branches["dev"])
  branch = local.branch_tmp == "HEAD\n" ? "master" : local.branch_tmp
  branch_parts = regex("(feature|bugfix|develop|release|hotfix|master)/*(.*)", local.branch)
  branch_prefix = local.branch_parts[0] != null && length(trimspace(local.branch_parts[0])) > 0 ? trimspace(local.branch_parts[0]) : "develop"

  branch_types = {
    feature = "fet"
    bugfix  = "bug"
    develop = "dev"
    release = "uat"
    hotfix  = "fix"
    master  = "prd"
  }

  branch_type = lookup(local.branch_types, local.branch_prefix)


  /*
   * Stage
   */
  stage = local.env_stage == "undefined" ? local.branch_type : local.env_stage


  /*
   * Qualifier
   */
  git_qualifier = local.branch_parts[1] != null && length(trimspace(local.branch_parts[1])) > 0 ? trimspace(local.branch_parts[1]) : "default"
  qualifier = local.env_qualifier == "undefined" ? local.git_qualifier : local.env_qualifier


  /*
   * Terraform Cloud
   */
  tfe_organization_name = "go9tech"
  tfe_workspace_name = "${local.service_name}-${local.stage}-${local.qualifier}"


  /*
   * Scaleway
   */
  scw_organization_name = "go9"
  scw_organization_id = "2af5e7de-6cab-4457-9050-80c329e66e92"

  scw_project_names = {
    fet = "staging"
    bug = "staging"
    dev = "staging"
    uat = "staging"
    fix = "staging"
    prd = "production"
  }
  scw_project_name = lookup(local.scw_project_names, local.branch_type)

  scw_project_ids = {
    staging = "e9ceeb53-3398-4dd4-9b52-49b086b7d5a1"
    production = "5cdce170-7767-4a51-ac1d-c41b1320ac48"
  }
  scw_project_id = lookup(local.scw_project_ids, local.scw_project_name)

  scw_regions = {
    fet = "fr-par"
    bug = "fr-par"
    dev = "fr-par"
    uat = "fr-par"
    fix = "fr-par"
    prd = "fr-par"
  }
  scw_region = lookup(local.scw_regions, local.branch_type)

  scw_zones = {
    fet = ["fr-par-1"]
    bug = ["fr-par-1"]
    dev = ["fr-par-1"]
    uat = ["fr-par-1"]
    fix = ["fr-par-1"]
    prd = ["fr-par-1"]
  }
  scw_zone = lookup(local.scw_zones, local.branch_type)[0]

}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
terraform {
  backend "remote" {
    organization = "${local.tfe_organization_name}"
    workspaces {
      name = "${local.tfe_workspace_name}"
    }
  }
}
EOF
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "scaleway" {
  organization_id = "${local.scw_organization_id}"
  project_id      = "${local.scw_project_id}"
  region          = "${local.scw_region}"
  zone            = "${local.scw_zone}"
}
EOF
}

inputs = {
  tfe_organization_name = local.tfe_organization_name
  scw_region            = local.scw_region
  scw_zones             = local.scw_zones
  scw_zone              = local.scw_zone
  stage                 = local.stage
  qualifier             = local.qualifier
  build                 = local.env_build_number
}
