class User < ActiveRecord::Base
  include Paperclip::RemoteAttachment
  include Untied::Consumer::Sync::Zombificator::ActsAsZombie

  attr_accessible :core_id, :login, :email, :first_name, :last_name, :role,
    :thumbnail, :client_applications, :core_role

  # Atributos de usuário Redu
  validates_presence_of :core_id, :login, :first_name, :last_name, :role
  validates_uniqueness_of :core_id, :login
  validates_length_of :login, minimum: 5, maximum: 20

  # Role (especialista / membro)
  as_enum :role, specialist: 0, member: 1

  # Aplicativos do usuário
  has_many :user_app_associations, dependent: :destroy
  has_many :apps, through: :user_app_associations

  # Ambientes em que o usuário pode adicionar aplicativos
  has_many :user_environment_associations, dependent: :destroy
  has_many :environments, through: :user_environment_associations

  # Cursos em que o usuário pode adicionar aplicativos
  has_many :user_course_associations, dependent: :destroy
  has_many :courses, through: :user_course_associations

  # Comentários
  has_many :comments, conditions: { type: 'Comment' }, dependent: :destroy

  # Thumbnail
  has_attached_file :thumbnail,
    ReduApps::Application.config.paperclip.merge({styles: { small: "x32#",
                                                            medium: "x90#" }})
  has_remote_file :thumbnail

  acts_as_authentic do |c|
    c.crypto_provider = CommunityEngineSha1CryptoMethod #lib/community_eng...
    # Utiliza o id do Core na sessão, desta forma o usuário também é logado no Core
    c.authlogic_record_primary_key = :core_id

    # Não é necessário pois não ocorrem cadastros através do Portal
    c.require_password_confirmation = false
    c.validate_password_field = false
    c.validate_email_field = false
    c.validate_login_field = false
  end

  def self.find_by_login_or_email(key)
    User.find_by_login(key) || User.find_by_email(key)
  end

  def to_param
    login
  end

  def display_name
    "#{self.first_name} #{self.last_name}"
  end

  # Associa token ao User.
  #
  # Ao receber uma lista do tipo:
  #   [{
  #    :user_token => "foo",
  #    :secret => "xxx",
  #   }]
  # Associa o :user_toke a self.token caso ReduApps::Application.config.
  # client_application possua o mesmo :secret. Caso contrário ignora a lista
  # recebida.
  def client_applications=(apps)
    apps ||= []
    secret = ReduApps::Application.config.client_application.
      fetch(:secret, nil)
    core_app = apps.detect { |a| a['secret'] == secret } || {}
    self.token = core_app.fetch('user_token', nil)
  end

  # Utiliza a coluna da tabela Users que guarda o role do usuário no Redu (core)
  def is_admin?
    core_role == 1
  end
end
