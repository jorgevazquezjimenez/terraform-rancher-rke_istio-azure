output "cluster_id" {
  value = rancher2_cluster.rke.id
}

output "kube_config" {
  value = rancher2_cluster.rke.kube_config
  sensitive = true
}