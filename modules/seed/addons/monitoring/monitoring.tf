# Copyright (c) 2017 SAP SE or an SAP affiliate company. All rights reserved. This file is licensed under the Apache Software License, v. 2 except as noted otherwise in the LICENSE file
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

################################################################
# special handling for monitoring addon
################################################################

variable "config" {
  type = "map"
}

variable "active" {
  type = "string"
}

variable "tls_dir" {
  type = "string"
}

variable "cluster_name" {
  type = "string"
}

variable "ingress_base_domain" {
  type = "string"
}

variable "dashboard_creds_b64" {
  type = "string"
}

variable "ca" {
  type = "string"
}

variable "ca_key" {
  type = "string"
}

module "monitoring" {
  source = "../../../flag"
  option = "${var.active}"
}

#
# prometheus
#
module "prometheus" {
  source = "../../../tls"

  #  active = "${var.active}"

  file_base    = "${var.tls_dir}/prometheus"
  common_name  = "prometheus"
  organization = "${var.cluster_name}"
  ca           = "${var.ca}"
  ca_key       = "${var.ca_key}"
  ip_addresses = []
  dns_names    = ["prometheus.${var.ingress_base_domain}"]
}

module "prometheus_config" {
  source = "../../../file"
  indent = 4
  path   = "${lookup(var.config,"prometheus_config_file","")}"
}

data "template_file" "prometheus_config" {
  template = "${file("${path.module}/templates/prometheus-config.yaml")}"
  vars     = {}
}

locals {
  prometheus_default_config_indent = "${indent(4,data.template_file.prometheus_config.rendered)}"
}

module "prometheus_rules" {
  source = "../../../file"
  indent = 2
  path   = "${lookup(var.config,"prometheus_rules_file","")}"
}

data "template_file" "prometheus_rules" {
  template = "${file("${path.module}/templates/prometheus-rules.yaml")}"
  vars     = {}
}

locals {
  prometheus_default_rules_indent = "${indent(2,data.template_file.prometheus_rules.rendered)}"
}

#
# grafana
#
module "grafana" {
  source = "../../../tls"
  active = "${var.active}"

  file_base    = "${var.tls_dir}/grafana"
  common_name  = "grafana"
  organization = "${var.cluster_name}"
  ca           = "${var.ca}"
  ca_key       = "${var.ca_key}"
  ip_addresses = []
  dns_names    = ["grafana.${var.ingress_base_domain}"]
}

module "grafana_config" {
  source = "../../../file"
  indent = 2
  path   = "${lookup(var.config,"grafana_config_file","")}"
}

data "template_file" "grafana_config" {
  template = "${file("${path.module}/templates/grafana-config.yaml")}"
  vars     = {}
}

locals {
  grafana_default_config_indent = "${indent(2,data.template_file.grafana_config.rendered)}"
  grafana_custom_config_indent  = "${module.grafana_config.indented}"
}

#
# alertmanager
#
module "alertmanager" {
  source = "../../../tls"
  active = "${var.active}"

  file_base    = "${var.tls_dir}/alertmanager"
  common_name  = "alertmanager"
  organization = "${var.cluster_name}"
  ca           = "${var.ca}"
  ca_key       = "${var.ca_key}"
  ip_addresses = []
  dns_names    = ["alertmanager.${var.ingress_base_domain}"]
}

module "alertmanager_custom_config" {
  source = "../../../file"
  path   = "${lookup(var.config,"alertmanager_config_file","")}"
}

data "template_file" "alertmanager_default_config" {
  template = "${file("${path.module}/templates/alertmanager-default-config.yaml")}"
  vars     = {}
}

locals {
  alertmanager_base_config = "${module.alertmanager_custom_config.content==""?data.template_file.alertmanager_default_config.rendered:module.alertmanager_custom_config.content}"
}

data "template_file" "alertmanager_base_config_template" {
  template = "${file("${path.module}/templates/alertmanager-base-config.yaml")}"

  vars = {
    alertmanager_smtp_host     = "${lookup(var.config,"smtp_host","smtp.example.com:587")}"
    alertmanager_smtp_from     = "${lookup(var.config,"smtp_from","john.doe@example.com")}"
    alertmanager_smtp_username = "${lookup(var.config,"smtp_username","admin")}"
    alertmanager_smtp_password = "${lookup(var.config,"smtp_password","admin")}"
    alertmanager_config        = "${local.alertmanager_base_config}"
  }
}

locals {
  alertmanager_config_b64 = "${base64encode(data.template_file.alertmanager_base_config_template.rendered)}"

  dummy = {
    prometheus_default_config = ""
    prometheus_custom_config  = ""
    prometheus_default_rules  = ""
    prometheus_custom_rules   = ""
    prometheus_crt_b64        = ""
    prometheus_key_b64        = ""
    prometheus_volume_size    = ""

    grafana_default_config = ""
    grafana_custom_config  = ""
    grafana_crt_b64        = ""
    grafana_key_b64        = ""

    alertmanager_crt_b64     = ""
    alertmanager_key_b64     = ""
    alertmanager_config_b64  = ""
    alertmanager_volume_size = ""
  }

  default_values = {
    basic_auth_b64 = "${var.dashboard_creds_b64}"

    prometheus_default_config = "${local.prometheus_default_config_indent}"
    prometheus_default_rules  = "${local.prometheus_default_rules_indent}"
    prometheus_crt_b64        = "${module.prometheus.cert_pem_b64}"
    prometheus_key_b64        = "${module.prometheus.private_key_pem_b64}"
    prometheus_volume_size    = "20Gi"

    grafana_default_config = "${local.grafana_default_config_indent}"
    grafana_crt_b64        = "${module.grafana.cert_pem_b64}"
    grafana_key_b64        = "${module.grafana.private_key_pem_b64}"

    alertmanager_crt_b64 = "${module.alertmanager.cert_pem_b64}"
    alertmanager_key_b64 = "${module.alertmanager.private_key_pem_b64}"

    alertmanager_config_b64  = "${local.alertmanager_config_b64}"
    alertmanager_volume_size = "10Gi"
  }

  generated = {
    grafana_default_config    = "${local.grafana_default_config_indent}"
    grafana_custom_config     = "${module.grafana_config.indented}"
    prometheus_default_config = "${local.prometheus_default_config_indent}"
    prometheus_custom_config  = "${module.prometheus_config.indented}"
    prometheus_default_rules  = "${local.prometheus_default_rules_indent}"
    prometheus_custom_rules   = "${module.prometheus_rules.indented}"

    alertmanager_config_b64 = "${local.alertmanager_config_b64}"
  }
}

#
# debug info
#
output "grafana_default_config" {
  value = "${local.grafana_default_config_indent}"
}

output "prometheus_default_config" {
  value = "${local.prometheus_default_config_indent}"
}

output "prometheus_default_rules" {
  value = "${local.prometheus_default_rules_indent}"
}

output "alertmanager_config_b64" {
  value = "${local.alertmanager_config_b64}"
}

output "active" {
  value = "${var.active}"
}

#
# addon module api
#
output "dummy" {
  value = "${local.dummy}"
}

output "defaults" {
  value = "${local.default_values}"
}

output "generated" {
  value = "${local.generated}"
}

output "manifests" {
  value = "${path.module}/templates/manifests"
}

output "deploy" {
  value = ""
}
