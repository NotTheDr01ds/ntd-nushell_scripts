use ../seAPI *
use ../wslClipboard *


export def getUserProfiles [ userIds, site = "stackoverflow" ] {
  let datadir = $"($env.HOME)/src/nushell/seUtils/data/"
  let userIdsString = ($userIds | str join ";")

  #let path = "/info"
  #let params = {
  #    filter: "!SnXC9rW3U5-2HgXt_6"
  #}
  #let res = (callSeApi $path $site -p $params)
  #let siteUrl = ($res.items.site.site_url | get 0)

  let path = $"/users/($userIdsString)"
  let params = {
      filter: "!40dOUW-SqsTOTdGSU",
  }

  let res = (callSeApi $path $site -p $params)
  let profiles = $res.items

  $profiles | each {|profile| 
    try {
      let now = (date now | format date "%F-%H%M%S")
      mkdir $"($datadir)/($site)/profiles/"
      $profile | to json | save $"($datadir)/($site)/profiles/($profile.user_id)-($profile.display_name)-($now).json"
    } catch {|e| print $e}

    $profile
  }
}

export def getUserProfilesFromClip [ site = "stackoverflow"] {
  let userIds = (pwsh.exe -c "Get-Clipboard" | lines | str trim)
  getUserProfiles $userIds $site
}