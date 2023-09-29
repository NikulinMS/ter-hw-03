locals {
  ssh = "${"ubuntu"}:${file("~/.ssh/id_ed25519.pub")}"
}