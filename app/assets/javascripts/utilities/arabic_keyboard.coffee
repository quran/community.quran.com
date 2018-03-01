class Utility.ArabicKeyboard
  constructor:  ->
    $(document).on 'click', 'textarea.transliteration', ->
      alert("d");
      setTimeout (->
        alert('done')
        $('.ui-keyboard').draggable()
      ), 2000
      
    $('textarea.transliteration').keyboard(
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
          "َ ً ُ ٌ ّ ْ ِ ٍ ء ي ئ {bksp}",
          "{tab} ك(Q) ّ(W) ے(Y) ث(T)",
          "{lock} آ(A) ص(S) ض(D) ق(F) غ(G) ه(H) ج(J) خ(K) إ(L) : \" {enter}"
          "{shift} خ(K) > < / {shift}",
          "{accept} {alt} {space}"
        ],
        'normal': [
          "َ ً ُ ٌ ّ ْ ِ ٍ ء ي ئ {bksp}",
          "{tab} ق(q) و(w) ع(e) ر(r) ت(t) ے(y) ِ(u) ي(i) ُ(o) ّ(p) [ ] \ ",
          "{lock} ا(a) س(s) د(d) ف(f) ع(g) ح(h) ج(j) ك(k) ل(l) ؛(;) '(') {enter}",
          "{shift} ز(z) ش(x) چ(c) ْ(v) ب(b) ن(n) م(m) ْ(,) . / {shift}",
          "{cancel} {alt} {space} {accept}"
        ],
        'alt': [
          "ْ ِ ٌ َ ً ُ ",
          "ء ي ئ ؤ ة إ أ آ",
          "{alt} {space} "
        ]
        
      }
    ).addTyping(showTyping:true).previewKeyset()
    
