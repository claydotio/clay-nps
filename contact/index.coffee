z = require 'zorium'
Dialog = require 'zorium-paper/dialog'
Button = require 'zorium-paper/button'
colors = require 'zorium-paper/colors.json'

CLAY_BLUE = '#0060ff'

module.exports = class Contact
  constructor: ->
    @$dialog = new Dialog()

    @$submitButton = new Button()
    @$cancelButton = new Button()

  render: ({onSubmit, onCancel}) =>
    z '.cn-contact',
      z @$dialog,
        title: 'We want to hear from you'
        $content:
          z '.cn-nps_dialog', {
            style:
              maxWidth: "#{window?.innerWidth - 64}px"
          },
            'Chat with us on Kik and let us know what you
            think of the game.'
        actions: [
          {
            $el: z @$cancelButton,
              text: 'not now'
              isShort: true
              colors:
                ink: CLAY_BLUE
              onclick: ->
                onCancel?()
          }
          {
            $el: z @$submitButton,
              text: 'sure!'
              isShort: true
              colors:
                ink: CLAY_BLUE
              onclick: ->
                onSubmit?()
          }
        ]
