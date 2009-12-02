class CreateAssignmentQuestionnaires < ActiveRecord::Migration
  def self.up
    drop_table :assignments_questionnaires
    create_table :assignment_questionnaires do |t|
      t.column :assignment_id,        :integer, :null => true
      t.column :questionnaire_id,     :integer, :null => true
      t.column :user_id,              :integer, :null => true
      t.column :notification_limit,   :integer, :null => false, :default => 15
      t.column :questionnaire_weight, :integer, :null => false, :default => 0
    end
    
    execute 'ALTER TABLE `assignment_questionnaires`
             ADD CONSTRAINT fk_aq_user_id
             FOREIGN KEY (user_id) REFERENCES users(id)'
  
    
    execute 'ALTER TABLE `assignment_questionnaires`
             ADD CONSTRAINT fk_aq_assignments_id
             FOREIGN KEY (assignment_id) REFERENCES assignments(id)'
  
    
    execute 'ALTER TABLE `assignment_questionnaires`
             ADD CONSTRAINT fk_aq_questionnaire_id
             FOREIGN KEY (questionnaire_id) REFERENCES questionnaires(id)'    
    
    Assignment.find(:all).each{
      | assignment |
      
      make_association('ReviewQuestionnaire',         assignment, assignment.review_questionnaire_id)
      make_association('MetareviewQuestionnaire',     assignment, assignment.review_of_review_questionnaire_id)
      make_association('AuthorFeedbackQuestionnaire', assignment, assignment.author_feedback_questionnaire_id)
      make_association('TeammateReviewQuestionnaire', assignment, assignment.teammate_review_questionnaire_id)        
    }
    
    NotificationLimit.find(:all).each{
      |l|
      begin
        association = AssignmentQuestionnaires.create(:user_id => l.user_id, :notification_limit => l.limit)
      rescue
        puts $!
      end
    }
    
    drop_table :questionnaire_weights
    drop_table :notification_limits               
  end
  
  def self.make_association(model, assignment, questionnaire_id)
      begin
        q = Object.const_get(model).find(questionnaire_id)
        association = AssignmentQuestionnaires.create(:assignment_id => assignment.id, :questionnaire_id => q.id)
                      
        l = NotificationLimit.find_by_assignment_id_and_questionnaire_id(assignment.id, q.id)
        w = QuestionnaireWeight.find_by_assignment_id_and_questionnaire_id(assignment.id, q.id)
        
        
        if l
          association.update_attribute("user_id",l.user_id)
          association.update_attribute("notification_limit",l.limit)  
          l.destroy
        end       
        
        if w
          association.update_attribute("questionnaire_weight",w.weight)    
          w.destroy
        end   
        
        if association.user_id.nil?
          association.update_attribute("user_id",assignment.instructor_id)
        end
      rescue
        puts "Assignment: #{assignment.id}"
        puts "  "+$!
      end     
  end

  def self.down
    drop_table :assignment_questionnaires
  end
end
