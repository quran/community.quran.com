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
    predictedPage = parseInt(Utility.RailsVars.page_number*1.6666)
    new Utility.ImageZoomer("http://static.quran.com/urdu_transliteration/#{predictedPage}.jpg")
    
    return


  edit: =>
    return
