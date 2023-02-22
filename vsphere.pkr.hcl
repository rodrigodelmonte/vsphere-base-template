packer {
  required_plugins {
    sshkey = {
      version = ">= 1.0.1"
      source  = "github.com/ivoronin/sshkey"
    }
    vsphere = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/vsphere"
    }
  }
}

// conntextion details
variable "vcenter_server" {
  type    = string
  default = "${env("VSPHERE_SERVER")}"
}

variable "vsphere_user" {
  type    = string
  default = "${env("VSPHERE_USER")}"
}

variable "vsphere_password" {
  type    = string
  default = "${env("VSPHERE_PASSWORD")}"
}

variable "vsphere_insecure_connection" {
  type    = string
  default = "false"
}


// vsphere related details
variable "vsphere_cluster" {
  type = string
}

variable "vsphere_datastore" {
  type = string
}

variable "vsphere_datacenter" {
  type = string
}

variable "vsphere_network" {
  type = string
}

variable "vsphere_resource_pool" {
  type    = string
  default = ""
}

variable "vsphere_folder" {
  type    = string
  default = ""
}


// image build related details
variable "distribution" {
  type = string
}

variable "distribution_version" {
  type = string
}

variable "iso_url" {
  type = string
}

variable "iso_checksum" {
  type    = string
  default = null
}


// customizations
variable "vm_name" {
  type        = string
  default     = ""
  description = "set the vm name (which will be the name of the template)"
}

variable "vm_name_prefix" {
  type        = string
  default     = "d2iq-base-"
  description = "add a prefix to the name"
}

variable "vm_name_postfix" {
  type        = string
  default     = "$$D2iQDefault$$"
  description = "add a postfix to the name"
}

variable "vsphere_guest_os_type" {
  type    = string
  default = ""
}

variable "cpu" {
  type    = string
  default = "4"
}

variable "cpu_cores" {
  type    = string
  default = "1"
}

variable "disk_size" {
  type    = number
  default = 20480
}

variable "memory" {
  type    = string
  default = "8192"
}

variable "disk_thin_provisioned" {
  type    = bool
  default = true
}

variable "firmware" {
  type    = string
  default = "bios"
}


variable "ssh_timeout" {
  type    = string
  default = "10m"
}

variable "ssh_username" {
  type    = string
  default = ""
}

variable "dry_run" {
  type    = bool
  default = false
}

data "sshkey" "install" {}

