export-env {
  $env.config.menus ++= [
    {
      name: ide_completion_menu
      only_buffer_difference: false
      marker: $" \n❯ (char -u '1f4ce') "
      type: {
        layout: ide
        min_completion_width: 0,
        max_completion_width: 50,
        max_completion_height: 10, # will be limited by the available lines in the terminal
        padding: 0,
        border: true,
        cursor_offset: 0,
        description_mode: "prefer_right"
        min_description_width: 0
        max_description_width: 50
        max_description_height: 10
        description_offset: 1
        # If true, the cursor pos will be corrected, so the suggestions match up with the typed text
        #
        # C:\> str
        #      str join
        #      str trim
        #      str split
        correct_cursor_pos: false
      }
      style: {
      #   text: { fg: "#33ff00" }
      #   selected_text: { fg: "#0c0c0c" bg: "#33ff00" attr: b}
      #   description_text: yellow
        text: green
        selected_text: {attr: r}
        description_text: yellow
        match_text: {fg: darkorange}
        selected_match_text: {fg: darkorange attr: r}
      }
    }
  ]

  $env.config.keybindings ++= [{
      name: ide_completion_menu
      modifier: control
      keycode: char_p
      mode: [emacs vi_normal vi_insert]
      event: {
        until: [
          { send: menu name: ide_completion_menu }
          { send: menuprevious }
          { edit: complete }
          { send: up }
        ]
      }
    }

   {
      name: ide_completion_menu
      modifier: control
      keycode: char_n
      mode: [emacs vi_normal vi_insert]
      event: {
        until: [
          { send: menu name: ide_completion_menu }
          { send: menunext }
          { edit: complete }
          { send: down }
        ]
      }
    }
  ]

}
