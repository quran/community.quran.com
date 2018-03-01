class App.ArabicTransliterations extends App.Base

  beforeAction: (action) =>
    return


  afterAction: (action) =>
    return


  index: =>
    $('select.form-control').chosen()
    return


  show: =>
    return


  new: =>
    $('select.form-control').chosen()
    predictedPage = parseInt(Utility.RailsVars.page_number)
    window.pageZoomer = new Utility.ImageZoomer("http://static.quran.com/urdu_transliteration/#{predictedPage}.jpg")
    $("#change_page").on "change", @jumpToPage
    new Utility.ArabicKeyboard()
    return

  edit: =>
    return

  jumpToPage: ->
    pageZoomer.changeImage("http://static.quran.com/urdu_transliteration/#{$(@).val()}.jpg")
