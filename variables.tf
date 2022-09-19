#Update before user
variable region {
    default = "us-east-1"
}
#Update before user
variable az1 {
    default = "us-east-1a"
}
#Update before user
variable az2 {
    default = "us-east-1b"
}

variable user {
    default = "wpuser"
}

variable password {
    type = string
    description = "SQL db Password"
    default = "wpuser123$"
}

variable dbname {
    default = "saferdsdb"
}

variable "images" {
  type    = map(string)
  default = {
    "us-east-1" = "ami-0070c5311b7677678"
    "us-west-1" = "ami-040a251ee9d7d1a9b"
    "us-east-2" = "ami-07f84a50d2dec2fa4"
    "us-west-2" = "ami-0aab355e1bfa1e72e"
  }
}

#Update before user
variable "keyname" {
    default = "virginia"
}

#Update before user
variable "csws3arn" {
    type    = string
    default = "arn:aws:s3:::secureworkloadvpcflowbucket"
}
