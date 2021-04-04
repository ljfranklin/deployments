terraform {
  required_providers {
    unifi = {
      # TODO(ljfranklin): use upstream once PR is merged
      # source = "paultyng/unifi"
      source = "ljfranklin/unifi"
      version = "0.23.1"
    }
  }
}

provider "unifi" {
  username = "{{ unifi_admin_username }}"
  password = "{{ unifi_admin_password }}"
  api_url  = "https://localhost:8443"
  allow_insecure = true
}

resource "unifi_network" "lan" {
  name    = "LAN"
  purpose = "corporate"

  subnet       = "192.168.1.0/24"
  dhcp_start   = "192.168.1.6"
  dhcp_stop    = "192.168.1.254"
  dhcp_enabled = true
  domain_name  = "localdomain"
}

data "unifi_ap_group" "default" {
}

data "unifi_user_group" "default" {
}

resource "unifi_wlan" "wifi_5g" {
  name       = "{{ unifi_wifi_ssid }}"
  passphrase = "{{ unifi_wifi_password }}"
  security   = "wpapsk"

  wlan_band     = "5g"
  network_id    = unifi_network.lan.id
  ap_group_ids  = [data.unifi_ap_group.default.id]
  user_group_id = data.unifi_user_group.default.id
}

resource "unifi_wlan" "wifi_2g" {
  name       = "{{ unifi_wifi_2g_ssid }}"
  passphrase = "{{ unifi_wifi_2g_password }}"
  security   = "wpapsk"

  wlan_band     = "2g"
  network_id    = unifi_network.lan.id
  ap_group_ids  = [data.unifi_ap_group.default.id]
  user_group_id = data.unifi_user_group.default.id
}
