ActiveAdmin.register ImportantNote do
  menu parent: "Notes"
  actions :all, except: :destroy

  filter :label
  filter :user

  filter :verse_id, as: :searchable_select,
         ajax: {resource: Verse}

  filter :word_id, as: :searchable_select,
         ajax: {resource: Word}

  permit_params do
    [:title, :text, :label, :chapter_id, :verse_id, :word_id]
  end

  index do
    column :id
    column :title
    column :label

    column :verse_id
    column :word_id

    actions
  end

  show do
    attributes_table do
      row :id
      row :admin_user do
        resource.admin_user.to_s
      end
      row :verse
      row :word
      row :title
      row :text do |resource|
        div do
          resource.text.to_s.html_safe
        end
      end
      row :created_at
      row :updated_at
    end

    active_admin_comments
  end

  form do |f|
    f.inputs "Notes Detail" do
      f.input :verse,
              as: :searchable_select,
              ajax: {resource: Verse}

      f.input :word,
              as: :searchable_select,
              ajax: {resource: Word}

      f.input :label

      toolbar = [
          ['bold', 'italic', 'underline', 'strike', 'size'],
          ['link', 'blockquote', 'code-block'],
          [{'script': 'sub'}, {'script': 'super'}],
          [{'align': []}, {list: 'ordered'}, {list: 'bullet'}],
          [{'color': []}, {'background': []}],
          [header: [], font: []],
          ['clean'],
      ]

      f.input :text, as: :quill_editor, input_html: {
          data: {
              options:
                  {
                      modules: {
                          toolbar: toolbar
                      }
                  }
          }
      }

    end
    f.actions
  end

  controller do
    def create
      attributes = permitted_params['important_note']
      note = ImportantNote.new(attributes)
      note.admin_user = current_admin_user

      if note.save
        redirect_to [:admin, note], notice: 'Note created successfully'
      else
        render action: :new
      end
    end
  end
end
