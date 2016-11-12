class Connection < ActiveRecord::Base
    belongs_to :user
    has_many :activities
    has_many :connection_scores
    has_many :connection_score_histories

    def name
        first_name+" "+last_name
    end

    def calculate_quality_score
        score = 0
        activities = self.activities
        # 1) Calculate the base score based on activities and weights assigned to each Relationship Quality Dimension (RQD)
        SystemSetting.search('rqd_weights').value_in_specified_type.each do |key, value|
            score += activities.joins{activity_definition.outer}.sum("activity_definitions.#{key.to_s} * #{value}").to_i
        end
        # 2) Add a bonus in for being initiated by connection
        percent_of_events_initiated_by_connection = activities.where(initiator:1).length.to_f / activites.length.to_f
        initator_bonus_settings = SystemSetting.search("initiator_bonus").value_in_specified_type
        bonus_multiplier = initiator_bonus_multiplier(percent_of_events_initiated_by_connection,initator_bonus_settings[:maximum_bonus_percent],initator_bonus_settings[:optimal_percent_of_events_initiated_by_connection],initator_bonus_settings[:point_of_zero_bonus_above_50_percent_of_events])
        
        score *= bonus_multiplier        
        score
    end

    def initiator_bonus_multiplier(percent_of_events_initiated_by_connection,maximum_bonus_percent,optimal_percent_of_events_initiated_by_connection,point_of_zero_bonus_above_50_percent_of_events)
          # use a root function for input percent from 0% to the optimal %, then a 6th root function to decrease down to bonus of 0 for input percentages above the optimal %. Decided by graphically looking at the plots
          parameter_increasing = (maximum_bonus_percent.to_f)/Math.sqrt(optimal_percent_of_events_initiated_by_connection.to_f)
          parameter_decreasing = (maximum_bonus_percent.to_f)/((-(optimal_percent_of_events_initiated_by_connection.to_f - point_of_zero_bonus_above_50_percent_of_events.to_f))**(1.000/6.000))

          if percent_of_events_initiated_by_connection.to_f <= optimal_percent_of_events_initiated_by_connection.to_f
            value = parameter_increasing * Math.sqrt(percent_of_events_initiated_by_connection.to_f) + 1
          else 
            value = parameter_decreasing * (-(percent_of_events_initiated_by_connection.to_f - point_of_zero_bonus_above_50_percent_of_events.to_f))**(1.000/6.000) + 1
          end
          value.instance_of?(Complex) ? 1 : value
    end
    
end
