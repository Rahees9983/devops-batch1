terraform {
  required_version = ">=1.9"

  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "1.236.0"
    }
  }
}

provider "alicloud" {
  region  = "me-central-1"
  profile = "rahees-uat"
  #   name = "ali-mehid"
}

resource "random_string" "rs1" {
  # length  = 16    # The length of the generated string
  length  = var.length
  special = true # Exclude special characters (!@#$%&...)
  upper   = true # Include uppercase letters
  lower   = true # Include lowercase letters
  numeric = true # Include numbers
}

data "alicloud_vpcs" "vpcs_ds" {
  name_regex = "vpc-ack-1"
}

output "vpc_data" {
  value = data.alicloud_vpcs.vpcs_ds.vpcs[*].vswitch_ids[0]
}


variable "names" {
  default = ["web", "db"]
}

resource "alicloud_instance" "this" {

  # count = 2
  # instance_name   = "rk-tf-vm-${count.index + 1}"
  # instance_name = var.names[count.index]
  # for_each = toset(["app","web","db"])
# for_each = {
#     web = "web-team"
#     # app = "app-team"
#     db  = "db-team"
#   }

  instance_name =  "vm-crearted-byrk-tf"
  security_groups = ["sg-l4vapo1aineclx0bdf33"]
  # vswitch_id           = "vsw-l4vs3m8iclf5infy6tw9k"
  vswitch_id           = data.alicloud_vpcs.vpcs_ds.vpcs[0].vswitch_ids[0]
  instance_type        = "ecs.c9i.large"
  image_id             = "ubuntu_24_04_x64_20G_alibase_20260119.vhd"
  system_disk_category = "cloud_essd"
  system_disk_size     = 55
  # internet_max_bandwidth_in = 1

   internet_max_bandwidth_out = 1

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install -y nginx",
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx"
    ]
    on_failure = continue
  }

  provisioner "local-exec" {
    command = "echo ${self.private_ip} >> rahees-private_ips.txt"
  }
  key_name =  "rahees-mac-m4-ssh-public-sky"

  # tags = {
  #   "owner" = "${each.key}"
  #   "team"  = "${each.value}"
  # }

 lifecycle {
   create_before_destroy = true
 }
}


# output "intance_private_ips" {
#   # value = for_each instance in alicloud_instance.this 
#   value = {
#     for n, i in alicloud_instance.this :
#     n => i.private_ip
#   }
# }

# output "instance_private_ips_using_values" {
#   value =  values(alicloud_instance.this)[*].private_ip
# }

# resource "alicloud_instance" "vm-create-manually-1" {

#   security_groups = [
#     "sg-l4vao1lbdtkdthx3s89n",
#     "sg-l4vapo1aineclx0bdf33",
#   ]
#   image_id             = "ubuntu_24_04_x64_20G_alibase_20260119.vhd"
#   instance_charge_type = "PostPaid"
#   instance_name        = "vm-crearted-manulally"
#   instance_type        = "ecs.c9i.large"


# }


# resource "alicloud_instance" "patel-vm" {

#   instance_name        = "patel-tf-vm-2"
#   security_groups      = ["sg-l4vapo1aineclx0bdf33"]
#   vswitch_id           = "vsw-l4vs3m8iclf5infy6tw9k"
#   instance_type        = "ecs.c9i.large"
#   image_id             = "ubuntu_24_04_x64_20G_alibase_20260119.vhd"
#   system_disk_category = "cloud_essd"
#   system_disk_size     = 55

#  data_disks {
#     name        = "patel-disk2"
#     size        = 20
#     category    = "cloud_essd"
#     description = "disk2"
#     encrypted   = true
#   }
# tags = {
#     "owner" = "rk"
#     "team"  = "service_delivery"
#   }

# }

# terraform import alicloud_instance.this i-l4vg35m05fzibez9uckd
# terraform import alicloud_instance.vm-create-manually-1 i-l4v15iq2u13i3psrvmcm

