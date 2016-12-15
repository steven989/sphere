
# ActivityDefinition.create!([
#   {activity: "1-to-1 hangout", point_shared_experience_one_to_one: 10, point_shared_experience_group_private: nil, point_shared_experience_group_public: nil, point_provide_help: nil, point_receive_help: nil, point_provide_gift: nil, point_receive_gift: nil, point_shared_outcome: nil, point_shared_challenge: nil, point_communication_digital: nil, point_communication_in_person: 20, point_shared_interest: 3, point_intimacy: 10, specificity_level: 2},
#   {activity: "Attended a small group event", point_shared_experience_one_to_one: nil, point_shared_experience_group_private: 9, point_shared_experience_group_public: 1, point_provide_help: nil, point_receive_help: nil, point_provide_gift: nil, point_receive_gift: nil, point_shared_outcome: nil, point_shared_challenge: nil, point_communication_digital: nil, point_communication_in_person: 15, point_shared_interest: 3, point_intimacy: 10, specificity_level: 2},
#   {activity: "Organized a small group event", point_shared_experience_one_to_one: nil, point_shared_experience_group_private: 9, point_shared_experience_group_public: 1, point_provide_help: 1, point_receive_help: nil, point_provide_gift: nil, point_receive_gift: nil, point_shared_outcome: nil, point_shared_challenge: nil, point_communication_digital: nil, point_communication_in_person: 15, point_shared_interest: 3, point_intimacy: 10, specificity_level: 2},
#   {activity: "Attended a large social or networking event (general event)", point_shared_experience_one_to_one: nil, point_shared_experience_group_private: 1, point_shared_experience_group_public: 9, point_provide_help: nil, point_receive_help: nil, point_provide_gift: nil, point_receive_gift: nil, point_shared_outcome: nil, point_shared_challenge: 2, point_communication_digital: nil, point_communication_in_person: 15, point_shared_interest: 6, point_intimacy: 1, specificity_level: 2},
#   {activity: "Organized a large social event (Holiday Party, Office Party, Fundraiser etc Expert level)", point_shared_experience_one_to_one: nil, point_shared_experience_group_private: 1, point_shared_experience_group_public: 9, point_provide_help: 2, point_receive_help: nil, point_provide_gift: nil, point_receive_gift: nil, point_shared_outcome: nil, point_shared_challenge: nil, point_communication_digital: nil, point_communication_in_person: 15, point_shared_interest: 6, point_intimacy: 1, specificity_level: 2},
#   {activity: "Giving (Gifts, compliments, advice, help etc)", point_shared_experience_one_to_one: nil, point_shared_experience_group_private: nil, point_shared_experience_group_public: nil, point_provide_help: 5, point_receive_help: nil, point_provide_gift: 10, point_receive_gift: nil, point_shared_outcome: nil, point_shared_challenge: nil, point_communication_digital: nil, point_communication_in_person: 5, point_shared_interest: nil, point_intimacy: 15, specificity_level: 2},
#   {activity: "Check In", point_shared_experience_one_to_one: 2, point_shared_experience_group_private: 1, point_shared_experience_group_public: 1, point_provide_help: nil, point_receive_help: nil, point_provide_gift: nil, point_receive_gift: nil, point_shared_outcome: nil, point_shared_challenge: nil, point_communication_digital: 4, point_communication_in_person: 1, point_shared_interest: 1, point_intimacy: 3, specificity_level: 1}
# ])

