resource "local_file" "ansible_inventory" {
  filename = "./inventory.yml"
  content = templatefile("ansible.tftpl", {
    webservers = yandex_compute_instance.count,
    databases = yandex_compute_instance.for_each,
    storage = yandex_compute_instance.storage,
  })
}