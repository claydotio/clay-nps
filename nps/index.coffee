z = require 'zorium'
_ = require 'lodash'
Rx = require 'rx-lite'
Dialog = require 'zorium-paper/dialog'
Input = require 'zorium-paper/input'
Button = require 'zorium-paper/button'
colors = require 'zorium-paper/colors.json'

if window?
  require './index.styl'

NPS_MIN = 0
NPS_MAX = 10
NPS_DEFAULT = 5
CLAY_BLUE = '#0060ff'
MIN_VISITS_TO_SHOW = 4

module.exports = class Nps
  constructor: ({@model}) ->
    @$dialog = new Dialog()

    @npsValue = new Rx.BehaviorSubject NPS_DEFAULT
    @commentsValue = new Rx.BehaviorSubject ''
    @emailValue = new Rx.BehaviorSubject ''

    @$commentsInput = new Input
      value: @commentsValue
    @$emailInput = new Input
      value: @emailValue

    @$submitButton = new Button()
    @$cancelButton = new Button()

    @state = z.state
      npsValue: @npsValue
      commentsValue: @commentsValue
      emailValue: @emailValue
      npsSet: false
      isLoading: false
      isPrompt: true

    if localStorage and not localStorage?['visitCount']
      localStorage['visitCount'] = 1
    else if localStorage
      localStorage['visitCount'] = parseInt(localStorage['visitCount']) + 1

  shouldBeShown: ->
    localStorage? and not localStorage['hasGivenFeedback'] and
      not localStorage['hasSkippedFeedback'] and
      localStorage['visitCount'] >= MIN_VISITS_TO_SHOW

  submitNps: ({gameKey}) =>
    {isLoading, npsValue, commentsValue, emailValue} = @state.getValue()

    if isLoading
      return

    unless npsValue >= 0 and npsValue <= 10
      return @npsError.onNext 'Must be a number between 0 and 10'

    @state.set isLoading: true
    localStorage?['hasGivenFeedback'] = '1'

    @model.nps.create {
      score: npsValue
      comments: commentsValue
      email: emailValue
      gameKey: gameKey
    }
    .then =>
      @state.set isLoading: false

  render: ({gameName, gameKey, onSubmit, onCancel}) =>
    {npsValue, isLoading, isPrompt} = @state.getValue()

    z '.cn-nps',
      if isPrompt
        z @$dialog,
          title: 'We\'d love to get your feedback'
          $content:
            z '.cn-nps_dialog', {
              style:
                maxWidth: "#{window?.innerWidth - 64}px"
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
                onclick: ->
                  localStorage?['hasSkippedFeedback'] = '1'
                  onCancel?()
            }
            {
              $el: z @$submitButton,
                text: 'sure'
                isShort: true
                colors:
                  ink: CLAY_BLUE
                onclick: =>
                  @state.set isPrompt: false
            }
          ]
      else
        z @$dialog,
          title: ''
          $content:
            z '.cn-nps_dialog',
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
                z '.text', 'Comments or suggestions?'
                z @$commentsInput,
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
                onclick: ->
                  localStorage?['hasSkippedFeedback'] = '1'
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
                  onSubmit?()
            }
          ]