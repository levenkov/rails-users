json.user do
  json.extract! current_user, :id, :email, :name, :role
  json.avatar_url current_user.avatar.attached? ? request.base_url + url_for(current_user.avatar) : nil
end
