##############################################################################
#
# DO NOT MODIFY MANUALLY
#
# general cluster configuration handling
# generated by variants/create.sh based on linked variables.tf found
# in module instance.
#
# DO NOT MODIFY MANUALLY
#
##############################################################################

variable "versions" {
  type = "map"
  default = {}
}

variable "etcd_backup" {
  type = "map"
  default = {
    storage_type = "pv"
  }
}
variable "dns" {
  type = "map"
}
variable "route53_access_key" {
  default = ""
}
variable "route53_secret_key" {
  default = ""
}
variable "route53_hosted_zone_id" {
  default = ""
}
locals {
  hosted_zone_id = "${var.route53_hosted_zone_id == "" ? lookup(var.dns, "hosted_zone_id", "") : var.route53_hosted_zone_id}"
  dns = "${merge(var.dns, map("hosted_zone_id", local.hosted_zone_id))}"
}

module "route53" {
  source = "../../modules/access/aws"
  defaults = {
    region = "us-east-1"
  }
  access_info = "${local.dns}"

  access_key = "${var.route53_access_key}"
  secret_key = "${var.route53_secret_key}"
}

module "dns" {
  source = "../../modules/condmap"
  if = "${lookup(local.dns,"dns_type","") == "route53"}"
  then = "${merge(local.dns,module.route53.access_info)}"
  else = "${local.dns}"
}

module "s3_etcd_backup" {
  source = "../../modules/access/aws"
  defaults = "${module.route53.access_info}"
  access_info = "${var.etcd_backup}"
}

provider "aws" {
  alias      = "route53"
  access_key = "${module.route53.access_key}"
  secret_key = "${module.route53.secret_key}"
  region     = "${module.route53.region}"
}
provider "aws" {
  alias      = "s3_etcd_backup"
  access_key = "${module.s3_etcd_backup.access_key}"
  secret_key = "${module.s3_etcd_backup.secret_key}"
  region     = "${module.s3_etcd_backup.region}"
}

locals {
  access_info = {
    route53_dns    = "${module.route53.access_info}"
    s3_etcd_backup = "${module.s3_etcd_backup.access_info}"
  }
}

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

###############################################################
# typical variables to set for all cluster projects
###############################################################


variable "ca_cert_pem" {
  default = ""
}
variable "ca_key_pem" {
  default = ""
}

variable "cluster_name" {
  type = "string"
}
variable "cluster_type" {
  type = "string"
}

variable "bastion" {
  type = "map"
  default = { }
}

variable "cluster-lb" {
  type = "string"
  default = "false"
}

#
# node config for worker and master
#
variable "worker" {
  type = "map"
  default = { }
}
variable "master" {
  type = "map"
  default = { }
}

variable "worker_count" {
  default = 1
}
variable "assign_worker_fips" {
  default = false
}
variable "worker_update_mode" {
  default = ""
}
variable "worker_generation" {
  default = 0
}
variable "worker_image_name" {
  type = "string"
  default = ""
}
variable "worker_flavor_name" {
  type = "string"
  default = ""
}

# deprecated
variable "master_count" {
  default = 1
}
variable "assign_master_fips" {
  default =  false
}
variable "master_update_mode" {
  default = ""
}
variable "master_generation" {
  default = 0
}
variable "master_image_name" {
  type = "string"
  default = ""
}
variable "master_flavor_name" {
  type = "string"
  default = ""
}

variable "master_volume_size" {
  type = "string"
  default = "20"
}
############

variable "etcd_backup_file" {
  type = "string"
  default = ""
}
variable "recover_cluster" {
  default = false
}
variable "keep_recovery_version" {
  default = "false"
}
variable "provision_bootkube" {
  default = false
}
variable "root_certs_file" {
  type = "string"
  default = ""
}
variable "pull_secret_file" {
  type = "string"
  default = ""
}

variable "dashboard_user" {
  default = ""
}
variable "dashboard_password" {
  default = ""
}
variable "dashboard_creds" {
  default = "admin:$apr1$BgPuasJn$W7sw.khdm/VqoZirMe6uE1"
}

variable "base_domain" {
  type = "string"
  default = ""
}
variable "domain_name" {
  type = "string"
  default = ""
}
variable "additional_domains" {
  type = "list"
  default = []
}
variable "additional_api_domains" {
  type = "list"
  default = []
}

variable "dns_nameservers" {
  type = "list"
  default = [
  ]
}

variable "flavor_name" {
  default = ""
}

variable "bastion_image_name" {
  default = "ubuntu-16.04"
}
variable "bastion_user" {
  default = "ubuntu"
}

variable "bastion_flavor_name" {
  default = ""
}


#
# oidc parameters for api server
#
variable "oidc_issuer_domain" {
  default = ""
}
variable "oidc_issuer_subdomain" {
  default = ""
}
variable "oidc_client_id" {
  default = "kube-kubectl"
}
variable "oidc_username_claim" {
  default = "email"
}
variable "oidc_groups_claim" {
  default = "groups"
}
variable "oidc_ca_file" {
  default = ""
}
variable "oidc_use_cluster_ca" {
  default = false
}

#
# flags
#

variable "use_bastion" {
  default = true
}

variable "use_lbaas" {
  default = true
}
variable "configure_additional_dns" {
  default = false
}



#
# vm update modes
#
variable "node_update_mode" {
  default = "Roll"
}
variable "generation" {
  default = 0
}

variable "update_kubelet" {
  default = false
}

# ooppps
# set this to true, to delete only the lbaas iaas elements
variable "omit_lbaas" {
  default = false
}

variable "addons" {
  default = {
    "dashboard" = { }
    "nginx-ingress" = { }
    "heapster" = { }
  }
}