# Badge.create!([
#   {name: "Great Friend", description: nil, criteria: "@level@>=4", graphic: nil},
#   {name: "Trusted Ally", description: nil, criteria: "@level@>=10", graphic: nil},
#   {name: "Professional Schmoozer", description: "", criteria: "@level@>=20", graphic: nil},
#   {name: "Party Sheriff", description: "Assembled 4 group hangouts this month", criteria: "@level@>2", graphic: "badge_id8_graphic.png"},
#   {name: "Social Animal", description: "Introduced yourself to 12 new people this month", criteria: "@level@>2", graphic: "badge_id7_graphic.png"},
#   {name: "Power Networkers", description: "Attended 8 networking events this month", criteria: "@level@>2", graphic: "badge_id2_graphic.png"}
# ])
Challenge.create!([
  {name: "Reach Out", instructions: "Contact a person you haven't spoken to  in a long time to catch up", description: "<h2>test</h2>", criteria: "(@level@ >=2)", repeated_allowed: true, graphic: "challenge_id6_graphic.png", days_to_complete: 7, reward: 150},
  {name: "The Coffee Challenge", instructions: "Ask the barista for a 10% discount on your coffee", description: "<h2>Nest's test somewhat</h2>", criteria: " (@level@ >=2)", repeated_allowed: true, graphic: "challenge_id5_graphic.png", days_to_complete: 7, reward: 1500},
  {name: "Social Stranger", instructions: "Say hi to 3 complete strangers in a public place", description: "<h2>Nest's test somewhat</h2>", criteria: " (@level@ >=2)", repeated_allowed: true, graphic: "challenge_id4_graphic.png", days_to_complete: 7, reward: 1500}
])

