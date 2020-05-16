module HomeHelper

  def content_tag_if(add_tag, tag_name, content)
    if add_tag
      content_tag tag_name, content
    else
      content
    end
  end
end
