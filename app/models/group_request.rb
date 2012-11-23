class GroupRequest < ActiveRecord::Base
  attr_accessible :admin_email, :description, :expected_size, :name, :cannot_contribute, :distribution_metric, :max_size
  validates :name, :presence => true, :length => {:maximum => 250}
  validates :description, :presence => true
  validates :admin_email, :presence => true, :email => true
  validates :expected_size, :presence => true


  belongs_to :group

  scope :approved, where(:status => :approved)
  scope :awaiting_approval, where(:status => :awaiting_approval)

  include AASM
  aasm :column => :status do  # defaults to aasm_state
    state :awaiting_approval, :initial => true
    state :approved
    state :ignored

    event :approve, :before => :approve_request do
      transitions :to => :approved, :from => [:awaiting_approval, :ignored]
    end

    event :ignore do
      transitions :to => :ignored, :from => [:awaiting_approval]
    end

    event :mark_as_already_approved do
      transitions :to => :approved, :from => [:awaiting_approval, :ignored]
    end
  end

  def distribution_metric_labels

  end

  private

  def approve_request
    @group = Group.new(:name => name)
    @group.creator = User.loomio_helper_bot
    @group.cannot_contribute = cannot_contribute
    @group.max_size = max_size
    @group.save!
    self.group_id = @group.id
    save!
    InvitesUsersToGroup.invite!(:recipient_emails => [admin_email],
                                :inviter => @group.creator,
                                :group => @group,
                                :access_level => "admin")
  end
end