Level.create!([
  {level: 1, criteria: "@xp@ >= 900", graphic: "level_id1_graphic.png"},
  {level: 2, criteria: "@xp@ >= 2924", graphic: "level_id2_graphic.png"},
  {level: 3, criteria: "@xp@ >= 5825", graphic: "level_id3_graphic.png"},
  {level: 4, criteria: "@xp@ >= 9500", graphic: "level_id4_graphic.png"},
  {level: 5, criteria: "@xp@ >= 13883", graphic: "level_id5_graphic.png"},
  {level: 6, criteria: "@xp@ >= 18927", graphic: "level_id6_graphic.png"},
  {level: 7, criteria: "@xp@ >= 24598", graphic: nil},
  {level: 8, criteria: "@xp@ >= 30867", graphic: nil},
  {level: 9, criteria: "@xp@ >= 37709", graphic: nil},
  {level: 10, criteria: "@xp@ >= 45106", graphic: nil},
  {level: 11, criteria: "@xp@ >= 53040", graphic: nil},
  {level: 12, criteria: "@xp@ >= 61496", graphic: nil},
  {level: 13, criteria: "@xp@ >= 70460", graphic: nil},
  {level: 14, criteria: "@xp@ >= 79920", graphic: nil},
  {level: 15, criteria: "@xp@ >= 89866", graphic: nil},
  {level: 16, criteria: "@xp@ >= 100287", graphic: nil},
  {level: 17, criteria: "@xp@ >= 111174", graphic: nil},
  {level: 18, criteria: "@xp@ >= 122519", graphic: nil},
  {level: 19, criteria: "@xp@ >= 134314", graphic: nil},
  {level: 20, criteria: "@xp@ >= 146552", graphic: nil},
  {level: 21, criteria: "@xp@ >= 159226", graphic: nil},
  {level: 22, criteria: "@xp@ >= 172330", graphic: nil},
  {level: 23, criteria: "@xp@ >= 185857", graphic: nil},
  {level: 24, criteria: "@xp@ >= 199802", graphic: nil},
  {level: 25, criteria: "@xp@ >= 214161", graphic: nil},
  {level: 26, criteria: "@xp@ >= 228927", graphic: nil},
  {level: 27, criteria: "@xp@ >= 244096", graphic: nil},
  {level: 28, criteria: "@xp@ >= 259663", graphic: nil},
  {level: 29, criteria: "@xp@ >= 275625", graphic: nil},
  {level: 30, criteria: "@xp@ >= 291977", graphic: nil},
  {level: 31, criteria: "@xp@ >= 308714", graphic: nil},
  {level: 32, criteria: "@xp@ >= 325834", graphic: nil},
  {level: 33, criteria: "@xp@ >= 343333", graphic: nil},
  {level: 34, criteria: "@xp@ >= 361207", graphic: nil},
  {level: 35, criteria: "@xp@ >= 379453", graphic: nil},
  {level: 36, criteria: "@xp@ >= 398067", graphic: nil},
  {level: 37, criteria: "@xp@ >= 417047", graphic: nil},
  {level: 38, criteria: "@xp@ >= 436389", graphic: nil},
  {level: 39, criteria: "@xp@ >= 456091", graphic: nil},
  {level: 40, criteria: "@xp@ >= 476150", graphic: nil},
  {level: 41, criteria: "@xp@ >= 496563", graphic: nil},
  {level: 42, criteria: "@xp@ >= 517328", graphic: nil},
  {level: 43, criteria: "@xp@ >= 538441", graphic: nil},
  {level: 44, criteria: "@xp@ >= 559902", graphic: nil},
  {level: 45, criteria: "@xp@ >= 581706", graphic: nil},
  {level: 46, criteria: "@xp@ >= 603852", graphic: nil},
  {level: 47, criteria: "@xp@ >= 626338", graphic: nil},
  {level: 48, criteria: "@xp@ >= 649161", graphic: nil},
  {level: 49, criteria: "@xp@ >= 672319", graphic: nil},
  {level: 50, criteria: "@xp@ >= 695811", graphic: nil},
  {level: 51, criteria: "@xp@ >= 719634", graphic: nil},
  {level: 52, criteria: "@xp@ >= 743786", graphic: nil},
  {level: 53, criteria: "@xp@ >= 768265", graphic: nil},
  {level: 54, criteria: "@xp@ >= 793070", graphic: nil},
  {level: 55, criteria: "@xp@ >= 818199", graphic: nil},
  {level: 56, criteria: "@xp@ >= 843649", graphic: nil},
  {level: 57, criteria: "@xp@ >= 869420", graphic: nil},
  {level: 58, criteria: "@xp@ >= 895509", graphic: nil},
  {level: 59, criteria: "@xp@ >= 921915", graphic: nil},
  {level: 60, criteria: "@xp@ >= 948636", graphic: nil},
  {level: 61, criteria: "@xp@ >= 975670", graphic: nil},
  {level: 62, criteria: "@xp@ >= 1003017", graphic: nil},
  {level: 63, criteria: "@xp@ >= 1030674", graphic: nil},
  {level: 64, criteria: "@xp@ >= 1058640", graphic: nil},
  {level: 65, criteria: "@xp@ >= 1086914", graphic: nil},
  {level: 66, criteria: "@xp@ >= 1115493", graphic: nil},
  {level: 67, criteria: "@xp@ >= 1144378", graphic: nil},
  {level: 68, criteria: "@xp@ >= 1173566", graphic: nil},
  {level: 69, criteria: "@xp@ >= 1203056", graphic: nil},
  {level: 70, criteria: "@xp@ >= 1232846", graphic: nil},
  {level: 71, criteria: "@xp@ >= 1262937", graphic: nil},
  {level: 72, criteria: "@xp@ >= 1293325", graphic: nil},
  {level: 73, criteria: "@xp@ >= 1324010", graphic: nil},
  {level: 74, criteria: "@xp@ >= 1354991", graphic: nil},
  {level: 75, criteria: "@xp@ >= 1386266", graphic: nil},
  {level: 76, criteria: "@xp@ >= 1417834", graphic: nil},
  {level: 77, criteria: "@xp@ >= 1449695", graphic: nil},
  {level: 78, criteria: "@xp@ >= 1481846", graphic: nil},
  {level: 79, criteria: "@xp@ >= 1514288", graphic: nil},
  {level: 80, criteria: "@xp@ >= 1547018", graphic: nil},
  {level: 81, criteria: "@xp@ >= 1580036", graphic: nil},
  {level: 82, criteria: "@xp@ >= 1613340", graphic: nil},
  {level: 83, criteria: "@xp@ >= 1646930", graphic: nil},
  {level: 84, criteria: "@xp@ >= 1680804", graphic: nil},
  {level: 85, criteria: "@xp@ >= 1714962", graphic: nil},
  {level: 86, criteria: "@xp@ >= 1749403", graphic: nil},
  {level: 87, criteria: "@xp@ >= 1784124", graphic: nil},
  {level: 88, criteria: "@xp@ >= 1819127", graphic: nil},
  {level: 89, criteria: "@xp@ >= 1854408", graphic: nil},
  {level: 90, criteria: "@xp@ >= 1889969", graphic: nil},
  {level: 91, criteria: "@xp@ >= 1925807", graphic: nil},
  {level: 92, criteria: "@xp@ >= 1961922", graphic: nil},
  {level: 93, criteria: "@xp@ >= 1998313", graphic: nil},
  {level: 94, criteria: "@xp@ >= 2034978", graphic: nil},
  {level: 95, criteria: "@xp@ >= 2071918", graphic: nil},
  {level: 96, criteria: "@xp@ >= 2109131", graphic: nil},
  {level: 97, criteria: "@xp@ >= 2146616", graphic: nil},
  {level: 98, criteria: "@xp@ >= 2184373", graphic: nil},
  {level: 99, criteria: "@xp@ >= 2222400", graphic: nil},
  {level: 100, criteria: "@xp@ >= 2260697", graphic: nil},
  {level: 101, criteria: "@xp@ >= 2300000", graphic: "level_id106_graphic.png"}
])

