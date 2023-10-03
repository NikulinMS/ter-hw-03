resource "yandex_compute_disk" "disk_vm" {
  count = 3
  name = "${"disk"}-${count.index}"
  size = 1
}

resource "yandex_compute_instance" "storage" {
  count = 1
  name        = "storage-${count.index+1}"
  depends_on = [yandex_compute_disk.disk_vm]
  platform_id = "standard-v1"
  resources {
    cores         = 2
    memory        = 1
    core_fraction = 5
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
    }
  }

dynamic "secondary_disk" {
  for_each = yandex_compute_disk.disk_vm[*].id
  content {
    disk_id = secondary_disk.value
  }
}

  scheduling_policy {
    preemptible = true
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.develop.id
    nat       = true
    security_group_ids = [yandex_vpc_security_group.example.id]
  }

  metadata = {
    serial-port-enable = 1
    ssh-keys           = local.ssh
  }

}