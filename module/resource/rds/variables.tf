
variable "environment" {
  type        = string
  description = "environment of rds"
  default     = "development"
}

variable "project_name" {
  type        = string
  description = "prefix of resource names"
}

variable "database_subnet_ids" {
  type        = list(string)
  description = "ids of database subnets (different AZs)"
}

variable "database_sg_id" {
  type        = string
  description = "id of database security group"
}

variable "availability_zone" {
  type        = string
  description = "AZ of the db instance (same AZ as the private server to avoid cross-AZ traffic)"
  default     = "ap-northeast-2a"
}

variable "instance_class" {
  type        = string
  description = "instance class of the db instance"
  default     = "db.t3.micro"
}

variable "db_name" {
  type        = string
  description = "name of the initial database"
  default     = "appdb"
}

variable "db_username" {
  type        = string
  description = "master username (note: 'admin' is reserved on PostgreSQL)"
  default     = "appuser"
}
