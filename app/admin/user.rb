ActiveAdmin.register User do
  permit_params :email, :first_name, :last_name, :password, on: :user
  
  action_item :confirm, only: :show do
    link_to "Confirm account", confirm_admin_user_path(resource), method: :put, data: { confirm: "Are you sure?" } unless resource.confirmed?
  end

  member_action :confirm, method: 'put' do
    resource.confirm
    
    redirect_to [:admin, resource], notice: 'account confirmed successfully!'
  end
  
  index do
    selectable_column
    id_column
    column :email
    column :first_name
    column :last_name

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
      f.input :password
      f.input :approved
    end
    f.actions
  end
 end
