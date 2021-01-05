RSpec.describe BannedPassword do
  context "#import_from_ncsc" do
    let(:response) do
      "***  Please note that this file contains the top 100,000 passwords from Troy Huntâ€™s Have I Been Pwned (https://haveibeenpwned.com) data set.
***  If you see a password that you use in this list you should change it immediately.
***  This blog explains why you should do this, and answers some common questions about password blacklists: https://www.ncsc.gov.uk/blog-post/passwords-passwords

--

123456789
password
"
    end

    before do
      stub_request(:get, "https://ncsc.gov.uk/static-assets/documents/PwnedPasswordsTop100k.txt")
        .to_return(status: 200, body: response)
    end

    it "doesn't treat the header lines as passwords" do
      described_class.import_from_ncsc

      expect(described_class.pluck(:password)).to eq(%w[123456789 password])
    end
  end

  context "#import_list" do
    it "imports the passwords" do
      passwords = %w[breadbread foobarbaz onetwothreefourfivesixseven 1234567890]

      described_class.import_list(passwords)

      passwords.each do |password|
        expect(described_class.is_password_banned?(password)).to be(true)
      end
    end

    it "discards any previous denylist" do
      old_passwords = %w[breadbread foobarbaz]
      new_passwords = %w[onetwothreefourfivesixseven 1234567890]

      described_class.import_list(old_passwords)
      described_class.import_list(new_passwords)

      old_passwords.each do |password|
        expect(described_class.is_password_banned?(password)).to be(false)
      end
      new_passwords.each do |password|
        expect(described_class.is_password_banned?(password)).to be(true)
      end
    end

    it "discards passwords which don't meet the Devise length criterion" do
      passwords = %w[1 breadbread 2 foobarbaz 3 onetwothreefourfivesixseven 456 1234567890]

      described_class.import_list(passwords)

      passwords.each do |password|
        expect(described_class.is_password_banned?(password)).to be(Devise.password_length.include?(password.length))
      end
    end
  end

  context "#is_password_banned?" do
    let(:passwords) { %w[FOOFOOFOOFOO BArBArBArBAr BazBazBazBaz baTbaTbaTbaT qUXqUXqUXqUX] }

    before { described_class.import_list passwords }

    it "does a case-insensitive comparison" do
      passwords.each do |password|
        expect(described_class.is_password_banned?(password.downcase)).to be(true)
        expect(described_class.is_password_banned?(password.upcase)).to be(true)
      end
    end

    it "allows a nil password" do
      expect(described_class.is_password_banned?(nil)).to be(false)
    end
  end
end
