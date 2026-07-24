variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "account_id" {
  description = "AWS account ID that owns this infra"
  type        = string
  default     = "743334887511"
}

variable "domain_name" {
  description = "Public hostname the app is served on"
  type        = string
  default     = "myapp.imauty.com"
}

variable "route53_zone_name" {
  description = "Route53 public hosted zone that owns domain_name (managed outside this stack)"
  type        = string
  default     = "imauty.com"
}

variable "key_pair_name" {
  description = "EC2 key pair used for SSH access"
  type        = string
  default     = "myapp-key"
}

variable "admin_ssh_cidr" {
  description = "CIDR allowed to SSH into the EC2 instance (your IP, e.g. 203.0.113.10/32). No default on purpose: set via terraform.tfvars (gitignored) or -var."
  type        = string
}
