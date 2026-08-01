# Pin npm packages by running ./bin/importmap

pin "application"
pin "user", preload: "user"

pin "autosize", to: "autosize.js", preload: "user"

pin "TomSelect", to: "TomSelect_base.js", preload: "user"
pin "TomSelect_caret_position", to: "TomSelect_caret_position.js", preload: "user"
pin "TomSelect_input_autogrow", to: "TomSelect_input_autogrow.js", preload: "user"
pin "TomSelect_remove_button", to: "TomSelect_remove_button.js", preload: "user"

pin "tom-select", to: "./vendor/assets/stylesheets/tom-select.css", preload: "user"
pin "tom-remove", to: "./vendor/assets/stylesheets/TomSelect_remove_button.css", preload: "user"
