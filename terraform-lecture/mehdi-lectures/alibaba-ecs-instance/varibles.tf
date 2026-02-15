variable "length" {
  type        = number
  default     = 8
  description = "pass the length of ramdomstring"
  validation {
    condition     = contains([8, 10, 20], var.length)
    error_message = "value must be 8, 10, 20."
  }
}