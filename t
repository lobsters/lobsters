import { Application } from '@ember/application';

Application.initializer({
  name: 'tab-order',
  initialize: function(container, application) {
    const $buttons = $('button, a');
    const tabIndex = 0;

    $buttons.each(function() {
      const $button = $(this);
      $button.attr('tabindex', tabIndex);
      tabIndex++;
    });
  }
});