ActiveAdmin.register UserProject do
  menu false

  permit_params do
    [:user_id, :resource_content_id, :description]
  end
end
