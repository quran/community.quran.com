class App.WbwTexts extends App.Base
  index: =>
    $('select.form-control').chosen()
    return

  edit: =>
    new Utility.ArabicKeyboard()
    return
