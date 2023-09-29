# Домашнее задание к занятию "`Управляющие конструкции в коде Terraform`" - `Никулин Михаил Сергеевич`



---

### Задание 1

1. Изучите проект.
2. Заполните файл personal.auto.tfvars.
3. Инициализируйте проект, выполните код. Он выполнится, даже если доступа к preview нет.

Примечание. Если у вас не активирован preview-доступ к функционалу «Группы безопасности» в Yandex Cloud, запросите доступ у поддержки облачного провайдера. Обычно его выдают в течение 24-х часов.

Приложите скриншот входящих правил «Группы безопасности» в ЛК Yandex Cloud или скриншот отказа в предоставлении доступа к preview-версии.

### Ответ:

![task_1_1.png](img%2Ftask_1_1.png)


---

### Задание 2

1. Создайте файл count-vm.tf. Опишите в нём создание двух одинаковых ВМ web-1 и web-2 (не web-0 и web-1) с минимальными параметрами, используя мета-аргумент count loop. Назначьте ВМ созданную в первом задании группу безопасности.(как это сделать узнайте в документации провайдера yandex/compute_instance )
2. Создайте файл for_each-vm.tf. Опишите в нём создание двух ВМ с именами "main" и "replica" разных по cpu/ram/disk , используя мета-аргумент for_each loop. Используйте для обеих ВМ одну общую переменную типа list(object({ vm_name=string, cpu=number, ram=number, disk=number })). При желании внесите в переменную все возможные параметры.
3. ВМ из пункта 2.2 должны создаваться после создания ВМ из пункта 2.1.
4. Используйте функцию file в local-переменной для считывания ключа ~/.ssh/id_rsa.pub и его последующего использования в блоке metadata, взятому из ДЗ 2.
5. Инициализируйте проект, выполните код.

### Ответ:

Создадим файл [count-vm.tf](src%2Fcount-vm.tf):
```
data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2004-lts"
}

resource "yandex_compute_instance" "count" {
  count = 2
  name        = "web-${count.index+1}"
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
    ssh-keys           = "ubuntu:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII2kpc8hkCtD5uVQdw0wUeGlNp/rKarSrCKoifhuRtCF shakal@Razer"
  }

}
```
Группы безопасности добавлены:
![task_2_2.png](img%2Ftask_2_2.png)
![task_2_3.png](img%2Ftask_2_3.png)
Создадим файл [for_each-vm.tf](src%2Ffor_each-vm.tf) и добавим переменную ```each_vm``` в [variables.tf](src%2Fvariables.tf):
```
resource "yandex_compute_instance" "for_each" {
  depends_on = [yandex_compute_instance.count]
  for_each = {
    main = var.each_vm[0]
    replica = var.each_vm[1]
  }
  name        = "${each.key}"
  platform_id = "standard-v1"
  resources {
    cores         = "${each.value.cpu}"
    memory        = "${each.value.ram}"
    core_fraction = 5
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
      type = "network-hdd"
      size = "${each.value.disk}"
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
```
```
variable "each_vm" {
  type = list(object({  cpu=number, ram=number, disk=number }))
  default = [
    {  cpu=4, ram=2, disk=10 },
    {  cpu=2, ram=1, disk=15 }
  ]
}
```
Добавим в [for_each-vm.tf](src%2Ffor_each-vm.tf) атрибут ```depends_on = [yandex_compute_instance.count]```, чтобы данный ресурс создавался после первых ВМ

Создадим файл [locals.tf](src%2Flocals.tf), куда внесем переменную ```ssh```, для считывания ключа ~/.ssh/id_ed25519.pub и его последующего использования в блоке metadata:
```
locals {
  ssh = "${"ubuntu"}:${file("~/.ssh/id_ed25519.pub")}"
}
```
Инициализируем проект:
```
Plan: 4 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

yandex_compute_instance.count[0]: Creating...
yandex_compute_instance.count[1]: Creating...
yandex_compute_instance.count[0]: Still creating... [10s elapsed]
yandex_compute_instance.count[1]: Still creating... [10s elapsed]
yandex_compute_instance.count[1]: Still creating... [20s elapsed]
yandex_compute_instance.count[0]: Still creating... [20s elapsed]
yandex_compute_instance.count[0]: Still creating... [30s elapsed]
yandex_compute_instance.count[1]: Still creating... [30s elapsed]
yandex_compute_instance.count[1]: Still creating... [40s elapsed]
yandex_compute_instance.count[0]: Still creating... [40s elapsed]
yandex_compute_instance.count[0]: Creation complete after 44s [id=fhmstmskrjmmbg610lbq]
yandex_compute_instance.count[1]: Creation complete after 47s [id=fhmg3520fsql3bbhstc3]
yandex_compute_instance.for_each["main"]: Creating...
yandex_compute_instance.for_each["replica"]: Creating...
yandex_compute_instance.for_each["replica"]: Still creating... [10s elapsed]
yandex_compute_instance.for_each["main"]: Still creating... [10s elapsed]
yandex_compute_instance.for_each["main"]: Still creating... [20s elapsed]
yandex_compute_instance.for_each["replica"]: Still creating... [20s elapsed]
yandex_compute_instance.for_each["replica"]: Still creating... [30s elapsed]
yandex_compute_instance.for_each["main"]: Still creating... [30s elapsed]
yandex_compute_instance.for_each["replica"]: Still creating... [40s elapsed]
yandex_compute_instance.for_each["main"]: Still creating... [40s elapsed]
yandex_compute_instance.for_each["main"]: Creation complete after 46s [id=fhmj08n2v7dbg8ahi7ec]
yandex_compute_instance.for_each["replica"]: Creation complete after 47s [id=fhmg7vot762am1edsu6u]

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
```
Результат:
![task_2_1.png](img%2Ftask_2_1.png)


