terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.21.2"
    }
  }
  required_version = ">= 0.13"
}

provider ibm {
    ibmcloud_api_key = var.ibmcloud_api_key
    ibmcloud_timeout = 60
}