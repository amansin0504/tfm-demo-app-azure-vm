# Update before use
variable location {
    type = map(string)
    default = {
      value = "Central US"
      suffix = "centralus"
    }
}

variable watchername {
  type = map(string)
  default = {
    value = "NetworkWatcher_centralus"
  }
}

variable watcherrg {
  type = map(string)
  default = {
    value = "NetworkWatcherRG"
  }
}
