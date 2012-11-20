# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :lecture do
    sequence(:core_id)
    name "Nova Aula"
    subject { FactoryGirl.create(:subject) }
    lectureable_type "rea"
    sequence(:lectureable_id)
  end
end
