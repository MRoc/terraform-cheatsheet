resource "local_file" "animal" {
  filename = "/root/animal_${count.index}.txt"
  content = "I am animal ${count.index}"
  count = 3
}