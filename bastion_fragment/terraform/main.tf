
# This code is auto generated and any changes will be lost if it is regenerated.

terraform {
    required_version = ">= 0.12.0"
}

# -- Copyright: Copyright (c) 2020, 2021, Oracle and/or its affiliates.
# ---- Author : Andrew Hopkinson (Oracle Cloud Solutions A-Team)
# ------ Connect to Provider
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# ------ Retrieve Regional / Cloud Data
# -------- Get a list of Availability Domains
data "oci_identity_availability_domains" "AvailabilityDomains" {
    compartment_id = var.compartment_ocid
}
data "template_file" "AvailabilityDomainNames" {
    count    = length(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains)
    template = data.oci_identity_availability_domains.AvailabilityDomains.availability_domains[count.index]["name"]
}
# -------- Get a list of Fault Domains
data "oci_identity_fault_domains" "FaultDomainsAD1" {
    availability_domain = element(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains, 0)["name"]
    compartment_id = var.compartment_ocid
}
data "oci_identity_fault_domains" "FaultDomainsAD2" {
    availability_domain = element(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains, 1)["name"]
    compartment_id = var.compartment_ocid
}
data "oci_identity_fault_domains" "FaultDomainsAD3" {
    availability_domain = element(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains, 2)["name"]
    compartment_id = var.compartment_ocid
}
# -------- Get Home Region Name
data "oci_identity_region_subscriptions" "RegionSubscriptions" {
    tenancy_id = var.tenancy_ocid
}
data "oci_identity_regions" "Regions" {
}
data "oci_identity_tenancy" "Tenancy" {
    tenancy_id = var.tenancy_ocid
}

locals {
#    HomeRegion = [for x in data.oci_identity_region_subscriptions.RegionSubscriptions.region_subscriptions: x if x.is_home_region][0]
    home_region = lookup(
        {
            for r in data.oci_identity_regions.Regions.regions : r.key => r.name
        },
        data.oci_identity_tenancy.Tenancy.home_region_key
    )
}
# ------ Get List Service OCIDs
data "oci_core_services" "RegionServices" {
}
# ------ Get List Images
data "oci_core_images" "InstanceImages" {
    compartment_id           = var.compartment_ocid
}

# ------ Home Region Provider
provider "oci" {
    alias            = "home_region"
    tenancy_ocid     = var.tenancy_ocid
    user_ocid        = var.user_ocid
    fingerprint      = var.fingerprint
    private_key_path = var.private_key_path
    region           = local.home_region
}

# ------ Create Compartment - Root True
# ------ Root Compartment
locals {
    Okit_Comp001_id              = var.compartment_ocid
}

output "Okit_Comp001Id" {
    value = local.Okit_Comp001_id
}

# ------ Create Virtual Cloud Network
resource "oci_core_vcn" "Okit_Bastion_Vcn" {
    # Required
    compartment_id = local.Okit_Comp001_id
    cidr_block     = "10.1.0.0/16"
    # Optional
    dns_label      = "bastionvcn"
    display_name   = "okit-bastion-vcn"
}

locals {
    Okit_Bastion_Vcn_id                       = oci_core_vcn.Okit_Bastion_Vcn.id
    Okit_Bastion_Vcn_dhcp_options_id          = oci_core_vcn.Okit_Bastion_Vcn.default_dhcp_options_id
    Okit_Bastion_Vcn_domain_name              = oci_core_vcn.Okit_Bastion_Vcn.vcn_domain_name
    Okit_Bastion_Vcn_default_dhcp_options_id  = oci_core_vcn.Okit_Bastion_Vcn.default_dhcp_options_id
    Okit_Bastion_Vcn_default_security_list_id = oci_core_vcn.Okit_Bastion_Vcn.default_security_list_id
    Okit_Bastion_Vcn_default_route_table_id   = oci_core_vcn.Okit_Bastion_Vcn.default_route_table_id
}


# ------ Create Internet Gateway
resource "oci_core_internet_gateway" "Okit_Bastion_Ig" {
    # Required
    compartment_id = local.Okit_Comp001_id
    vcn_id         = local.Okit_Bastion_Vcn_id
    # Optional
    enabled        = true
    display_name   = "okit-bastion-ig"
}

locals {
    Okit_Bastion_Ig_id = oci_core_internet_gateway.Okit_Bastion_Ig.id
}

# ------ Create Security List
# ------- Update VCN Default Security List
resource "oci_core_default_security_list" "Okit_Bastion_Sl" {
    # Required
    manage_default_resource_id = local.Okit_Bastion_Vcn_default_security_list_id
    egress_security_rules {
        # Required
        protocol    = "all"
        destination = "0.0.0.0/0"
        # Optional
        destination_type  = "CIDR_BLOCK"
        description  = "Egress Rule 01"
    }
    ingress_security_rules {
        # Required
        protocol    = "6"
        source      = "0.0.0.0/0"
        # Optional
        source_type  = "CIDR_BLOCK"
        description  = "Ingress Rule 01"
        tcp_options {
            min = "22"
            max = "22"
        }
    }
    ingress_security_rules {
        # Required
        protocol    = "1"
        source      = "0.0.0.0/0"
        # Optional
        source_type  = "CIDR_BLOCK"
        description  = "Ingress Rule 02"
        icmp_options {
            type = "3"
            code = "4"
        }
    }
    ingress_security_rules {
        # Required
        protocol    = "1"
        source      = "10.0.0.0/16"
        # Optional
        source_type  = "CIDR_BLOCK"
        description  = "Ingress Rule 03"
        icmp_options {
            type = "3"
        }
    }
    # Optional
    display_name   = "okit-bastion-sl"
}

