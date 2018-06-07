window.Utility ||= {}
class Utility.AjaxModal
  url: ""
  modal: ""
  dialogClass: ""

  constructor: (url, dialogClass)->
    @url = url
    @dialogClass = dialogClass

  load: (callback)->
    @modal = @createModal()
    that = @
    $('body').modalmanager('loading');
    $.get(@url).done (data, status, xhr) =>
      @modal.find('.modal-content').html data
      that.modal.modal('show')
      callback(that.modal) if callback?
      $('body').modalmanager('removeLoading');

  body: ->
    @modal

  createModal: ->
    $('#ajax-modal').remove() if $('#ajax-modal').length > 0

    dialog = $("<div />",
      id: "ajax-modal"
      class: "modal fade"
      tabindex: "-1"
      role: "dialog"
      "aria-labelledby": "ajax-modal"
      "aria-hidden": "true"
      'data-backdrop': "static"
      'data-keyboard': "false"
    ).html('<div class="modal-dialog" role="document"><div class="modal-content"></div></div>')

    dialog.appendTo "body"
    $('#ajax-modal')


  
