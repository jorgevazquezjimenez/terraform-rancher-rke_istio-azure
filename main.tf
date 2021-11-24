# Configure Rancher provider
terraform {
  required_providers {
    rancher2 = {
      source = "rancher/rancher2"
    }
  }
}

provider "rancher2" {
  api_url = "https://sanes-rancher.westeurope.cloudapp.azure.com"
  access_key = var.access_key
  secret_key = var.secret_key
  insecure = true
}

data "rancher2_node_template" "controlplane_template" {
  name = var.control_node_template
}

data "rancher2_node_template" "workers_template" {
  name = var.workers_node_template
}

resource "rancher2_cluster" "rke" {
  name = var.name
  description = var.description

  rke_config {
    network {
      plugin = var.kubernetes_network_plugin
    }
  }

  enable_cluster_monitoring = true
  cluster_monitoring_input {
    answers = {
      "exporter-kubelets.https" = true
      "exporter-node.enabled" = true
      "exporter-node.ports.metrics.port" = 9796
      "exporter-node.resources.limits.cpu" = "200m"
      "exporter-node.resources.limits.memory" = "200Mi"
      "grafana.persistence.enabled" = false
      "grafana.persistence.size" = "10Gi"
      "grafana.persistence.storageClass" = "default"
      "operator.resources.limits.memory" = "500Mi"
      "prometheus.persistence.enabled" = "false"
      "prometheus.persistence.size" = "50Gi"
      "prometheus.persistence.storageClass" = "default"
      "prometheus.persistent.useReleaseName" = "true"
      "prometheus.resources.core.limits.cpu" = "1000m",
      "prometheus.resources.core.limits.memory" = "1500Mi"
      "prometheus.resources.core.requests.cpu" = "750m"
      "prometheus.resources.core.requests.memory" = "750Mi"
      "prometheus.retention" = "12h"
    }
  }
}

resource "rancher2_node_pool" "etcd_pool" {
  cluster_id = rancher2_cluster.rke.id
  name = format("%s-%s",var.node_pool_name,"etcd")
  hostname_prefix = var.hostname_prefix
  node_template_id = data.rancher2_node_template.controlplane_template.id

  quantity = var.etcd_node_count
  control_plane = false
  etcd = true
  worker = false
}

resource "rancher2_node_pool" "controlplane_pool" {
  cluster_id = rancher2_cluster.rke.id
  name = format("%s-%s",var.node_pool_name,"controlplane")
  hostname_prefix = var.hostname_prefix
  node_template_id = data.rancher2_node_template.controlplane_template.id

  quantity = var.controlplane_node_count
  control_plane = true
  etcd = false
  worker = false
}

resource "rancher2_node_pool" "workers_pool" {
  cluster_id = rancher2_cluster.rke.id
  name = format("%s-%s",var.node_pool_name,"workers")
  hostname_prefix = var.hostname_prefix
  node_template_id = data.rancher2_node_template.workers_template.id

  quantity = var.workers_node_count
  control_plane = false
  etcd = false
  worker = true
}

resource "rancher2_cluster_sync" "rke_sync" {
  cluster_id =  rancher2_cluster.rke.id
  wait_monitoring = rancher2_cluster.rke.enable_cluster_monitoring
}

resource "rancher2_namespace" "istio_namespace" {
  name = "istio-system"
  project_id = rancher2_cluster_sync.rke_sync.system_project_id
  description = "Istio namespace"
}

resource "rancher2_app" "istio" {
  catalog_name     = "system-library"
  name             = "cluster-istio"
  project_id       = rancher2_namespace.istio_namespace.project_id
  description = "Terraform app acceptance test"
  target_namespace = rancher2_namespace.istio_namespace.id
  template_name = "rancher-istio"
  template_version = "0.1.1"
  answers = {
    "certmanager.enabled" = false
    "enableCRDs" = true
    "galley.enabled" = true
    "gateways.enabled" = false
    "gateways.istio-ingressgateway.resources.limits.cpu" = "2000m"
    "gateways.istio-ingressgateway.resources.limits.memory" = "1024Mi"
    "gateways.istio-ingressgateway.resources.requests.cpu" = "100m"
    "gateways.istio-ingressgateway.resources.requests.memory" = "128Mi"
    "gateways.istio-ingressgateway.type" = "NodePort"
    "global.monitoring.type" = "cluster-monitoring"
    "global.rancher.clusterId" = rancher2_cluster_sync.rke_sync.cluster_id
    "istio_cni.enabled" = "false"
    "istiocoredns.enabled" = "false"
    "kiali.enabled" = "true"
    "mixer.enabled" = "true"
    "mixer.policy.enabled" = "true"
    "mixer.policy.resources.limits.cpu" = "4800m"
    "mixer.policy.resources.limits.memory" = "4096Mi"
    "mixer.policy.resources.requests.cpu" = "1000m"
    "mixer.policy.resources.requests.memory" = "1024Mi"
    "mixer.telemetry.resources.limits.cpu" = "4800m",
    "mixer.telemetry.resources.limits.memory" = "4096Mi"
    "mixer.telemetry.resources.requests.cpu" = "1000m"
    "mixer.telemetry.resources.requests.memory" = "1024Mi"
    "mtls.enabled" = false
    "nodeagent.enabled" = false
    "pilot.enabled" = true
    "pilot.resources.limits.cpu" = "1000m"
    "pilot.resources.limits.memory" = "4096Mi"
    "pilot.resources.requests.cpu" = "500m"
    "pilot.resources.requests.memory" = "2048Mi"
    "pilot.traceSampling" = "1"
    "security.enabled" = true
    "sidecarInjectorWebhook.enabled" = true
    "tracing.enabled" = true
    "tracing.jaeger.resources.limits.cpu" = "500m"
    "tracing.jaeger.resources.limits.memory" = "1024Mi"
    "tracing.jaeger.resources.requests.cpu" = "100m"
    "tracing.jaeger.resources.requests.memory" = "100Mi"
  }
}