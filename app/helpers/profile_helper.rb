module ProfileHelper
  def user_details(user)
    [
      {
        field: "Email",
        value: user.email,
      },
    ].reject { |detail| detail.fetch(:value).blank? }
  end
end
