class App.WbwTexts extends App.Base
  index: =>
    $('select.form-control').chosen(allow_single_deselect: true)
    return

  edit: =>
    new Utility.ArabicKeyboard()
    return