###############################################################
# constants
###############################################################

#
# iaas
#
variable "subnet_cidr" {
  type = "string"
  default = ""
}
variable "service_cidr" {
  type = "string"
  default = "10.241.0.0/17"
}
variable "pod_cidr" {
  type = "string"
  default = "10.241.128.0/17"
}


variable "host_ssl_certs_dir" {
  default = "/etc/ssl/certs"
}

variable "api_ports" {
  default = [ "443" ]
}

variable "nginx_ports" {
  default = [ "80", "443" ]
}

variable "deploy_tiller" {
  default = "true"
}

variable "event_ttl" {
  default = "48h0m0s"
}

###############################################################
# process related inputs
###############################################################

variable "bootkube" {
  default = 1
}

variable "master_state" {
  default = { }
}
variable "worker_state" {
  default = { }
}
variable "recovery_version" {
  default = "0"
}

#
# create cluster by calling main module
#
module "instance" {
  source = "../../modules/instance"

  iaas_config = "${module.iaas_config.iaas_config}"
  versions    = "${var.versions}"

  platform = "${local.platform}"

  access_info = "${local.access_info}"
  etcd_backup = "${var.etcd_backup}"
  cluster-lb = "${var.cluster-lb}"
  dns = "${module.dns.value}"
  ca_cert_pem = "${var.ca_cert_pem}"
  ca_key_pem = "${var.ca_key_pem}"
  cluster_name = "${var.cluster_name}"
  cluster_type = "${var.cluster_type}"
  bastion = "${var.bastion}"
  cluster-lb = "${var.cluster-lb}"
  worker = "${var.worker}"
  master = "${var.master}"
  worker_count = "${var.worker_count}"
  assign_worker_fips = "${var.assign_worker_fips}"
  worker_update_mode = "${var.worker_update_mode}"
  worker_generation = "${var.worker_generation}"
  worker_image_name = "${var.worker_image_name}"
  worker_flavor_name = "${var.worker_flavor_name}"
  master_count = "${var.master_count}"
  assign_master_fips = "${var.assign_master_fips}"
  master_update_mode = "${var.master_update_mode}"
  master_generation = "${var.master_generation}"
  master_image_name = "${var.master_image_name}"
  master_flavor_name = "${var.master_flavor_name}"
  master_volume_size = "${var.master_volume_size}"
  etcd_backup_file = "${var.etcd_backup_file}"
  recover_cluster = "${var.recover_cluster}"
  keep_recovery_version = "${var.keep_recovery_version}"
  provision_bootkube = "${var.provision_bootkube}"
  root_certs_file = "${var.root_certs_file}"
  pull_secret_file = "${var.pull_secret_file}"
  dashboard_user = "${var.dashboard_user}"
  dashboard_password = "${var.dashboard_password}"
  dashboard_creds = "${var.dashboard_creds}"
  base_domain = "${var.base_domain}"
  domain_name = "${var.domain_name}"
  additional_domains = "${var.additional_domains}"
  additional_api_domains = "${var.additional_api_domains}"
  dns_nameservers = "${var.dns_nameservers}"
  flavor_name = "${var.flavor_name}"
  bastion_image_name = "${var.bastion_image_name}"
  bastion_user = "${var.bastion_user}"
  bastion_flavor_name = "${var.bastion_flavor_name}"
  oidc_issuer_domain = "${var.oidc_issuer_domain}"
  oidc_issuer_subdomain = "${var.oidc_issuer_subdomain}"
  oidc_client_id = "${var.oidc_client_id}"
  oidc_username_claim = "${var.oidc_username_claim}"
  oidc_groups_claim = "${var.oidc_groups_claim}"
  oidc_ca_file = "${var.oidc_ca_file}"
  oidc_use_cluster_ca = "${var.oidc_use_cluster_ca}"
  use_bastion = "${var.use_bastion}"
  use_lbaas = "${var.use_lbaas}"
  configure_additional_dns = "${var.configure_additional_dns}"
  node_update_mode = "${var.node_update_mode}"
  generation = "${var.generation}"
  update_kubelet = "${var.update_kubelet}"
  omit_lbaas = "${var.omit_lbaas}"
  addons = "${var.addons}"
  subnet_cidr = "${var.subnet_cidr}"
  service_cidr = "${var.service_cidr}"
  pod_cidr = "${var.pod_cidr}"
  host_ssl_certs_dir = "${var.host_ssl_certs_dir}"
  api_ports = "${var.api_ports}"
  nginx_ports = "${var.nginx_ports}"
  deploy_tiller = "${var.deploy_tiller}"
  event_ttl = "${var.event_ttl}"
  bootkube = "${var.bootkube}"
  master_state = "${var.master_state}"
  worker_state = "${var.worker_state}"
  recovery_version = "${var.recovery_version}"
}

#
# standard output required by utility scripts
#
output "bastion" {
  value = "${module.instance.bastion}"
}
output "bastion_user" {
  value = "${module.instance.bastion_user}"
}


output "master_roll_info" {
  value = "${module.instance.master_roll_info}"
}
output "worker_roll_info" {
  value = "${module.instance.worker_roll_info}"
}

output "master" {
  value = "${module.instance.master}"
}
output "master_ips" {
  value = "${module.instance.master_ips}"
}
output "master_count" {
  value = "${module.instance.master_count}"
}

output "worker" {
  value = "${module.instance.worker}"
}
output "worker_ips" {
  value = "${module.instance.worker_ips}"
}
output "worker_count" {
  value = "${module.instance.worker_count}"
}

output "etcd_service_ip" {
  value = "${module.instance.etcd_service_ip}"
}
output "structure-version" {
  value = "${module.instance.structure-version}"
}
