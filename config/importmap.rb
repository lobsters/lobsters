# Pin npm packages by running ./bin/importmap

pin "application"
pin_all_from "app/javascript"
# pin_all_from "vendor/javascripts"

pin "autosize", to: "autosize.js"

pin "TomSelect", to: "TomSelect_base.js"
pin "TomSelect_caret_position", to: "TomSelect_caret_position.js"
pin "TomSelect_input_autogrow", to: "TomSelect_input_autogrow.js"
pin "TomSelect_remove_button", to: "TomSelect_remove_button.js"

pin "tom-select", to: "./vendor/assets/stylesheets/tom-select.css"
pin "tom-remove", to: "./vendor/assets/stylesheets/TomSelect_remove_button.css"
