class Environment < ActiveRecord::Base
  include Paperclip::RemoteAttachment
  include Untied::Consumer::Sync::Zombificator::ActsAsZombie

  attr_accessible :core_id, :name, :zombie, :owner

  # Associações
  belongs_to :owner, class_name: 'User', foreign_key: 'user_id'

  has_many :user_environment_associations, dependent: :destroy
  has_many :users, through: :user_environment_associations

  has_many :courses, dependent: :destroy

  # Validadores
  validates_uniqueness_of :core_id
  validates_presence_of :core_id, :name, :owner

  # Thumbnail
  has_attached_file :thumbnail,
    ReduApps::Application.config.paperclip.merge({ styles: { small: "32x32#" } })

  has_remote_file :thumbnail

  def self.with_admin_permission(user)
    roles = [UserCourseAssociation.teacher,
      UserCourseAssociation.environment_admin]

    Environment.includes({ courses: [:spaces, :user_course_associations] }).
      where("user_course_associations.user_id" => user.id,
            "user_course_associations.role_cd" => roles)
  end
end
