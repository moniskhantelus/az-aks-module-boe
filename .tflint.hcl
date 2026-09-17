plugin "terraform" {
  enabled = true
  preset  = "recommended"
}
config {
  format = "compact"
}
rule "terraform_standard_module_structure" {
  enabled = false  # allows outputs in main.tf when the calling layer is not a reusable module
}