# All locals variables are generated from variables that uses expressions
# that are not allowed in HCL2 variables.
# Read the documentation for locals blocks here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/locals
locals {
  vm_name_postfix = var.vm_name_postfix == "$$D2iQDefault$$" ? "-${regex_replace(timestamp(), "[- TZ:]", "")}" : var.vm_name_postfix
  vm_name_var     = var.vm_name == "" ? "${var.distribution}-${var.distribution_version}" : var.vm_name
  vm_name         = "${var.vm_name_prefix}${local.vm_name_var}${local.vm_name_postfix}"

  # lookup by <distro_name>-<distro_version> fallback to <distro_version>
  distro_version_bootfile_lookup = {
    "RHEL-7.9"     = "${path.root}/bootfiles/rhel/rhel7.ks"
    "RHEL"         = "${path.root}/bootfiles/rhel/rhel8.ks"
    "RockyLinux"   = "${path.root}/bootfiles/rocky/rocky.ks"
    "CentOS"       = "${path.root}/bootfiles/centos/centos7.ks"
    "Ubuntu"       = "${path.root}/bootfiles/ubuntu/autoinstall.yaml"
    "Ubuntu-18.04" = "${path.root}/bootfiles/ubuntu/preseed.cfg"
  }

  el_old_bootcommand = [
    "<tab><wait>",
    " ks=hd:sr1:/bootfile.cfg<enter>"
  ]

  el_bootcommand = [
    "<tab><wait>",
    " inst.ks=hd:sr1:/bootfile.cfg<enter>"
  ]

  ubuntu_bionic_bootcommand = [
    "<wait>e<down><down><down><end><wait>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs>",
    "/install/vmlinuz",
    " priority=critical locale=en_US",
    " file=/media/BOOTFILE.CFG",
    "<f10>"
  ]

  ubuntu_bootcommand = [
    "<esc><esc><esc><esc><esc><esc><esc><esc>",
    "<esc><wait>",
    "<esc><wait>",
    "linux /casper/vmlinuz autoinstall ds=nocloud text",
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot",
    "<enter>"
  ]

  ubuntu_jammy_bootcommand = [
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall ds=nocloud text",
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot",
    "<enter>"
  ]

  # lookup by <distro_name>-<distro_version> fallback to <distro_name>
  distro_boot_command_lookup = {
    "RHEL-7"       = local.el_old_bootcommand
    "RHEL"         = local.el_bootcommand
    "CentOS"       = local.el_old_bootcommand
    "RockyLinux"   = local.el_bootcommand
    "Ubuntu-18.04" = local.ubuntu_bionic_bootcommand
    "Ubuntu-20.04" = local.ubuntu_bootcommand
    "Ubuntu-22.04" = local.ubuntu_jammy_bootcommand
  }

  default_firmware = "bios"
  # lookup by <distro_name>-<distro_version> fallback to <distro_version> fallback to local.default_firmware
  distro_firmware_lookup = {
    "Ubuntu" = "efi-secure"
  }

  default_bootwait = "10s"
  # lookup by <distro_name>-<distro_version> fallback to <distro_version> fallback to local.default_bootwait
  distro_bootwait_lookup = {
    "Ubuntu" = "1s"
  }

  # lookup by <distro_name>-<distro_version> fallback to <distro_version> fallback to ""
  distro_cd_label_lookup = {
    "Ubuntu" = "cidata"
  }

  default_vsphere_guest_os_type = "otherlinux64guest"

  distro_vsphere_guest_os_type_lookup = {
    "Ubuntu"     = "ubuntu64Guest",
    "CentOS"     = "centos64Guest",
    "RHEL"       = "rhel7_64Guest"
    "RockyLinux" = "centos64Guest"
  }

  # lookup by <distro_name>-<distro_version> fallback to <distro_name>
  distro_default_ssh_username = {
    "Ubuntu"     = "ubuntu",
    "CentOS"     = "centos",
    "RHEL"       = "eluser"
    "RockyLinux" = "rockstar"
  }

  boot_command_distro = lookup(local.distro_boot_command_lookup, "${var.distribution}", [""])
  boot_command        = lookup(local.distro_boot_command_lookup, "${var.distribution}-${var.distribution_version}", local.boot_command_distro)

  firmware  = lookup(local.distro_firmware_lookup, "${var.distribution}-${var.distribution_version}", lookup(local.distro_firmware_lookup, "${var.distribution}", local.default_firmware))
  boot_wait = lookup(local.distro_bootwait_lookup, "${var.distribution}-${var.distribution_version}", lookup(local.distro_bootwait_lookup, "${var.distribution}", local.default_bootwait))
  cd_label  = lookup(local.distro_cd_label_lookup, "${var.distribution}-${var.distribution_version}", lookup(local.distro_cd_label_lookup, "${var.distribution}", ""))

  fallback_username   = "user"
  distro_ssh_username = lookup(local.distro_default_ssh_username, "${var.distribution}-${var.distribution_version}", lookup(local.distro_default_ssh_username, "${var.distribution}", local.fallback_username))
  ssh_username        = var.ssh_username != "" ? var.ssh_username : local.distro_ssh_username

  distro_vsphere_guest_os_type = var.vsphere_guest_os_type != "" ? var.vsphere_guest_os_type : lookup(local.distro_vsphere_guest_os_type_lookup, "${var.distribution}-${var.distribution_version}", lookup(local.distro_vsphere_guest_os_type_lookup, "${var.distribution}", local.default_vsphere_guest_os_type))

  bootfile_name = lookup(local.distro_version_bootfile_lookup, "${var.distribution}-${var.distribution_version}", lookup(local.distro_version_bootfile_lookup, "${var.distribution}", ""))
  bootfile = templatefile(local.bootfile_name, {
    ssh_username         = local.ssh_username
    public_key           = data.sshkey.install.public_key
    sha512_fake_pw       = sha512(uuidv4())
    distribution         = var.distribution
    distribution_version = var.distribution_version
  })
}

