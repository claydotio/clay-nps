z = require 'zorium'
_ = require 'lodash'
Rx = require 'rx-lite'
Environment = require 'clay-environment'
Dialog = require 'zorium-paper/dialog'
Input = require 'zorium-paper/input'
Button = require 'zorium-paper/button'
colors = require 'zorium-paper/colors.json'
log = require 'loga'

if window?
  require './index.styl'

NPS_MIN = 0
NPS_MAX = 10
NPS_DEFAULT = 5
CLAY_BLUE = '#0060ff'
MIN_VISITS_TO_SHOW = 4

# TODO: rewrite

module.exports = class Nps
  constructor: ({@model}) ->
    @$dialog = new Dialog()

    @npsValue = new Rx.BehaviorSubject NPS_DEFAULT
    @commentValue = new Rx.BehaviorSubject ''
    @emailValue = new Rx.BehaviorSubject ''

    @$commentInput = new Input
      value: @commentValue
    @$emailInput = new Input
      value: @emailValue

    @$submitButton = new Button()
    @$cancelButton = new Button()

    @state = z.state
      npsValue: @npsValue
      commentValue: @commentValue
      emailValue: @emailValue
      npsSet: false
      isLoading: false
      isVisible: localStorage? and not localStorage['hasGivenFeedback'] and
        not localStorage['hasSkippedFeedback'] and
        localStorage['visitCount'] >= MIN_VISITS_TO_SHOW
      step: 'prompt'

    if localStorage? and not localStorage?['visitCount']
      localStorage['visitCount'] = 1
    else if localStorage?
      localStorage['visitCount'] = parseInt(localStorage['visitCount']) + 1

  shouldBeShown: =>
    {isVisible} = @state.getValue()
    isVisible

  submitNps: ({gameKey}) =>
    {isLoading, npsValue, commentValue, emailValue} = @state.getValue()

    if isLoading
      return

    unless npsValue >= 0 and npsValue <= 10
      return @npsError.onNext 'Must be a number between 0 and 10'

    @state.set isLoading: true
    localStorage?['hasGivenFeedback'] = '1'

    @model.user?.emit? 'nps', {
      fields:
        value: parseInt npsValue
    }
    .catch log.trace

    @model.nps.create {
      score: npsValue
      comment: commentValue
      email: emailValue
      gameKey: gameKey
    }
    .then =>
      @state.set isLoading: false

  render: ({gameName, gameKey, onSubmit, onCancel, onRate}) =>
    {npsValue, isLoading, step} = @state.getValue()

    z '.cn-nps',
      if step is 'prompt'
        z @$dialog,
          title: 'We\'d love to get your feedback'
          $content:
            z '.cn-nps_dialog', {
              style:
                maxWidth: "#{Math.min(240, window?.innerWidth - 64)}px"
            },
              'Loving the game? Have a suggestion? Your feedback
              helps shape our games.'
          actions: [
            {
              $el: z @$cancelButton,
                text: 'not now'
                isShort: true
                colors:
                  ink: CLAY_BLUE
                onclick: =>
                  localStorage?['hasSkippedFeedback'] = '1'
                  @state.set isVisible: false
                  onCancel?()
            }
            {
              $el: z @$submitButton,
                text: 'sure'
                isShort: true
                colors:
                  ink: CLAY_BLUE
                onclick: =>
                  @state.set step: 'nps'
            }
          ]
      else if step is 'rate'
        z @$dialog,
          title: 'Rate Kitten Cards'
          $content:
            z '.cn-nps_dialog', {
              style:
                maxWidth: "#{Math.min(240, window?.innerWidth - 64)}px"
            },
              z 'p', 'Thanks for your feedback!'
              z 'p', 'We\'d love it if you could give Kitten
                      Cards a rating in the app store :)'
              z 'p', 'More ratings helps us a lot!'
          actions: [
            {
              $el: z @$cancelButton,
                text: 'not now'
                isShort: true
                colors:
                  ink: CLAY_BLUE
                onclick: =>
                  @state.set isVisible: false
                  onCancel?()
            }
            {
              $el: z @$submitButton,
                text: 'sure'
                isShort: true
                colors:
                  ink: CLAY_BLUE
                onclick: =>
                  @state.set isVisible: false
                  onRate()
            }
          ]
      else
        z @$dialog,
          title: ''
          $content:
            z '.cn-nps_dialog', {
              style:
                maxWidth: "#{Math.min(240, window?.innerWidth - 64)}px"
            },
              z 'label.label',
                z '.text', "How would you rate #{gameName}?"
                z '.range-container',
                  z 'input.range',
                    type: 'range'
                    min: NPS_MIN
                    max: NPS_MAX
                    value: npsValue
                    onchange: (e) =>
                      @npsValue.onNext e.currentTarget.value
                      @state.set npsSet: true
                z '.numbers',
                  _.map _.range(NPS_MIN, NPS_MAX + 1), (number) =>
                    z '.number', {
                      onclick: =>
                        @npsValue.onNext number
                        @state.set npsSet: true
                    },
                      number
              z 'label.label',
                z '.text', 'comment or suggestions?'
                z @$commentInput,
                  hintText: 'Tell us what you think'
                  colors:
                    c500: colors.$grey900

              z 'label.label',
                z '.text', 'In case we need to follow up'
                z @$emailInput,
                  hintText: 'Email address'
                  colors:
                    c500: colors.$grey900
          actions: [
            {
              $el: z @$cancelButton,
                text: 'cancel'
                isShort: true
                colors:
                  ink: CLAY_BLUE
                onclick: =>
                  localStorage?['hasSkippedFeedback'] = '1'
                  @state.set isVisible: false
                  onCancel?()
            }
            {
              $el: z @$submitButton,
                text: if isLoading then 'loading...' else 'submit'
                isShort: true
                colors:
                  ink: CLAY_BLUE
                onclick: =>
                  @submitNps {gameKey}

                  if npsValue >= 8 and onRate and Environment.isGameApp(gameKey)
                    @state.set step: 'rate'
                  else
                    @state.set isVisible: false
                  onSubmit?()
            }
          ]
