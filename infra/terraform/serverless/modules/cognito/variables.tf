variable "name" {
  description = "Prefix for Cognito resources."
  type        = string
}

variable "callback_urls" {
  description = "Allowed callback URLs for the user pool client."
  type        = list(string)
  default     = []
}

variable "logout_urls" {
  description = "Allowed logout URLs for the user pool client."
  type        = list(string)
  default     = []
}

variable "domain_prefix" {
  description = "Optional AWS managed domain prefix (e.g. my-app -> my-app.auth.<region>.amazoncognito.com)."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
