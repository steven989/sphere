class ScheduledTask < ActiveRecord::Base
    
    def self.run_all_tasks(force_all=false)
        report = []

        sch_tasks = force_all ? ScheduledTask.all : ScheduledTask.where{((day_of_week == Date.today.wday) & (hour_of_day == Time.now.hour)) | ((day_of_week == nil) & (hour_of_day == Time.now.hour)) | ((day_of_week == nil) & (hour_of_day == nil)) }
        if sch_tasks.length > 0
            sch_tasks.each do |t|
                report.push(t.run)
            end
            SystemMailer.scheduled_task_report(report).deliver if report.select {|r| !r[:status] }.length > 0
        else
            puts "No schedueld job right now"
        end 
    end

    def run
        begin
            if self.parameter_1.blank?
                Rake::Task[self.task_name].reenable
                Rake::Task[self.task_name].invoke
                Rake::Task[self.task_name].reenable
            else
                if self.parameter_2.blank?
                    parameter_1 = self.parameter_1_type == "integer" ? self.parameter_1.to_i : self.parameter_1
                    Rake::Task[self.task_name].reenable
                    Rake::Task[self.task_name].invoke(parameter_1)
                    Rake::Task[self.task_name].reenable
                else 
                    if self.parameter_3.blank?
                        parameter_1 = self.parameter_1_type == "integer" ? self.parameter_1.to_i : self.parameter_1
                        parameter_2 = self.parameter_2_type == "integer" ? self.parameter_2.to_i : self.parameter_2
                        Rake::Task[self.task_name].reenable
                        Rake::Task[self.task_name].invoke(parameter_1,parameter_2)
                        Rake::Task[self.task_name].reenable
                    else 
                        parameter_1 = self.parameter_1_type == "integer" ? self.parameter_1.to_i : self.parameter_1
                        parameter_2 = self.parameter_2_type == "integer" ? self.parameter_2.to_i : self.parameter_2
                        parameter_3 = self.parameter_3_type == "integer" ? self.parameter_3.to_i : self.parameter_3
                        Rake::Task[self.task_name].reenable
                        Rake::Task[self.task_name].invoke(parameter_1,parameter_2,parameter_3)
                        Rake::Task[self.task_name].reenable
                    end
                end
            end
        rescue => error
            self.update_attributes(last_attempt_date: Time.now)
            result = {task_name:self.task_name,status:false,reason:error.message}
        else 
            self.update_attributes(last_successful_run: Time.now)
            self.update_attributes(last_attempt_date: Time.now)
            result = {task_name:self.task_name,status:true}
        end
        result 
    end

end
