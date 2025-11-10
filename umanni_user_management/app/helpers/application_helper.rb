module ApplicationHelper
  include Pagy::Frontend

  def flash_class(level)
    case level.to_sym
    when :notice then "alert-info"
    when :success then "alert-success"
    when :error, :alert then "alert-danger"
    when :warning then "alert-warning"
    else "alert-info"
    end
  end

  def user_avatar_url(user, size: 150)
    if user.avatar_image.attached?
      url_for(user.avatar_image)
    else
      "https://ui-avatars.com/api/?name=#{user.full_name.gsub(' ', '+')}&size=#{size}&background=random"
    end
  end
end
