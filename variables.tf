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
  default = []

}