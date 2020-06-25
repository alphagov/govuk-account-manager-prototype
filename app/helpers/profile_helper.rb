module ProfileHelper
  def user_details(user)
    [
      {
        field: "Email",
        value: user.email,
      },
      {
        field: "Name",
        value: user.first_name,
      },
    ].reject { |detail| detail.fetch(:value).blank? }
  end
end
