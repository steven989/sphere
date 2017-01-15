class ApplicationMailer < ActionMailer::Base
  default from: "Sphere App #{ENV['SYSTEM_EMAIL']}"
  layout 'mailer'
end
