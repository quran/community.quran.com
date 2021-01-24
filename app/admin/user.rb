ActiveAdmin.register User do
  permit_params :email, :first_name, :last_name, :password, :approved, on: :user

  index do
    selectable_column
    id_column
    column :email
    column :first_name
    column :last_name
    column :approved

    column :created_at
    actions
  end

  filter :first_name
  filter :email
  filter :approved
  filter :created_at

  form do |f|
    f.inputs "User Details" do
      f.input :first_name
      f.input :last_name
      f.input :email
      f.input :password, required: false
      f.input :approved
    end
    f.actions
  end

  sidebar 'Projects', only: :show do
    div do
      render 'shared/user_project_form'
    end

    table do
      thead do
        td :id
        td :name
      end

      tbody do
        resource.user_projects.each do |p|
          tr do
            td p.resource_content_id
            td link_to(p.resource_content.name, [:admin, p.resource_content])
          end
        end
      end
    end
  end

  controller do
    def update
      attributes = permitted_params['user']
      attributes.delete(:password) if attributes[:password].blank?
      if resource.update(attributes)
        redirect_to [:admin, resource], notice: 'Updated successfully'
      else
        render action: :edit
      end
    end
  end
end