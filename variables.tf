variable "api_url" {
  type = string
  description = "(Required) Rancher API URL"
}

variable "access_key" {
  type = string
  description = "(Required) Rancher Access Key"
}

variable "secret_key" {
  type = string
  description = "(Required) Rancher Secret Key"
}

# RKE config
variable "name" {
  type = string
  description = "(Required) Rancher RKE cluster name"
}

variable "description" {
  type = string
  description = "(Required) RKE cluster description"
}

variable "control_node_template" {
  type = string
  description = "(Required) RKE control nodes template name."
}

variable "workers_node_template" {
  type = string
  description = "(Required) RKE worker nodes template name."
}

variable "node_pool_name" {
  type = string
  description = "(Required) RKE node pool name."
  default = "agentpool"
}

variable "kubernetes_network_plugin" {
  type = string
  description = "(Optional) Kubernetes network plugin. Default value is calico"
  default = "calico"
}

variable "etcd_node_count" {
  type = number
  description = "(Required) Number of etcd nodes in the cluster"
  default = 3
}

variable "controlplane_node_count" {
  type = number
  description = "(Required) Number of control plane nodes in the cluster"
  default = 1
}

variable "workers_node_count" {
  type = number
  description = "(Required) Number of worker nodes in the cluster"
  default = 3
}

variable "hostname_prefix" {
  type = string
  description = "(Optional) Hostname prefix for nodes. Default value is rancher"
  default = "rancher"
}