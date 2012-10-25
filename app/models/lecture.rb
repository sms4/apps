class Lecture < ActiveRecord::Base
  attr_accessible :lectureable_id, :lectureable_type, :lid, :name

  # Associações
  belongs_to :subject
  belongs_to :app

  # Validadores
  validates_presence_of :name, :subject
end