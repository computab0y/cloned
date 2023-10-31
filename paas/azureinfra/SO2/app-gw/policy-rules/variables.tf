
variable "ocp_cluster_instance" {
  default       = ""
  description   = "OCP Cluster instance name."
}

variable "ocp_vnet_prefix" {
  default       = "vnet"
  description   = "VNet prefix"
}

variable "location_identifier" {
  default       = "uks"
  description   = "TLA for location"
}

variable "ocp_base_dns_zone" {
    default     = ""
  description = "Base Azure DNS zone name for the OCP cluster"
}

variable "op_env" {
  default     = "prod"
  description = "Operating environment for the resources"
  
}
variable "shrd_kv_name" {
  default = ""
  
}
variable "mgmt_sub_id" {
  default     = ""
}

variable "infra_sub_id" {
  default     = ""
}
# This is an array object of allowed IP addresses/ranges
variable "app_gw_allow_ips" { 
  default = [
"86.147.75.248",
"77.100.224.94",    # SemirM
"94.195.175.164",   # Ray Bryan
"84.65.91.137",
"149.71.74.117",    # GeorgeR
"79.70.59.191",
"140.82.115.0/24",  # GitHub range
"82.34.80.79",
"194.75.196.200",   # Connor Duncan
"51.19.122.33",     # Ray Bryan
"86.146.112.82",    # Gary Bennett
"82.41.70.207",     # GrBe
"217.155.44.1",     # GrBe
"217.38.8.142",     # PA Proxy Server
"3.11.50.65",       # Durden
"185.13.50.0/24",   # MoD range 
"86.182.38.71",     # Martin Hill
"82.68.64.166",     # Zac Tolley
"78.150.95.71",     # JHRS - Jason
"82.68.158.160/29", # Mark Fernyhough
"91.125.134.22",    # Richard Harper - InfinityWorks - Home
"31.76.39.227",     # Dean Francis, Reservist
"86.143.97.124",    # Steve Murray
"188.241.156.248",  # Casper Stevens - reservist
"80.6.204.158",     # Francis Dean
"81.157.56.188",    # Luke Phillips - CapG
"86.144.35.27",     # Peter Green - CapG
"5.65.196.64",      # Paul Sowerby - Accenture
"81.79.6.3",        # Tamar L Coates - Accenture
"94.4.91.187",      # RH ACS SME
"80.197.129.97",    # RH ACS SME
"20.90.238.224",    # ocp1 fw
"20.108.146.114",   # ocp3 fw
"3.10.206.171",     # ACN URL isolation URL
"18.170.228.157",   # ACN URL isolation URL
"84.65.66.169",     # Tamar Coates (Office)
"87.74.175.209",    # Mohson Qureshi IP 1
"86.18.226.24",     # Mohson Qureshi IP 2
"192.176.203.18",   # Cap Gemini VPN
"147.147.107.240",  # Matthew Maskery
"35.195.101.80",    # Improbable Team
"178.62.4.225",     # i3 Pen Testers
"77.103.35.16",     # i3 pen testers 
"194.69.103.0/24",  # TVP wifi
"37.60.86.0/24",    # Mustang wifi
"82.42.169.119",    # Satinder Khela - Accenture
"109.155.19.234",   # Sushil Kumar - Accenture
"82.1.26.7",        # Kareem Ghazaly - Accenture
"52.51.7.138",      # Product/Services Pages Team VPN
"82.36.72.244",     # Daniel MacLaren
"2.220.186.203",      # Simon Cross
"192.168.0.129"     # Will Lamb
#"217.155.36.127"   # Matt Parker
  ]
}

# This is an array object, using ISO country codes, e.g. GB
variable "app_gw_allow_regions" {
default = ["GB"]
}

variable "waf_access_list_enabled" {
  type    = bool
  default = true
}
variable "waf_pol_global_name" {
  default = "preda-openshift-AppGW-Global-WAF"
}

variable "ocp_vnet_name_rg" {
  default       = "preda-infra-vnet"
  description   = "VNet rg name"
}

variable "waf_public_domains_enabled" {
  type    = bool
  default = false
}

# This is an array object of public domains
variable "app_gw_public_domains" { 
  default = [
"automation.service.mod.gov.uk",
"data-ai.service.mod.gov.uk",
"devsecops.service.mod.gov.uk",
"foundry.service.mod.gov.uk",
"mod-cloud.service.mod.gov.uk",
"synthetics.service.mod.gov.uk",
"tech-digital-teams.service.mod.gov.uk"
]
}