
variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  default = "mukta-uat" #REPLACE
}

variable "cluster_oidc_url" {
  default = "https://oidc.eks.ap-south-1.amazonaws.com/id/8743058B97BBA43BFA13DCD5ECBF899F"
}

variable "kubernetes_version" {
  description = "kubernetes version"
  default = "1.29"
}

variable "instance_type" {
  description = "eGov recommended below instance type as a default"
  default = "r5ad.large"
}

variable "override_instance_types" {
  description = "Arry of instance types for SPOT instances"
  default = ["r5a.large", "r5ad.large", "r5d.large", "m4.xlarge"]

}

variable "number_of_worker_nodes" {
  description = "eGov recommended below worker node counts as default"
  default = "5" #REPLACE IF NEEDED
}

variable "db_version" {
  description = "database version"
  default = "15.7"
}

variable "db_name" {
  description = "RDS DB name. Make sure there are no hyphens or other special characters in the DB name. Else, DB creation will fail"
  default = "mukta_uat_db" #REPLACE
}

variable "db_username" {
  description = "RDS database user name"
  default = "muktauat" #REPLACE
}

#DO NOT fill in here. This will be asked at runtime
variable "db_password" {
  default = "muktauat123"
}

