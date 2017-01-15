class ApplicationMailer < ActionMailer::Base
  default from: "Sphere #{ENV['SYSTEM_EMAIL']}"
  layout 'mailer'
end
