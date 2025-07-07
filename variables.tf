variable "public_subnets" {
  type    = list(any)
  default = []

}
variable "private_subnets" {
  type    = list(any)
  default = []

}
variable "database_subnets" {
  type    = list(any)
  default = []

}
variable "availability_zones" {
  type    = list(any)
  default = ["us-east-1a", "us-east-1b"]

}
