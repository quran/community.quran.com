module HomeHelper

  def content_tag_if(add_tag, tag_name, content)
    if add_tag
      content_tag tag_name, content
    else
      content
    end
  end

  def diff_text(text1, text2)
    diff = `git diff $(echo #{text1} | git hash-object -w --stdin) $(echo #{text2} | git hash-object -w --stdin)  --word-diff`

    if diff.present?
      result = diff.split('@@').last.strip

      [result, result.gsub(/\[-/, ' <del> ').gsub(/-\]/, ' </del> ').gsub(/\{\+/, ' <ins> ').gsub(/\+\}/, ' </ins> ')].join("</br></br/>")
    else
      'No difference found'
    end
  end
end
