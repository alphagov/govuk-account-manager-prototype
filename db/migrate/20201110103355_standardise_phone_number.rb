class StandardisePhoneNumber < ActiveRecord::Migration[6.0]
  def up
    User.all.each do |user|
      if user.phone
        standardised_phone = TelephoneNumber.parse(user.phone, :gb).e164_number
        user.update!(phone: standardised_phone)
      end

      if user.unconfirmed_phone
        standardised_phone = TelephoneNumber.parse(user.unconfirmed_phone, :gb).e164_number
        user.update!(unconfirmed_phone: standardised_phone)
      end
    end

    RegistrationState.all.each do |registration|
      if registration.phone
        standardised_phone = TelephoneNumber.parse(registration.phone, :gb).e164_number
        registration.update!(phone: standardised_phone)
      end
    end
  end
end
