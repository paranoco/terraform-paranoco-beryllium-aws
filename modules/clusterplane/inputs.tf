variable "name" {
  type = string
}

variable "securecluster" {
  type = map(any)
}

variable "securecluster_lists" {
  type = map(any)
}