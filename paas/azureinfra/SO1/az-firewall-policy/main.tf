data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  provider  = azurerm.mgmt
  name      = "rg-mgmt-${var.op_env}-shared-${var.location_identifier}"
  
}


#Firewall Policy
data "azurerm_firewall_policy" "fw-pol01" {
  provider                = azurerm.mgmt
  name                    = "pol-fw-${var.op_env}-shared-${var.location_identifier}"
  resource_group_name     = data.azurerm_resource_group.rg.name

}

data "azurerm_resource_group" "ocpmgmt" {
  provider  = azurerm.infra
  name      = "rg-${var.ocp_cluster_instance}mgmt-${var.op_env}-${var.location_identifier}"

}

data "azurerm_virtual_network" "ocpcluster" {
  provider            = azurerm.infra
  name                = "${var.ocp_vnet_prefix}-${var.ocp_cluster_instance}-${var.op_env}-${var.location_identifier}"
  resource_group_name = data.azurerm_resource_group.ocpmgmt.name
}

data  "azurerm_subnet" "default" {
  provider            = azurerm.infra
  name                = "default"
  resource_group_name  = data.azurerm_resource_group.ocpmgmt.name
  virtual_network_name = data.azurerm_virtual_network.ocpcluster.name
}
resource "azurerm_firewall_policy_rule_collection_group" "ocp-nw" {
  name               = "${var.ocp_cluster_instance}-netw-fwpolicy-rcg"
  firewall_policy_id = data.azurerm_firewall_policy.fw-pol01.id
  priority           = var.rule_priority + 3
  lifecycle {
      create_before_destroy = true
    }
  network_rule_collection {
    name     = "${var.ocp_cluster_instance}-nw-rule-coll_core-platform"
    priority = var.rule_priority + 3
    action   = "Allow"
    rule {
      name                  = "${var.ocp_cluster_instance}-rule_ncsc-protected-dns"
      protocols             = ["TCP", "UDP"]
      source_addresses      = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_addresses = [
        "25.25.25.25", 
        "25.26.27.28"
        ]
      destination_ports     = ["53"]
    }
    rule {
      name                  = "${var.ocp_cluster_instance}-rule_ntp"
      protocols             = ["UDP"]
      source_addresses      = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_addresses = [
        "*"
        ]
      destination_ports     = ["123"]
    }
  }
}
resource "azurerm_firewall_policy_rule_collection_group" "ocp" {
  name               = "${var.ocp_cluster_instance}-fwpolicy-rcg"
  firewall_policy_id = data.azurerm_firewall_policy.fw-pol01.id
  priority           = var.rule_priority
  lifecycle {
      create_before_destroy = true
    }
  application_rule_collection {
    name     = "${var.ocp_cluster_instance}-rule-coll_core-platform"
    priority = var.rule_priority 
    action   = "Allow"
    # Azure / Microsoft endpoints
    # https://docs.microsoft.com/en-us/azure/azure-monitor/app/ip-addresses
    rule {
      name = "${var.ocp_cluster_instance}-rule_azmonitor-telemetry-https"
      description = "Azure Monitor telemetry https://docs.microsoft.com/en-us/azure/azure-monitor/app/ip-addresses"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_fqdns = [
        "dc.applicationinsights.azure.com",
        "dc.applicationinsights.microsoft.com",
        "dc.services.visualstudio.com",
        "*.in.applicationinsights.azure.com",
        "live.applicationinsights.azure.com",
        "rt.applicationinsights.microsoft.com",
        "rt.services.visualstudio.com"
      
        ]
    }
    rule {
      name = "${var.ocp_cluster_instance}-rule_azmonitor-logs-https"
      description = "Azure Log Analytics  https://docs.microsoft.com/en-us/azure/azure-monitor/app/ip-addresses"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_fqdns = [
        "*.ods.opinsights.azure.com",
        "*.oms.opinsights.azure.com",
        "*.blob.core.windows.net",
        "*.azure-automation.net",
        "uksouth.monitoring.azure.com"
        ]
    }
    rule {
      name = "${var.ocp_cluster_instance}-rule_azmonitor-config-https"
      description = "Azure monitor config endpoints https://docs.microsoft.com/en-us/azure/azure-monitor/app/ip-addresses"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      terminate_tls = true
      destination_urls = [
        "management.core.windows.net",
        "management.azure.com",
        "login.windows.net",
        "login.microsoftonline.com",
        "secure.aadcdn.microsoftonline-p.com",
        "auth.gfx.ms",
        "login.live.com",
        "globalcdn.nuget.org",
        "packages.nuget.org",
        "api.nuget.org/v3/index.json",
        "nuget.org",
        "api.nuget.org",
        "dc.services.vsallin.net"
        ]
    }
    # Azure Graph - for installation of the Cluster by Linux commission host.
    rule {
      name = "${var.ocp_cluster_instance}-rule_linuxmgmt-ocp-install-https"
      description = "Azure Graph - for installation of the Cluster by Linux commission host for Terraform."
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${data.azurerm_subnet.default.address_prefixes[0]}"]
      destination_fqdns = [
        "graph.windows.net",
        "*.queue.core.windows.net"
        ]
    }
    #Azure Arc
    rule {
      name = "${var.ocp_cluster_instance}-rule_Arc-https"
      description = "Azure Arc endpoints"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_fqdns = [
        "*.servicebus.windows.net",
        "guestnotificationservice.azure.com",
        "*.guestnotificationservice.azure.com",
        "uksouth.dp.kubernetesconfiguration.azure.com",
        "sts.windows.net" # Azure AD 
      ]
    }
    rule {
      name = "${var.ocp_cluster_instance}-rule_Arc-cli-extension-https"
      description = "Azure Arc CLI endpoints"
      terminate_tls = true
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_urls = [
        "pypi.org/simple/pycryptodome/*",  # required for CLI extension updates module
        "files.pythonhosted.org/packages/*"
      ]
    }
    rule {
      name = "${var.ocp_cluster_instance}-rule_msft-defender-http"
      description = "MS Defender endpoints https://download.microsoft.com/download/8/a/5/8a51eee5-cd02-431c-9d78-a58b7f77c070/mde-urls.xlsx"
      protocols {
        type = "Http"
        port = 80
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_urls = [
        "ctldl.windowsupdate.com",
        "crl.microsoft.com/pki/crl/*",
        "www.microsoft.com/pkiops/*",
        "www.microsoft.com/pkiops/crl/",
        "www.microsoft.com/pkiops/certs",
        "www.microsoft.com/pki/certs"
        ]
    }
    #MS Defender : https://download.microsoft.com/download/8/a/5/8a51eee5-cd02-431c-9d78-a58b7f77c070/mde-urls.xlsx
    rule {
      name = "${var.ocp_cluster_instance}-rule_msft-defender-https"
      description = "MS Defender endpoints https://download.microsoft.com/download/8/a/5/8a51eee5-cd02-431c-9d78-a58b7f77c070/mde-urls.xlsx"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      terminate_tls = true
      destination_urls = [
        "events.data.microsoft.com",
        "x.cp.wd.microsoft.com",
        "cdn.x.cp.wd.microsoft.com",
        "eu-cdn.x.cp.wd.microsoft.com",
        "wu-cdn.x.cp.wd.microsoft.com",
        "officecdn-microsoft-com.akamaized.net",
        "packages.microsoft.com",
        "unitedkingdom.x.cp.wd.microsoft.com",
        "uk-v20.events.data.microsoft.com",
        "winatp-gw-uks.microsoft.com",
        "winatp-gw-ukw.microsoft.com",
        "ussuk1southprod.blob.core.windows.net",
        "ussuk1westprod.blob.core.windows.net"
        ]
    }
     rule {
      name = "${var.ocp_cluster_instance}-rule_msft-update-mgmt-http"
      description = "MS update mgmt endpoints https://download.microsoft.com/download/8/a/5/8a51eee5-cd02-431c-9d78-a58b7f77c070/mde-urls.xlsx"
      protocols {
        type = "Http"
        port = 80
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_urls = [
        "2.tlu.dl.delivery.mp.microsoft.com",
        "packages.microsoft.com/keys/microsoft.asc"
        ]
    }
    # OpenShift endpoints
    rule {
      name = "${var.ocp_cluster_instance}-rule_OpenShift-https"
      description = "OpenShift endpoints"
      protocols {
        type = "Https"
        port = 443
      }
 
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      terminate_tls = true
      destination_urls = [
        "*.openshift.com",
        "registry.redhat.io",
        "*.quay.io",
        "quay.io",
        "quayio-production-s3.s3.amazonaws.com",
        "storage.googleapis.com/openshift-release",
        "sso.redhat.com",
        "registry.access.redhat.com",
        "registry.connect.redhat.com",
        "access.redhat.com",
        "cloud.redhat.com",
        "*.openshift.io",
        "cdn-ubi.redhat.com",
        "rhc4tp-prod-z8cxf-image-registry-us-east-1-evenkyleffocxqvofrk.s3.dualstack.us-east-1.amazonaws.com", # https://access.redhat.com/solutions/6184221
        "ghcr.io",
        "awscli.amazonaws.com"
        ]
    }
       # Used for Certificate Provisioning
    rule {
      name = "${var.ocp_cluster_instance}-rule_SSL-CAs"
      description = "Used for Certificate Provisioning"
      protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Http"
        port = 80
      }
      source_addresses  = ["${data.azurerm_subnet.default.address_prefixes[0]}"]
      destination_fqdns = [
        "api.zerossl.com",
        "acme.zerossl.com",
        "cloudflare-dns.com"        
        ]
    }
    # Cluster Provisioning / {Pipelines}
     rule {
      name = "${var.ocp_cluster_instance}-rule_github"
      description = "github"
      protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Http"
        port = 80
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_fqdns = [
          "*.github.com",
          "github.com",
          "raw.githubusercontent.com",
          "objects.githubusercontent.com",
          "gcr.io",
          "*.gcr.io"
        ]
    }
    # Google IDP
     rule {
      name = "${var.ocp_cluster_instance}-rule_Goole-IDp"
      description = "Google IDP"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_fqdns = [
          "oauth2.googleapis.com",
          "openidconnect.googleapis.com"
        ]
    }
    
  }
  application_rule_collection {
    name     = "${var.ocp_cluster_instance}-rule-coll_platform-coarse_grained"
    priority = var.rule_priority + 2
    action   = "Allow"
    # Azure / Microsoft endpoints
    rule {
      name = "${var.ocp_cluster_instance}-rule_msft-https"
      description = "Azure endpoints"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_fqdns = [
       "*.microsoft.com",
        "*.blob.storage.azure.net",
        "*.vault.azure.net",
        "*.azure.com",
        "aka.ms",
        "*.azureedge.net",
        "*.azure-automation.net"
        ]
    }
  }
  application_rule_collection {
    name     = "${var.ocp_cluster_instance}-rule-coll_ocp-providers"
    priority = var.rule_priority + 1
    action   = "Allow"
    # Required by RH Quay - Clair update #https://access.redhat.com/documentation/en-us/red_hat_quay/3.6/html-single/manage_red_hat_quay/index
     rule {
      name = "${var.ocp_cluster_instance}-rule_rh-quay"
      description = "RH Quay Clair https://access.redhat.com/documentation/en-us/red_hat_quay/3.6/html-single/manage_red_hat_quay/index"
      protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Http"
        port = 80
      }
      terminate_tls = true
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_urls = [
          "people.canonical.com/~ubuntu-security/oval/",
          "secdb.alpinelinux.org",
          "cdn.amazonlinux.com",
          "support.novell.com",
          "linux.oracle.com/security/oval/",
          "packages.vmware.com/photon/photon_oval_definitions/",
          "storage.googleapis.com",
          "www.debian.org/security/oval/",
          "cdn.amazonlinux.com/2/core/latest/x86_64/mirror.list",
          "repo.us-west-2.amazonaws.com/2018.03/updates/x86_64/mirror.list",
          "github.com/pyupio/safety-db/archive/",
          "catalog.redhat.com/api/containers/",
          "www.redhat.com/security/data/",
          "packages.us-west-2.amazonaws.com/2018.03/updates/*",
          "ftp.debian.org/*",
          "rubygems.org/*",
          "index.rubygems.org/*",
          "alas.aws.amazon.com",
          "ftp.suse.com",
          "git.launchpad.net",
          "smallstep.github.io/helm-charts"
        ]
    }
        rule {
      name = "${var.ocp_cluster_instance}-rule_rh-scanner"
      description = "RH Scanner"
      protocols {
        type = "Https"
        port = 443
      }
      terminate_tls = true
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_urls = [
          "nvd.nist.gov",
          "search.maven.org",
          "maven.repository.redhat.com",
          "repo1.maven.org",
          "*.repo1.maven.org"

        ]
    }
    # RH ACS
    rule {
      name = "${var.ocp_cluster_instance}-rule_rh-acs-https"
      description = "RH ACS"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_fqdns = [
          "definitions.stackrox.io",
          "collector-modules.stackrox.io"
        ]
    }
    # DSO Pipeline
    rule {
      name = "${var.ocp_cluster_instance}-rule_dso-pipeline-https"
      description = "remote dso repos"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      terminate_tls = true
      destination_urls = [
          "registry.npmjs.org/*",
          "repo.maven.apache.org/*"
        ]
    }
    rule {
      name = "${var.ocp_cluster_instance}-rule_cucumber-https"
      description = "ChromeDriver binaries that Cucumber uses to run a headless chrome instance"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_fqdns = [
          "chromedriver.storage.googleapis.com" # cucumber testing
        ]
    }
    # Monitoring
     rule {
      name = "${var.ocp_cluster_instance}-rule_grafana-https"
      description = "Grafana"
      protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Http"
        port = 80
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_fqdns = [
          "grafana.com",
          "stats.grafana.org"
        ]
    }
    # Slack integration
     rule {
      name = "${var.ocp_cluster_instance}-rule_slack-https"
      description = "Slack integration"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_fqdns = [
          "hooks.slack.com",
          "*.hooks.slack.com"
        ]
    }
    #Sonar Qube
    rule {
      name = "${var.ocp_cluster_instance}-rule_sonarqube"
      description = "Sonarqube external endpoints"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_fqdns = [
          "update.sonarsource.org",
          "telemetry.sonarsource.com"
        ]
    }
    # Docker for container access
    rule {
      name = "${var.ocp_cluster_instance}-rule_container-repos"
      description = "Docker registries"
      protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Http"
        port = 80
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_fqdns = [
         "*.docker.io",
         "docker.io",
         "production.cloudflare.docker.com"
        ]
    }
    rule {
      name = "${var.ocp_cluster_instance}-rule_juiceshop-repos"
      description = "requirements for juiceshop"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_fqdns = [
         "nodejs.org",
         "mapbox-node-binary.s3.amazonaws.com",
         "secure.gravatar.com"
        ]
    }
    rule {
      name = "${var.ocp_cluster_instance}-rule_management_host"
      description = "requirements for management server"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_fqdns = [
         "*.releases.hashicorp.com",
         "registry.terraform.io",
         "pypi.python.org", # required for pip installs
         "checkpoint-api.hashicorp.com",
         "get.helm.sh"
        ]
    }
  rule {
      name = "${var.ocp_cluster_instance}-rule_allow_ocpclusters"
      description = "allow access to other ocp clusters"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_fqdns = [
         "*.azure.dso.digital.mod.uk"
        ]
    }
  rule {
      name = "${var.ocp_cluster_instance}-rule_allow_angular"
      description = "allow access devfile for angular pre-reqs"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_fqdns = [
         "registry.devfile.io"
        ]
    }
  rule {
      name = "${var.ocp_cluster_instance}-rule_allow_sigstore"
      description = "allow access for sigstore pre-reqs"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_fqdns = [
         "rekor.sigstore.dev",
         "sigstore-tuf-root.storage.googleapis.com"
        ]
    }
    rule {
      name = "${var.ocp_cluster_instance}-rule_allow_infinityworks_app_urls"
      description = "allow access for infinityworks app team"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_fqdns = [
         "*dgw-dev.mod.uk",
         "dl-cdn.alpinelinux.org"
        ]
    }
    rule {
      name = "${var.ocp_cluster_instance}-rule_allow_anchore"
      description = "allow access for anchore"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_fqdns = [
         "anchorectl-releases.s3-us-west-2.amazonaws.com",
         "security-tracker.debian.org",
         "salsa.debian.org"
        ]
    }

    #Sonatype
    rule {
      name = "${var.ocp_cluster_instance}-rule_sonatype"
      description = "Sonatype external endpoint"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_fqdns = [
          "clm.sonatype.com"
        ]
    }

    #Trivy
    rule {
      name = "${var.ocp_cluster_instance}-rule_trivy"
      description = "Trivy external endpoint"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_fqdns = [
          "ghcr.io",
          "pkg-containers.githubusercontent.com"
        ]
    }

    #Allow access for JIRA 
    rule {
      name = "${var.ocp_cluster_instance}-rule_jira"
      description = "allow access for JIRA"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_fqdns = [
          "defencedigital.atlassian.net"
        ]
    }

       #Allow access for Spring 
    rule {
      name = "${var.ocp_cluster_instance}-rule_spring"
      description = "allow access for Spring"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_fqdns = [
          "repo.spring.io"
        ]
    }

     #Allow access for Veteran ID to get out to gov.uk
    rule {
      name = "${var.ocp_cluster_instance}-rule_oidc_integration_account_gov_uk"
      description = "allow access for oidc.integration.account.gov.uk"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_fqdns = [
          "oidc.integration.account.gov.uk",
          "api.notifications.service.gov.uk"
        ]
    }


  }
}