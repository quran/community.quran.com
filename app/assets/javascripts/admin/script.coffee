$(document).on 'ready page:load turbolinks:load', ->
# In order for index scopes to overflow properly onto the next line, we have
# to manually set its width based on the width of the batch action button.
  if (play_btns = $(".play")).length
    play_btns.click (e)->
      e.preventDefault()
      audio = $(this).closest("td").find(".audio");
      audio.attr("src", audio.data("url"))
      audio[0].play()

  $('.mark-btn').on 'ajax:success', (e, response) ->
    $(@).closest('div').html(response)

  if (footnote = $('.translation sub')).length
    footnote.click (e)->
      e.preventDefault()
      e.stopImmediatePropagation()
      footnoteId = $(this).attr('foot_note')
      $.get("/admin/foot_notes/#{footnoteId}.json").success (data, status) =>
        $("<div>").html(data.text).addClass("#{data.language_name} footnote-dialog").appendTo("body").dialog()
