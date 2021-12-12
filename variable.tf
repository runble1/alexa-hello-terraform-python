variable "region" {
  description = "AWSリージョン"
  default     = "ap-northeast-1"
}

variable "profile" {
  description = "awsのprofile"
  default     = "terraform"
}

variable "env" {
  description = "awsの環境"
  default     = "dev"
}

variable "alexa_skill_id" {
  description = "alexa skill id"
}