StatisticDefinition.create!([
  {name: "level", description: "This is the user's current level", definition: "statistic = current_user.user_statistics.find_statistic(\"level\"); statistic.blank? ? current_user.user_statistics.create(statistic_definition_id:statistic_definition_id,name:\"level\",value:Level.find_level_for(current_user)) : statistic.take.update_attributes(value:Level.find_level_for(current_user))", operation_type: "individual", operation_trigger: "create_activity", priority: 0},
  {name: "xp", description: "Overall points for leveling purposes", definition: "quality_score = ActiveRecord::Base.connection.execute(\"Select sum(score_quality) From connection_scores where user_id = \#{current_user.id}\").values[0][0].to_i; challenge_score = ActiveRecord::Base.connection.execute(\"Select sum(reward) From user_challenge_completeds where user_id = \#{current_user.id}\").values[0][0].to_i ;statistic = current_user.user_statistics.where(name:\"xp\"); statistic.blank? ? current_user.user_statistics.create(statistic_definition_id:statistic_definition_id,name:\"xp\",value:quality_score+challenge_score) : statistic.take.update_attributes(value:quality_score+challenge_score)", operation_type: "individual", operation_trigger: "create_activity, complete_challenge", priority: 1}
])
SystemSetting.create!([
  {name: "rqd_weights", data_type: "hash", value: "{point_shared_experience_one_to_one:10,point_shared_experience_group_private:10,point_shared_experience_group_public:10,point_provide_help:20,point_receive_help:20,point_provide_gift:15,point_receive_gift:15,point_shared_outcome:20,point_shared_challenge:20,point_communication_digital:4,point_communication_in_person:6,point_shared_interest:15,point_intimacy:2}", description: nil},
  {name: "initiator_bonus", data_type: "hash", value: "{maximum_bonus_percent:0.5,optimal_percent_of_events_initiated_by_connection:0.5,point_of_zero_bonus_above_50_percent_of_events:0.75}", description: nil},
  {name: "default_contact_interval", data_type: "integer", value: "31", description: "This parameter is the default number of days to reach out to a contact. A user can change the interval for individual connections but this is what shows up for all new connections"},
  {name: "bubbles_parameters", data_type: "hash", value: "{:min_gap_between_bubbles=>17, :min_distance_from_center_of_central_bubble=>5, :min_size_of_bubbles=>25, :max_size_of_bubbles=>55, :number_of_recursions=>20, :radius_of_central_bubble=>50}", description: "This setting controls the visualization parameters of the bubbles on user dashboard"},
  {name: "expiring_connection_notification_period_in_days", data_type: "integer", value: "5", description: "The number of days prior to the connection expiring when a reminder notification will appear in user's dashboard to remind the user to reach out to the connection"},
  {name: "default_user_settings", data_type: "hash", value: "{send_event_booking_notification_by_default:true,share_my_calendar_with_contacts:true,default_contact_interval_in_days:20,event_add_granularity:\"detailed\"}", description: nil},
  {name: "activity_detail_level_to_be_shown", data_type: "integer", value: "1", description: "This setting allows the control of the level of details to be shown when user checks in with a connection. The level is specified in the specificity_level column in ActivityDefinition model"},
  {name: "number_of_challenges_to_display_to_user", data_type: "integer", value: "3", description: "This is the number of challenges a user will see at a time on their dashboard"}
])