locals {
    Okit_Bastion_Sl_id = oci_core_default_security_list.Okit_Bastion_Sl.id
}


# ------ Create Route Table
# ------- Update VCN Default Route Table
resource "oci_core_default_route_table" "Okit_Bastion_Rt" {
    # Required
    manage_default_resource_id = local.Okit_Bastion_Vcn_default_route_table_id
    route_rules    {
        destination_type  = "CIDR_BLOCK"
        destination       = "0.0.0.0/0"
        network_entity_id = local.Okit_Bastion_Ig_id
        description       = "Rule 01"
    }
    # Optional
    display_name   = "okit-bastion-rt"
}

locals {
    Okit_Bastion_Rt_id = oci_core_default_route_table.Okit_Bastion_Rt.id
    }


# ------ Create Subnet
# ---- Create Public Subnet
resource "oci_core_subnet" "Okit_Bastion_Sn" {
    # Required
    compartment_id             = local.Okit_Comp001_id
    vcn_id                     = local.Okit_Bastion_Vcn_id
    cidr_block                 = "10.1.0.0/24"
    # Optional
    display_name               = "okit-bastion-sn"
    dns_label                  = "bastionsn"
    security_list_ids          = [local.Okit_Bastion_Sl_id]
    route_table_id             = local.Okit_Bastion_Rt_id
    dhcp_options_id            = local.Okit_Bastion_Vcn_dhcp_options_id
    prohibit_public_ip_on_vnic = false
}

locals {
    Okit_Bastion_Sn_id              = oci_core_subnet.Okit_Bastion_Sn.id
    Okit_Bastion_Sn_domain_name     = oci_core_subnet.Okit_Bastion_Sn.subnet_domain_name
}

# ------ Get List Images
data "oci_core_images" "Okit_Bastion_ServerImages" {
    compartment_id           = var.compartment_ocid
    operating_system         = "Oracle Linux"
    operating_system_version = ""
    shape                    = "VM.Standard.E2.1"
}

# ------ Create Instance
resource "oci_core_instance" "Okit_Bastion_Server" {
    # Required
    compartment_id      = local.Okit_Comp001_id
    shape               = "VM.Standard.E2.1"
    # Optional
    display_name        = "okit-bastion-server"
    availability_domain = data.oci_identity_availability_domains.AvailabilityDomains.availability_domains["1" - 1]["name"]
    agent_config {
        # Optional
    }
    create_vnic_details {
        # Required
        subnet_id        = local.Okit_Bastion_Sn_id
        # Optional
        assign_public_ip = true
        display_name     = "okit-bastion-server vnic 00"
        hostname_label   = "okit-in001"
        skip_source_dest_check = "false"
    }
#    extended_metadata {
#        some_string = "stringA"
#        nested_object = "{\"some_string\": \"stringB\", \"object\": {\"some_string\": \"stringC\"}}"
#    }
    metadata = {
        ssh_authorized_keys = ""
        user_data           = base64encode("#cloud-config\nwrite_files:\n  # Add aliases to bash (Note: At time of writing the append flag does not appear to be working)\n  - path: /etc/.bashrc\n    append: true\n    content: |\n      alias lh='ls -lash'\n      alias lt='ls -last'\n      alias env='/usr/bin/env | sort'\n      alias ssh='/usr/bin/ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oConnectTimeout=10 -i /etc/ssh/ssh_host_rsa_key '\n\nssh_keys:\n  rsa_private: |\n    -----BEGIN OPENSSH PRIVATE KEY-----\n    Add Private Key\n    -----END OPENSSH PRIVATE KEY-----\n  rsa_public: ssh-rsa Add Public Key\n\nruncmd:\n  # Set Private Key to read everyone\n  - sudo chmod a+r /etc/ssh/ssh_host_rsa_key*\n  # Add additional environment information because append does not appear to work in write_file\n  - sudo bash -c \"echo 'source /etc/.bashrc' >> /etc/bashrc\"\n\nfinal_message: \"**** The Bastion Instance is finally up, after $UPTIME seconds ****\"\n")
    }
    source_details {
        # Required
        source_id               = data.oci_core_images.Okit_Bastion_ServerImages.images[0]["id"]
        source_type             = "image"
        # Optional
        boot_volume_size_in_gbs = "50"
#        kms_key_id              = 
    }
    preserve_boot_volume = false
}

locals {
    Okit_Bastion_Server_id            = oci_core_instance.Okit_Bastion_Server.id
    Okit_Bastion_Server_public_ip     = oci_core_instance.Okit_Bastion_Server.public_ip
    Okit_Bastion_Server_private_ip    = oci_core_instance.Okit_Bastion_Server.private_ip
}

output "okit-bastion-serverPublicIP" {
    value = local.Okit_Bastion_Server_public_ip
}

output "okit-bastion-serverPrivateIP" {
    value = local.Okit_Bastion_Server_private_ip
}

# ------ Create Block Storage Attachments

# ------ Create VNic Attachments

