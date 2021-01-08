class RenameBrexitCheckerAppName < ActiveRecord::Migration[6.0]
  def up
    Doorkeeper::Application.find_by(uid: "r0JFn7O_750_W4i-IjQpMA8j970dNchgKbJ7ZGz0ozI")&.update!(name: "Brexit checker (Demonstration App)")
    Doorkeeper::Application.find_by(uid: "01zNRqAHzpPv1biZ4NOOpFyV568uYlVPhycwfzicWUE")&.update!(name: "Brexit checker (Integration)")
    Doorkeeper::Application.find_by(uid: "ZAHfbCrOLCjvWQNsgal-i79UavGkytB_093jNzRPJR0")&.update!(name: "Brexit checker (Staging)")
    Doorkeeper::Application.find_by(uid: "20VwoXiasGyUE7nS3M9l9TBjew8Lid_qCd6eSmSXuQU")&.update!(name: "Brexit checker")
  end
end
