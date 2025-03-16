locals {
  # To attach a specific role in the specific environment
  env_roles = {
    dev = { dev_users = "ro", devops_users = "rw", admin_users = "admin" }
    stg = { dev_users = "ro", devops_users = "rw", admin_users = "admin" }
    prd = { dev_users = "ro", devops_users = "ro", admin_users = "admin" }
  }

  # List of application user identities
  app_users = {
    dev_users = [
      "dev_user_a",
      "dev_user_b",
      "dev_user_c",
      "dev_user_d"
    ]
    devops_users = [
      "devops_user_a",
      "devops_user_b"
    ]
    admin_users = [
      "admin_user_a",
      "admin_user_b"
    ]
  }
  # Flatten users across all teams, creating a map of username => role
  db_users = merge([
    for team, users in local.app_users : {
      for user in users : user => {
        role = local.env_roles[var.env_name][team]
      }
    }
  ]...)
}

# output "db_users" {
#   value = local.db_users
# }