---

### Задание 3

1. Создайте 3 одинаковых виртуальных диска размером 1 Гб с помощью ресурса yandex_compute_disk и мета-аргумента count в файле disk_vm.tf .
2. Создайте в том же файле одиночную(использовать count или for_each запрещено из-за задания №4) ВМ c именем "storage" . Используйте блок dynamic secondary_disk{..} и мета-аргумент for_each для подключения созданных вами дополнительных дисков.

### Ответ:

Создадим файл [disk_vm.tf](src%2Fdisk_vm.tf) и внесем в него ресурс ```yandex_compute_disk```:
```
resource "yandex_compute_disk" "disk_vm" {
  count = 3
  name = "${"disk"}-${count.index}"
  size = 1
}
```
Добавим в файл [disk_vm.tf](src%2Fdisk_vm.tf) инструкции по созданию дополнительной ВМ и подключению к ней созданных дисков, добавим дополнительно инструкцию ```depends_on = [yandex_compute_disk.disk_vm]```, чтобы ВМ создавалась только после создания дисков:
```
resource "yandex_compute_instance" "storage" {
  name        = "storage"
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
    ssh-keys           = "ubuntu:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII2kpc8hkCtD5uVQdw0wUeGlNp/rKarSrCKoifhuRtCF shakal@Razer"
  }

}
```
Инициализируем проект:
```
Plan: 4 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

yandex_compute_disk.disk_vm[0]: Creating...
yandex_compute_disk.disk_vm[2]: Creating...
yandex_compute_disk.disk_vm[1]: Creating...
yandex_compute_disk.disk_vm[0]: Creation complete after 7s [id=fhmjo6adscnlu308rfdo]
yandex_compute_disk.disk_vm[2]: Creation complete after 7s [id=fhmhe8hpktb181rsuaip]
yandex_compute_disk.disk_vm[1]: Still creating... [10s elapsed]
yandex_compute_disk.disk_vm[1]: Still creating... [20s elapsed]
yandex_compute_disk.disk_vm[1]: Still creating... [30s elapsed]
yandex_compute_disk.disk_vm[1]: Still creating... [40s elapsed]
yandex_compute_disk.disk_vm[1]: Creation complete after 40s [id=fhm19phfeaemg4ovo78b]
yandex_compute_instance.storage: Creating...
yandex_compute_instance.storage: Still creating... [10s elapsed]
yandex_compute_instance.storage: Still creating... [20s elapsed]
yandex_compute_instance.storage: Still creating... [30s elapsed]
yandex_compute_instance.storage: Creation complete after 34s [id=fhm78165hu031u274849]

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
```
Результат:
![task_3_1.png](img%2Ftask_3_1.png)


---

### Задание 4

`Приведите ответ в свободной форме........`

1. `Заполните здесь этапы выполнения, если требуется ....`
2. `Заполните здесь этапы выполнения, если требуется ....`
3. `Заполните здесь этапы выполнения, если требуется ....`
4. `Заполните здесь этапы выполнения, если требуется ....`
5. `Заполните здесь этапы выполнения, если требуется ....`
6. 

```
Поле для вставки кода...
....
....
....
....
```

`При необходимости прикрепитe сюда скриншоты
![Название скриншота](ссылка на скриншот)`

---
## Дополнительные задания (со звездочкой*)


### Задание 5

`Приведите ответ в свободной форме........`

1. `Заполните здесь этапы выполнения, если требуется ....`
2. `Заполните здесь этапы выполнения, если требуется ....`
3. `Заполните здесь этапы выполнения, если требуется ....`
4. `Заполните здесь этапы выполнения, если требуется ....`
5. `Заполните здесь этапы выполнения, если требуется ....`
6. 

`При необходимости прикрепитe сюда скриншоты
![Название скриншота](ссылка на скриншот)`
