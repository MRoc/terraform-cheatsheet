variable "filenames" {
  type = set(string)
  default = [
    "/root/cat.txt",
    "/root/dog.txt",
    "/root/cow.txt"
  ]
}

resource "local_file" "pets" {
  filename = each.value
  content = each.value
  for_each = var.filenames
}

output "pets" {
  value = local_file.pets
}