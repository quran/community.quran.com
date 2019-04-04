class App.WbwTranslations extends App.Base
  afterAction: (action) =>
    $(document).on "click", '.ajax-modal, [data-toggle="ajax-modal"]', (e) ->
      e.preventDefault()
      e.stopImmediatePropagation()
      modal = new Utility.AjaxModal($(@).data('url'), $(@).data('modal-class'))
      modal.load ->
        $.rails.enableElement($(e.target));
    return

  new: =>
    new Utility.ArabicKeyboard()
    return

  edit: =>
    new Utility.ArabicKeyboard()
    return