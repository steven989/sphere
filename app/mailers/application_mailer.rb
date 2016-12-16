class ApplicationMailer < ActionMailer::Base
  default from: ENV['SYSTEM_EMAIL']
  layout 'mailer'
end
