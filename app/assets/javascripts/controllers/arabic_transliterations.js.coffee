class App.ArabicTransliterations extends App.Base

  new: =>
    $('select.form-control').chosen()
    predictedPage = parseInt(Utility.RailsVars.page_number)
    window.pageZoomer = new Utility.ImageZoomer("http://static.quran.com/urdu_transliteration/#{predictedPage}.jpg")

    #if Utility.RailsVars.page_zoom?
    #  window.pageZoomer.transform(Utility.RailsVars.page_pos_x, Utility.RailsVars.page_pos_y)
    #  window.pageZoomer.zoom(Utility.RailsVars.page_zoom)

    $("#change_page").on "change", @jumpToPage
    new Utility.ArabicKeyboard()


  jumpToPage: ->
    $(".word-page").val($(@).val())
    pageZoomer.changeImage("http://static.quran.com/urdu_transliteration/#{$(@).val()}.jpg")
