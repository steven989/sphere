class SystemMailer < ApplicationMailer

  def scheduled_task_report(report)
    @report = report
    mail(
      to: ENV['ADMIN_EMAIL'], 
      subject: 'Scheduled task report'
      ) do |format|
        format.text
    end 
  end

end
