TAJWEED_RULE_DESCRIPTION = {
  ham_wasl: "Hamzat ul Wasl",
  slnt: "Silent",
  laam_shamsiyah: "Lam Shamsiyyah",
  madda_normal: "Normal Prolongation: 2 Vowels",
  madda_permissible: "Permissible Prolongation: 2, 4, 6 Vowels",
  madda_necessary: "Necessary Prolongation: 6 Vowels",
  madda_obligatory: "Obligatory Prolongation: 4-5 Vowels",
  qalaqah: "Qalaqah",
  ikhafa_shafawi: "Ikhafa' Shafawi - With Meem",
  ikhafa: "Ikhafa'",
  iqlab: "Iqlab",
  idgham_shafawi: "Idgham Shafawi - With Meem",
  idgham_ghunnah: "Idgham - With Ghunnah",
  idgham_wo_ghunnah: "Idgham - Without Ghunnah",
  idgham_mutajanisayn: "Idgham - Mutajanisayn",
  idgham_mutaqaribayn: "Idgham - Mutaqaribayn",
  ghunnah: "Ghunnah: 2 Vowels"
}

TAJWEED_RULES = [
  "ham_wasl",
  "slnt",
  "laam_shamsiyah",
  "madda_normal",
  "madda_permissible",
  "madda_necessary",
  "madda_obligatory",
  "qalaqah",
  "ikhafa_shafawi",
  "ikhafa",
  "iqlab",
  "idgham_shafawi",
  "idgham_ghunnah",
  "idgham_wo_ghunnah",
  "idgham_mutajanisayn",
  "idgham_mutaqaribayn",
  "ghunnah"
]

bindTajweedTooltip = function (dom){
  TAJWEED_RULES.forEach (function (value) {
      dom.find(".#{name}").attr('title', TAJWEED_RULE_DESCRIPTION[name])
  })
}

$(document).on('ready page:load turbolinks:load', function () {
// In order for index scopes to overflow properly onto the next line, we have
// to manually set its width based on the width of the batch action button.
    var tajweedDom = $(".row-uthmani_simple_tajweed")
    if(tajweedDom.length > 0)
        bindTajweedTooltip(tajweedDom);

    if($("#arabic_transliteration_text").length)
        new Utility.ArabicKeyboard()

    var play_btns = $(".play")
    if (play_btns.length){
        play_btns.click(function (e) {
            e.preventDefault()
            audio = $(this).closest("td").find(".audio");
            audio.attr("src", audio.data("url"))
            audio[0].play()
        })
    }

    $('.mark-btn').on('ajax:success', function(e, response){
        $(e.target).closest('div').html(response)
    })

    var footnote = $('.translation sup')
    if (footnote.length){
        footnote.click(function(e) {
            e.preventDefault()
            e.stopImmediatePropagation()
            var footnoteId = $(this).attr('foot_note')
            $.get("/admin/foot_notes/#{footnoteId}.json", {}).then(function (data) {
                $("<div>").html(data.text).addClass("#{data.language_name} footnote-dialog").appendTo("body").dialog()
            })
        })
    }
})






