variable "name" {
  description = "PSQL Cluster name"
  type = string
}

variable "engine_mode" {
    description = "PSQL engine mode"
    type = string
    default = "provisioned"
}

variable "storage_encrypted" {
  description = "Data storage will be encrypted"
  type = bool
  default = true
}

variable "master_username" {
  description = "PSQL user name"
  type = string
}

variable "security_group_name" {
  description = "PSQL security group name"
  type = string
}

variable "database_name" {
  description = "database_name"
  type = string
}

variable "domain_iam_role_name" {
  description = "domain_iam_role_name"
  type = string
}

variable "vpc_id" {
  description = "default vpc id"
  type = string
}

variable "db_subnet_group_name" {
  description = "default db subent groups"
}

variable "subnets" {
  description = "subnets"
  type = list(string)
}

variable "create_db_subnet_group" {
  description = "create_db_subnet_group"
  type = bool
  default = false  
}

variable "create_security_group" {
  description = "create_security_group"
  type = bool
  default = false
}

variable "tags" {
  description = "A map of tags to add to all the resource"
  type = object({
    Project = string
    Environment = string
    Zone    =   string 
  })
}