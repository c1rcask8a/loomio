require 'spec_helper'

describe Motion do
  subject do
    @motion = Motion.new
    @motion.valid?
    @motion
  end
  it {should have(1).errors_on(:name)}
  it {should have(1).errors_on(:author)}
  it {should have(1).errors_on(:group)}
  it {should have(1).errors_on(:facilitator_id)}

  context "user has voted" do
    it "user_has_votes?(user) returns true" do
      @user = User.make!
      @motion = create_motion(:author => @user)
      @vote = Vote.make(:user => @user, :motion => @motion, :position => "yes")
      @vote.save!
      @motion.user_has_voted?(@user).should == true
    end
  end

  context "user has not voted" do
    context "motion is open" do
      it "user_has_votes?(user) returns false" do
        @user1 = User.make!
        @motion1 = create_motion(:author => @user1)
        @motion1.user_has_voted?(@user1).should == false
      end
    end

    context "motion is closed" do
      it "user_has_votes?(user) returns false" do
        @user2 = User.make
        @user2.save
        @motion2 = create_motion(:author => @user2)
        @vote2 = Vote.make(:user => @user2, :motion => @motion2, :position => "did_not_vote")
        @vote2.save!
        @motion2.user_has_voted?(@user2).should == false
      end
    end
  end

  it "sends notification email to group members on successful create" do
    group = Group.make!
    group.add_member!(User.make!)
    group.add_member!(User.make!)
    # Do not send email to author, so subtract one from total emails sent
    MotionMailer.should_receive(:new_motion_created)
      .exactly(group.users.count - 1).times
      .with(kind_of(Motion), kind_of("")).and_return(stub(deliver: true))
    @motion = create_motion
  end

  it "cannot have invalid phases" do
    @motion = create_motion
    @motion.phase = 'bad'
    @motion.should_not be_valid
  end

  it "it can remain un-blocked" do
    @motion = create_motion
    user1 = User.make
    user1.save
    @motion.group.add_member!(user1)
    Vote.create!(position: 'yes', motion: @motion, user: user1)
    @motion.blocked?.should == false
  end

  it "it can be blocked" do
    @motion = create_motion
    user1 = User.make
    user1.save
    @motion.group.add_member!(user1)
    Vote.create!(position: 'block', motion: @motion, user: user1)
    @motion.blocked?.should == true
  end

  it "can have a close date" do
    @motion = create_motion
    @motion.close_date = '2012-12-12'
    @motion.close_date.should == Date.parse('2012-12-12')
    @motion.should be_valid
  end

  it "can have a discussion link" do
    @motion = create_motion
    @motion.discussion_url = "http://our-discussion.com"
    @motion.should be_valid
  end

  it "can have a discussion" do
    @motion = create_motion
    @motion.save
    @motion.discussion.should_not be_nil
  end

  it "can update vote_activity" do
    @motion = create_motion
    @motion.vote_activity = 3
    @motion.update_vote_activity
    @motion.vote_activity.should == 4
  end

  it "can update discussion_activity" do
    @motion = create_motion
    @motion.discussion_activity = 3
    @motion.update_discussion_activity
    @motion.discussion_activity.should == 4
  end

  context "users have voted" do
    before :each do
      @motion = create_motion
      user1 = @motion.author
      user2 = @motion.facilitator
      @user3 = User.make
      @user3.save
      @user4 = User.make
      @user4.save
      @motion.group.add_member!(user1)
      @motion.group.add_member!(user2)
      @motion.group.add_member!(@user3)
      @motion.group.add_member!(@user4)
      Vote.create!(position: 'yes', motion: @motion, user: user1)
      Vote.create!(position: 'no', motion: @motion, user: user2)
      Vote.create!(position: 'yes', motion: @motion, user: @user3)
      @motion.close_voting
    end

    it "members_voted returns number who voted" do
      @motion.members_voted.should == 3
    end

    it "members_count_when_closed returns group size at time of close" do
      user5 = User.make
      user5.save
      @motion.group.add_member!(user5)
      @motion.members_count_when_closed.should == 4
    end

    it "members_did_not_vote returns number who did not vote" do
      @motion.members_did_not_vote.should == 1
    end

    it "store_yet_to_vote should create votes for users who did not vote" do
      @motion.votes.for_user(@user3).position.should_not == "did_not_vote"
      @motion.votes.for_user(@user4).position.should == "did_not_vote"
    end

    it "clear_yet_to_vote should delete votes for users who did not vote" do
      @motion.open_voting
      @motion.votes.for_user(@user4).should == nil
    end
  end
end
