class App.ArabicTransliterations extends App.Base

  beforeAction: (action) =>
    return


  afterAction: (action) =>
    return


  index: =>
    $('select.form-control').chosen()
    return


  show: =>
    $('select.form-control').chosen()
    predictedPage = parseInt(Utility.RailsVars.page_number)
    window.pageZoomer = new Utility.ImageZoomer("http://static.quran.com/urdu_transliteration/#{predictedPage}.jpg")

    return


  new: =>
    $('select.form-control').chosen()
    predictedPage = parseInt(Utility.RailsVars.page_number)
    window.pageZoomer = new Utility.ImageZoomer("http://static.quran.com/urdu_transliteration/#{predictedPage}.jpg")

    if Utility.RailsVars.page_zoom?
      window.pageZoomer.transform(Utility.RailsVars.page_pos_x, Utility.RailsVars.page_pos_y)
      window.pageZoomer.zoom(Utility.RailsVars.page_zoom)
      
    $("#change_page").on "change", @jumpToPage
    new Utility.ArabicKeyboard()
    return

  edit: =>
    return

  jumpToPage: ->
    $(".word-page").val($(@).val())
    pageZoomer.changeImage("http://static.quran.com/urdu_transliteration/#{$(@).val()}.jpg")
