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

  filter :email
  filter :created_at

  form do |f|
    f.inputs "User Details" do
      f.input :first_name
      f.input :last_name
      f.input :email
      f.input :password, optional: true
      f.input :approved
    end
    f.actions
  end
end