source "vsphere-iso" "baseimage" {
  CPUs                 = var.cpu
  RAM                  = var.memory
  cluster              = var.vsphere_cluster
  disk_controller_type = ["pvscsi"]
  guest_os_type        = local.distro_vsphere_guest_os_type
  network_adapters {
    network_card = "vmxnet3"
    network      = var.vsphere_network
  }
  boot_wait    = local.boot_wait
  boot_command = local.boot_command
  firmware     = local.firmware

  cd_content = {
    "/bootfile.cfg" = local.bootfile,
    # make it cloud-config compatible
    "/user-data"       = local.bootfile,
    "/meta-data"       = "",
    "/authorized_keys" = data.sshkey.install.public_key
  }

  cd_label = local.cd_label

  floppy_content = {
    "/BOOTFILE.CFG" = local.bootfile,
    # make it cloud-config compatible
    "/user-data"       = local.bootfile,
    "/meta-data"       = "",
    "/authorized_keys" = data.sshkey.install.public_key
  }

  storage {
    disk_size             = var.disk_size
    disk_thin_provisioned = var.disk_thin_provisioned
  }

  communicator                = "ssh"
  cpu_cores                   = var.cpu_cores
  datacenter                  = var.vsphere_datacenter
  resource_pool               = var.vsphere_resource_pool
  datastore                   = var.vsphere_datastore
  folder                      = var.vsphere_folder
  insecure_connection         = var.vsphere_insecure_connection
  iso_url                     = var.iso_url
  iso_checksum                = var.iso_checksum
  password                    = var.vsphere_password
  ssh_private_key_file        = data.sshkey.install.private_key_path
  ssh_clear_authorized_keys   = true
  ssh_key_exchange_algorithms = ["curve25519-sha256@libssh.org", "ecdh-sha2-nistp256", "ecdh-sha2-nistp384", "ecdh-sha2-nistp521", "diffie-hellman-group14-sha1", "diffie-hellman-group1-sha1"]
  ssh_timeout                 = var.ssh_timeout
  ssh_username                = local.ssh_username
  username                    = var.vsphere_user
  vcenter_server              = var.vcenter_server
  vm_name                     = local.vm_name

  storage {
      disk_size = 40000
  }


  create_snapshot     = !var.dry_run
  convert_to_template = !var.dry_run
}

locals {
  distro_build_scripts = {
    "Ubuntu" = [
      "${path.root}/scripts/ubuntu/install_open_vm_tools.sh",
      "${path.root}/scripts/ubuntu/post_cleanup.sh",
    ],
    "CentOS" = [
      "${path.root}/scripts/el/install_open_vm_tools.sh",
      "${path.root}/scripts/el/cleanup_yum.sh"
    ],
    "RHEL-7" = [
      "${path.root}/scripts/el/install_open_vm_tools.sh",
      "${path.root}/scripts/el/cleanup_yum.sh"
    ],
    "RHEL" = [
      "${path.root}/scripts/el/install_open_vm_tools.sh",
      "${path.root}/scripts/el/cleanup_dnf.sh"
    ],
    "RockyLinux" = [
      "${path.root}/scripts/el/install_open_vm_tools.sh",
      "${path.root}/scripts/el/cleanup_dnf.sh"
    ],
  }
  build_scripts = lookup(local.distro_build_scripts, "${var.distribution}-${var.distribution_version}", lookup(local.distro_build_scripts, "${var.distribution}", []))
}

build {
  sources = ["source.vsphere-iso.baseimage"]

  provisioner "shell" {
    execute_command = "sudo su -m root -c 'sh -eux {{.Path}}'"
    scripts         = local.build_scripts
  }

  post-processor "manifest" {
    output     = "manifests/${local.vm_name}.json"
    strip_path = true
    custom_data = {
      iso_url      = var.iso_url
      iso_checksum = var.iso_checksum
    }
  }
}
