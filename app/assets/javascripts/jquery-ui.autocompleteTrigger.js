/********************************************************************************
/*
 * triggeredAutocomplete (jQuery UI autocomplete widget)
 * 2012 by Hawkee.com (hawkee@gmail.com)
 *
 * Version 1.4.3
 * 
 * Requires jQuery 1.7 and jQuery UI 1.8
 *
 * Dual licensed under MIT or GPLv2 licenses
 *   http://en.wikipedia.org/wiki/MIT_License
 *   http://en.wikipedia.org/wiki/GNU_General_Public_License
 *
*/

;(function ( $, window, document, undefined ) {
  $.widget("ui.triggeredAutocomplete", $.extend(true, {}, $.ui.autocomplete.prototype, {
    
    options: {
      trigger: "@",
      allowDuplicates: true
    },

    _create:function() {

      var self = this;
      this.id_map = new Object();
      this.stopIndex = -1;
      this.stopLength = -1;
      this.contents = '';
      this.cursorPos = 0;
      
      /** Fixes some events improperly handled by ui.autocomplete */
      this.element.bind('keydown.autocomplete.fix', function (e) {
        switch (e.keyCode) {
          case $.ui.keyCode.ESCAPE:
            self.close(e);
            e.stopImmediatePropagation();
            break;
          case $.ui.keyCode.UP:
          case $.ui.keyCode.DOWN:
            if (!self.menu.element.is(":visible")) {
              e.stopImmediatePropagation();
            }
        }
      });

      // Check for the id_map as an attribute.  This is for editing.

      var id_map_string = this.element.attr('id_map');
      if(id_map_string) this.id_map = jQuery.parseJSON(id_map_string);

      this.ac = $.ui.autocomplete.prototype;
      this.ac._create.apply(this, arguments);

      this.updateHidden();

      // Select function defined via options.
      this.options.select = function(event, ui) {
        var contents = self.contents;
        var cursorPos = self.cursorPos;

        // Save everything following the cursor (in case they went back to add a mention)
        // Separate everything before the cursor
        // Remove the trigger and search
        // Rebuild: start + result + end

        var end = contents.substring(cursorPos, contents.length);
        var start = contents.substring(0, cursorPos);
        start = start.substring(0, start.lastIndexOf(self.options.trigger));

        var top = self.element.scrollTop();
        this.value = start + self.options.trigger+ui.item.label+' ' + end;
        self.element.scrollTop(top);

        // Create an id map so we can create a hidden version of this string with id's instead of labels.

        self.id_map[ui.item.label] = ui.item.value;
        self.updateHidden();

        /** Places the caret right after the inserted item. */
        var index = start.length + self.options.trigger.length + ui.item.label.length + 2;
        if (this.createTextRange) {
                var range = this.createTextRange();
                range.move('character', index);
                range.select();
            } else if (this.setSelectionRange) {
              this.setSelectionRange(index, index);
            }
        
        return false;
      };

      // Don't change the input as you browse the results.
      this.options.focus = function(event, ui) { return false; }
      this.menu.options.blur = function(event, ui) { return false; }

      // Any changes made need to update the hidden field.
      this.element.focus(function() { self.updateHidden(); });
      this.element.change(function() { self.updateHidden(); });
    },

    // If there is an 'img' then show it beside the label.

    _renderItem:  function( ul, item ) {
      if(item.img != undefined) {
        return $( "<li></li>" )
          .data( "item.autocomplete", item )
          .append( "<a>" + "<img src='" + item.img + "' /><span>"+item.label+"</span></a>" )
          .appendTo( ul );
      }   
      else {  
        return $( "<li></li>" )
          .data( "item.autocomplete", item )
          .append( $( "<a></a>" ).text( item.label ) )
          .appendTo( ul );
      }
    },

    // This stops the input box from being cleared when traversing the menu.

    _move: function( direction, event ) {
      if ( !this.menu.element.is(":visible") ) {
        this.search( null, event );
        return;
      }
      if ( this.menu.first() && /^previous/.test(direction) ||
          this.menu.last() && /^next/.test(direction) ) {
        this.menu.deactivate();
        return;
      }
      this.menu[ direction ]( event );
    },

    search: function(value, event) {

      var contents = this.element.val();
      var cursorPos = this.getCursor();
      this.contents = contents;
      this.cursorPos = cursorPos;
      var check_contents = contents.substring(contents.lastIndexOf(this.options.trigger) - 1, cursorPos);
      var regex = new RegExp('\\B\\'+this.options.trigger+'([\\w\\-]+)');

      if (contents.indexOf(this.options.trigger) >= 0 && check_contents.match(regex)) {

        // Get the characters following the trigger and before the cursor position.
        // Get the contents up to the cursortPos first then get the lastIndexOf the trigger to find the search term.

        contents = contents.substring(0, cursorPos);
        var term = contents.substring(contents.lastIndexOf(this.options.trigger) + 1, contents.length);

        // Only query the server if we have a term and we haven't received a null response.
        // First check the current query to see if it already returned a null response.

        if(this.stopIndex == contents.lastIndexOf(this.options.trigger) && term.length > this.stopLength) { term = ''; }
      
        if(term.length > 0) {
          // Updates the hidden field to check if a name was removed so that we can put them back in the list.
          this.updateHidden();
          return this._search(term);
        }
        else this.close();
      } 
    },

    // Slightly altered the default ajax call to stop querying after the search produced no results.
    // This is to prevent unnecessary querying.

    _initSource: function() {
      var self = this, array, url;
      if ( $.isArray(this.options.source) ) {
        array = this.options.source;
        this.source = function( request, response ) {
          response( $.ui.autocomplete.filter(array, request.term) );
        };
      } else if ( typeof this.options.source === "string" ) {
        url = this.options.source;
        this.source = function( request, response ) {
          if ( self.xhr ) {
            self.xhr.abort();
          }
          self.xhr = $.ajax({
            url: url,
            data: request,
            dataType: 'json',
            success: function(data) {
              if(data != null) {
                response($.map(data, function(item) {
                  if (typeof item === "string") {
                    label = item;
                  }
                  else {
                    label = item.label;
                  }
                  // If the item has already been selected don't re-include it.
                  if(!self.id_map[label] || self.options.allowDuplicates) {
                    return item
                  }
                }));
                self.stopLength = -1;
                self.stopIndex = -1;
              }
              else {
                // No results, record length of string and stop querying unless the length decreases
                self.stopLength = request.term.length;
                self.stopIndex = self.contents.lastIndexOf(self.options.trigger);
                self.close();
              }
            }
          });
        };
      } else {
        this.source = this.options.source;
      }
    },

    destroy: function() {
      $.Widget.prototype.destroy.call(this);
    },

    // Gets the position of the cursor in the input box.

    getCursor: function() {
      var i = this.element[0];

      if(i.selectionStart) {
        return i.selectionStart;
      }
      else if(i.ownerDocument.selection) {
        var range = i.ownerDocument.selection.createRange();
        if(!range) return 0;
        var textrange = i.createTextRange();
        var textrange2 = textrange.duplicate();

        textrange.moveToBookmark(range.getBookmark());
        textrange2.setEndPoint('EndToStart', textrange);
        return textrange2.text.length;
      }
    },

    // Populates the hidden field with the contents of the entry box but with 
    // ID's instead of usernames.  Better for storage.

    updateHidden: function() {
      var trigger = this.options.trigger;
      var top = this.element.scrollTop();
      var contents = this.element.val();
      for(var key in this.id_map) {
        var find = trigger+key;
        find = find.replace(/[^a-zA-Z 0-9@]+/g,'\\$&');
        var regex = new RegExp(find, "g");
        var old_contents = contents;
        contents = contents.replace(regex, trigger+'['+this.id_map[key]+']');
        if(old_contents == contents) delete this.id_map[key];
      }
      $(this.options.hidden).val(contents);
      this.element.scrollTop(top);
    }

  }));  
})( jQuery, window , document );