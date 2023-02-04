locals {

  /*
   * Env
   */
  env_stage = get_env("STAGE", "undefined")
  env_qualifier = get_env("QUALIFIER", "undefined")


  /*
   * Organization
   */
  organization_name = "go9tech"

  organization_ids = {
    go9tech = "org-brLEaBdqTZYHrcNQ"
    go9ai   = "org-yVj67m1T8nShsocV"
  }

  organization_id = lookup(local.organization_ids, local.organization_name)


  /*
   * Service
   */
  artifact_id = "scw-base-stack"
  //module = "@project.artifactId@"
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
   * Project
   */
  project_names = {
    fet = "staging"
    bug = "staging"
    dev = "staging"
    uat = "staging"
    fix = "staging"
    prd = "production"
  }

  project_name = lookup(local.project_names, local.branch_type)

  project_ids = {
    staging = "e9ceeb53-3398-4dd4-9b52-49b086b7d5a1"
    production = "5cdce170-7767-4a51-ac1d-c41b1320ac48"
  }

  project_id = lookup(local.project_ids, local.project_name)


  /*
   * Region
   */
  regions = {
    fet = ["fr-par"]
    bug = ["fr-par"]
    dev = ["fr-par"]
    uat = ["fr-par"]
    fix = ["fr-par"]
    prd = ["fr-par"]
  }

  region = lookup(local.regions, local.branch_type)[0]


  /*
   * Zone
   */
  zones = {
    fet = {
      fr-par = ["fr-par-1"]
    }
    bug = {
      fr-par = ["fr-par-1"]
    }
    dev = {
      fr-par = ["fr-par-1"]
    }
    uat = {
      fr-par = ["fr-par-1"]
    }
    fix = {
      fr-par = ["fr-par-1"]
    }
    prd = {
      fr-par = ["fr-par-1", "fr-par-2", "fr-par-3"]
    }
  }

  zone = lookup(lookup(local.zones, local.branch_type), local.region)[0]


  /*
   * Stage
   */
  stages = {
    fet = "fet"
    bug = "bug"
    dev = "dev"
    uat = "uat"
    fix = "fix"
    prd = "prd"
  }

  stage = lookup(local.stages, local.branch_type)


  /*
   * Qualifier
   */
  git_qualifier = local.branch_parts[1] != null && length(trimspace(local.branch_parts[1])) > 0 ? trimspace(local.branch_parts[1]) : "default"
  qualifier = local.env_qualifier == "undefined" ? local.git_qualifier : local.env_qualifier


  /*
   * Workspace
   */
  workspace = "${local.service_name}-${local.qualifier}-${local.stage}"

}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
terraform {
  backend "remote" {
    organization = "${local.organization_name}"
    workspaces {
      name = "${local.workspace}"
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
  organization_id = "${local.organization_id}"
  project_id      = "${local.project_id}"
  region          = "${local.region}"
  zone            = "${local.zone}"
}
EOF
}

inputs = {
  regions = local.regions
  region  = local.region
  zones   = local.zones
  zone    = local.zone
  stage = local.stage
  qualifier = local.qualifier
  build = get_env("BITBUCKET_BUILD_NUMBER", "undefined")
}
