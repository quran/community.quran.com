class Utility.ArabicKeyboard
  constructor:  ->
    $('input.transliteration').keyboard(
      autoAccept: false
      stayOpen: true
      layout: 'custom'
      rtl: true
      language: ['en']
      closeByClickEvent: false
      enterNavigation: false
      usePreview: true
      css:
        input: 'form-control'
        container: 'center-block dropdown-menu'
        buttonDefault: 'btn btn-default'
        buttonHover: 'btn-primary'
        buttonAction: 'active'
        buttonDisabled: 'disabled'
      customLayout: {
        'custom' : [
          '',
          '{tab} \u0636(c) \u0635 \u062b \u0642 \u0641 \u063a \u0639 \u0647 \u062e \u062d \u062c \u062f',
          '{lock} \u0634 \u0633 \u064a \u0628 \u0644 \u0627 \u062a \u0646 \u0645 \u0643 \u0637 \u0630 {enter}',
          '{shift} \u0640 \u0626 \u0621 \u0624 \u0631 \ufefb \u0649 \u0629 \u0648 \u0632 \u0638 {shift}',
          '{accept} {alt} {space} {alt} {custom}'
        ],
        'shift' : [
          "~ ! @ # $ \u066a ^ \u06d6 \u066d ) ( _ + {bksp}",
          "{tab} \u0638 \u0636 \u0630 \u0688 \u062b \u0651 \u06c3 \u0640 \u0686 \u062e } { |",
          "{lock} \u0698 \u0632 \u0691 \u06ba \u06c2 \u0621 \u0622 \u06af \u064a : \" {enter}",
          "{shift} | \u200d \u200c \u06d3 \u200e \u0624 \u0626 \u200f > < / {shift}",
          "{accept} {alt} {space}"
        ],
        'normal': [
          "؏(~) \u0661 \u0662 \u0663 \u0664 \u0665 \u0666 \u0667 \u0668 \u0669 \u0660 - = {bksp}",
          "{tab} ق(q) و(w) ع(e) ر(r) ت(t) ے(y) ِ(u) َ(i) ُ(o) ّ(p) [ ] \ ",
          "{lock} ا(a) س(s) د(d) ف(f) ع(g) ح(h) ج(j) ك(k) ل(l) ؛(;) '(') {enter}",
          "{shift} ز(z) خ(x) چ(c) ڢ(v) ب(b) ن(n) م(m) ْ(,) . / {shift}",
          "{cancel} {alt} {space} {accept}"
        ],
        'zab': [
          "A"
        ]
        
      }
    ).addTyping(showTyping:true).previewKeyset()

    setTimeout (->
      $('.ui-keyboard').draggable()
    ), 2000
